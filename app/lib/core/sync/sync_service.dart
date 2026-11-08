import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';
import '../providers/app_mode_provider.dart';
import '../providers/isar_provider.dart';
import '../providers/pruefprotokoll_provider.dart';
import 'sync_engine.dart';

enum SyncStatus { idle, syncing, error, success }

enum SyncResult {
  success,
  offline,
  error,

  /// Roadmap M9.1: Server-Revision ist gegenüber dem zuletzt bekannten
  /// Stand zurückgesprungen (vermutlich Restore auf ein älteres Backup).
  /// Der Pull wurde zum Schutz lokaler Daten übersprungen; lokale Daten
  /// wurden stattdessen erneut hochgeladen.
  rollbackDetected,
}

class SyncService {
  static Timer? _pushTimer;

  // ── Pull ──────────────────────────────────────────────────────────────────

  /// Zieht alle Rohdaten vom Backend und speichert sie lokal (siehe
  /// [SyncEngine.pull]): Server-Datensätze überschreiben nur lokal
  /// unveränderte Datensätze; lokal geänderte warten auf den Push oder
  /// werden bei abweichender Serverversion zum Konflikt — AUSSER die
  /// Server-Revision ist gegenüber dem zuletzt bekannten Stand
  /// zurückgesprungen (Roadmap M9.1: Server-Restore-Schutz). In dem Fall
  /// wird der Merge übersprungen, um lokale, dem restaurierten Server noch
  /// unbekannte Daten nicht zu überschreiben.
  ///
  /// Gibt `true` zurück, wenn ein Rollback erkannt und der Merge deshalb
  /// übersprungen wurde, sonst `false`.
  ///
  /// Roadmap M9.7 — selektive Synchronisation: Es wird immer die aktuelle,
  /// geräteeigene Auswahl (SyncAuswahlRepository) mitgeschickt. Kunden
  /// sowie Basisdaten von Standorten/Verteilern kommen serverseitig
  /// trotzdem immer vollständig zurück — nur der "Aufbau" (Komponenten,
  /// Messungen, Sichtprüfungen) wird dadurch eingeschränkt. Frisch
  /// eingerichtete Geräte haben eine leere Auswahl (Default false) und
  /// laden deshalb zunächst keinen Aufbau — spart Datenvolumen/Speicher.
  static Future<bool> pullAll(Database db) async {
    try {
      return await _seriell(() => SyncEngine(db).pull());
    } catch (e) {
      debugPrint('pullAll fehlgeschlagen: $e');
      return false;
    }
  }

  /// Schiebt alle lokal geänderten Datensätze zum Backend (Roadmap
  /// Geräteprüfung M3: versioniert, Konflikte landen beim Nutzer statt
  /// still überschrieben zu werden). Gibt die Anzahl gesendeter zurück.
  static Future<int> pushAll(Database db) async =>
      (await _seriell(() => SyncEngine(db).push())).gesendet;

  /// Push und Pull laufen nie gleichzeitig (60-s-Pull vs. entprellter
  /// Push), sonst könnten sich die Sync-Metadaten gegenseitig überholen.
  static Future<void> _letzter = Future.value();

  static Future<T> _seriell<T>(Future<T> Function() aufgabe) {
    final ergebnis = _letzter.then((_) => aufgabe());
    _letzter = ergebnis.then((_) {}, onError: (_) {});
    return ergebnis;
  }

  // ── Ausstehende Protokoll-Uploads (Retry) ───────────────────────────────────

  /// Lädt alle lokal noch nicht im Backend angekommenen Prüfprotokolle
  /// erneut hoch — deckt sowohl "beim Erstellen offline gewesen" als auch
  /// "Upload ist wegen abgelaufenem Token mit 401 fehlgeschlagen" ab, da
  /// beide Fälle das PDF unverändert lokal zurücklassen (Task: Monteure
  /// haben nicht immer und überall Empfang). Einzelne fehlgeschlagene
  /// Retries brechen den Lauf nicht ab — sie bleiben einfach bis zum
  /// nächsten Sync ausstehend. Gibt die Anzahl erfolgreicher Uploads zurück.
  static Future<int> retryAusstehendeProtokolle(Database db) async {
    final repo = PruefprotokollRepository(db);
    final ausstehende = await repo.getAusstehende();
    var erfolgreich = 0;
    for (final p in ausstehende) {
      final pdfBase64 = p.pdfBase64;
      if (pdfBase64 == null) continue;
      try {
        final backendUuid = await ApiService.uploadProtokoll(
          pdfBytes: base64Decode(pdfBase64),
          verteilerBezeichnung: p.verteilerBezeichnung ?? '',
          standortBezeichnung: p.standortBezeichnung,
          kundenBezeichnung: p.kundenBezeichnung,
          prueferName: p.prueferName,
          firmaName: p.firma,
          protokollDatum: p.protokollDatum,
          messdatenJson: p.messdatenSnapshot,
          art: p.art,
        );
        if (backendUuid != null) {
          await repo.save(p.mitBackendUuid(backendUuid).ohnePdf());
          erfolgreich++;
        }
      } catch (e) {
        debugPrint('Retry-Upload für Protokoll ${p.uuid} fehlgeschlagen: $e');
      }
    }
    return erfolgreich;
  }

  // ── Triggered Push (debounced) ────────────────────────────────────────────

  /// Löst einen Push aus, 2 Sekunden nach dem letzten Aufruf.
  /// Nur aktiv wenn ein JWT-Token vorhanden (= Company-Modus).
  static void scheduleSync(Database db) {
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(seconds: 2), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString('jwt_token') == null) return;
        await pushAll(db);
      } catch (e) {
        debugPrint('scheduleSync push fehlgeschlagen: $e');
      }
    });
  }

  // ── Auto-Sync (connectivity-aware) ───────────────────────────────────────

  /// Push + Pull — bricht ab wenn kein JWT vorhanden oder Server nicht
  /// erreichbar. Gibt das Ergebnis zurück, damit Aufrufer Feedback zeigen können.
  /// Alle Netzwerkfehler (offline, Timeout, server error) werden als [SyncResult.offline]
  /// behandelt — kein Fehler-Popup für den Nutzer.
  ///
  /// Push läuft bewusst VOR dem Pull (Roadmap M9.1): Wurde der Server auf
  /// ein älteres Backup zurückgesetzt, lädt der Push lokale Daten dorthin
  /// idempotent wieder hoch, bevor der anschließende Pull die Revision
  /// prüft und einen ggf. weiterhin veralteten Serverstand erkennt, statt
  /// ihn blind zu übernehmen. Ausstehende Protokoll-Uploads laufen aus
  /// demselben Grund direkt nach dem Push — auch das ist letztlich nur
  /// eine weitere Art, lokale Daten zum Server zu bringen.
  ///
  /// Läuft schon ein Durchgang, kehrt ein weiterer sofort zurück — sonst
  /// könnten zwei Läufe dasselbe ausstehende PDF doppelt ablegen.
  static Future<SyncResult> autoSync(Database db) async {
    if (_autoSyncLaeuft) return SyncResult.success;
    _autoSyncLaeuft = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('jwt_token') == null) return SyncResult.offline;
      await pushAll(db);
      await retryAusstehendeProtokolle(db);
      final rollbackDetected = await pullAll(db);
      return rollbackDetected ? SyncResult.rollbackDetected : SyncResult.success;
    } catch (e) {
      debugPrint('autoSync: keine Verbindung oder Fehler: $e');
      return SyncResult.offline;
    } finally {
      _autoSyncLaeuft = false;
    }
  }

  static bool _autoSyncLaeuft = false;

  // ── Backward compat (weiterhin exportiert) ────────────────────────────────

  /// @deprecated Nutze pullAll()
  static Future<void> pullKunden(Database db) => pullAll(db);

  /// @deprecated Nutze scheduleSync()
  static void pushAfterChange(Database db) => scheduleSync(db);
}

final syncStatusProvider =
    StateProvider<SyncStatus>((ref) => SyncStatus.idle);

/// Ein automatischer Sync-Durchgang; in Tests ersetzbar.
final syncLaufProvider = Provider<Future<SyncResult> Function(Database db)>((ref) => SyncService.autoSync);

/// Angemeldet am Backend: sofort (nach Login bzw. App-Start) alle lokalen
/// Daten hochladen, danach alle 60 s Push + ausstehende Protokolle + Pull —
/// so kommen auch Änderungen aus einem Funkloch ohne weiteres Zutun an.
/// Der Download bleibt auf die Auswahl beschränkt (siehe [SyncEngine.pull]).
/// Stoppt sich selbst bei Logout. In AppScaffold watchen.
final autoSyncProvider = Provider<void>((ref) {
  final modus = ref.watch(appModusProvider).valueOrNull;
  if (modus != AppModus.company) return;

  final db = ref.watch(dbProvider).valueOrNull;
  if (db == null) return;

  final lauf = ref.watch(syncLaufProvider);
  unawaited(lauf(db));
  final timer = Timer.periodic(const Duration(seconds: 60), (_) => lauf(db));
  ref.onDispose(timer.cancel);
});

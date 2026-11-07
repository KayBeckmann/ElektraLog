import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/isar_service.dart';
import '../api/api_service.dart';
import '../models/kunde.dart';
import '../models/standort.dart';
import '../models/verteiler.dart';
import '../models/verteiler_komponente.dart';
import '../models/messung.dart';
import '../models/sichtpruefung.dart';
import '../providers/app_mode_provider.dart';
import '../providers/isar_provider.dart';
import '../providers/pruefprotokoll_provider.dart';
import '../providers/sync_auswahl_provider.dart';
import 'sync_revision.dart';

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

  static const _lastRevisionPrefsKey = 'sync_last_known_revision';

  static Future<int?> _getLastKnownRevision() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastRevisionPrefsKey);
  }

  static Future<void> _storeLastKnownRevision(int revision) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastRevisionPrefsKey, revision);
  }

  // ── Pull ──────────────────────────────────────────────────────────────────

  /// Zieht alle Rohdaten vom Backend und speichert sie lokal.
  /// Server hat Vorrang: Server-Datensatz überschreibt den lokalen —
  /// AUSSER die Server-Revision ist gegenüber dem zuletzt bekannten Stand
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
      final auswahl = SyncAuswahlRepository(db);
      final data = await ApiService.pullAll(
        standortUuids: await auswahl.getAktivierteStandortUuids(),
        verteilerUuids: await auswahl.getAktivierteVerteilerUuids(),
      );

      final serverRevision = data['syncRevision'] as int?;
      if (serverRevision != null) {
        final lastKnown = await _getLastKnownRevision();
        final check = evaluateSyncRevision(
          lastKnown: lastKnown,
          serverRevision: serverRevision,
        );
        if (check == RevisionCheck.rollbackDetected) {
          debugPrint(
            'Sync-Rollback erkannt: Server-Revision $serverRevision < '
            'zuletzt bekannt $lastKnown — Pull-Merge übersprungen.',
          );
          return true;
        }
        // Baseline nur bei nicht-erkanntem Rollback fortschreiben, damit
        // ein erkannter Rollback bei jedem weiteren Sync erneut geprüft
        // wird, bis der Server den alten Stand wieder erreicht/überholt hat.
        await _storeLastKnownRevision(serverRevision);
      }

      await _mergeList<Kunde>(
        db: db,
        store: StorageService.kundenStore,
        items: (data['kunden'] as List? ?? [])
            .map((e) => Kunde.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

      await _mergeList<Standort>(
        db: db,
        store: StorageService.standorteStore,
        items: (data['standorte'] as List? ?? [])
            .map((e) => Standort.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

      await _mergeList<Verteiler>(
        db: db,
        store: StorageService.verteilerStore,
        items: (data['verteiler'] as List? ?? [])
            .map((e) => Verteiler.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

      await _mergeList<VerteilerKomponente>(
        db: db,
        store: StorageService.komponentenStore,
        items: (data['komponenten'] as List? ?? [])
            .map((e) => VerteilerKomponente.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
      );

      await _mergeList<Messung>(
        db: db,
        store: StorageService.messungenStore,
        items: (data['messungen'] as List? ?? [])
            .map((e) => Messung.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

      await _mergeList<Sichtpruefung>(
        db: db,
        store: StorageService.sichtpruefungStore,
        items: (data['sichtpruefungen'] as List? ?? [])
            .map((e) =>
                Sichtpruefung.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );
      return false;
    } catch (e) {
      debugPrint('pullAll fehlgeschlagen: $e');
      return false;
    }
  }

  /// Speichert Server-Datensätze lokal — Serverdaten haben IMMER Vorrang
  /// (siehe Obsidian-Inbox "Synchronisation"-Notiz), unabhängig von
  /// irgendwelchen Zeitstempeln. Lokale, noch nicht gepushte Änderungen
  /// werden dadurch beim nächsten Pull überschrieben.
  static Future<void> _mergeList<T>({
    required Database db,
    required StoreRef store,
    required List<T> items,
  }) async {
    for (final item in items) {
      final json = (item as dynamic).toJson() as Map<String, dynamic>;
      final uuid = json['uuid'] as String?;
      if (uuid == null) continue;

      await store.record(uuid).put(db, json.cast<String, Object?>());
    }
  }

  // ── Push ──────────────────────────────────────────────────────────────────

  /// Schiebt alle lokalen Rohdaten zum Backend. Das Backend übernimmt sie
  /// unconditional (kein Last-Write-Wins per Zeitstempel mehr) — der
  /// anschließende [pullAll] stellt sicher, dass am Ende immer der
  /// Serverstand lokal gilt.
  static Future<int> pushAll(Database db) async {
    final kunden = (await StorageService.kundenStore.find(db))
        .map((s) => Kunde.fromJson(s.value.cast<String, dynamic>()).toJson())
        .toList();

    final standorte = (await StorageService.standorteStore.find(db))
        .map((s) =>
            Standort.fromJson(s.value.cast<String, dynamic>()).toJson())
        .toList();

    final verteiler = (await StorageService.verteilerStore.find(db))
        .map((s) =>
            Verteiler.fromJson(s.value.cast<String, dynamic>()).toJson())
        .toList();

    final komponenten = (await StorageService.komponentenStore.find(db))
        .map((s) => VerteilerKomponente.fromJson(
                s.value.cast<String, dynamic>())
            .toJson())
        .toList();

    final messungen = (await StorageService.messungenStore.find(db))
        .map((s) => Messung.fromJson(s.value.cast<String, dynamic>()).toJson())
        .toList();

    final sichtpruefungen = (await StorageService.sichtpruefungStore.find(db))
        .map((s) =>
            Sichtpruefung.fromJson(s.value.cast<String, dynamic>()).toJson())
        .toList();

    await ApiService.syncAll([
      {'type': 'kunden', 'items': kunden},
      {'type': 'standorte', 'items': standorte},
      {'type': 'verteiler', 'items': verteiler},
      {'type': 'komponenten', 'items': komponenten},
      {'type': 'messungen', 'items': messungen},
      {'type': 'sichtpruefungen', 'items': sichtpruefungen},
    ]);

    return kunden.length +
        standorte.length +
        verteiler.length +
        komponenten.length +
        messungen.length +
        sichtpruefungen.length;
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
  static Future<SyncResult> autoSync(Database db) async {
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
    }
  }

  // ── Backward compat (weiterhin exportiert) ────────────────────────────────

  /// @deprecated Nutze pullAll()
  static Future<void> pullKunden(Database db) => pullAll(db);

  /// @deprecated Nutze scheduleSync()
  static void pushAfterChange(Database db) => scheduleSync(db);
}

final syncStatusProvider =
    StateProvider<SyncStatus>((ref) => SyncStatus.idle);

/// Startet automatisch einen Pull alle 60s wenn im Company-Modus.
/// Stoppt sich selbst bei Logout. In AppScaffold watchen.
final autoSyncProvider = Provider<void>((ref) {
  final modus = ref.watch(appModusProvider).valueOrNull;
  if (modus != AppModus.company) return;

  final db = ref.watch(dbProvider).valueOrNull;
  if (db == null) return;

  final timer = Timer.periodic(const Duration(seconds: 60), (_) {
    SyncService.pullAll(db);
  });
  ref.onDispose(timer.cancel);
});

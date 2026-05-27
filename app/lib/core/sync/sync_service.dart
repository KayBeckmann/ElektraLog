import 'dart:async';
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

enum SyncStatus { idle, syncing, error, success }

class SyncService {
  static Timer? _pushTimer;

  // ── Pull ──────────────────────────────────────────────────────────────────

  /// Zieht alle Rohdaten vom Backend und speichert sie lokal.
  /// Last-write-wins: Server-Datensatz gewinnt nur wenn neuer als lokaler.
  static Future<void> pullAll(Database db) async {
    try {
      final data = await ApiService.pullAll();

      await _mergeList<Kunde>(
        db: db,
        store: StorageService.kundenStore,
        items: (data['kunden'] as List? ?? [])
            .map((e) => Kunde.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        timestampKey: 'aktualisiertAm',
      );

      await _mergeList<Standort>(
        db: db,
        store: StorageService.standorteStore,
        items: (data['standorte'] as List? ?? [])
            .map((e) => Standort.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        timestampKey: 'aktualisiertAm',
      );

      await _mergeList<Verteiler>(
        db: db,
        store: StorageService.verteilerStore,
        items: (data['verteiler'] as List? ?? [])
            .map((e) => Verteiler.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        timestampKey: 'aktualisiertAm',
      );

      await _mergeList<VerteilerKomponente>(
        db: db,
        store: StorageService.komponentenStore,
        items: (data['komponenten'] as List? ?? [])
            .map((e) => VerteilerKomponente.fromJson(
                (e as Map).cast<String, dynamic>()))
            .toList(),
        timestampKey: 'aktualisiertAm',
      );

      await _mergeList<Messung>(
        db: db,
        store: StorageService.messungenStore,
        items: (data['messungen'] as List? ?? [])
            .map((e) => Messung.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        timestampKey: 'aktualisiertAm',
      );

      await _mergeList<Sichtpruefung>(
        db: db,
        store: StorageService.sichtpruefungStore,
        items: (data['sichtpruefungen'] as List? ?? [])
            .map((e) =>
                Sichtpruefung.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        timestampKey: 'aktualisiertAm',
      );
    } catch (e) {
      debugPrint('pullAll fehlgeschlagen: $e');
    }
  }

  /// Speichert Server-Datensätze lokal, wenn neuer als lokale Version.
  static Future<void> _mergeList<T>({
    required Database db,
    required StoreRef store,
    required List<T> items,
    required String timestampKey,
  }) async {
    for (final item in items) {
      final json = (item as dynamic).toJson() as Map<String, dynamic>;
      final uuid = json['uuid'] as String;
      final serverTs = DateTime.tryParse(json[timestampKey] as String? ?? '');
      if (serverTs == null) continue;

      final existing = await store.record(uuid).get(db) as Map?;
      if (existing != null) {
        final localTs = DateTime.tryParse(
            existing[timestampKey] as String? ?? existing['erstelltAm'] as String? ?? '');
        if (localTs != null && !serverTs.isAfter(localTs)) continue;
      }
      await store.record(uuid).put(db, json.cast<String, Object?>());
    }
  }

  // ── Push ──────────────────────────────────────────────────────────────────

  /// Schiebt alle lokalen Rohdaten zum Backend. Backend akzeptiert nur
  /// wenn der Client-Zeitstempel neuer ist als der Server-Zeitstempel.
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

  // ── Backward compat (weiterhin exportiert) ────────────────────────────────

  /// @deprecated Nutze pullAll()
  static Future<void> pullKunden(Database db) => pullAll(db);

  /// @deprecated Nutze scheduleSync()
  static void pushAfterChange(Database db) => scheduleSync(db);
}

final syncStatusProvider =
    StateProvider<SyncStatus>((ref) => SyncStatus.idle);

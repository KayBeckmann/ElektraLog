import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../api/api_service.dart';
import '../models/kunde.dart';

enum SyncStatus { idle, syncing, error, success }

class SyncService {
  /// Push: alle lokalen Kunden zum Backend hochladen (Upsert).
  static Future<int> syncToBackend(Database db) async {
    final snapshots = await StorageService.kundenStore.find(db);
    if (snapshots.isEmpty) return 0;
    final kunden = snapshots
        .map((s) => Kunde.fromJson(s.value.cast<String, dynamic>()))
        .toList();
    await ApiService.syncKunden(kunden.map((k) => k.toJson()).toList());
    return kunden.length;
  }

  /// Pull: Kunden vom Backend holen und lokal einspeichern.
  /// Backend ist Source of Truth — vorhandene Einträge werden überschrieben.
  static Future<void> pullKunden(Database db) async {
    try {
      final remote = await ApiService.getKunden();
      for (final raw in remote) {
        final k = Kunde.fromJson((raw as Map).cast<String, dynamic>());
        await StorageService.kundenStore
            .record(k.uuid)
            .put(db, k.toJson().cast<String, Object?>());
      }
    } catch (e) {
      debugPrint('pullKunden fehlgeschlagen: $e');
    }
  }

  /// Push nach einzelner lokaler Änderung — feuert im Hintergrund.
  static void pushAfterChange(Database db) {
    syncToBackend(db).catchError((e) {
      debugPrint('pushAfterChange fehlgeschlagen: $e');
    });
  }
}

final syncStatusProvider =
    StateProvider<SyncStatus>((ref) => SyncStatus.idle);

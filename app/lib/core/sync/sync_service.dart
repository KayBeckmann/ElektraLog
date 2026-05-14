import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../api/api_service.dart';
import '../models/kunde.dart';

enum SyncStatus { idle, syncing, error, success }

class SyncService {
  /// Uploads all local Sembast Kunden to the backend via bulk-sync.
  /// Returns the number of items synced.
  static Future<int> syncToBackend(Database db) async {
    final snapshots = await StorageService.kundenStore.find(db);
    if (snapshots.isEmpty) return 0;

    final kunden = snapshots
        .map((s) => Kunde.fromJson(s.value.cast<String, dynamic>()))
        .toList();

    await ApiService.syncKunden(kunden.map((k) => k.toJson()).toList());
    return kunden.length;
  }
}

final syncStatusProvider =
    StateProvider<SyncStatus>((ref) => SyncStatus.idle);

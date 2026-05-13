import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/verteiler.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class VerteilerRepository {
  const VerteilerRepository(this._db);

  final Database _db;

  Stream<List<Verteiler>> watchByStandort(String standortUuid) {
    final finder = Finder(
      filter: Filter.equals('standortUuid', standortUuid),
      sortOrders: [SortOrder('bezeichnung')],
    );
    return StorageService.verteilerStore
        .query(finder: finder)
        .onSnapshots(_db)
        .map((snapshots) => snapshots
            .map((s) => Verteiler.fromJson(s.value.cast<String, dynamic>()))
            .toList());
  }

  Future<List<Verteiler>> getByStandort(String standortUuid) async {
    final finder = Finder(
      filter: Filter.equals('standortUuid', standortUuid),
      sortOrders: [SortOrder('bezeichnung')],
    );
    final snapshots =
        await StorageService.verteilerStore.find(_db, finder: finder);
    return snapshots
        .map((s) => Verteiler.fromJson(s.value.cast<String, dynamic>()))
        .toList();
  }

  Future<Verteiler?> getByUuid(String uuid) async {
    final snapshot =
        await StorageService.verteilerStore.record(uuid).get(_db);
    if (snapshot == null) return null;
    return Verteiler.fromJson(snapshot.cast<String, dynamic>());
  }

  Future<void> save(Verteiler verteiler) async {
    await StorageService.verteilerStore
        .record(verteiler.uuid)
        .put(_db, verteiler.toJson().cast<String, Object?>());
  }

  Future<void> delete(String uuid) async {
    await StorageService.verteilerStore.record(uuid).delete(_db);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final verteilerRepositoryProvider = Provider<VerteilerRepository>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => VerteilerRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final verteilerByStandortProvider =
    StreamProvider.family<List<Verteiler>, String>((ref, standortUuid) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => VerteilerRepository(db).watchByStandort(standortUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

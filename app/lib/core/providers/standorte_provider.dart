import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/standort.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class StandorteRepository {
  const StandorteRepository(this._db);

  final Database _db;

  Stream<List<Standort>> watchByKunde(String kundeUuid) {
    final finder = Finder(
      filter: Filter.equals('kundeUuid', kundeUuid),
      sortOrders: [SortOrder('bezeichnung')],
    );
    return StorageService.standorteStore
        .query(finder: finder)
        .onSnapshots(_db)
        .map((snapshots) => snapshots
            .map((s) => Standort.fromJson(s.value.cast<String, dynamic>()))
            .toList());
  }

  Future<List<Standort>> getByKunde(String kundeUuid) async {
    final finder = Finder(
      filter: Filter.equals('kundeUuid', kundeUuid),
      sortOrders: [SortOrder('bezeichnung')],
    );
    final snapshots = await StorageService.standorteStore.find(_db, finder: finder);
    return snapshots
        .map((s) => Standort.fromJson(s.value.cast<String, dynamic>()))
        .toList();
  }

  Future<Standort?> getByUuid(String uuid) async {
    final snapshot =
        await StorageService.standorteStore.record(uuid).get(_db);
    if (snapshot == null) return null;
    return Standort.fromJson(snapshot.cast<String, dynamic>());
  }

  Future<int> countByKunde(String kundeUuid) async {
    final filter = Filter.equals('kundeUuid', kundeUuid);
    return StorageService.standorteStore.count(_db, filter: filter);
  }

  Future<void> save(Standort standort) async {
    await StorageService.standorteStore
        .record(standort.uuid)
        .put(_db, standort.toJson().cast<String, Object?>());
  }

  Future<void> delete(String uuid) async {
    await StorageService.standorteStore.record(uuid).delete(_db);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final standorteRepositoryProvider = Provider<StandorteRepository>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => StandorteRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final standorteByKundeProvider =
    StreamProvider.family<List<Standort>, String>((ref, kundeUuid) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => StandorteRepository(db).watchByKunde(kundeUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

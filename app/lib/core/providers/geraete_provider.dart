import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/geraet.dart';
import 'isar_provider.dart';

class GeraeteRepository {
  final Database db;
  GeraeteRepository(this.db);

  Stream<List<Geraet>> watchByStandort(String standortUuid) {
    final finder = Finder(filter: Filter.equals('standortUuid', standortUuid));
    return StorageService.geraeteStore
        .query(finder: finder)
        .onSnapshots(db)
        .map((s) => s
            .map((snap) => Geraet.fromJson(snap.value.cast<String, dynamic>()))
            .toList()
          ..sort((a, b) => a.bezeichnung.compareTo(b.bezeichnung)));
  }

  Stream<List<Geraet>> watchAll() {
    return StorageService.geraeteStore
        .query()
        .onSnapshots(db)
        .map((s) => s
            .map((snap) => Geraet.fromJson(snap.value.cast<String, dynamic>()))
            .toList());
  }

  Future<void> save(Geraet geraet) async {
    await StorageService.geraeteStore
        .record(geraet.uuid)
        .put(db, geraet.toJson().cast<String, Object?>());
  }

  Future<void> delete(String uuid) async {
    await StorageService.geraeteStore.record(uuid).delete(db);
  }

  Future<Geraet?> findByUuid(String uuid) async {
    final snap = await StorageService.geraeteStore.record(uuid).get(db);
    if (snap == null) return null;
    return Geraet.fromJson(snap.cast<String, dynamic>());
  }
}

final geraeteRepositoryProvider = Provider<GeraeteRepository>((ref) {
  final db = ref.watch(dbProvider).requireValue;
  return GeraeteRepository(db);
});

final geraeteByStandortProvider =
    StreamProvider.family<List<Geraet>, String>((ref, standortUuid) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => GeraeteRepository(db).watchByStandort(standortUuid),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

final alleGeraeteProvider = StreamProvider<List<Geraet>>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => GeraeteRepository(db).watchAll(),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

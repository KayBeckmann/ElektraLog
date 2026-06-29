import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/pruefprotokoll.dart';
import 'isar_provider.dart';

class PruefprotokollRepository {
  const PruefprotokollRepository(this._db);
  final Database _db;

  Stream<List<Pruefprotokoll>> watchByVerteiler(String verteilerUuid) {
    final finder = Finder(
      filter: Filter.equals('verteilerUuid', verteilerUuid),
      sortOrders: [SortOrder('protokollDatum', false)],
    );
    return StorageService.pruefprotokollStore
        .query(finder: finder)
        .onSnapshots(_db)
        .map((s) => s
            .map((snap) =>
                Pruefprotokoll.fromJson(snap.value.cast<String, dynamic>()))
            .toList());
  }

  Future<List<Pruefprotokoll>> getByVerteiler(String verteilerUuid) async {
    final finder = Finder(
      filter: Filter.equals('verteilerUuid', verteilerUuid),
      sortOrders: [SortOrder('protokollDatum', false)],
    );
    final snaps =
        await StorageService.pruefprotokollStore.find(_db, finder: finder);
    return snaps
        .map((snap) =>
            Pruefprotokoll.fromJson(snap.value.cast<String, dynamic>()))
        .toList();
  }

  Future<Pruefprotokoll?> latestByVerteiler(String verteilerUuid) async {
    final finder = Finder(
      filter: Filter.equals('verteilerUuid', verteilerUuid),
      sortOrders: [SortOrder('protokollDatum', false)],
      limit: 1,
    );
    final snaps =
        await StorageService.pruefprotokollStore.find(_db, finder: finder);
    if (snaps.isEmpty) return null;
    return Pruefprotokoll.fromJson(snaps.first.value.cast<String, dynamic>());
  }

  Future<void> save(Pruefprotokoll p) async {
    await StorageService.pruefprotokollStore
        .record(p.uuid)
        .put(_db, p.toJson().cast<String, Object?>());
  }
}

final pruefprotokollRepositoryProvider =
    Provider<PruefprotokollRepository>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => PruefprotokollRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final pruefprotokolleByVerteilerProvider =
    StreamProvider.family<List<Pruefprotokoll>, String>(
        (ref, verteilerUuid) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) =>
        PruefprotokollRepository(db).watchByVerteiler(verteilerUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

final allePruefprotokolleProvider =
    StreamProvider<List<Pruefprotokoll>>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) {
      final finder = Finder(sortOrders: [SortOrder('protokollDatum', false)]);
      return StorageService.pruefprotokollStore
          .query(finder: finder)
          .onSnapshots(db)
          .map((snaps) => snaps
              .map((snap) =>
                  Pruefprotokoll.fromJson(snap.value.cast<String, dynamic>()))
              .toList());
    },
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

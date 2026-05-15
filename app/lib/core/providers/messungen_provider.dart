import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/messung.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class MessungenRepository {
  const MessungenRepository(this._db);

  final Database _db;

  Stream<List<Messung>> watchByKomponente(String komponenteUuid) {
    final finder = Finder(
      filter: Filter.equals('komponenteUuid', komponenteUuid),
      sortOrders: [SortOrder('pruefungDatum', false)],
    );
    return StorageService.messungenStore
        .query(finder: finder)
        .onSnapshots(_db)
        .map((snapshots) => snapshots
            .map((s) => Messung.fromJson(s.value.cast<String, dynamic>()))
            .toList());
  }

  Stream<List<Messung>> watchByGeraet(String geraetUuid) {
    final finder = Finder(
      filter: Filter.equals('geraetUuid', geraetUuid),
      sortOrders: [SortOrder('pruefungDatum', false)],
    );
    return StorageService.messungenStore
        .query(finder: finder)
        .onSnapshots(_db)
        .map((snapshots) => snapshots
            .map((s) => Messung.fromJson(s.value.cast<String, dynamic>()))
            .toList());
  }

  Future<List<Messung>> getByKomponente(String komponenteUuid) async {
    final finder = Finder(
      filter: Filter.equals('komponenteUuid', komponenteUuid),
      sortOrders: [SortOrder('pruefungDatum', false)],
    );
    final snapshots =
        await StorageService.messungenStore.find(_db, finder: finder);
    return snapshots
        .map((s) => Messung.fromJson(s.value.cast<String, dynamic>()))
        .toList();
  }

  Future<List<Messung>> getByGeraet(String geraetUuid) async {
    final finder = Finder(
      filter: Filter.equals('geraetUuid', geraetUuid),
      sortOrders: [SortOrder('pruefungDatum', false)],
    );
    final snapshots =
        await StorageService.messungenStore.find(_db, finder: finder);
    return snapshots
        .map((s) => Messung.fromJson(s.value.cast<String, dynamic>()))
        .toList();
  }

  Future<void> deleteByKomponente(String komponenteUuid) async {
    final messungen = await getByKomponente(komponenteUuid);
    for (final m in messungen) {
      await StorageService.messungenStore.record(m.uuid).delete(_db);
    }
  }

  Future<List<Messung>> getAll() async {
    final finder = Finder(sortOrders: [SortOrder('pruefungDatum', false)]);
    final snapshots =
        await StorageService.messungenStore.find(_db, finder: finder);
    return snapshots
        .map((s) => Messung.fromJson(s.value.cast<String, dynamic>()))
        .toList();
  }

  Future<Messung?> getByUuid(String uuid) async {
    final snapshot =
        await StorageService.messungenStore.record(uuid).get(_db);
    if (snapshot == null) return null;
    return Messung.fromJson(snapshot.cast<String, dynamic>());
  }

  Future<void> save(Messung messung) async {
    await StorageService.messungenStore
        .record(messung.uuid)
        .put(_db, messung.toJson().cast<String, Object?>());
  }

  Future<void> delete(String uuid) async {
    await StorageService.messungenStore.record(uuid).delete(_db);
  }

  /// Alle Messungen für eine Liste von Komponenten-UUIDs (für PDF-Export)
  Future<List<Messung>> getByKomponenteUuids(List<String> uuids) async {
    if (uuids.isEmpty) return [];
    final finder = Finder(
      filter: Filter.inList('komponenteUuid', uuids),
      sortOrders: [SortOrder('pruefungDatum', false)],
    );
    final snapshots =
        await StorageService.messungenStore.find(_db, finder: finder);
    return snapshots
        .map((s) => Messung.fromJson(s.value.cast<String, dynamic>()))
        .toList();
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final messungenRepositoryProvider = Provider<MessungenRepository>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => MessungenRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final messungenByKomponenteProvider =
    StreamProvider.family<List<Messung>, String>((ref, komponenteUuid) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => MessungenRepository(db).watchByKomponente(komponenteUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

final messungenByGeraetProvider =
    StreamProvider.family<List<Messung>, String>((ref, geraetUuid) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => MessungenRepository(db).watchByGeraet(geraetUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

final alleMessungenProvider = StreamProvider<List<Messung>>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => StorageService.messungenStore
        .query()
        .onSnapshots(db)
        .map((snapshots) => snapshots
            .map((s) => Messung.fromJson(s.value.cast<String, dynamic>()))
            .toList()),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

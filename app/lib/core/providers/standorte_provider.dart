import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/standort.dart';
import '../sync/sync_service.dart';
import '../online/online_daten.dart';
import '../online/online_repositories.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

/// Datenzugriff; lokal (Endgeräte, sembast) oder online (Web-App, siehe
/// `core/online`). `StandorteRepository(db)` liefert die lokale Umsetzung.
abstract interface class StandorteRepository {
  const factory StandorteRepository(Database db) = LokaleStandorteRepository;

  Stream<List<Standort>> watchByKunde(String kundeUuid);
  Future<List<Standort>> getByKunde(String kundeUuid);
  Future<Standort?> getByUuid(String uuid);
  Future<int> countByKunde(String kundeUuid);
  Future<void> save(Standort standort);
  Future<void> delete(String uuid);
}

class LokaleStandorteRepository implements StandorteRepository {
  const LokaleStandorteRepository(this._db);

  final Database _db;

  @override
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

  @override
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

  @override
  Future<Standort?> getByUuid(String uuid) async {
    final snapshot =
        await StorageService.standorteStore.record(uuid).get(_db);
    if (snapshot == null) return null;
    return Standort.fromJson(snapshot.cast<String, dynamic>());
  }

  @override
  Future<int> countByKunde(String kundeUuid) async {
    final filter = Filter.equals('kundeUuid', kundeUuid);
    return StorageService.standorteStore.count(_db, filter: filter);
  }

  @override
  Future<void> save(Standort standort) async {
    await StorageService.standorteStore
        .record(standort.uuid)
        .put(_db, standort.toJson().cast<String, Object?>());
    SyncService.scheduleSync(_db);
  }

  @override
  Future<void> delete(String uuid) async {
    await StorageService.standorteStore.record(uuid).delete(_db);
    SyncService.scheduleSync(_db);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final standorteRepositoryProvider = Provider<StandorteRepository>((ref) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineStandorteRepository(o);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => StandorteRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final standorteByKundeProvider =
    StreamProvider.family<List<Standort>, String>((ref, kundeUuid) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineStandorteRepository(o).watchByKunde(kundeUuid);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => StandorteRepository(db).watchByKunde(kundeUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

final alleStandorteProvider = StreamProvider<List<Standort>>((ref) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineStandorteRepository(o).watchAlle();
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) {
      return StorageService.standorteStore
          .query(finder: Finder(sortOrders: [SortOrder('bezeichnung')]))
          .onSnapshots(db)
          .map((snaps) => snaps
              .map((snap) => Standort.fromJson(snap.value.cast<String, dynamic>()))
              .toList());
    },
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

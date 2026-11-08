import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/geraet.dart';
import '../models/raum.dart';
import '../sync/sync_service.dart';
import 'isar_provider.dart';

// ── Repositories ──────────────────────────────────────────────────────────────

class RaeumeRepository {
  const RaeumeRepository(this._db);

  final Database _db;

  static Raum _raum(RecordSnapshot<String, Map<String, Object?>> s) => Raum.fromJson(s.value.cast<String, dynamic>());

  Stream<List<Raum>> watchByStandort(String standortUuid) => StorageService.raeumeStore
      .query(
        finder: Finder(
          filter: Filter.equals('standortUuid', standortUuid),
          sortOrders: [SortOrder('bezeichnung')],
        ),
      )
      .onSnapshots(_db)
      .map((snaps) => snaps.map(_raum).toList());

  Future<List<Raum>> getByStandort(String standortUuid) async => (await StorageService.raeumeStore.find(
        _db,
        finder: Finder(
          filter: Filter.equals('standortUuid', standortUuid),
          sortOrders: [SortOrder('bezeichnung')],
        ),
      ))
          .map(_raum)
          .toList();

  Future<Raum?> getByUuid(String uuid) async {
    final snap = await StorageService.raeumeStore.record(uuid).get(_db);
    return snap == null ? null : Raum.fromJson(snap.cast<String, dynamic>());
  }

  Future<void> save(Raum raum) async {
    if (raum.bezeichnung.trim().isEmpty) {
      throw ArgumentError('Bezeichnung fehlt');
    }
    await StorageService.raeumeStore.record(raum.uuid).put(_db, raum.toJson().cast<String, Object?>());
    SyncService.scheduleSync(_db);
  }

  /// Nur leere Räume — Geräte erst umhängen (wie auf dem Server).
  Future<bool> deleteWennLeer(String uuid) async {
    final belegt = await StorageService.geraeteStore.count(_db, filter: Filter.equals('raumUuid', uuid));
    if (belegt > 0) return false;
    await StorageService.raeumeStore.record(uuid).delete(_db);
    SyncService.scheduleSync(_db);
    return true;
  }
}

class GeraeteRepository {
  const GeraeteRepository(this._db);

  final Database _db;

  static Geraet _geraet(RecordSnapshot<String, Map<String, Object?>> s) =>
      Geraet.fromJson(s.value.cast<String, dynamic>());

  static final _sortierung = [SortOrder('bezeichnung')];

  Stream<List<Geraet>> _watch(Filter? filter) => StorageService.geraeteStore
      .query(finder: Finder(filter: filter, sortOrders: _sortierung))
      .onSnapshots(_db)
      .map((snaps) => snaps.map(_geraet).toList());

  Stream<List<Geraet>> watchByStandort(String standortUuid) => _watch(Filter.equals('standortUuid', standortUuid));

  Stream<List<Geraet>> watchByRaum(String raumUuid) => _watch(Filter.equals('raumUuid', raumUuid));

  Stream<List<Geraet>> watchAlle() => _watch(null);

  Stream<Geraet?> watch(String uuid) => StorageService.geraeteStore
      .record(uuid)
      .onSnapshot(_db)
      .map((s) => s == null ? null : Geraet.fromJson(s.value.cast<String, dynamic>()));

  Future<Geraet?> getByUuid(String uuid) async {
    final snap = await StorageService.geraeteStore.record(uuid).get(_db);
    return snap == null ? null : Geraet.fromJson(snap.cast<String, dynamic>());
  }

  Future<List<Geraet>> getAlle() async =>
      (await StorageService.geraeteStore.find(_db, finder: Finder(sortOrders: _sortierung))).map(_geraet).toList();

  /// Speichert nur gültige Geräte (gleiche Regeln wie der Server).
  Future<void> save(Geraet geraet) async {
    final fehler = geraet.fehler;
    if (fehler.isNotEmpty) throw ArgumentError(fehler.join(', '));
    await StorageService.geraeteStore.record(geraet.uuid).put(_db, geraet.toJson().cast<String, Object?>());
    SyncService.scheduleSync(_db);
  }

  Future<void> delete(String uuid) async {
    await StorageService.geraeteStore.record(uuid).delete(_db);
    SyncService.scheduleSync(_db);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

T _mitDb<T>(Ref ref, T Function(Database db) f) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: f,
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
}

Stream<T> _streamMitDb<T>(Ref ref, Stream<T> Function(Database db) f) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: f,
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
}

final raeumeRepositoryProvider = Provider<RaeumeRepository>((ref) => _mitDb(ref, RaeumeRepository.new));

final geraeteRepositoryProvider = Provider<GeraeteRepository>((ref) => _mitDb(ref, GeraeteRepository.new));

final raeumeByStandortProvider = StreamProvider.family<List<Raum>, String>(
  (ref, standortUuid) => _streamMitDb(ref, (db) => RaeumeRepository(db).watchByStandort(standortUuid)),
);

final geraeteByStandortProvider = StreamProvider.family<List<Geraet>, String>(
  (ref, standortUuid) => _streamMitDb(ref, (db) => GeraeteRepository(db).watchByStandort(standortUuid)),
);

final geraeteByRaumProvider = StreamProvider.family<List<Geraet>, String>(
  (ref, raumUuid) => _streamMitDb(ref, (db) => GeraeteRepository(db).watchByRaum(raumUuid)),
);

final geraetProvider = StreamProvider.family<Geraet?, String>(
  (ref, uuid) => _streamMitDb(ref, (db) => GeraeteRepository(db).watch(uuid)),
);

final alleGeraeteProvider = StreamProvider<List<Geraet>>(
  (ref) => _streamMitDb(ref, (db) => GeraeteRepository(db).watchAlle()),
);

final alleRaeumeProvider = StreamProvider<List<Raum>>(
  (ref) => _streamMitDb(
    ref,
    (db) => StorageService.raeumeStore
        .query()
        .onSnapshots(db)
        .map((snaps) => snaps.map((s) => Raum.fromJson(s.value.cast<String, dynamic>())).toList()),
  ),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/geraet.dart';
import '../models/geraete_faelligkeit.dart';
import '../models/geraete_pruefung.dart';
import '../models/pruefmatrix.dart';
import '../models/raum.dart';
import '../sync/sync_meta.dart';
import '../sync/sync_service.dart';
import '../online/online_daten.dart';
import '../online/online_repositories.dart';
import 'isar_provider.dart';

// ── Repositories ──────────────────────────────────────────────────────────────

/// Datenzugriff; lokal (Endgeräte, sembast) oder online (Web-App, siehe
/// `core/online`). `RaeumeRepository(db)` liefert die lokale Umsetzung.
abstract interface class RaeumeRepository {
  const factory RaeumeRepository(Database db) = LokaleRaeumeRepository;

  Stream<List<Raum>> watchByStandort(String standortUuid);
  Future<List<Raum>> getByStandort(String standortUuid);
  Future<Raum?> getByUuid(String uuid);
  Future<void> save(Raum raum);
  /// Nur leere Räume — Geräte erst umhängen (wie auf dem Server).
  Future<bool> deleteWennLeer(String uuid);
}

class LokaleRaeumeRepository implements RaeumeRepository {
  const LokaleRaeumeRepository(this._db);

  final Database _db;

  static Raum _raum(RecordSnapshot<String, Map<String, Object?>> s) => Raum.fromJson(s.value.cast<String, dynamic>());

  @override
  Stream<List<Raum>> watchByStandort(String standortUuid) => StorageService.raeumeStore
      .query(
        finder: Finder(
          filter: Filter.equals('standortUuid', standortUuid),
          sortOrders: [SortOrder('bezeichnung')],
        ),
      )
      .onSnapshots(_db)
      .map((snaps) => snaps.map(_raum).toList());

  @override
  Future<List<Raum>> getByStandort(String standortUuid) async => (await StorageService.raeumeStore.find(
        _db,
        finder: Finder(
          filter: Filter.equals('standortUuid', standortUuid),
          sortOrders: [SortOrder('bezeichnung')],
        ),
      ))
          .map(_raum)
          .toList();

  @override
  Future<Raum?> getByUuid(String uuid) async {
    final snap = await StorageService.raeumeStore.record(uuid).get(_db);
    return snap == null ? null : Raum.fromJson(snap.cast<String, dynamic>());
  }

  @override
  Future<void> save(Raum raum) async {
    if (raum.bezeichnung.trim().isEmpty) {
      throw ArgumentError('Bezeichnung fehlt');
    }
    await StorageService.raeumeStore.record(raum.uuid).put(_db, raum.toJson().cast<String, Object?>());
    SyncService.scheduleSync(_db);
  }

  /// Nur leere Räume — Geräte erst umhängen (wie auf dem Server).
  @override
  Future<bool> deleteWennLeer(String uuid) async {
    final belegt = await StorageService.geraeteStore.count(_db, filter: Filter.equals('raumUuid', uuid));
    if (belegt > 0) return false;
    await StorageService.raeumeStore.record(uuid).delete(_db);
    SyncService.scheduleSync(_db);
    return true;
  }
}

/// Datenzugriff; lokal (Endgeräte, sembast) oder online (Web-App, siehe
/// `core/online`). `GeraeteRepository(db)` liefert die lokale Umsetzung.
abstract interface class GeraeteRepository {
  const factory GeraeteRepository(Database db) = LokaleGeraeteRepository;

  Stream<List<Geraet>> watchByStandort(String standortUuid);
  Stream<List<Geraet>> watchByRaum(String raumUuid);
  Stream<List<Geraet>> watchAlle();
  Stream<Geraet?> watch(String uuid);
  Future<Geraet?> getByUuid(String uuid);
  Future<List<Geraet>> getAlle();
  /// Speichert nur gültige Geräte (gleiche Regeln wie der Server).
  Future<void> save(Geraet geraet);
  /// Mit vom Nutzer bestätigtem Wechsel von Kunde, Standort oder Raum.
  Future<void> saveUmgehaengt(Geraet geraet);
  Future<void> delete(String uuid);
}

class LokaleGeraeteRepository implements GeraeteRepository {
  const LokaleGeraeteRepository(this._db);

  final Database _db;

  static Geraet _geraet(RecordSnapshot<String, Map<String, Object?>> s) =>
      Geraet.fromJson(s.value.cast<String, dynamic>());

  static final _sortierung = [SortOrder('bezeichnung')];

  Stream<List<Geraet>> _watch(Filter? filter) => StorageService.geraeteStore
      .query(finder: Finder(filter: filter, sortOrders: _sortierung))
      .onSnapshots(_db)
      .map((snaps) => snaps.map(_geraet).toList());

  @override
  Stream<List<Geraet>> watchByStandort(String standortUuid) => _watch(Filter.equals('standortUuid', standortUuid));

  @override
  Stream<List<Geraet>> watchByRaum(String raumUuid) => _watch(Filter.equals('raumUuid', raumUuid));

  @override
  Stream<List<Geraet>> watchAlle() => _watch(null);

  @override
  Stream<Geraet?> watch(String uuid) => StorageService.geraeteStore
      .record(uuid)
      .onSnapshot(_db)
      .map((s) => s == null ? null : Geraet.fromJson(s.value.cast<String, dynamic>()));

  @override
  Future<Geraet?> getByUuid(String uuid) async {
    final snap = await StorageService.geraeteStore.record(uuid).get(_db);
    return snap == null ? null : Geraet.fromJson(snap.cast<String, dynamic>());
  }

  @override
  Future<List<Geraet>> getAlle() async =>
      (await StorageService.geraeteStore.find(_db, finder: Finder(sortOrders: _sortierung))).map(_geraet).toList();

  /// Speichert nur gültige Geräte (gleiche Regeln wie der Server).
  @override
  Future<void> save(Geraet geraet) async {
    final fehler = geraet.fehler;
    if (fehler.isNotEmpty) throw ArgumentError(fehler.join(', '));
    await StorageService.geraeteStore.record(geraet.uuid).put(_db, geraet.toJson().cast<String, Object?>());
    SyncService.scheduleSync(_db);
  }

  /// Speichert ein Gerät mit vom Nutzer bestätigtem Wechsel von Kunde,
  /// Standort oder Raum. Ohne diese Bestätigung lehnt der Server den
  /// Ortswechsel als Konflikt ab (Roadmap M3).
  @override
  Future<void> saveUmgehaengt(Geraet geraet) async {
    await SyncMetaRepository(_db).bestaetigeZuordnung('geraete', geraet.uuid);
    await save(geraet);
  }

  @override
  Future<void> delete(String uuid) async {
    await StorageService.geraeteStore.record(uuid).delete(_db);
    SyncService.scheduleSync(_db);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Lokale Datenbank, oder online (Web-App angemeldet, siehe core/online).
T _mitDb<T>(Ref ref, T Function(Database db) f, T Function(OnlineDaten o) online) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return online(o);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: f,
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
}

Stream<T> _streamMitDb<T>(Ref ref, Stream<T> Function(Database db) f, Stream<T> Function(OnlineDaten o) online) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return online(o);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: f,
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
}

final raeumeRepositoryProvider = Provider<RaeumeRepository>((ref) => _mitDb(ref, RaeumeRepository.new, OnlineRaeumeRepository.new));

final geraeteRepositoryProvider = Provider<GeraeteRepository>((ref) => _mitDb(ref, GeraeteRepository.new, OnlineGeraeteRepository.new));

final raeumeByStandortProvider = StreamProvider.family<List<Raum>, String>(
  (ref, standortUuid) => _streamMitDb(
    ref,
    (db) => RaeumeRepository(db).watchByStandort(standortUuid),
    (o) => OnlineRaeumeRepository(o).watchByStandort(standortUuid),
  ),
);

final geraeteByStandortProvider = StreamProvider.family<List<Geraet>, String>(
  (ref, standortUuid) => _streamMitDb(
    ref,
    (db) => GeraeteRepository(db).watchByStandort(standortUuid),
    (o) => OnlineGeraeteRepository(o).watchByStandort(standortUuid),
  ),
);

final geraeteByRaumProvider = StreamProvider.family<List<Geraet>, String>(
  (ref, raumUuid) => _streamMitDb(
    ref,
    (db) => GeraeteRepository(db).watchByRaum(raumUuid),
    (o) => OnlineGeraeteRepository(o).watchByRaum(raumUuid),
  ),
);

final geraetProvider = StreamProvider.family<Geraet?, String>(
  (ref, uuid) => _streamMitDb(ref, (db) => GeraeteRepository(db).watch(uuid), (o) => OnlineGeraeteRepository(o).watch(uuid)),
);

final alleGeraeteProvider = StreamProvider<List<Geraet>>(
  (ref) => _streamMitDb(ref, (db) => GeraeteRepository(db).watchAlle(), (o) => OnlineGeraeteRepository(o).watchAlle()),
);

final alleRaeumeProvider = StreamProvider<List<Raum>>(
  (ref) => _streamMitDb(
    ref,
    (db) => StorageService.raeumeStore
        .query()
        .onSnapshots(db)
        .map((snaps) => snaps.map((s) => Raum.fromJson(s.value.cast<String, dynamic>())).toList()),
    (o) => OnlineRaeumeRepository(o).watchAlle(),
  ),
);

/// Datenzugriff; lokal (Endgeräte, sembast) oder online (Web-App, siehe
/// `core/online`). `GeraetePruefungenRepository(db)` liefert die lokale Umsetzung.
abstract interface class GeraetePruefungenRepository {
  const factory GeraetePruefungenRepository(Database db) = LokaleGeraetePruefungenRepository;

  Stream<List<GeraetePruefung>> watchByGeraet(String geraetUuid);
  Stream<List<GeraetePruefung>> watchAlle();
  Stream<GeraetePruefung?> watch(String uuid);
  Future<GeraetePruefung?> getByUuid(String uuid);
  Future<List<GeraetePruefung>> getByGeraet(String geraetUuid);
  Future<List<GeraetePruefung>> getAlle();
  /// Entwurf oder Abschluss; abgeschlossene sind unveränderlich.
  Future<void> save(GeraetePruefung p);
  /// Nur Entwürfe dürfen verworfen werden.
  Future<void> entwurfVerwerfen(String uuid);
}

class LokaleGeraetePruefungenRepository implements GeraetePruefungenRepository {
  const LokaleGeraetePruefungenRepository(this._db);

  final Database _db;

  static GeraetePruefung _pruefung(RecordSnapshot<String, Map<String, Object?>> s) =>
      GeraetePruefung.fromJson(s.value.cast<String, dynamic>());

  @override
  Stream<List<GeraetePruefung>> watchByGeraet(String geraetUuid) => StorageService.geraetepruefungenStore
      .query(
        finder: Finder(
          filter: Filter.equals('geraetUuid', geraetUuid),
          sortOrders: [SortOrder('pruefungDatum', false), SortOrder('erstelltAm', false)],
        ),
      )
      .onSnapshots(_db)
      .map((snaps) => snaps.map(_pruefung).toList());

  @override
  Stream<List<GeraetePruefung>> watchAlle() =>
      StorageService.geraetepruefungenStore.query().onSnapshots(_db).map((snaps) => snaps.map(_pruefung).toList());

  @override
  Stream<GeraetePruefung?> watch(String uuid) => StorageService.geraetepruefungenStore
      .record(uuid)
      .onSnapshot(_db)
      .map((s) => s == null ? null : GeraetePruefung.fromJson(s.value.cast<String, dynamic>()));

  @override
  Future<GeraetePruefung?> getByUuid(String uuid) async {
    final snap = await StorageService.geraetepruefungenStore.record(uuid).get(_db);
    return snap == null ? null : GeraetePruefung.fromJson(snap.cast<String, dynamic>());
  }

  @override
  Future<List<GeraetePruefung>> getByGeraet(String geraetUuid) async => (await StorageService.geraetepruefungenStore
          .find(_db, finder: Finder(filter: Filter.equals('geraetUuid', geraetUuid))))
      .map(_pruefung)
      .toList();

  @override
  Future<List<GeraetePruefung>> getAlle() async =>
      (await StorageService.geraetepruefungenStore.find(_db)).map(_pruefung).toList();

  /// Speichert einen Entwurf oder den Abschluss. Abgeschlossene Prüfungen
  /// sind unveränderlich; neue Prüfungen nur für aktive Geräte.
  @override
  Future<void> save(GeraetePruefung p) async {
    final bisher = await getByUuid(p.uuid);
    if (bisher != null && bisher.abgeschlossen) {
      throw StateError('Abgeschlossene Prüfung ist unveränderlich — Korrektur als neue Prüfung anlegen');
    }
    if (bisher == null) {
      final geraet = await GeraeteRepository(_db).getByUuid(p.geraetUuid);
      if (geraet == null) throw StateError('Gerät unbekannt');
      if (!geraet.aktiv) throw StateError('Inaktives Gerät: keine neue Prüfung');
    }
    if (p.abgeschlossen && abschlussFehler(p).isNotEmpty) {
      throw StateError(abschlussFehler(p).join(', '));
    }
    await StorageService.geraetepruefungenStore.record(p.uuid).put(_db, p.toJson().cast<String, Object?>());
    SyncService.scheduleSync(_db);
  }

  /// Nur Entwürfe dürfen verworfen werden.
  @override
  Future<void> entwurfVerwerfen(String uuid) async {
    final p = await getByUuid(uuid);
    if (p == null || p.abgeschlossen) return;
    await StorageService.geraetepruefungenStore.record(uuid).delete(_db);
    SyncService.scheduleSync(_db);
  }
}

final geraetePruefungenRepositoryProvider =
    Provider<GeraetePruefungenRepository>((ref) => _mitDb(ref, GeraetePruefungenRepository.new, OnlineGeraetePruefungenRepository.new));

final pruefungenByGeraetProvider = StreamProvider.family<List<GeraetePruefung>, String>(
  (ref, geraetUuid) => _streamMitDb(
    ref,
    (db) => GeraetePruefungenRepository(db).watchByGeraet(geraetUuid),
    (o) => OnlineGeraetePruefungenRepository(o).watchByGeraet(geraetUuid),
  ),
);

final geraetePruefungProvider = StreamProvider.family<GeraetePruefung?, String>(
  (ref, uuid) => _streamMitDb(
    ref,
    (db) => GeraetePruefungenRepository(db).watch(uuid),
    (o) => OnlineGeraetePruefungenRepository(o).watch(uuid),
  ),
);

final allePruefungenProvider = StreamProvider<List<GeraetePruefung>>(
  (ref) => _streamMitDb(
    ref,
    (db) => GeraetePruefungenRepository(db).watchAlle(),
    (o) => OnlineGeraetePruefungenRepository(o).watchAlle(),
  ),
);

/// Letzte gültige abgeschlossene Prüfung je Gerät (Basis der Fälligkeit).
final geraetePruefNachweiseProvider = StreamProvider<Map<String, PruefNachweis>>(
  (ref) => _streamMitDb(
    ref,
    (db) => GeraetePruefungenRepository(db).watchAlle().map(pruefNachweise),
    (o) => OnlineGeraetePruefungenRepository(o).watchAlle().map(pruefNachweise),
  ),
);

final geraetPruefNachweisProvider = Provider.family<AsyncValue<PruefNachweis?>, String>(
  (ref, uuid) => ref.watch(geraetePruefNachweiseProvider).whenData((m) => m[uuid]),
);

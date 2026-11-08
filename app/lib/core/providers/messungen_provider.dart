import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/messung.dart';
import '../sync/sync_service.dart';
import '../online/online_daten.dart';
import '../online/online_repositories.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

/// Datenzugriff; lokal (Endgeräte, sembast) oder online (Web-App, siehe
/// `core/online`). `MessungenRepository(db)` liefert die lokale Umsetzung.
abstract interface class MessungenRepository {
  const factory MessungenRepository(Database db) = LokaleMessungenRepository;

  Stream<List<Messung>> watchByKomponente(String komponenteUuid);
  Future<List<Messung>> getByKomponente(String komponenteUuid);
  Future<void> deleteByKomponente(String komponenteUuid);
  Future<List<Messung>> getAll();
  Future<Messung?> getByUuid(String uuid);
  Future<void> save(Messung messung);
  Future<void> delete(String uuid);
  Future<List<Messung>> getByKomponenteUuids(List<String> uuids);
}

class LokaleMessungenRepository implements MessungenRepository {
  const LokaleMessungenRepository(this._db);

  final Database _db;

  @override
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

  @override
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

  @override
  Future<void> deleteByKomponente(String komponenteUuid) async {
    final messungen = await getByKomponente(komponenteUuid);
    for (final m in messungen) {
      await StorageService.messungenStore.record(m.uuid).delete(_db);
    }
  }

  @override
  Future<List<Messung>> getAll() async {
    final finder = Finder(sortOrders: [SortOrder('pruefungDatum', false)]);
    final snapshots =
        await StorageService.messungenStore.find(_db, finder: finder);
    return snapshots
        .map((s) => Messung.fromJson(s.value.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<Messung?> getByUuid(String uuid) async {
    final snapshot = await StorageService.messungenStore.record(uuid).get(_db);
    if (snapshot == null) return null;
    return Messung.fromJson(snapshot.cast<String, dynamic>());
  }

  @override
  Future<void> save(Messung messung) async {
    await StorageService.messungenStore
        .record(messung.uuid)
        .put(_db, messung.toJson().cast<String, Object?>());
    SyncService.scheduleSync(_db);
  }

  @override
  Future<void> delete(String uuid) async {
    await StorageService.messungenStore.record(uuid).delete(_db);
    SyncService.scheduleSync(_db);
  }

  /// Alle Messungen für eine Liste von Komponenten-UUIDs (für PDF-Export)
  @override
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
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineMessungenRepository(o);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => MessungenRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final messungenByKomponenteProvider =
    StreamProvider.family<List<Messung>, String>((ref, komponenteUuid) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineMessungenRepository(o).watchByKomponente(komponenteUuid);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => MessungenRepository(db).watchByKomponente(komponenteUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

final alleMessungenProvider = StreamProvider<List<Messung>>((ref) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineMessungenRepository(o).watchAlle();
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => StorageService.messungenStore.query().onSnapshots(db).map(
        (snapshots) => snapshots
            .map((s) => Messung.fromJson(s.value.cast<String, dynamic>()))
            .toList()),
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

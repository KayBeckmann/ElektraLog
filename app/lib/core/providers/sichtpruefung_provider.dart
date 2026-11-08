import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/sichtpruefung.dart';
import '../sync/sync_service.dart';
import '../online/online_daten.dart';
import '../online/online_repositories.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

/// Datenzugriff; lokal (Endgeräte, sembast) oder online (Web-App, siehe
/// `core/online`). `SichtpruefungRepository(db)` liefert die lokale Umsetzung.
abstract interface class SichtpruefungRepository {
  const factory SichtpruefungRepository(Database db) = LokaleSichtpruefungRepository;

  Stream<List<Sichtpruefung>> watchByVerteiler(String verteilerUuid);
  Future<Sichtpruefung?> getLatestByVerteiler(String verteilerUuid);
  Future<void> save(Sichtpruefung sichtpruefung);
}

class LokaleSichtpruefungRepository implements SichtpruefungRepository {
  const LokaleSichtpruefungRepository(this._db);

  final Database _db;

  @override
  Stream<List<Sichtpruefung>> watchByVerteiler(String verteilerUuid) {
    final finder = Finder(
      filter: Filter.equals('verteilerUuid', verteilerUuid),
      sortOrders: [SortOrder('pruefungDatum', false)],
    );
    return StorageService.sichtpruefungStore
        .query(finder: finder)
        .onSnapshots(_db)
        .map((snapshots) => snapshots
            .map((s) =>
                Sichtpruefung.fromJson(s.value.cast<String, dynamic>()))
            .toList());
  }

  @override
  Future<Sichtpruefung?> getLatestByVerteiler(String verteilerUuid) async {
    final finder = Finder(
      filter: Filter.equals('verteilerUuid', verteilerUuid),
      sortOrders: [SortOrder('pruefungDatum', false)],
      limit: 1,
    );
    final snapshots =
        await StorageService.sichtpruefungStore.find(_db, finder: finder);
    if (snapshots.isEmpty) return null;
    return Sichtpruefung.fromJson(
        snapshots.first.value.cast<String, dynamic>());
  }

  @override
  Future<void> save(Sichtpruefung sichtpruefung) async {
    await StorageService.sichtpruefungStore
        .record(sichtpruefung.uuid)
        .put(_db, sichtpruefung.toJson().cast<String, Object?>());
    SyncService.scheduleSync(_db);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final sichtpruefungRepositoryProvider =
    Provider<SichtpruefungRepository>((ref) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineSichtpruefungRepository(o);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => SichtpruefungRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final sichtpruefungenByVerteilerProvider =
    StreamProvider.family<List<Sichtpruefung>, String>(
        (ref, verteilerUuid) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineSichtpruefungRepository(o).watchByVerteiler(verteilerUuid);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) =>
        SichtpruefungRepository(db).watchByVerteiler(verteilerUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

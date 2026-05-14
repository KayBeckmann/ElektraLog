import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/sichtpruefung.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class SichtpruefungRepository {
  const SichtpruefungRepository(this._db);

  final Database _db;

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

  Future<void> save(Sichtpruefung sichtpruefung) async {
    await StorageService.sichtpruefungStore
        .record(sichtpruefung.uuid)
        .put(_db, sichtpruefung.toJson().cast<String, Object?>());
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final sichtpruefungRepositoryProvider =
    Provider<SichtpruefungRepository>((ref) {
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
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) =>
        SichtpruefungRepository(db).watchByVerteiler(verteilerUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

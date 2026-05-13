import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/kunde.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class KundenRepository {
  const KundenRepository(this._db);

  final Database _db;

  Stream<List<Kunde>> watchAll() {
    return StorageService.kundenStore
        .query()
        .onSnapshots(_db)
        .map((snapshots) => snapshots
            .map((s) => Kunde.fromJson(s.value.cast<String, dynamic>()))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)));
  }

  Future<List<Kunde>> getAll() async {
    final snapshots = await StorageService.kundenStore.find(_db);
    return snapshots
        .map((s) => Kunde.fromJson(s.value.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<Kunde?> getByUuid(String uuid) async {
    final snapshot =
        await StorageService.kundenStore.record(uuid).get(_db);
    if (snapshot == null) return null;
    return Kunde.fromJson(snapshot.cast<String, dynamic>());
  }

  Future<void> save(Kunde kunde) async {
    await StorageService.kundenStore
        .record(kunde.uuid)
        .put(_db, kunde.toJson().cast<String, Object?>());
  }

  Future<void> delete(String uuid) async {
    await StorageService.kundenStore.record(uuid).delete(_db);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final kundenRepositoryProvider = Provider<KundenRepository>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => KundenRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final kundenProvider = StreamProvider<List<Kunde>>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => KundenRepository(db).watchAll(),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

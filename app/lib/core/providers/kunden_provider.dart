import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/kunde.dart';
import '../sync/sync_service.dart';
import '../online/online_daten.dart';
import '../online/online_repositories.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

/// Datenzugriff; lokal (Endgeräte, sembast) oder online (Web-App, siehe
/// `core/online`). `KundenRepository(db)` liefert die lokale Umsetzung.
abstract interface class KundenRepository {
  const factory KundenRepository(Database db) = LokaleKundenRepository;

  Stream<List<Kunde>> watchAll();
  Future<List<Kunde>> getAll();
  Future<Kunde?> getByUuid(String uuid);
  Future<void> save(Kunde kunde);
  Future<void> delete(String uuid);
}

class LokaleKundenRepository implements KundenRepository {
  const LokaleKundenRepository(this._db);

  final Database _db;

  @override
  Stream<List<Kunde>> watchAll() {
    return StorageService.kundenStore
        .query()
        .onSnapshots(_db)
        .map((snapshots) => snapshots
            .map((s) => Kunde.fromJson(s.value.cast<String, dynamic>()))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)));
  }

  @override
  Future<List<Kunde>> getAll() async {
    final snapshots = await StorageService.kundenStore.find(_db);
    return snapshots
        .map((s) => Kunde.fromJson(s.value.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<Kunde?> getByUuid(String uuid) async {
    final snapshot =
        await StorageService.kundenStore.record(uuid).get(_db);
    if (snapshot == null) return null;
    return Kunde.fromJson(snapshot.cast<String, dynamic>());
  }

  @override
  Future<void> save(Kunde kunde) async {
    await StorageService.kundenStore
        .record(kunde.uuid)
        .put(_db, kunde.toJson().cast<String, Object?>());
    SyncService.scheduleSync(_db);
  }

  @override
  Future<void> delete(String uuid) async {
    await StorageService.kundenStore.record(uuid).delete(_db);
    SyncService.scheduleSync(_db);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final kundenRepositoryProvider = Provider<KundenRepository>((ref) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineKundenRepository(o);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => KundenRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final kundenProvider = StreamProvider<List<Kunde>>((ref) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineKundenRepository(o).watchAll();
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => KundenRepository(db).watchAll(),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

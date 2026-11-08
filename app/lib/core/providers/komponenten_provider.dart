import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/verteiler_komponente.dart';
import '../sync/sync_service.dart';
import '../online/online_daten.dart';
import '../online/online_repositories.dart';
import 'isar_provider.dart';

/// Speichert die zuletzt angelegte Komponente als Vorlage für die nächste.
/// Wird in KomponenteFormular nach dem Speichern gesetzt.
final letzteKomponenteTemplateProvider =
    StateProvider<VerteilerKomponente?>((_) => null);

// ── Repository ────────────────────────────────────────────────────────────────

/// Datenzugriff; lokal (Endgeräte, sembast) oder online (Web-App, siehe
/// `core/online`). `KomponentenRepository(db)` liefert die lokale Umsetzung.
abstract interface class KomponentenRepository {
  const factory KomponentenRepository(Database db) = LokaleKomponentenRepository;

  Stream<List<VerteilerKomponente>> watchByVerteiler(String verteilerUuid);
  Future<List<VerteilerKomponente>> getByVerteiler(String verteilerUuid);
  Future<VerteilerKomponente?> getByUuid(String uuid);
  Future<void> save(VerteilerKomponente komponente);
  Future<void> delete(String uuid);
}

class LokaleKomponentenRepository implements KomponentenRepository {
  const LokaleKomponentenRepository(this._db);

  final Database _db;

  @override
  Stream<List<VerteilerKomponente>> watchByVerteiler(String verteilerUuid) {
    final finder = Finder(
      filter: Filter.equals('verteilerUuid', verteilerUuid),
      sortOrders: [SortOrder('position')],
    );
    return StorageService.komponentenStore
        .query(finder: finder)
        .onSnapshots(_db)
        .map((snapshots) => snapshots
            .map((s) =>
                VerteilerKomponente.fromJson(s.value.cast<String, dynamic>()))
            .toList());
  }

  @override
  Future<List<VerteilerKomponente>> getByVerteiler(
      String verteilerUuid) async {
    final finder = Finder(
      filter: Filter.equals('verteilerUuid', verteilerUuid),
      sortOrders: [SortOrder('position')],
    );
    final snapshots =
        await StorageService.komponentenStore.find(_db, finder: finder);
    return snapshots
        .map((s) =>
            VerteilerKomponente.fromJson(s.value.cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<VerteilerKomponente?> getByUuid(String uuid) async {
    final snapshot =
        await StorageService.komponentenStore.record(uuid).get(_db);
    if (snapshot == null) return null;
    return VerteilerKomponente.fromJson(snapshot.cast<String, dynamic>());
  }

  @override
  Future<void> save(VerteilerKomponente komponente) async {
    await StorageService.komponentenStore
        .record(komponente.uuid)
        .put(_db, komponente.toJson().cast<String, Object?>());
    SyncService.scheduleSync(_db);
  }

  @override
  Future<void> delete(String uuid) async {
    await StorageService.komponentenStore.record(uuid).delete(_db);
    SyncService.scheduleSync(_db);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final komponentenRepositoryProvider = Provider<KomponentenRepository>((ref) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineKomponentenRepository(o);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => KomponentenRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

final komponentenByVerteilerProvider =
    StreamProvider.family<List<VerteilerKomponente>, String>(
        (ref, verteilerUuid) {
  final o = ref.watch(onlineDatenProvider);
  if (o != null) return OnlineKomponentenRepository(o).watchByVerteiler(verteilerUuid);
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => KomponentenRepository(db).watchByVerteiler(verteilerUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

final komponenteProvider = FutureProvider.family<VerteilerKomponente?, String>((ref, uuid) async {
  final repo = ref.watch(komponentenRepositoryProvider);
  return repo.getByUuid(uuid);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import '../models/verteiler_komponente.dart';
import 'isar_provider.dart';

/// Speichert die zuletzt angelegte Komponente als Vorlage für die nächste.
/// Wird in KomponenteFormular nach dem Speichern gesetzt.
final letzteKomponenteTemplateProvider =
    StateProvider<VerteilerKomponente?>((_) => null);

// ── Repository ────────────────────────────────────────────────────────────────

class KomponentenRepository {
  const KomponentenRepository(this._db);

  final Database _db;

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

  Future<VerteilerKomponente?> getByUuid(String uuid) async {
    final snapshot =
        await StorageService.komponentenStore.record(uuid).get(_db);
    if (snapshot == null) return null;
    return VerteilerKomponente.fromJson(snapshot.cast<String, dynamic>());
  }

  Future<void> save(VerteilerKomponente komponente) async {
    await StorageService.komponentenStore
        .record(komponente.uuid)
        .put(_db, komponente.toJson().cast<String, Object?>());
  }

  Future<void> delete(String uuid) async {
    await StorageService.komponentenStore.record(uuid).delete(_db);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final komponentenRepositoryProvider = Provider<KomponentenRepository>((ref) {
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
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => KomponentenRepository(db).watchByVerteiler(verteilerUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

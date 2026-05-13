import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../models/verteiler_komponente.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class KomponentenRepository {
  const KomponentenRepository(this._isar);

  final Isar _isar;

  Stream<List<VerteilerKomponente>> watchByVerteiler(String verteilerUuid) {
    return _isar.verteilerKomponentes
        .filter()
        .verteilerUuidEqualTo(verteilerUuid)
        .watch(fireImmediately: true);
  }

  Future<List<VerteilerKomponente>> getByVerteiler(
      String verteilerUuid) async {
    return _isar.verteilerKomponentes
        .filter()
        .verteilerUuidEqualTo(verteilerUuid)
        .sortByPosition()
        .findAll();
  }

  Future<VerteilerKomponente?> getByUuid(String uuid) async {
    return _isar.verteilerKomponentes.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<void> save(VerteilerKomponente komponente) async {
    if (komponente.uuid.isEmpty) {
      komponente.uuid = const Uuid().v4();
    }
    komponente.erstelltAm ??= DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.verteilerKomponentes.put(komponente);
    });
  }

  Future<void> delete(String uuid) async {
    final existing = await getByUuid(uuid);
    if (existing == null) return;
    await _isar.writeTxn(() async {
      await _isar.verteilerKomponentes.delete(existing.id);
    });
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final komponentenRepositoryProvider = Provider<KomponentenRepository>((ref) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => KomponentenRepository(isar),
    loading: () => throw StateError('Isar not ready'),
    error: (e, _) => throw e,
  );
});

final komponentenByVerteilerProvider =
    StreamProvider.family<List<VerteilerKomponente>, String>(
        (ref, verteilerUuid) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => KomponentenRepository(isar).watchByVerteiler(verteilerUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

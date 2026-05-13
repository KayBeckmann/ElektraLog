import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../models/standort.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class StandorteRepository {
  const StandorteRepository(this._isar);

  final Isar _isar;

  Stream<List<Standort>> watchByKunde(String kundeUuid) {
    return _isar.standorts
        .filter()
        .kundeUuidEqualTo(kundeUuid)
        .watch(fireImmediately: true);
  }

  Future<List<Standort>> getByKunde(String kundeUuid) async {
    return _isar.standorts
        .filter()
        .kundeUuidEqualTo(kundeUuid)
        .sortByBezeichnung()
        .findAll();
  }

  Future<Standort?> getByUuid(String uuid) async {
    return _isar.standorts.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<int> countByKunde(String kundeUuid) async {
    return _isar.standorts.filter().kundeUuidEqualTo(kundeUuid).count();
  }

  Future<void> save(Standort standort) async {
    if (standort.uuid.isEmpty) {
      standort.uuid = const Uuid().v4();
    }
    standort.erstelltAm ??= DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.standorts.put(standort);
    });
  }

  Future<void> delete(String uuid) async {
    final existing = await getByUuid(uuid);
    if (existing == null) return;
    await _isar.writeTxn(() async {
      await _isar.standorts.delete(existing.id);
    });
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final standorteRepositoryProvider = Provider<StandorteRepository>((ref) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => StandorteRepository(isar),
    loading: () => throw StateError('Isar not ready'),
    error: (e, _) => throw e,
  );
});

final standorteByKundeProvider =
    StreamProvider.family<List<Standort>, String>((ref, kundeUuid) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => StandorteRepository(isar).watchByKunde(kundeUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

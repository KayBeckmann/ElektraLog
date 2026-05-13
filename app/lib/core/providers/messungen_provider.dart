import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../models/messung.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class MessungenRepository {
  const MessungenRepository(this._isar);

  final Isar _isar;

  Stream<List<Messung>> watchByKomponente(String komponenteUuid) {
    return _isar.messungs
        .filter()
        .komponenteUuidEqualTo(komponenteUuid)
        .watch(fireImmediately: true);
  }

  Future<List<Messung>> getByKomponente(String komponenteUuid) async {
    return _isar.messungs
        .filter()
        .komponenteUuidEqualTo(komponenteUuid)
        .sortByPruefungDatumDesc()
        .findAll();
  }

  Future<List<Messung>> getAll() async {
    return _isar.messungs.where().sortByPruefungDatumDesc().findAll();
  }

  Future<Messung?> getByUuid(String uuid) async {
    return _isar.messungs.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<int> countToday() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    return _isar.messungs
        .filter()
        .pruefungDatumBetween(start, end)
        .count();
  }

  Future<void> save(Messung messung) async {
    if (messung.uuid.isEmpty) {
      messung.uuid = const Uuid().v4();
    }
    messung.erstelltAm ??= DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.messungs.put(messung);
    });
  }

  Future<void> delete(String uuid) async {
    final existing = await getByUuid(uuid);
    if (existing == null) return;
    await _isar.writeTxn(() async {
      await _isar.messungs.delete(existing.id);
    });
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final messungenRepositoryProvider = Provider<MessungenRepository>((ref) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => MessungenRepository(isar),
    loading: () => throw StateError('Isar not ready'),
    error: (e, _) => throw e,
  );
});

final messungenByKomponenteProvider =
    StreamProvider.family<List<Messung>, String>((ref, komponenteUuid) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) =>
        MessungenRepository(isar).watchByKomponente(komponenteUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

final alleMessungenProvider = FutureProvider<List<Messung>>((ref) async {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => MessungenRepository(isar).getAll(),
    loading: () async => [],
    error: (e, _) => throw e,
  );
});

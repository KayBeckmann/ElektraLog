import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../models/verteiler.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class VerteilerRepository {
  const VerteilerRepository(this._isar);

  final Isar _isar;

  Stream<List<Verteiler>> watchByStandort(String standortUuid) {
    return _isar.verteilers
        .filter()
        .standortUuidEqualTo(standortUuid)
        .watch(fireImmediately: true);
  }

  Future<List<Verteiler>> getByStandort(String standortUuid) async {
    return _isar.verteilers
        .filter()
        .standortUuidEqualTo(standortUuid)
        .sortByBezeichnung()
        .findAll();
  }

  Future<Verteiler?> getByUuid(String uuid) async {
    return _isar.verteilers.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<void> save(Verteiler verteiler) async {
    if (verteiler.uuid.isEmpty) {
      verteiler.uuid = const Uuid().v4();
    }
    verteiler.erstelltAm ??= DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.verteilers.put(verteiler);
    });
  }

  Future<void> delete(String uuid) async {
    final existing = await getByUuid(uuid);
    if (existing == null) return;
    await _isar.writeTxn(() async {
      await _isar.verteilers.delete(existing.id);
    });
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final verteilerRepositoryProvider = Provider<VerteilerRepository>((ref) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => VerteilerRepository(isar),
    loading: () => throw StateError('Isar not ready'),
    error: (e, _) => throw e,
  );
});

final verteilerByStandortProvider =
    StreamProvider.family<List<Verteiler>, String>((ref, standortUuid) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => VerteilerRepository(isar).watchByStandort(standortUuid),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

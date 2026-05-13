import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

import '../models/kunde.dart';
import 'isar_provider.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class KundenRepository {
  const KundenRepository(this._isar);

  final Isar _isar;

  Stream<List<Kunde>> watchAll() {
    return _isar.kundes.where().sortByName().watch(fireImmediately: true);
  }

  Future<List<Kunde>> getAll() async {
    return _isar.kundes.where().sortByName().findAll();
  }

  Future<Kunde?> getByUuid(String uuid) async {
    return _isar.kundes.filter().uuidEqualTo(uuid).findFirst();
  }

  Future<void> save(Kunde kunde) async {
    if (kunde.uuid.isEmpty) {
      kunde.uuid = const Uuid().v4();
    }
    kunde.erstelltAm ??= DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.kundes.put(kunde);
    });
  }

  Future<void> delete(String uuid) async {
    final existing = await getByUuid(uuid);
    if (existing == null) return;
    await _isar.writeTxn(() async {
      await _isar.kundes.delete(existing.id);
    });
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final kundenRepositoryProvider = Provider<KundenRepository>((ref) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => KundenRepository(isar),
    loading: () => throw StateError('Isar not ready'),
    error: (e, _) => throw e,
  );
});

final kundenProvider = StreamProvider<List<Kunde>>((ref) {
  final isarAsync = ref.watch(isarProvider);
  return isarAsync.when(
    data: (isar) => KundenRepository(isar).watchAll(),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

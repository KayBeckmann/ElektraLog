import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';
import 'isar_provider.dart';

/// Geräteeigene (NICHT mit dem Server synchronisierte) Auswahl, welche
/// Standorte/Verteiler dieses Gerät im Detail synchron halten soll — siehe
/// Roadmap M9.7. Default für jeden Standort/Verteiler ist "nicht aktiviert",
/// damit ein frisch eingerichtetes Gerät nicht sofort die komplette
/// Firmendatenbank (Komponentenbäume, Messungen, Sichtprüfungen) lädt.
///
/// Kunden sowie die Basisdaten von Standorten/Verteilern (Bezeichnung,
/// Adresse) werden davon NICHT beeinflusst — die werden immer vollständig
/// synchronisiert, damit der Nutzer überhaupt browsen und etwas auswählen
/// kann. Deaktivieren löscht keine bereits lokal vorhandenen Daten — es
/// stoppt nur künftige Downloads für diesen Bereich (siehe SyncService).
class SyncAuswahlRepository {
  const SyncAuswahlRepository(this._db);
  final Database _db;

  static const _typStandort = 'standort';
  static const _typVerteiler = 'verteiler';

  String _key(String typ, String uuid) => '$typ:$uuid';

  Future<bool> istStandortAktiviert(String uuid) =>
      _istAktiviert(_typStandort, uuid);

  Future<bool> istVerteilerAktiviert(String uuid) =>
      _istAktiviert(_typVerteiler, uuid);

  Future<bool> _istAktiviert(String typ, String uuid) async {
    final snap = await StorageService.syncAuswahlStore
        .record(_key(typ, uuid))
        .get(_db);
    return (snap?['aktiviert'] as bool?) ?? false;
  }

  Future<void> setStandortAktiviert(String uuid, bool aktiviert) =>
      _setAktiviert(_typStandort, uuid, aktiviert);

  Future<void> setVerteilerAktiviert(String uuid, bool aktiviert) =>
      _setAktiviert(_typVerteiler, uuid, aktiviert);

  Future<void> _setAktiviert(String typ, String uuid, bool aktiviert) async {
    final key = _key(typ, uuid);
    if (aktiviert) {
      await StorageService.syncAuswahlStore.record(key).put(_db, {
        'typ': typ,
        'uuid': uuid,
        'aktiviert': true,
      });
    } else {
      // Kein Eintrag = nicht aktiviert (Default) — Abwesenheit == false,
      // spart Platz und hält die Abfrage denkbar einfach.
      await StorageService.syncAuswahlStore.record(key).delete(_db);
    }
  }

  Stream<Set<String>> watchAktivierteStandortUuids() =>
      _watchAktivierteUuids(_typStandort);

  Stream<Set<String>> watchAktivierteVerteilerUuids() =>
      _watchAktivierteUuids(_typVerteiler);

  Stream<Set<String>> _watchAktivierteUuids(String typ) {
    final finder = Finder(filter: Filter.equals('typ', typ));
    return StorageService.syncAuswahlStore
        .query(finder: finder)
        .onSnapshots(_db)
        .map((snaps) => snaps.map((s) => s['uuid'] as String).toSet());
  }

  /// Für [SyncService.pullAll] — einmaliger Snapshot statt Stream, da vor
  /// jedem Sync-Aufruf frisch abgefragt wird.
  Future<Set<String>> getAktivierteStandortUuids() =>
      _getAktivierteUuids(_typStandort);

  Future<Set<String>> getAktivierteVerteilerUuids() =>
      _getAktivierteUuids(_typVerteiler);

  Future<Set<String>> _getAktivierteUuids(String typ) async {
    final finder = Finder(filter: Filter.equals('typ', typ));
    final snaps =
        await StorageService.syncAuswahlStore.find(_db, finder: finder);
    return snaps.map((s) => s['uuid'] as String).toSet();
  }
}

final syncAuswahlRepositoryProvider = Provider<SyncAuswahlRepository>((ref) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => SyncAuswahlRepository(db),
    loading: () => throw StateError('DB not ready'),
    error: (e, _) => throw e,
  );
});

/// True, wenn dieser Standort geräteweit für die Detail-Synchronisation
/// aktiviert wurde (deckt dann automatisch alle seine Verteiler mit ab).
final standortSyncAktiviertProvider =
    StreamProvider.family<bool, String>((ref, standortUuid) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => SyncAuswahlRepository(db)
        .watchAktivierteStandortUuids()
        .map((uuids) => uuids.contains(standortUuid)),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

/// True, wenn genau dieser Verteiler individuell aktiviert wurde —
/// unabhängig vom übergeordneten Standort-Flag (siehe
/// [standortSyncAktiviertProvider] für den kombinierten/effektiven Zustand).
final verteilerSyncAktiviertProvider =
    StreamProvider.family<bool, String>((ref, verteilerUuid) {
  final dbAsync = ref.watch(dbProvider);
  return dbAsync.when(
    data: (db) => SyncAuswahlRepository(db)
        .watchAktivierteVerteilerUuids()
        .map((uuids) => uuids.contains(verteilerUuid)),
    loading: () => const Stream.empty(),
    error: (e, _) => Stream.error(e),
  );
});

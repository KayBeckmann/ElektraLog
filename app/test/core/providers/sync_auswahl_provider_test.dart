// Roadmap M9.7 — selektive Standort-/Verteiler-Synchronisation.
//
// Testet SyncAuswahlRepository gegen eine In-Memory-Sembast-DB (kein
// Netzwerk, keine Plattform-IO) — insbesondere den Default-false-Zustand
// und die Trennung zwischen Standort- und Verteiler-Flags.

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:elektralog/core/providers/sync_auswahl_provider.dart';

void main() {
  group('SyncAuswahlRepository', () {
    late SyncAuswahlRepository repo;
    var dbCounter = 0;

    setUp(() async {
      // Eigener DB-Pfad pro Test — databaseFactoryMemory hält In-Memory-DBs
      // sonst über Testfälle hinweg am Leben (siehe pruefprotokoll_
      // repository_test.dart für den identischen Stolperstein).
      final db = await databaseFactoryMemory
          .openDatabase('sync-auswahl-test-${dbCounter++}.db');
      repo = SyncAuswahlRepository(db);
    });

    test('Default für unbekannten Standort/Verteiler ist false', () async {
      expect(await repo.istStandortAktiviert('unbekannt'), isFalse);
      expect(await repo.istVerteilerAktiviert('unbekannt'), isFalse);
    });

    test('setStandortAktiviert(true) macht istStandortAktiviert true',
        () async {
      await repo.setStandortAktiviert('standort-1', true);
      expect(await repo.istStandortAktiviert('standort-1'), isTrue);
    });

    test('setStandortAktiviert(false) nach true setzt zurück auf false',
        () async {
      await repo.setStandortAktiviert('standort-1', true);
      await repo.setStandortAktiviert('standort-1', false);
      expect(await repo.istStandortAktiviert('standort-1'), isFalse);
    });

    test('Standort- und Verteiler-Flags sind unabhängig, auch bei '
        'identischer UUID (Typ-Trennung im Store-Key)', () async {
      const geteilteUuid = 'gleiche-uuid';
      await repo.setStandortAktiviert(geteilteUuid, true);
      expect(await repo.istStandortAktiviert(geteilteUuid), isTrue);
      expect(await repo.istVerteilerAktiviert(geteilteUuid), isFalse);
    });

    test('getAktivierteStandortUuids liefert nur aktivierte, keine '
        'Verteiler-UUIDs', () async {
      await repo.setStandortAktiviert('s1', true);
      await repo.setStandortAktiviert('s2', true);
      await repo.setVerteilerAktiviert('v1', true);

      final result = await repo.getAktivierteStandortUuids();
      expect(result, {'s1', 's2'});
    });

    test('getAktivierteVerteilerUuids liefert nur aktivierte Verteiler',
        () async {
      await repo.setVerteilerAktiviert('v1', true);
      await repo.setVerteilerAktiviert('v2', true);
      await repo.setVerteilerAktiviert('v2', false);

      final result = await repo.getAktivierteVerteilerUuids();
      expect(result, {'v1'});
    });

    test('watchAktivierteStandortUuids emittiert bei Änderungen', () async {
      final stream = repo.watchAktivierteStandortUuids();
      final werte = <Set<String>>[];
      final sub = stream.listen(werte.add);

      await repo.setStandortAktiviert('s1', true);
      await Future<void>.delayed(Duration.zero);
      await repo.setStandortAktiviert('s1', false);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(werte.last, isEmpty);
      expect(werte.any((s) => s.contains('s1')), isTrue);
    });
  });
}

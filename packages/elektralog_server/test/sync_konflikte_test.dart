@Tags(['postgres'])
library;

import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'support/test_server.dart';

/// Roadmap Geräteprüfung M3: Versionen pro Datensatz, Konflikte statt
/// stiller Überschreibung, bestätigte Zuordnungswechsel mit Audit,
/// Mandantengrenze für alle Typen, ältere Clients bleiben lauffähig.
void main() {
  group('Versionierter Sync', skip: skipWithoutDb, () {
    final server = TestServer();
    late String token;
    final kunde = const Uuid().v4();
    final standort = const Uuid().v4();
    final raumA = const Uuid().v4();
    final raumB = const Uuid().v4();

    setUp(() async {
      await server.start();
      token = (await server.firmaMitBenutzer('Firma A', 'a@test.invalid')).token;
      await push(server, token, [
        ('kunden', [
          {'uuid': kunde, 'name': 'Kunde', '_basisVersion': null},
        ]),
        ('standorte', [
          {'uuid': standort, 'kundeUuid': kunde, 'bezeichnung': 'Werk', '_basisVersion': null},
        ]),
        ('raeume', [
          {'uuid': raumA, 'standortUuid': standort, 'bezeichnung': 'A', '_basisVersion': null},
          {'uuid': raumB, 'standortUuid': standort, 'bezeichnung': 'B', '_basisVersion': null},
        ]),
      ]);
    });
    tearDown(server.stop);

    Future<Map> kundeAufServer() async => ((await pull(server, token))['kunden'] as List).single as Map;

    test('Version steigt mit jeder übernommenen Änderung', () async {
      expect((await kundeAufServer())['version'], 1);
      final r = await push(server, token, [
        ('kunden', [
          {'uuid': kunde, 'name': 'Neu', '_basisVersion': 1},
        ]),
      ]);
      expect(r['ergebnisse'], [
        {'type': 'kunden', 'uuid': kunde, 'version': 2},
      ]);
      expect(r['konflikte'], isEmpty);
      expect(await kundeAufServer(), containsPair('version', 2));
    });

    test('Zwei Geräte ändern offline denselben Datensatz: keine stille Überschreibung', () async {
      // Gerät 1 überträgt zuerst.
      await push(server, token, [
        ('kunden', [
          {'uuid': kunde, 'name': 'Gerät 1', '_basisVersion': 1},
        ]),
      ]);
      // Gerät 2 beruht noch auf Version 1.
      final r = await push(server, token, [
        ('kunden', [
          {'uuid': kunde, 'name': 'Gerät 2', 'ort': 'Bonn', '_basisVersion': 1},
        ]),
      ]);
      final k = (r['konflikte'] as List).single as Map;
      expect(k['art'], 'konflikt');
      expect(k['version'], 2);
      expect((k['server'] as Map)['name'], 'Gerät 1');
      expect((await kundeAufServer())['name'], 'Gerät 1', reason: 'Serverstand unverändert');

      // Nutzer führt zusammen und überträgt auf Basis der Serverversion.
      final gemerged = await push(server, token, [
        ('kunden', [
          {'uuid': kunde, 'name': 'Gerät 1', 'ort': 'Bonn', '_basisVersion': 2},
        ]),
      ]);
      expect(gemerged['konflikte'], isEmpty);
      final s = await kundeAufServer();
      expect((s['name'], s['ort'], s['version']), ('Gerät 1', 'Bonn', 3));
    });

    test('Basis null bei vorhandenem Datensatz ist ein Konflikt (z. B. nach Server-Restore)', () async {
      final r = await push(server, token, [
        ('kunden', [
          {'uuid': kunde, 'name': 'Anders', '_basisVersion': null},
        ]),
      ]);
      expect((r['konflikte'] as List).single, containsPair('version', 1));
    });

    test('Älterer Client ohne Versionen: neuerer Zeitstempel gewinnt, älterer wird ignoriert', () async {
      await push(server, token, [
        ('kunden', [
          {'uuid': kunde, 'name': 'Neu', 'aktualisiertAm': '2099-01-01T00:00:00.000Z'},
        ]),
      ]);
      expect(await kundeAufServer(), allOf(containsPair('name', 'Neu'), containsPair('version', 2)));
      final r = await push(server, token, [
        ('kunden', [
          {'uuid': kunde, 'name': 'Alt', 'aktualisiertAm': '2020-01-01T00:00:00.000Z'},
        ]),
      ]);
      expect(r['konflikte'], isEmpty, reason: 'alte App bekommt keine unbekannte Antwort');
      expect((await kundeAufServer())['name'], 'Neu');
    });

    test('Raumwechsel eines Geräts nur mit Bestätigung, bestätigter Wechsel wird auditiert', () async {
      final g = const Uuid().v4();
      Map<String, dynamic> geraet(String raum, int? basis, {bool? bestaetigt}) => {
            'uuid': g,
            'kundeUuid': kunde,
            'standortUuid': standort,
            'raumUuid': raum,
            'bezeichnung': 'Leiter',
            '_basisVersion': basis,
            if (bestaetigt != null) '_zuordnungBestaetigt': bestaetigt,
          };
      await push(server, token, [
        ('geraete', [geraet(raumA, null)]),
      ]);

      final ohne = await push(server, token, [
        ('geraete', [geraet(raumB, 1)]),
      ]);
      expect(((ohne['konflikte'] as List).single as Map)['art'], 'zuordnung');
      expect((((await pull(server, token))['geraete'] as List).single as Map)['raumUuid'], raumA);

      final mit = await push(server, token, [
        ('geraete', [geraet(raumB, 1, bestaetigt: true)]),
      ]);
      expect(mit['konflikte'], isEmpty);
      expect((((await pull(server, token))['geraete'] as List).single as Map)['raumUuid'], raumB);

      final audit = await server.db.execute('SELECT alt_raum_uuid::text, neu_raum_uuid::text, benutzer_id FROM zuordnung_audit');
      expect(audit, hasLength(1));
      expect((audit.first[0], audit.first[1]), (raumA, raumB));
      expect(audit.first[2], isNotNull, reason: 'wer bestätigt hat');

      final nurStamm = await push(server, token, [
        ('geraete', [
          {...geraet(raumB, 2), 'bezeichnung': 'Stehleiter'},
        ]),
      ]);
      expect(nurStamm['konflikte'], isEmpty, reason: 'Stammdaten ohne Ortswechsel brauchen keine Bestätigung');
    });

    test('Mandantengrenze für alle Typen: fremde Eltern-IDs werden abgelehnt', () async {
      final verteiler = const Uuid().v4();
      final komponente = const Uuid().v4();
      await push(server, token, [
        ('verteiler', [
          {'uuid': verteiler, 'standortUuid': standort, 'bezeichnung': 'UV1', '_basisVersion': null},
        ]),
        ('komponenten', [
          {'uuid': komponente, 'verteilerUuid': verteiler, 'typ': 'rcd', 'zielbezeichnung': 'FI', '_basisVersion': null},
        ]),
      ]);
      final b = (await server.firmaMitBenutzer('Firma B', 'b@test.invalid')).token;
      final r = await push(server, b, [
        ('standorte', [
          {'uuid': const Uuid().v4(), 'kundeUuid': kunde, 'bezeichnung': 'x', '_basisVersion': null},
        ]),
        ('verteiler', [
          {'uuid': const Uuid().v4(), 'standortUuid': standort, 'bezeichnung': 'x', '_basisVersion': null},
        ]),
        ('komponenten', [
          {'uuid': const Uuid().v4(), 'verteilerUuid': verteiler, 'typ': 'rcd', 'zielbezeichnung': 'x', '_basisVersion': null},
        ]),
        ('messungen', [
          {
            'uuid': const Uuid().v4(),
            'komponenteUuid': komponente,
            'pruefungDatum': '2026-11-08',
            'ergebnis': 'bestanden',
            '_basisVersion': null,
          },
        ]),
        ('sichtpruefungen', [
          {'uuid': const Uuid().v4(), 'verteilerUuid': verteiler, 'pruefungDatum': '2026-11-08', 'ergebnis': 'bestanden', '_basisVersion': null},
        ]),
        ('raeume', [
          {'uuid': const Uuid().v4(), 'standortUuid': standort, 'bezeichnung': 'x', '_basisVersion': null},
        ]),
        ('kunden', [
          {'uuid': kunde, 'name': 'gekapert', '_basisVersion': 1},
        ]),
      ]);
      expect(r['abgelehnt'], hasLength(7));
      expect(r['ergebnisse'], isEmpty);
      expect((await kundeAufServer())['name'], 'Kunde');
    });

    test('Ausstehende Uploads kommen an, auch wenn der Raum nicht mehr ausgewählt ist', () async {
      final g = const Uuid().v4();
      final r = await push(server, token, [
        ('geraete', [
          {'uuid': g, 'kundeUuid': kunde, 'standortUuid': standort, 'raumUuid': raumA, 'bezeichnung': 'X', '_basisVersion': null},
        ]),
      ]);
      expect(r['ergebnisse'], hasLength(1));
      final ohneAuswahl = await pull(server, token, query: 'geraeteStandorte=&raeume=');
      expect(ohneAuswahl['geraete'], isEmpty);
      expect(((await pull(server, token, query: 'raeume=$raumA'))['geraete'] as List).single['uuid'], g);
    });

    test('Kunden-REST-Update erhöht ebenfalls die Version', () async {
      final r = await server.call('PUT', '/api/kunden/$kunde', token: token, body: {'name': 'Per REST'});
      expect(r.status, 200);
      expect(await kundeAufServer(), containsPair('version', 2));
    });
    test('Prüfgerät je Messung: übernommen, ältere Clients löschen es nicht', () async {
      final verteiler = const Uuid().v4();
      final komponente = const Uuid().v4();
      final messung = const Uuid().v4();
      Map<String, dynamic> m(Map<String, Object?> extra) => {
            'uuid': messung,
            'komponenteUuid': komponente,
            'pruefungDatum': '2026-11-08',
            'ergebnis': 'bestanden',
            ...extra,
          };
      Future<Map> aufServer() async => ((await pull(server, token))['messungen'] as List).single as Map;
      await push(server, token, [
        ('verteiler', [
          {'uuid': verteiler, 'standortUuid': standort, 'bezeichnung': 'UV1', '_basisVersion': null},
        ]),
        ('komponenten', [
          {'uuid': komponente, 'verteilerUuid': verteiler, 'typ': 'rcd', 'zielbezeichnung': 'FI', '_basisVersion': null},
        ]),
        ('messungen', [
          m({'pruefgeraet': 'Fluke 1664 FC #123', '_basisVersion': null}),
        ]),
      ]);
      expect(await aufServer(), containsPair('pruefgeraet', 'Fluke 1664 FC #123'));

      // Älterer Client ohne Feld (und ohne _basisVersion): Bemerkung neu, Prüfgerät bleibt.
      await push(server, token, [
        ('messungen', [
          m({'bemerkung': 'nachgetragen', 'aktualisiertAm': DateTime.now().toUtc().add(const Duration(minutes: 1)).toIso8601String()}),
        ]),
      ]);
      final nachAlt = await aufServer();
      expect((nachAlt['bemerkung'], nachAlt['pruefgeraet']), ('nachgetragen', 'Fluke 1664 FC #123'));

      // Neuer Client darf es ändern.
      await push(server, token, [
        ('messungen', [
          m({'bemerkung': 'nachgetragen', 'pruefgeraet': 'Metrel MI 3152', '_basisVersion': nachAlt['version']}),
        ]),
      ]);
      expect(await aufServer(), containsPair('pruefgeraet', 'Metrel MI 3152'));
    });
    test('Ganzer Kunde ausgewählt: Aufbau und Geräte aller seiner Standorte, sonst nur Namen', () async {
      final verteiler = const Uuid().v4();
      final komponente = const Uuid().v4();
      final geraet = const Uuid().v4();
      final andererKunde = const Uuid().v4();
      final andererStandort = const Uuid().v4();
      final andererVerteiler = const Uuid().v4();
      await push(server, token, [
        ('kunden', [
          {'uuid': andererKunde, 'name': 'Anderer', '_basisVersion': null},
        ]),
        ('standorte', [
          {'uuid': andererStandort, 'kundeUuid': andererKunde, 'bezeichnung': 'Fremdwerk', '_basisVersion': null},
        ]),
        ('verteiler', [
          {'uuid': verteiler, 'standortUuid': standort, 'bezeichnung': 'UV1', '_basisVersion': null},
          {'uuid': andererVerteiler, 'standortUuid': andererStandort, 'bezeichnung': 'UV9', '_basisVersion': null},
        ]),
        ('komponenten', [
          {'uuid': komponente, 'verteilerUuid': verteiler, 'typ': 'rcd', 'zielbezeichnung': 'FI', '_basisVersion': null},
          {'uuid': const Uuid().v4(), 'verteilerUuid': andererVerteiler, 'typ': 'rcd', 'zielbezeichnung': 'FI', '_basisVersion': null},
        ]),
        ('messungen', [
          {'uuid': const Uuid().v4(), 'komponenteUuid': komponente, 'pruefungDatum': '2026-11-08', 'ergebnis': 'bestanden', '_basisVersion': null},
        ]),
        ('geraete', [
          {'uuid': geraet, 'kundeUuid': kunde, 'standortUuid': standort, 'raumUuid': raumA, 'bezeichnung': 'Lampe', '_basisVersion': null},
        ]),
      ]);

      final leer = await pull(server, token, query: 'kunden=&standorte=&verteiler=&geraeteStandorte=&raeume=');
      expect([leer['komponenten'], leer['messungen'], leer['geraete']], everyElement(isEmpty));
      expect(leer['kunden'], hasLength(2), reason: 'Namen kommen immer, damit man auswählen kann');
      expect(leer['verteiler'], hasLength(2));

      final mitKunde = await pull(server, token, query: 'kunden=$kunde&standorte=&verteiler=&geraeteStandorte=&raeume=');
      expect([for (final k in mitKunde['komponenten'] as List) k['verteilerUuid']], [verteiler]);
      expect(mitKunde['messungen'], hasLength(1));
      expect([for (final g in mitKunde['geraete'] as List) g['uuid']], [geraet]);
    });
  });
}

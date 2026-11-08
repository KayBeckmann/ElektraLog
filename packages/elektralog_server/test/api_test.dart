@Tags(['postgres'])
library;

import 'dart:async';

import 'package:elektralog_server/src/app.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'support/test_server.dart';

/// API-Tests gegen den echten Handler und echtes Postgres (siehe
/// `test/support/test_server.dart`). Grundlage für die Abnahmen der
/// Roadmap Geräteprüfung (Mandantentrennung, Rechte, Sync).
void main() {
  group('Server-API', skip: skipWithoutDb, () {
    final server = TestServer();
    const uuid = Uuid();

    setUp(server.start);
    tearDown(server.stop);

    /// Kunde → Standort → Verteiler → Komponente per Sync-Push anlegen.
    Future<({String kunde, String standort, String verteiler, String komponente})> anlage(String token) async {
      final ids = (kunde: uuid.v4(), standort: uuid.v4(), verteiler: uuid.v4(), komponente: uuid.v4());
      final r = await server.call('POST', '/api/sync', token: token, body: {
        'batches': [
          {
            'type': 'kunden',
            'items': [
              {'uuid': ids.kunde, 'name': 'Kunde'},
            ],
          },
          {
            'type': 'standorte',
            'items': [
              {'uuid': ids.standort, 'kundeUuid': ids.kunde, 'bezeichnung': 'Halle'},
            ],
          },
          {
            'type': 'verteiler',
            'items': [
              {'uuid': ids.verteiler, 'standortUuid': ids.standort, 'bezeichnung': 'UV1'},
            ],
          },
          {
            'type': 'komponenten',
            'items': [
              {'uuid': ids.komponente, 'verteilerUuid': ids.verteiler, 'typ': 'rcd', 'betriebsmittelkennzeichen': '-F1'},
            ],
          },
        ],
      });
      expect(r.status, 200, reason: '${r.body}');
      return ids;
    }

    List<String> uuids(dynamic body, String key) => [for (final e in (body as Map)[key] as List) (e as Map)['uuid'] as String];

    test('Health ist öffentlich erreichbar', () async {
      final r = await server.call('GET', '/api/health');
      expect(r.status, 200);
      expect((r.body as Map)['status'], 'ok');
    });

    test('Anmeldung: falsches Passwort und fehlendes Token werden abgewiesen', () async {
      await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      final falsch = await server.call('POST', '/api/auth/login', body: {'email': 'a@test.invalid', 'passwort': 'falsch'});
      expect(falsch.status, 401);
      expect((await server.call('GET', '/api/sync')).status, 401);
      expect((await server.call('GET', '/api/sync', token: 'kein.gueltiges.token')).status, 401);
    });

    test('Superadmin-Routen sind für Firmenbenutzer gesperrt', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      expect((await server.call('GET', '/api/admin/firmen', token: a.token)).status, 403);
    });

    test('Mandantentrennung: Pull liefert nur eigene Daten, fremde UUID überschreibt nichts', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      final b = await server.firmaMitBenutzer('Firma B', 'b@test.invalid');
      final anlageA = await anlage(a.token);

      final pullB = await server.call('GET', '/api/sync', token: b.token);
      expect(pullB.status, 200);
      expect(uuids(pullB.body, 'kunden'), isEmpty);
      expect(uuids(pullB.body, 'komponenten'), isEmpty);

      // B schickt einen Kunden mit A's UUID — A's Datensatz bleibt unverändert.
      await server.call('POST', '/api/sync', token: b.token, body: {
        'type': 'kunden',
        'items': [
          {'uuid': anlageA.kunde, 'name': 'Übernommen'},
        ],
      });
      final pullA = await server.call('GET', '/api/sync', token: a.token);
      final kunde = ((pullA.body as Map)['kunden'] as List).single as Map;
      expect(kunde['name'], 'Kunde');
      expect(uuids((await server.call('GET', '/api/sync', token: b.token)).body, 'kunden'), isEmpty);
    });

    test('Selektiver Pull (M9.7): Aufbau nur für gewählte Standorte/Verteiler, nie fremde', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      final b = await server.firmaMitBenutzer('Firma B', 'b@test.invalid');
      final eins = await anlage(a.token);
      final zwei = await anlage(a.token);
      final fremd = await anlage(b.token);

      final perStandort = await server.call('GET', '/api/sync?standorte=${eins.standort}', token: a.token);
      expect(perStandort.status, 200);
      expect(uuids(perStandort.body, 'verteiler'), unorderedEquals([eins.verteiler, zwei.verteiler]),
          reason: 'Basisdaten aller Verteiler bleiben sichtbar');
      expect(uuids(perStandort.body, 'komponenten'), [eins.komponente]);

      final perVerteiler = await server.call('GET', '/api/sync?verteiler=${zwei.verteiler}', token: a.token);
      expect(uuids(perVerteiler.body, 'komponenten'), [zwei.komponente]);

      final leer = await server.call('GET', '/api/sync?standorte=&verteiler=', token: a.token);
      expect(uuids(leer.body, 'komponenten'), isEmpty, reason: 'leere Auswahl = kein Aufbau');

      final ohneFilter = await server.call('GET', '/api/sync', token: a.token);
      expect(uuids(ohneFilter.body, 'komponenten'), unorderedEquals([eins.komponente, zwei.komponente]),
          reason: 'alte Clients ohne Parameter bekommen alles');

      final fremdeIds = await server.call(
        'GET',
        '/api/sync?standorte=${fremd.standort}&verteiler=${fremd.verteiler}',
        token: a.token,
      );
      expect(uuids(fremdeIds.body, 'komponenten'), isEmpty);
    });

    test('Selektiver Pull: ungültige UUID in der Auswahl ist ein Client-Fehler (400), kein Serverfehler', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      final r = await server.call('GET', '/api/sync?standorte=keine-uuid', token: a.token);
      expect(r.status, 400, reason: '${r.body}');
    });

    test('Logs enthalten nie Header oder Token', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      final logs = <String>[];
      // Wie im Betrieb: mit Request-Logging.
      final handler = buildHandler(server.db, jwtSecret: testJwtSecret);
      await runZoned(
        () async {
          for (final token in [a.token, 'kaputt.${a.token}', 'kein.gueltiges.token']) {
            await handler(Request('GET', Uri.parse('http://localhost/api/sync'),
                headers: {'authorization': 'Bearer $token'}));
          }
        },
        zoneSpecification: ZoneSpecification(print: (_, __, ___, line) => logs.add(line)),
      );
      expect(logs, isNotEmpty, reason: 'Request-Logging läuft');
      for (final line in logs) {
        expect(line, isNot(contains(a.token)));
        expect(line, isNot(contains('kein.gueltiges.token')));
        expect(line.toLowerCase(), isNot(contains('authorization')));
      }
    });

    test('Gesperrte Firma: gültiges Token bekommt 403', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      final admin = await server.login(superadminEmail, superadminPassword);
      final sperre = await server.call('PATCH', '/api/admin/firmen/${a.firmaId}/status',
          body: {'status': 'gesperrt'}, token: admin);
      expect(sperre.status, 200, reason: '${sperre.body}');
      expect((await server.call('GET', '/api/sync', token: a.token)).status, 403);
    });
  });
}

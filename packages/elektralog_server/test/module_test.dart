@Tags(['postgres'])
library;

import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'support/test_server.dart';

/// Roadmap Geräteprüfung M1: Firmenmodule Anlagen-/Geräteprüfung.
/// Nur der Firmenadmin schaltet um (serverseitig, Rolle aus der DB),
/// Umschalten löscht keine Daten.
void main() {
  group('Firmenmodule', skip: skipWithoutDb, () {
    final server = TestServer();

    setUp(server.start);
    tearDown(server.stop);

    Future<Map> module(String token) async {
      final r = await server.call('GET', '/api/firma', token: token);
      expect(r.status, 200, reason: '${r.body}');
      return (r.body as Map)['module'] as Map;
    }

    Future<({int status, dynamic body})> setze(String token, Map<String, Object?> body) =>
        server.call('PUT', '/api/firma/module', token: token, body: body);

    /// Legt in der Firma des Admins einen weiteren Benutzer an und meldet ihn an.
    Future<({String token, String id})> mitarbeiter(String adminToken, String email, String rolle) async {
      final r = await server.call('POST', '/api/firma/benutzer',
          token: adminToken, body: {'email': email, 'passwort': 'passwort-12345', 'name': rolle, 'rolle': rolle});
      expect(r.status, 200, reason: '${r.body}');
      return (token: await server.login(email, 'passwort-12345'), id: (r.body as Map)['id'] as String);
    }

    test('Neue Firma hat beide Module', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      expect(await module(a.token), {'anlagenpruefung': true, 'geraetepruefung': true});
    });

    test('Firmenadmin schaltet alle vier Kombinationen, GET liefert jeweils den Stand', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      for (final (anlagen, geraete) in [(true, true), (true, false), (false, true), (false, false)]) {
        final r = await setze(a.token, {'anlagenpruefung': anlagen, 'geraetepruefung': geraete});
        expect(r.status, 200, reason: '${r.body}');
        expect(r.body, {'anlagenpruefung': anlagen, 'geraetepruefung': geraete});
        expect(await module(a.token), {'anlagenpruefung': anlagen, 'geraetepruefung': geraete});
      }
      // Einzelnes Feld lässt das andere unverändert.
      await setze(a.token, {'geraetepruefung': true});
      expect(await module(a.token), {'anlagenpruefung': false, 'geraetepruefung': true});
    });

    test('Projektleiter, Monteur und fremde Firma können nicht umschalten', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      final b = await server.firmaMitBenutzer('Firma B', 'b@test.invalid');
      final projektleiter = await mitarbeiter(a.token, 'pl@test.invalid', 'Projektleiter');
      final monteur = await mitarbeiter(a.token, 'mo@test.invalid', 'Monteur');

      for (final token in [projektleiter.token, monteur.token]) {
        expect((await setze(token, {'anlagenpruefung': false})).status, 403);
        expect(await module(token), {'anlagenpruefung': true, 'geraetepruefung': true}, reason: 'lesen dürfen alle');
      }
      expect((await setze(b.token, {'anlagenpruefung': false})).status, 200, reason: 'B schaltet nur B');
      expect(await module(a.token), {'anlagenpruefung': true, 'geraetepruefung': true});
      expect((await server.call('PUT', '/api/firma/module', body: {'anlagenpruefung': false})).status, 401);
    });

    test('Zurückgestufter Admin mit noch gültigem Token wird abgewiesen', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      final zweiterAdmin = await mitarbeiter(a.token, 'a2@test.invalid', 'Firmenadmin');
      expect((await setze(zweiterAdmin.token, {'geraetepruefung': false})).status, 200);

      final r = await server.call('PATCH', '/api/firma/benutzer/${zweiterAdmin.id}/rolle',
          token: a.token, body: {'rolle': 'Monteur'});
      expect(r.status, 200, reason: '${r.body}');
      expect((await setze(zweiterAdmin.token, {'geraetepruefung': true})).status, 403);
    });

    test('Ungültiger Body ist 400', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      expect((await setze(a.token, {})).status, 400);
      expect((await setze(a.token, {'anlagenpruefung': 'nein'})).status, 400);
    });

    test('Abschalten löscht nichts, Sync läuft weiter, Wiedereinschalten zeigt alles', () async {
      final a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
      final kunde = const Uuid().v4();
      Future<List> kunden() async =>
          ((await server.call('GET', '/api/sync', token: a.token)).body as Map)['kunden'] as List;

      await server.call('POST', '/api/sync', token: a.token, body: {
        'type': 'kunden',
        'items': [
          {'uuid': kunde, 'name': 'Vorher'},
        ],
      });
      await setze(a.token, {'anlagenpruefung': false, 'geraetepruefung': false});

      expect(await kunden(), hasLength(1));
      final push = await server.call('POST', '/api/sync', token: a.token, body: {
        'type': 'kunden',
        'items': [
          {'uuid': kunde, 'name': 'Offline geändert'},
        ],
      });
      expect(push.status, 200, reason: 'offene Offline-Änderungen kommen weiter an');

      await setze(a.token, {'anlagenpruefung': true});
      expect(((await kunden()).single as Map)['name'], 'Offline geändert');
    });
  });
}

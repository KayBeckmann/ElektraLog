@Tags(['postgres'])
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'support/test_server.dart';

/// Online-Zugriff der Web-App: je Ansicht genau die Daten, gleiche
/// Versionen wie beim Sync, Mandantengrenze, Löschregeln.
void main() {
  group('Daten-API', skip: skipWithoutDb, () {
    final server = TestServer();
    late String token;
    final kunde = const Uuid().v4();
    final standort = const Uuid().v4();
    final raumA = const Uuid().v4();
    final raumB = const Uuid().v4();
    final gA = const Uuid().v4();
    final gB = const Uuid().v4();
    final verteiler = const Uuid().v4();
    final komponente = const Uuid().v4();
    final messung = const Uuid().v4();

    Map<String, dynamic> pruefung(String uuid, String status) => {
          'uuid': uuid,
          'geraetUuid': gA,
          'pruefart': 'wiederholungspruefung',
          'pruefartText': 'DGUV V3',
          'pruefungDatum': '2026-11-08',
          'prueferName': 'Kay',
          'regelVersion': 'test-v1',
          'schutzklasse': 'I',
          'status': status,
          'ergebnis': status == 'abgeschlossen' ? 'bestanden' : null,
          'punkteJson': jsonEncode([
            {'id': 'rpe', 'bewertung': 'io', 'messwert': 0.1, 'grenzwert': 0.3},
          ]),
          '_basisVersion': null,
        };

    setUp(() async {
      await server.start();
      token = (await server.firmaMitBenutzer('Firma A', 'a@test.invalid')).token;
      Map<String, dynamic> g(String id, String raum) => {
            'uuid': id,
            'kundeUuid': kunde,
            'standortUuid': standort,
            'raumUuid': raum,
            'bezeichnung': 'Gerät',
            '_basisVersion': null,
          };
      await push(server, token, [
        ('kunden', [
          {'uuid': kunde, 'name': 'Kunde', '_basisVersion': null},
        ]),
        ('standorte', [
          {'uuid': standort, 'kundeUuid': kunde, 'bezeichnung': 'Werk', '_basisVersion': null},
        ]),
        ('verteiler', [
          {'uuid': verteiler, 'standortUuid': standort, 'bezeichnung': 'UV1', '_basisVersion': null},
        ]),
        ('komponenten', [
          {'uuid': komponente, 'verteilerUuid': verteiler, 'typ': 'rcd', 'zielbezeichnung': 'FI', '_basisVersion': null},
        ]),
        ('messungen', [
          {'uuid': messung, 'komponenteUuid': komponente, 'pruefungDatum': '2026-11-08', 'ergebnis': 'bestanden', '_basisVersion': null},
        ]),
        ('raeume', [
          {'uuid': raumA, 'standortUuid': standort, 'bezeichnung': 'A', '_basisVersion': null},
          {'uuid': raumB, 'standortUuid': standort, 'bezeichnung': 'B', '_basisVersion': null},
        ]),
        ('geraete', [g(gA, raumA), g(gB, raumB)]),
      ]);
    });
    tearDown(server.stop);

    Future<dynamic> get(String pfad, {String? mit}) async {
      final r = await server.call('GET', pfad, token: mit ?? token);
      expect(r.status, 200, reason: '$pfad: ${r.body}');
      return r.body;
    }

    test('Liste mit Filter, mehrere Werte, einzelner Datensatz mit Version', () async {
      final imRaumA = await get('/api/daten/geraete?raumUuid=$raumA') as List;
      expect([for (final x in imRaumA) x['uuid']], [gA]);
      expect(imRaumA.single['version'], 1);
      expect(await get('/api/daten/geraete?raumUuid=$raumA,$raumB'), hasLength(2));
      expect(await get('/api/daten/raeume?standortUuid=$standort'), hasLength(2));
      expect(await get('/api/daten/messungen?komponenteUuid=$komponente'), hasLength(1));
      expect(await get('/api/daten/kunden'), hasLength(1));
      final einzeln = await get('/api/daten/verteiler/$verteiler') as Map;
      expect((einzeln['bezeichnung'], einzeln['version']), ('UV1', 1));
    });

    test('Unbekannter Typ/Filter, ungültige UUID, nicht vorhanden', () async {
      expect((await server.call('GET', '/api/daten/firmen', token: token)).status, 404);
      expect((await server.call('GET', '/api/daten/geraete?firmaId=x', token: token)).status, 400);
      expect((await server.call('GET', '/api/daten/geraete?raumUuid=kaputt', token: token)).status, 400);
      expect((await server.call('GET', '/api/daten/geraete/${const Uuid().v4()}', token: token)).status, 404);
      expect((await server.call('GET', '/api/daten/geraete')).status, 401);
    });

    test('Mandantengrenze: fremde Firma sieht nichts, auch nicht per UUID', () async {
      final b = (await server.firmaMitBenutzer('Firma B', 'b@test.invalid')).token;
      expect(await get('/api/daten/geraete', mit: b), isEmpty);
      expect((await server.call('GET', '/api/daten/geraete/$gA', token: b)).status, 404);
      expect((await server.call('DELETE', '/api/daten/messungen/$messung', token: b)).status, 200);
      expect(await get('/api/daten/messungen'), hasLength(1), reason: 'fremdes Löschen wirkt nicht');
    });

    test('Messung löschen; Prüfungs-Entwurf löschbar, abgeschlossene nicht', () async {
      expect((await server.call('DELETE', '/api/daten/messungen/$messung', token: token)).status, 200);
      expect(await get('/api/daten/messungen'), isEmpty);

      final entwurf = const Uuid().v4();
      final fertig = const Uuid().v4();
      await push(server, token, [
        ('geraetepruefungen', [pruefung(entwurf, 'entwurf'), pruefung(fertig, 'abgeschlossen')]),
      ]);
      expect((await server.call('DELETE', '/api/daten/geraetepruefungen/$entwurf', token: token)).status, 200);
      expect((await server.call('DELETE', '/api/daten/geraetepruefungen/$fertig', token: token)).status, 409);
      expect([for (final p in await get('/api/daten/geraetepruefungen?geraetUuid=$gA') as List) p['uuid']], [fertig]);
      expect((await server.call('DELETE', '/api/daten/geraete/$gA', token: token)).status, 404,
          reason: 'Geräte löschen weiter über /api/geraete');
    });

    test('Protokolle mit Bezug: Prüfverlauf je Verteiler', () async {
      Map<String, Object?> p(String titel, String? bezug) {
        final pdf = utf8.encode('%PDF $titel');
        return {
          'verteilerBezeichnung': titel,
          'protokollDatum': '2026-11-08T12:00:00Z',
          'pdfBase64': base64Encode(pdf),
          'pdfHash': sha256.convert(pdf).toString(),
          if (bezug != null) 'bezugUuid': bezug,
        };
      }

      await server.call('POST', '/api/protokolle', body: p('UV1', verteiler), token: token);
      await server.call('POST', '/api/protokolle', body: p('alt', null), token: token);
      final verlauf = await get('/api/protokolle?bezug=$verteiler') as List;
      expect([for (final x in verlauf) (x['verteilerBezeichnung'], x['bezugUuid'])], [('UV1', verteiler)]);
      expect(await get('/api/protokolle'), hasLength(2));
      expect((await server.call('POST', '/api/protokolle', body: p('x', 'kaputt'), token: token)).status, 400);
    });
  });
}

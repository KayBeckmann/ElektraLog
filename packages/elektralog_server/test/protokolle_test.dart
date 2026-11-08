@Tags(['postgres'])
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import 'support/test_server.dart';

/// Dokumentenablage: Anlagen- und Geräteprotokolle mit Art, Mandantengrenze.
void main() {
  group('Protokoll-Ablage', skip: skipWithoutDb, () {
    final server = TestServer();
    late String token;

    setUp(() async {
      await server.start();
      token = (await server.firmaMitBenutzer('Firma A', 'a@test.invalid')).token;
    });
    tearDown(server.stop);

    Map<String, Object?> protokoll(String titel, {String? art}) {
      final pdf = utf8.encode('%PDF-1.4 $titel');
      return {
        'verteilerBezeichnung': titel,
        'standortBezeichnung': 'Werk',
        'kundenBezeichnung': 'Kunde',
        'prueferName': 'Kay',
        'protokollDatum': '2026-11-08T12:00:00Z',
        'pdfBase64': base64Encode(pdf),
        'pdfHash': sha256.convert(pdf).toString(),
        if (art != null) 'art': art,
      };
    }

    test('ohne Art = Anlagenprotokoll, Geräteprotokoll mit Art, PDF abrufbar', () async {
      expect((await server.call('POST', '/api/protokolle', body: protokoll('UV1'), token: token)).status, 200);
      final g = await server.call('POST', '/api/protokolle',
          body: protokoll('Geräteübersicht Raum Büro', art: 'geraete'), token: token);
      expect(g.status, 200);

      final liste = (await server.call('GET', '/api/protokolle', token: token)).body as List;
      expect({for (final p in liste) p['verteilerBezeichnung']: p['art']},
          {'UV1': 'anlage', 'Geräteübersicht Raum Büro': 'geraete'});

      final id = (g.body as Map)['id'];
      expect(((await server.call('GET', '/api/protokolle/$id', token: token)).body as Map)['art'], 'geraete');
    });

    test('unbekannte Art wird abgelehnt', () async {
      final r = await server.call('POST', '/api/protokolle', body: protokoll('X', art: 'sonstiges'), token: token);
      expect(r.status, 400);
      expect((await server.call('GET', '/api/protokolle', token: token)).body, isEmpty);
    });

    test('fremde Firma sieht keine Geräteprotokolle', () async {
      await server.call('POST', '/api/protokolle', body: protokoll('G', art: 'geraete'), token: token);
      final b = (await server.firmaMitBenutzer('Firma B', 'b@test.invalid')).token;
      expect((await server.call('GET', '/api/protokolle', token: b)).body, isEmpty);
    });
  });
}

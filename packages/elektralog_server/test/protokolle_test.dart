@Tags(['postgres'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
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

    test('PDF mit Umlauten im Namen lässt sich über echtes HTTP herunterladen', () async {
      final r = await server.call('POST', '/api/protokolle',
          body: protokoll('Geräteübersicht Standort', art: 'geraete'), token: token);
      final http = await shelf_io.serve(server.handler, InternetAddress.loopbackIPv4, 0);
      addTearDown(() => http.close(force: true));
      final client = HttpClient();
      addTearDown(client.close);
      final req = await client.get('127.0.0.1', http.port, '/api/protokolle/${(r.body as Map)['id']}/pdf');
      req.headers.set('authorization', 'Bearer $token');
      final resp = await req.close();
      final bytes = await resp.fold<List<int>>([], (a, b) => a..addAll(b));
      expect(resp.statusCode, 200);
      expect(utf8.decode(bytes), startsWith('%PDF'));
      final cd = resp.headers.value('content-disposition')!;
      expect(cd, contains('filename="Protokoll_Geraeteuebersicht_Standort_2026-11-08.pdf"'));
      expect(cd, contains("filename*=UTF-8''Protokoll_Ger%C3%A4te%C3%BCbersicht_Standort_2026-11-08.pdf"));
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

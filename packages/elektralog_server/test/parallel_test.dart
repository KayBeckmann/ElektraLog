@Tags(['postgres'])
library;

import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'support/test_server.dart';

/// Mehrere Nutzer gleichzeitig (Web-App online): Speichern in Transaktionen
/// und Lesen parallel dürfen sich nicht gegenseitig scheitern lassen.
void main() {
  group('Parallele Anfragen', skip: skipWithoutDb, () {
    final server = TestServer();
    late String token;
    setUp(() async {
      await server.start();
      token = (await server.firmaMitBenutzer('Firma A', 'a@test.invalid')).token;
    });
    tearDown(server.stop);

    test('Speichern und Lesen gleichzeitig', () async {
      final laeufe = [
        for (var i = 0; i < 20; i++) ...[
          server.call('POST', '/api/sync', token: token, body: {
            'batches': [
              {
                'type': 'kunden',
                'items': [
                  {'uuid': const Uuid().v4(), 'name': 'Kunde $i', '_basisVersion': null},
                ],
              },
            ],
          }),
          server.call('GET', '/api/daten/kunden', token: token),
          server.call('GET', '/api/sync', token: token),
        ],
      ];
      final status = [for (final r in await Future.wait(laeufe)) r.status];
      expect(status, everyElement(200));
      expect((await server.call('GET', '/api/daten/kunden', token: token)).body, hasLength(20));
    });
  });
}

@Tags(['postgres'])
library;

import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'support/test_server.dart';

/// Roadmap Geräteprüfung M2: Räume und Geräte über den Sync — Pflichtangaben,
/// Mandantengrenze, selektiver Pull, Löschregeln.
void main() {
  group('Räume und Geräte', skip: skipWithoutDb, () {
    final server = TestServer();
    late String token;
    final kunde = const Uuid().v4();
    final standort = const Uuid().v4();
    final standort2 = const Uuid().v4();
    final raumA = const Uuid().v4();
    final raumB = const Uuid().v4();

    setUp(() async {
      await server.start();
      token = (await server.firmaMitBenutzer('Firma A', 'a@test.invalid')).token;
      await push(server, token, [
        ('kunden', [
          {'uuid': kunde, 'name': 'Kunde'},
        ]),
        ('standorte', [
          {'uuid': standort, 'kundeUuid': kunde, 'bezeichnung': 'Werk 1'},
          {'uuid': standort2, 'kundeUuid': kunde, 'bezeichnung': 'Werk 2'},
        ]),
        ('raeume', [
          {'uuid': raumA, 'standortUuid': standort, 'bezeichnung': 'Büro'},
          {'uuid': raumB, 'standortUuid': standort, 'bezeichnung': 'Werkstatt'},
        ]),
      ]);
    });
    tearDown(server.stop);

    Map<String, dynamic> geraet({String? uuid, String? raum, Map<String, dynamic> extra = const {}}) => {
          'uuid': uuid ?? const Uuid().v4(),
          'kundeUuid': kunde,
          'standortUuid': standort,
          'raumUuid': raum ?? raumA,
          'bezeichnung': 'Wasserkocher',
          ...extra,
        };

    test('Gerät mit allen Feldern anlegen und vollständig zurückbekommen', () async {
      final g = geraet(extra: {
        'hersteller': 'Hersteller GmbH',
        'typ': 'WK 1',
        'seriennummer': 'SN-1',
        'inventarnummer': 'INV-7',
        'schutzart': 'IP20',
        'schutzklasse': 'I',
        'pruefintervallMonate': 12,
        'intervallBegruendung': 'Büro, geringe Beanspruchung',
        'letztePruefungDatum': '2026-03-31',
        'letztePruefungErsatzwert': false,
        'erstelltAm': '2026-11-01T10:00:00.000Z',
      });
      final r = await push(server, token, [('geraete', [g])]);
      expect(r['abgelehnt'], isEmpty);

      final pulled = (await pull(server, token))['geraete'] as List;
      final s = pulled.single as Map;
      for (final key in g.keys.where((k) => k != 'erstelltAm')) {
        expect(s[key], g[key], reason: key);
      }
      expect(s['aktiv'], true, reason: 'Default aktiv');
      expect(s['erstelltAm'], '2026-11-01T10:00:00.000Z', reason: 'UUID und Erstellung bleiben stabil');
    });

    test('Fehlende Pflichtangaben und ungültige Werte werden mit Grund abgelehnt', () async {
      final faelle = {
        'Bezeichnung fehlt': geraet(extra: {'bezeichnung': '  '}),
        'Raum fehlt': geraet(extra: {'raumUuid': null}),
        'Kunde fehlt': geraet(extra: {'kundeUuid': null}),
        'Schutzklasse': geraet(extra: {'schutzklasse': '1'}),
        'inaktiv ohne Grund': geraet(extra: {'aktiv': false}),
        'Intervall 0': geraet(extra: {'pruefintervallMonate': 0}),
        'Intervall 25': geraet(extra: {'pruefintervallMonate': 25}),
        'Intervall dezimal': geraet(extra: {'pruefintervallMonate': 1.5}),
      };
      final r = await push(server, token, [('geraete', faelle.values.toList())]);
      final abgelehnt = r['abgelehnt'] as List;
      expect(abgelehnt, hasLength(faelle.length));
      expect(abgelehnt.every((a) => (a['grund'] as String).isNotEmpty), isTrue);
      expect((await pull(server, token))['geraete'], isEmpty);

      final raum = await push(server, token, [
        ('raeume', [
          {'uuid': const Uuid().v4(), 'standortUuid': standort, 'bezeichnung': ''},
        ]),
      ]);
      expect(raum['abgelehnt'], hasLength(1));
    });

    test('Inaktives Gerät mit Grund wird gespeichert', () async {
      await push(server, token, [
        ('geraete', [
          geraet(extra: {'aktiv': false, 'inaktivGrund': 'defekt, in Reparatur'}),
        ]),
      ]);
      final g = ((await pull(server, token))['geraete'] as List).single as Map;
      expect(g['aktiv'], false);
      expect(g['inaktivGrund'], 'defekt, in Reparatur');
    });

    test('Raum muss zum Standort und Standort zum Kunden passen', () async {
      final r = await push(server, token, [
        ('geraete', [
          geraet(extra: {'standortUuid': standort2}), // Raum A liegt in Werk 1
          geraet(extra: {'kundeUuid': const Uuid().v4()}),
        ]),
      ]);
      expect(r['abgelehnt'], hasLength(2));
    });

    test('Fremde Firma: keine Räume/Geräte sichtbar, fremde IDs abgelehnt', () async {
      final eigenes = geraet();
      await push(server, token, [('geraete', [eigenes])]);
      final b = (await server.firmaMitBenutzer('Firma B', 'b@test.invalid')).token;

      final bSicht = await pull(server, b);
      expect(bSicht['raeume'], isEmpty);
      expect(bSicht['geraete'], isEmpty);

      final r = await push(server, b, [
        ('geraete', [
          geraet(), // A's Kunde/Standort/Raum
          {...eigenes, 'bezeichnung': 'übernommen'}, // A's Geräte-UUID
        ]),
        ('raeume', [
          {'uuid': raumA, 'standortUuid': standort, 'bezeichnung': 'gekapert'},
        ]),
      ]);
      expect(r['abgelehnt'], hasLength(3));
      final aSicht = await pull(server, token);
      expect(((aSicht['geraete'] as List).single as Map)['bezeichnung'], 'Wasserkocher');
      expect((aSicht['raeume'] as List).map((r) => r['bezeichnung']), containsAll(['Büro', 'Werkstatt']));

      expect((await server.call('DELETE', '/api/geraete/${eigenes['uuid']}', token: b)).status, 200);
      expect(((await pull(server, token))['geraete'] as List), hasLength(1), reason: 'fremdes Löschen wirkt nicht');
    });

    test('Selektiver Pull: Räume immer, Geräte nur für gewählte Räume/Standorte', () async {
      final inA = geraet(raum: raumA);
      final inB = geraet(raum: raumB);
      await push(server, token, [
        ('geraete', [inA, inB]),
      ]);
      List<String> ids(Map data) => [for (final g in data['geraete'] as List) g['uuid'] as String];

      final nichts = await pull(server, token, query: 'standorte=&verteiler=&geraeteStandorte=&raeume=');
      expect(nichts['raeume'], hasLength(2), reason: 'Grunddaten zum Auswählen');
      expect(nichts['geraete'], isEmpty);
      expect(ids(await pull(server, token, query: 'geraeteStandorte=&raeume=$raumA')), [inA['uuid']]);
      expect(ids(await pull(server, token, query: 'geraeteStandorte=$standort&raeume=$raumA')),
          unorderedEquals([inA['uuid'], inB['uuid']]));
      expect(ids(await pull(server, token, query: 'standorte=$standort')), isEmpty,
          reason: 'Anlagen-Auswahl lädt keine Geräte');
      expect((await server.call('GET', '/api/sync?raeume=kaputt', token: token)).status, 400);
    });

    test('Raum mit Geräten lässt sich nicht löschen, leerer schon', () async {
      await push(server, token, [
        ('geraete', [geraet(raum: raumA)]),
      ]);
      expect((await server.call('DELETE', '/api/raeume/$raumA', token: token)).status, 409);
      expect((await server.call('DELETE', '/api/raeume/$raumB', token: token)).status, 200);
      expect((await pull(server, token))['raeume'], hasLength(1));
    });

    test('Standort löschen entfernt seine Räume und Geräte', () async {
      await push(server, token, [
        ('geraete', [geraet()]),
      ]);
      expect((await server.call('DELETE', '/api/standorte/$standort', token: token)).status, 200);
      final data = await pull(server, token);
      expect(data['raeume'], isEmpty);
      expect(data['geraete'], isEmpty);
    });
  });
}

Future<Map<String, dynamic>> push(TestServer server, String token, List<(String, List)> batches) async {
  final r = await server.call('POST', '/api/sync', token: token, body: {
    'batches': [
      for (final (type, items) in batches) {'type': type, 'items': items},
    ],
  });
  expect(r.status, 200, reason: '${r.body}');
  return (r.body as Map).cast<String, dynamic>();
}

Future<Map<String, dynamic>> pull(TestServer server, String token, {String? query}) async {
  final r = await server.call('GET', query == null ? '/api/sync' : '/api/sync?$query', token: token);
  expect(r.status, 200, reason: '${r.body}');
  return (r.body as Map).cast<String, dynamic>();
}

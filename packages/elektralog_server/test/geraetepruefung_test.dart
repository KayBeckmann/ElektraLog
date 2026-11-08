@Tags(['postgres'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'support/test_server.dart';

/// Roadmap Geräteprüfung M5: Prüfereignisse — Entwurf, Abschluss,
/// Unveränderlichkeit, Korrektur, keine neuen Prüfungen für inaktive Geräte.
void main() {
  group('Geräteprüfungen', skip: skipWithoutDb, () {
    final server = TestServer();
    late String token;
    final kunde = const Uuid().v4();
    final standort = const Uuid().v4();
    final raum = const Uuid().v4();
    final geraet = const Uuid().v4();

    Map<String, dynamic> geraetJson({bool aktiv = true, int? basis}) => {
          'uuid': geraet,
          'kundeUuid': kunde,
          'standortUuid': standort,
          'raumUuid': raum,
          'bezeichnung': 'Kaffeemaschine',
          'schutzklasse': 'I',
          'aktiv': aktiv,
          if (!aktiv) 'inaktivGrund': 'defekt',
          '_basisVersion': basis,
        };

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
          {'uuid': raum, 'standortUuid': standort, 'bezeichnung': 'Küche', '_basisVersion': null},
        ]),
        ('geraete', [geraetJson()]),
      ]);
    });
    tearDown(server.stop);

    Map<String, dynamic> pruefung(String uuid, {String status = 'entwurf', String? ergebnis, int? basis, List<Map>? punkte}) => {
          'uuid': uuid,
          'geraetUuid': geraet,
          'pruefart': 'wiederholungspruefung',
          'pruefartText': 'Prüfung nach DGUV Vorschrift 3 für ortsveränderliche elektrische Betriebsmittel',
          'pruefungDatum': '2026-11-08',
          'prueferName': 'Kay',
          'regelVersion': 'test-v1',
          'schutzklasse': 'I',
          'status': status,
          'ergebnis': ergebnis,
          'punkteJson': jsonEncode(punkte ??
              [
                {'id': 'rpe', 'bewertung': 'io', 'messwert': 0.12, 'grenzwert': 0.3},
              ]),
          '_basisVersion': basis,
        };

    Future<Map<String, dynamic>> sende(Map<String, dynamic> p) => push(server, token, [
          ('geraetepruefungen', [p]),
        ]);

    test('Entwurf ändern, abschließen, danach unveränderlich; Wiederholung des Abschlusses ist ok', () async {
      final id = const Uuid().v4();
      expect((await sende(pruefung(id)))['ergebnisse'], hasLength(1));
      expect((await sende({...pruefung(id, basis: 1), 'bemerkung': 'Zwischenstand'}))['ergebnisse'].single['version'], 2);
      final abschluss = pruefung(id, status: 'abgeschlossen', ergebnis: 'bestanden', basis: 2);
      expect((await sende(abschluss))['ergebnisse'].single['version'], 3);

      final nochmal = await sende({...abschluss, '_basisVersion': 3});
      expect(nochmal['abgelehnt'], isEmpty, reason: 'gleicher Inhalt erneut gesendet');
      final aenderung = await sende({...abschluss, '_basisVersion': 3, 'ergebnis': 'nicht_bestanden'});
      expect((aenderung['abgelehnt'] as List).single['grund'], contains('unveränderlich'));
      final p = ((await pull(server, token))['geraetepruefungen'] as List).single as Map;
      expect((p['status'], p['ergebnis'], p['version']), ('abgeschlossen', 'bestanden', 3));
      expect(p['abgeschlossenAm'], isNotNull);
    });

    test('Abschluss braucht Ergebnis und Prüfer; bestanden trotz „nicht i. O.“ wird abgelehnt', () async {
      final r = await push(server, token, [
        ('geraetepruefungen', [
          pruefung(const Uuid().v4(), status: 'abgeschlossen'),
          {...pruefung(const Uuid().v4(), status: 'abgeschlossen', ergebnis: 'bestanden'), 'prueferName': null},
          pruefung(const Uuid().v4(), status: 'abgeschlossen', ergebnis: 'bestanden', punkte: [
            {'id': 'riso', 'bewertung': 'nio'},
          ]),
        ]),
      ]);
      expect(r['abgelehnt'], hasLength(3));
      final nichtBestanden = await sende(pruefung(const Uuid().v4(), status: 'abgeschlossen', ergebnis: 'nicht_bestanden', punkte: [
        {'id': 'riso', 'bewertung': 'nio'},
      ]));
      expect(nichtBestanden['ergebnisse'], hasLength(1));
    });

    test('Korrektur als neue Prüfung mit Verweis', () async {
      final alt = const Uuid().v4();
      await sende(pruefung(alt, status: 'abgeschlossen', ergebnis: 'bestanden'));
      final neu = await sende({...pruefung(const Uuid().v4(), status: 'abgeschlossen', ergebnis: 'nicht_bestanden'), 'ersetztUuid': alt});
      expect(neu['ergebnisse'], hasLength(1));
      final alle = (await pull(server, token))['geraetepruefungen'] as List;
      expect(alle.map((p) => p['ersetztUuid']), containsAll([null, alt]));
    });

    test('Inaktives Gerät bekommt keine neue Prüfung', () async {
      await push(server, token, [
        ('geraete', [geraetJson(aktiv: false, basis: 1)]),
      ]);
      final r = await sende(pruefung(const Uuid().v4()));
      expect((r['abgelehnt'] as List).single['grund'], contains('Inaktives Gerät'));
    });

    test('Gerät mit Prüfungen lässt sich nicht löschen', () async {
      await sende(pruefung(const Uuid().v4()));
      expect((await server.call('DELETE', '/api/geraete/$geraet', token: token)).status, 409);
    });

    test('Prüfungen nur für ausgewählte Räume, nie für fremde Firmen', () async {
      await sende(pruefung(const Uuid().v4()));
      expect((await pull(server, token, query: 'raeume='))['geraetepruefungen'], isEmpty);
      expect((await pull(server, token, query: 'raeume=$raum'))['geraetepruefungen'], hasLength(1));

      final b = (await server.firmaMitBenutzer('Firma B', 'b@test.invalid')).token;
      expect((await pull(server, b))['geraetepruefungen'], isEmpty);
      final r = await push(server, b, [
        ('geraetepruefungen', [pruefung(const Uuid().v4())]),
      ]);
      expect(r['abgelehnt'], hasLength(1));
    });
  });
}

@Tags(['postgres'])
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'support/test_server.dart';

const uuid = Uuid();

/// Roadmap-Nachtrag 20./21.11.2026: Ansprechpartner am Kunden, eigener
/// Kontakt je Standort, SMTP-Zugang der Firma und Versand archivierter
/// Protokolle an die Standort-E-Mail.
void main() {
  group('Kontakte, SMTP und Protokollversand', skip: skipWithoutDb, () {
    final server = TestServer();
    late ({String token, String firmaId}) a;

    setUp(() async {
      await server.start();
      a = await server.firmaMitBenutzer('Firma A', 'a@test.invalid');
    });
    tearDown(server.stop);

    Future<String> mitarbeiter(String email, String rolle) async {
      final r = await server.call('POST', '/api/firma/benutzer',
          token: a.token, body: {'email': email, 'passwort': 'passwort-12345', 'name': rolle, 'rolle': rolle});
      expect(r.status, 200, reason: '${r.body}');
      return server.login(email, 'passwort-12345');
    }

    /// Kunde mit zwei Standorten (unterschiedliche Kontakte), je ein
    /// Verteiler, im zweiten Standort ein Raum.
    Future<({String kunde, String nord, String sued, String uvNord, String raumSued})> bestand(String token) async {
      final ids = (kunde: uuid.v4(), nord: uuid.v4(), sued: uuid.v4(), uvNord: uuid.v4(), raumSued: uuid.v4());
      await push(server, token, [
        ('kunden', [
          {'uuid': ids.kunde, 'name': 'Muster GmbH', 'kontaktEmail': 'zentrale@muster.invalid', 'ansprechpartner': 'Frau Zentral'},
        ]),
        ('standorte', [
          {
            'uuid': ids.nord,
            'kundeUuid': ids.kunde,
            'bezeichnung': 'Werk Nord',
            'kontaktPerson': 'Herr Nord',
            'kontaktEmail': 'nord@muster.invalid',
            'kontaktTelefon': '0401',
          },
          {
            'uuid': ids.sued,
            'kundeUuid': ids.kunde,
            'bezeichnung': 'Werk Süd',
            'kontaktPerson': 'Frau Süd',
            'kontaktEmail': 'sued@muster.invalid',
          },
        ]),
        ('verteiler', [
          {'uuid': ids.uvNord, 'standortUuid': ids.nord, 'bezeichnung': 'UV Nord'},
        ]),
        ('raeume', [
          {'uuid': ids.raumSued, 'standortUuid': ids.sued, 'bezeichnung': 'Werkstatt'},
        ]),
      ]);
      return ids;
    }

    Future<({String id, String hash, List<int> pdf})> protokoll(String token, String titel,
        {String? bezug, String art = 'anlage'}) async {
      final pdf = utf8.encode('%PDF-1.4 $titel');
      final hash = sha256.convert(pdf).toString();
      final r = await server.call('POST', '/api/protokolle', token: token, body: {
        'verteilerBezeichnung': titel,
        'standortBezeichnung': 'Standort laut PDF',
        'kundenBezeichnung': 'Muster GmbH',
        'prueferName': 'Kay',
        'firmaName': 'Firma A',
        'protokollDatum': '2026-11-20T09:00:00Z',
        'pdfBase64': base64Encode(pdf),
        'pdfHash': hash,
        'art': art,
        if (bezug != null) 'bezugUuid': bezug,
      });
      expect(r.status, 200, reason: '${r.body}');
      return (id: (r.body as Map)['id'] as String, hash: hash, pdf: pdf);
    }

    Map<String, Object?> smtp({Object? passwort = 'geheim-123', bool mitPasswort = true}) => {
          'host': 'smtp.test.invalid',
          'port': 587,
          'tlsModus': 'starttls',
          'absenderEmail': 'protokolle@firma-a.invalid',
          'absenderName': 'Firma A',
          'benutzer': 'protokolle@firma-a.invalid',
          if (mitPasswort) 'passwort': passwort,
        };

    test('Standorte desselben Kunden behalten eigene Kontakte, Kunde seinen Ansprechpartner', () async {
      final ids = await bestand(a.token);
      final daten = await pull(server, a.token);
      final standorte = {for (final s in daten['standorte'] as List) (s as Map)['uuid']: s};
      expect(standorte[ids.nord], containsPair('kontaktEmail', 'nord@muster.invalid'));
      expect(standorte[ids.nord], containsPair('kontaktPerson', 'Herr Nord'));
      expect(standorte[ids.nord], containsPair('kontaktTelefon', '0401'));
      expect(standorte[ids.sued], containsPair('kontaktEmail', 'sued@muster.invalid'));
      expect(standorte[ids.sued], containsPair('kontaktPerson', 'Frau Süd'));
      final kunde = (daten['kunden'] as List).single as Map;
      expect(kunde['ansprechpartner'], 'Frau Zentral');

      // Web-App-Lesezugriff liefert dieselben Felder.
      final online = await server.call('GET', '/api/daten/standorte/${ids.sued}', token: a.token);
      expect(online.body, containsPair('kontaktEmail', 'sued@muster.invalid'));
    });

    test('Älterer Client ohne die neuen Felder überschreibt Kontakte nicht; leeren geht ausdrücklich', () async {
      final ids = await bestand(a.token);
      Future<Map> standort() async =>
          ((await pull(server, a.token))['standorte'] as List).cast<Map>().firstWhere((s) => s['uuid'] == ids.nord);

      await push(server, a.token, [
        ('standorte', [
          {'uuid': ids.nord, 'kundeUuid': ids.kunde, 'bezeichnung': 'Werk Nord (alt)'},
        ]),
        ('kunden', [
          {'uuid': ids.kunde, 'name': 'Muster GmbH'},
        ]),
      ]);
      expect(await standort(), allOf(containsPair('bezeichnung', 'Werk Nord (alt)'), containsPair('kontaktPerson', 'Herr Nord')));
      expect(((await pull(server, a.token))['kunden'] as List).single, containsPair('ansprechpartner', 'Frau Zentral'));

      await push(server, a.token, [
        ('standorte', [
          {'uuid': ids.nord, 'kundeUuid': ids.kunde, 'bezeichnung': 'Werk Nord', 'kontaktPerson': '', 'kontaktEmail': null},
        ]),
      ]);
      expect(await standort(), allOf(containsPair('kontaktPerson', null), containsPair('kontaktEmail', null)));
    });

    test('Ungültige Standort-E-Mail wird abgelehnt', () async {
      final ids = await bestand(a.token);
      final r = await push(server, a.token, [
        ('standorte', [
          {'uuid': ids.nord, 'kundeUuid': ids.kunde, 'bezeichnung': 'Werk Nord', 'kontaktEmail': 'kein-at-zeichen'},
        ]),
      ]);
      expect(r['abgelehnt'], hasLength(1));
      expect(jsonEncode(r['abgelehnt']), contains('Standort-E-Mail ungültig'));
    });

    test('SMTP: nur Firmenadmin, Passwort verschlüsselt und nie ausgeliefert', () async {
      expect((await server.call('GET', '/api/firma/smtp', token: a.token)).body, {'konfiguriert': false});
      final r = await server.call('PUT', '/api/firma/smtp', token: a.token, body: smtp());
      expect(r.status, 200, reason: '${r.body}');
      expect(r.body, containsPair('passwortGesetzt', true));
      expect(jsonEncode(r.body), isNot(contains('geheim-123')));

      final gespeichert = await server.db.execute(
        Sql.named('SELECT passwort_verschluesselt FROM firmen_smtp WHERE firma_id = @fid'),
        parameters: {'fid': a.firmaId},
      );
      expect(gespeichert.first[0], allOf(startsWith('v1:'), isNot(contains('geheim-123'))));

      for (final rolle in ['Projektleiter', 'Monteur']) {
        final t = await mitarbeiter('${rolle.toLowerCase()}@test.invalid', rolle);
        expect((await server.call('GET', '/api/firma/smtp', token: t)).status, 403);
        expect((await server.call('PUT', '/api/firma/smtp', token: t, body: smtp())).status, 403);
      }
      final b = await server.firmaMitBenutzer('Firma B', 'b@test.invalid');
      expect((await server.call('GET', '/api/firma/smtp', token: b.token)).body, {'konfiguriert': false});

      // Ohne Passwortfeld bleibt es, leer entfernt es.
      await server.call('PUT', '/api/firma/smtp', token: a.token, body: smtp(mitPasswort: false));
      expect((await server.call('GET', '/api/firma/smtp', token: a.token)).body, containsPair('passwortGesetzt', true));
      await server.call('PUT', '/api/firma/smtp', token: a.token, body: smtp(passwort: ''));
      expect((await server.call('GET', '/api/firma/smtp', token: a.token)).body, containsPair('passwortGesetzt', false));

      // Prüfungen
      for (final (feld, wert) in [('port', 0), ('tlsModus', 'tls'), ('absenderEmail', 'x'), ('host', ' ')]) {
        final f = await server.call('PUT', '/api/firma/smtp', token: a.token, body: {...smtp(), feld: wert});
        expect(f.status, 400, reason: feld);
      }
      expect((await server.call('DELETE', '/api/firma/smtp', token: a.token)).body, {'konfiguriert': false});
    });

    test('Testmail nutzt das entschlüsselte Passwort; unlesbares Passwort meldet sich verständlich', () async {
      expect((await server.call('POST', '/api/firma/smtp/test', token: a.token, body: {'empfaenger': 'kay@test.invalid'})).status, 409);
      await server.call('PUT', '/api/firma/smtp', token: a.token, body: smtp());
      final r = await server.call('POST', '/api/firma/smtp/test', token: a.token, body: {'empfaenger': 'kay@test.invalid'});
      expect(r.status, 200, reason: '${r.body}');
      final (zugang, nachricht) = server.mail.gesendet.single;
      expect((zugang.passwort, zugang.host, zugang.tlsModus, nachricht.an), ('geheim-123', 'smtp.test.invalid', 'starttls', 'kay@test.invalid'));

      server.mail.fehler = 'Anmeldung am SMTP-Server fehlgeschlagen';
      final f = await server.call('POST', '/api/firma/smtp/test', token: a.token, body: {'empfaenger': 'kay@test.invalid'});
      expect((f.status, (f.body as Map)['error']), (502, 'Anmeldung am SMTP-Server fehlgeschlagen'));

      // Mit anderem Serverschlüssel verschlüsselt → nicht lesbar.
      await server.db.execute(
        Sql.named("UPDATE firmen_smtp SET passwort_verschluesselt = 'v1:AAAAAAAAAAAAAAAA:AAAAAAAAAAAAAAAAAAAAAA==' WHERE firma_id = @fid"),
        parameters: {'fid': a.firmaId},
      );
      final u = await server.call('POST', '/api/firma/smtp/test', token: a.token, body: {'empfaenger': 'kay@test.invalid'});
      expect(u.status, 409);
      expect((u.body as Map)['error'], contains('neu eingeben'));
    });

    test('Versandinfo schlägt den Standort des Protokolls vor — Verteiler- und Raumbezug', () async {
      final ids = await bestand(a.token);
      final anlage = await protokoll(a.token, 'UV Nord', bezug: ids.uvNord);
      final geraete = await protokoll(a.token, 'Werkstatt', bezug: ids.raumSued, art: 'geraete');
      final alt = await protokoll(a.token, 'Altprotokoll');

      final i1 = (await server.call('GET', '/api/protokolle/${anlage.id}/versand', token: a.token)).body as Map;
      expect(i1['standort'], containsPair('kontaktEmail', 'nord@muster.invalid'));
      expect(i1['standort'], containsPair('kontaktPerson', 'Herr Nord'));
      expect(i1['kunde'], containsPair('kontaktEmail', 'zentrale@muster.invalid'));
      expect((i1['smtpKonfiguriert'], i1['pdfHash']), (false, anlage.hash));
      expect(i1['verlauf'], isEmpty);

      final i2 = (await server.call('GET', '/api/protokolle/${geraete.id}/versand', token: a.token)).body as Map;
      expect(i2['standort'], containsPair('kontaktEmail', 'sued@muster.invalid'));

      final i3 = (await server.call('GET', '/api/protokolle/${alt.id}/versand', token: a.token)).body as Map;
      expect((i3['standort'], i3['kunde']), (null, null));

      final b = await server.firmaMitBenutzer('Firma B', 'b@test.invalid');
      expect((await server.call('GET', '/api/protokolle/${anlage.id}/versand', token: b.token)).status, 404);
    });

    test('Versand: genau das archivierte PDF, kein Doppelversand, Fehler im Verlauf', () async {
      final ids = await bestand(a.token);
      final p = await protokoll(a.token, 'UV Nord', bezug: ids.uvNord);
      final monteur = await mitarbeiter('mo@test.invalid', 'Monteur');
      Map<String, Object?> anfrage(String id, {String? hash, String an = 'nord@muster.invalid', List<String> cc = const []}) =>
          {'anfrageId': id, 'empfaenger': an, 'cc': cc, 'pdfHash': hash ?? p.hash};
      Future<({int status, dynamic body})> sende(Map<String, Object?> body, [String? token]) =>
          server.call('POST', '/api/protokolle/${p.id}/versand', token: token ?? a.token, body: body);

      expect((await sende(anfrage(uuid.v4()))).status, 409, reason: 'ohne SMTP');
      await server.call('PUT', '/api/firma/smtp', token: a.token, body: smtp());

      expect((await sende(anfrage(uuid.v4(), an: 'falsch'))).status, 400);
      expect((await sende(anfrage(uuid.v4(), cc: ['auch falsch']))).status, 400);
      expect((await sende({...anfrage(uuid.v4()), 'anfrageId': 'x'})).status, 400);
      expect((await sende(anfrage(uuid.v4(), hash: 'veraltet'))).status, 409);
      expect(server.mail.gesendet, isEmpty);

      final id = uuid.v4();
      final r = await sende(anfrage(id, cc: ['buero@firma-a.invalid']), monteur);
      expect(r.status, 200, reason: '${r.body}');
      expect(r.body, allOf(containsPair('status', 'gesendet'), containsPair('benutzer', 'Monteur')));
      final (_, mail) = server.mail.gesendet.single;
      expect(mail.an, 'nord@muster.invalid');
      expect(mail.cc, ['buero@firma-a.invalid']);
      expect(mail.betreff, 'Prüfprotokoll Anlagenprüfung — Werk Nord vom 20.11.2026');
      expect(mail.anhaenge.single.bytes, p.pdf);
      expect(mail.anhaenge.single.dateiname, 'Protokoll_UV_Nord_2026-11-20.pdf');

      // Wiederholung nach Timeout: kein zweiter Versand.
      final w = await sende(anfrage(id));
      expect((w.status, (w.body as Map)['wiederholt'], (w.body as Map)['status']), (200, true, 'gesendet'));
      expect(server.mail.gesendet, hasLength(1));

      server.mail.fehler = 'Versand abgelehnt: Mailbox voll';
      final f = await sende(anfrage(uuid.v4()));
      expect((f.status, (f.body as Map)['status'], (f.body as Map)['error']), (502, 'fehler', 'Versand abgelehnt: Mailbox voll'));

      final verlauf = ((await server.call('GET', '/api/protokolle/${p.id}/versand', token: a.token)).body as Map)['verlauf'] as List;
      expect([for (final v in verlauf) (v as Map)['status']], ['fehler', 'gesendet']);

      // Fremde Firma kann nicht versenden.
      final b = await server.firmaMitBenutzer('Firma B', 'b@test.invalid');
      await server.call('PUT', '/api/firma/smtp', token: b.token, body: smtp());
      expect((await sende(anfrage(uuid.v4()), b.token)).status, 404);
    });
  });
}

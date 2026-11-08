@Tags(['e2e'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:elektralog/core/api/api_service.dart';
import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/kunde.dart';
import 'package:elektralog/core/models/messung.dart';
import 'package:elektralog/core/models/pruefmatrix.dart';
import 'package:elektralog/core/models/pruefprotokoll.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/models/verteiler.dart';
import 'package:elektralog/core/models/verteiler_komponente.dart';
import 'package:elektralog/core/online/online_daten.dart';
import 'package:elektralog/core/online/online_repositories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// Web-App online (Kay, 2026-11-08): zwei Browser-Sitzungen derselben
/// Firma gegen den echten Server — je Ansicht gezielt geladen, versioniert
/// gespeichert, nichts still überschrieben. Läuft nur mit
/// ELEKTRALOG_E2E_URL/ELEKTRALOG_E2E_ADMIN (siehe README „End-to-End-Test“).
void main() {
  final url = Platform.environment['ELEKTRALOG_E2E_URL'];
  final admin = Platform.environment['ELEKTRALOG_E2E_ADMIN'];
  final skip = url == null || admin == null ? 'ELEKTRALOG_E2E_URL/ELEKTRALOG_E2E_ADMIN nicht gesetzt' : false;

  Future<Map<String, dynamic>> api(String method, String pfad, {Object? body, String? token}) async {
    final req = http.Request(method, Uri.parse('$url/api$pfad'))
      ..headers['Content-Type'] = 'application/json'
      ..body = body == null ? '' : jsonEncode(body);
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    final resp = await http.Response.fromStream(await req.send());
    if (resp.statusCode >= 300) throw StateError('$method $pfad: ${resp.statusCode} ${resp.body}');
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<String> login(String email, String passwort) async =>
      (await api('POST', '/auth/login', body: {'email': email, 'passwort': passwort}))['token'] as String;

  Future<String> testfirma() async {
    final teile = admin!.split(':');
    final superadmin = await login(teile.first, teile.sublist(1).join(':'));
    final firma = await api('POST', '/admin/firmen',
        body: {'name': 'E2E Online ${DateTime.now().millisecondsSinceEpoch}'}, token: superadmin);
    final email = '${const Uuid().v4().substring(0, 8)}@e2e.invalid';
    await api('POST', '/admin/firmen/${firma['id']}/benutzer',
        body: {'email': email, 'passwort': 'e2e-passwort-123', 'name': 'E2E Online'}, token: superadmin);
    return login(email, 'e2e-passwort-123');
  }

  test('Zwei Browser-Sitzungen: je Ansicht laden, versioniert speichern, löschen, ablegen', skip: skip, () async {
    final token = await testfirma();
    final a = OnlineDaten(_HttpTransport(url!, token));
    final b = OnlineDaten(_HttpTransport(url, token));
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    // Anlegen in Sitzung A.
    final kunde = Kunde(uuid: const Uuid().v4(), name: 'Fiktive Bäckerei');
    await OnlineKundenRepository(a).save(kunde);
    final standort = Standort(kundeUuid: kunde.uuid, bezeichnung: 'Filiale');
    await OnlineStandorteRepository(a).save(standort);
    final raumA = Raum(standortUuid: standort.uuid, bezeichnung: 'Backstube');
    final raumB = Raum(standortUuid: standort.uuid, bezeichnung: 'Verkauf');
    await OnlineRaeumeRepository(a).save(raumA);
    await OnlineRaeumeRepository(a).save(raumB);
    final g = Geraet.neu(
      kundeUuid: kunde.uuid,
      standortUuid: standort.uuid,
      raumUuid: raumA.uuid,
      bezeichnung: 'Teigmaschine',
      schutzklasse: 'I',
    ).mitIntervall(12, begruendung: 'Backstube');
    await OnlineGeraeteRepository(a).save(g);

    // Sitzung B sieht genau die Ansicht — Geräte des Raums, Räume des Standorts.
    expect((await OnlineGeraeteRepository(b).watchByRaum(raumA.uuid).first).single.bezeichnung, 'Teigmaschine');
    expect(await OnlineGeraeteRepository(b).watchByRaum(raumB.uuid).first, isEmpty);
    expect([for (final r in await OnlineRaeumeRepository(b).getByStandort(standort.uuid)) r.bezeichnung],
        ['Backstube', 'Verkauf']);

    // Gleichzeitiges Bearbeiten: A speichert zuerst, B wird nicht still übernommen.
    final ga = (await OnlineGeraeteRepository(a).getByUuid(g.uuid))!;
    final gb = (await OnlineGeraeteRepository(b).getByUuid(g.uuid))!;
    await OnlineGeraeteRepository(a).save(ga.mitStammdaten(
        bezeichnung: 'Teigmaschine', hersteller: 'A', schutzklasse: 'I', pruefintervallMonate: 12, intervallBegruendung: 'x'));
    await expectLater(
      OnlineGeraeteRepository(b).save(gb.mitStammdaten(
          bezeichnung: 'Teigmaschine', hersteller: 'B', schutzklasse: 'I', pruefintervallMonate: 12, intervallBegruendung: 'x')),
      throwsA(isA<OnlineSpeicherFehler>()),
    );
    expect((await OnlineGeraeteRepository(b).getByUuid(g.uuid))!.hersteller, 'A', reason: 'nichts überschrieben');
    final neuB = (await OnlineGeraeteRepository(b).getByUuid(g.uuid))!;
    await OnlineGeraeteRepository(b).save(neuB.mitStammdaten(
        bezeichnung: 'Teigmaschine', hersteller: 'B', schutzklasse: 'I', pruefintervallMonate: 12, intervallBegruendung: 'x'));
    expect((await OnlineGeraeteRepository(a).getByUuid(g.uuid))!.hersteller, 'B', reason: 'nach Neuladen gespeichert');

    // Ortswechsel nur mit Bestätigung.
    final aktuell = (await OnlineGeraeteRepository(a).getByUuid(g.uuid))!;
    final umgezogen = aktuell.umgehaengt(kundeUuid: kunde.uuid, standortUuid: standort.uuid, raumUuid: raumB.uuid);
    await expectLater(OnlineGeraeteRepository(a).save(umgezogen), throwsA(isA<OnlineSpeicherFehler>()));
    await OnlineGeraeteRepository(a).saveUmgehaengt(umgezogen);
    expect((await OnlineGeraeteRepository(b).getByUuid(g.uuid))!.raumUuid, raumB.uuid);
    expect(await OnlineRaeumeRepository(a).deleteWennLeer(raumB.uuid), isFalse, reason: 'Raum mit Gerät');
    expect(await OnlineRaeumeRepository(a).deleteWennLeer(raumA.uuid), isTrue);

    // Prüfmaske: schnelles Tippen (viele Speichervorgänge ohne Warten) ohne Konflikt.
    final geraet = (await OnlineGeraeteRepository(a).getByUuid(g.uuid))!;
    var entwurf = neuerEntwurf(geraet, prueferName: 'Kay');
    final pruefungen = OnlineGeraetePruefungenRepository(a);
    await pruefungen.save(entwurf);
    final laeufe = <Future<void>>[];
    for (var i = 1; i <= 10; i++) {
      entwurf = entwurf.kopie(bemerkung: 'Tippen $i');
      laeufe.add(pruefungen.save(entwurf));
    }
    await Future.wait(laeufe);
    expect((await OnlineGeraetePruefungenRepository(b).getByUuid(entwurf.uuid))!.bemerkung, 'Tippen 10');
    await pruefungen.entwurfVerwerfen(entwurf.uuid);
    expect(await OnlineGeraetePruefungenRepository(b).getByGeraet(g.uuid), isEmpty);

    // Anlagen: Messung anlegen und löschen.
    final verteiler = Verteiler(standortUuid: standort.uuid, bezeichnung: 'UV1');
    await OnlineVerteilerRepository(a).save(verteiler);
    final komponente = VerteilerKomponente(verteilerUuid: verteiler.uuid, typ: 'rcd', zielbezeichnung: 'FI');
    await OnlineKomponentenRepository(a).save(komponente);
    final m = Messung(
      komponenteUuid: komponente.uuid,
      norm: 'vde_0100',
      pruefungDatum: DateTime(2026, 11, 8),
      ergebnis: 'bestanden',
      pruefgeraet: 'Fluke',
    );
    await OnlineMessungenRepository(a).save(m);
    expect((await OnlineMessungenRepository(b).getByKomponenteUuids([komponente.uuid])).single.pruefgeraet, 'Fluke');
    await OnlineMessungenRepository(b).delete(m.uuid);
    expect(await OnlineMessungenRepository(a).getByKomponente(komponente.uuid), isEmpty);

    // Dokumentenablage: Prüfverlauf des Verteilers kommt vom Server.
    Future<List<dynamic>> laden(String? bezug) async {
      final r = await http.get(
        Uri.parse('$url/api/protokolle').replace(queryParameters: {if (bezug != null) 'bezug': bezug}),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(r.body) as List;
    }

    Future<String?> hochladen(Pruefprotokoll p, Uint8List bytes) async => (await api('POST', '/protokolle', token: token, body: {
          'verteilerBezeichnung': p.verteilerBezeichnung,
          'protokollDatum': p.protokollDatum.toIso8601String(),
          'pdfBase64': base64Encode(bytes),
          'pdfHash': sha256.convert(bytes).toString(),
          'bezugUuid': p.verteilerUuid,
        }))['id'] as String?;

    final ablage = OnlinePruefprotokollRepository(a, laden: laden);
    final pdf = Uint8List.fromList(utf8.encode('%PDF test'));
    await ablage.ablegen(
      Pruefprotokoll(verteilerUuid: verteiler.uuid, protokollDatum: DateTime.now(), verteilerBezeichnung: 'UV1'),
      pdf,
      upload: hochladen,
    );
    final verlauf = await OnlinePruefprotokollRepository(b, laden: laden).watchByVerteiler(verteiler.uuid).first;
    expect([for (final p in verlauf) (p.verteilerBezeichnung, p.verteilerUuid)], [('UV1', verteiler.uuid)]);
  });
}

class _HttpTransport implements OnlineTransport {
  _HttpTransport(this.url, this.token);
  final String url;
  final String token;

  Map<String, String> get _kopf => {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

  void _pruefen(http.Response r) {
    if (r.statusCode != 200) throw ApiException(r.statusCode, r.body);
  }

  @override
  Future<dynamic> get(String pfad, [Map<String, String>? query]) async {
    final r = await http.get(
      Uri.parse('$url/api$pfad').replace(queryParameters: query == null || query.isEmpty ? null : query),
      headers: _kopf,
    );
    _pruefen(r);
    return jsonDecode(r.body);
  }

  @override
  Future<Map<String, dynamic>> sync(List<Map<String, dynamic>> batches) async {
    final r = await http.post(Uri.parse('$url/api/sync'), headers: _kopf, body: jsonEncode({'batches': batches}));
    _pruefen(r);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  @override
  Future<void> delete(String pfad) async => _pruefen(await http.delete(Uri.parse('$url/api$pfad'), headers: _kopf));
}

@Tags(['e2e'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/kunde.dart';
import 'package:elektralog/core/models/pruefmatrix.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/providers/geraete_provider.dart';
import 'package:elektralog/core/providers/kunden_provider.dart';
import 'package:elektralog/core/providers/standorte_provider.dart';
import 'package:elektralog/core/providers/sync_auswahl_provider.dart';
import 'package:elektralog/core/sync/sync_engine.dart';
import 'package:elektralog/core/sync/sync_meta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Roadmap Geräteprüfung M8: Ende-zu-Ende mit zwei Arbeitsgeräten (echte
/// App-SyncEngine, getrennte lokale Datenbanken) gegen den echten Server
/// mit Postgres. Läuft nur mit
///
///   ELEKTRALOG_E2E_URL=http://localhost:18080
///   ELEKTRALOG_E2E_ADMIN=<superadmin-email>:<passwort>
///
/// und legt eigene, fiktive Testfirmen an — nie gegen eine produktive
/// Instanz laufen lassen. Ablauf siehe README „End-to-End-Test“.
void main() {
  final url = Platform.environment['ELEKTRALOG_E2E_URL'];
  final admin = Platform.environment['ELEKTRALOG_E2E_ADMIN'];
  final skip = url == null || admin == null ? 'ELEKTRALOG_E2E_URL/ELEKTRALOG_E2E_ADMIN nicht gesetzt' : false;

  setUpAll(() {
    disableSembastCooperator();
    SharedPreferences.setMockInitialValues({});
  });

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

  /// Neue fiktive Firma mit Firmenadmin, liefert dessen Token.
  Future<String> testfirma(String name) async {
    final teile = admin!.split(':');
    final superadmin = await login(teile.first, teile.sublist(1).join(':'));
    final firma = await api('POST', '/admin/firmen', body: {'name': name}, token: superadmin);
    final email = '${const Uuid().v4().substring(0, 8)}@e2e.invalid';
    await api('POST', '/admin/firmen/${firma['id']}/benutzer',
        body: {'email': email, 'passwort': 'e2e-passwort-123', 'name': 'E2E $name'}, token: superadmin);
    return login(email, 'e2e-passwort-123');
  }

  test('Zwei Geräte: Geräteprüfung durchgängig über den echten Server', skip: skip, () async {
    final token = await testfirma('E2E Firma ${DateTime.now().millisecondsSinceEpoch}');
    final a = await _Geraet.neu(url!, token, 'a');
    final b = await _Geraet.neu(url, token, 'b');

    // A: Stammdaten anlegen.
    await KundenRepository(a.db).save(Kunde(uuid: const Uuid().v4(), name: 'Fiktive Bäckerei'));
    final kunde = (await KundenRepository(a.db).getAll()).single;
    final standort = Standort(kundeUuid: kunde.uuid, bezeichnung: 'Filiale Nord');
    await StandorteRepository(a.db).save(standort);
    final raumA = Raum(standortUuid: standort.uuid, bezeichnung: 'Backstube');
    final raumB = Raum(standortUuid: standort.uuid, bezeichnung: 'Verkauf');
    await RaeumeRepository(a.db).save(raumA);
    await RaeumeRepository(a.db).save(raumB);
    final geraet = Geraet.neu(
      kundeUuid: kunde.uuid,
      standortUuid: standort.uuid,
      raumUuid: raumA.uuid,
      bezeichnung: 'Teigmaschine',
      schutzklasse: 'I',
    ).mitIntervall(12, begruendung: 'Backstube');
    await GeraeteRepository(a.db).save(geraet);
    expect((await a.engine.push()).abgelehnt, 0);

    // B: sieht Räume, lädt Geräte erst nach Auswahl.
    await b.engine.pull();
    expect(await RaeumeRepository(b.db).getByStandort(standort.uuid), hasLength(2));
    expect(await GeraeteRepository(b.db).getAlle(), isEmpty);
    await SyncAuswahlRepository(b.db).setRaumAktiviert(raumA.uuid, true);
    await b.engine.pull();
    expect((await GeraeteRepository(b.db).getByUuid(geraet.uuid))!.bezeichnung, 'Teigmaschine');

    // Gleichzeitige Offline-Änderung → Konflikt auf B, Server unverändert.
    final ga = (await GeraeteRepository(a.db).getByUuid(geraet.uuid))!;
    final gb = (await GeraeteRepository(b.db).getByUuid(geraet.uuid))!;
    await GeraeteRepository(a.db).save(ga.mitStammdaten(bezeichnung: 'Teigmaschine', hersteller: 'Hersteller A', schutzklasse: 'I', pruefintervallMonate: 12, intervallBegruendung: 'Backstube'));
    await GeraeteRepository(b.db).save(gb.mitStammdaten(bezeichnung: 'Teigmaschine', seriennummer: 'SN-B', schutzklasse: 'I', pruefintervallMonate: 12, intervallBegruendung: 'Backstube'));
    await a.engine.push();
    expect((await b.engine.push()).konflikte, 1);
    final k = (await SyncKonfliktRepository(b.db).watchAlle().first).single;
    await b.engine.aufloesen(k, {...k.server!, 'seriennummer': 'SN-B'});
    expect((await b.engine.push()).konflikte, 0);
    await a.engine.pull();
    await SyncAuswahlRepository(a.db).setGeraeteStandortAktiviert(standort.uuid, true);
    await a.engine.pull();
    final zusammen = (await GeraeteRepository(a.db).getByUuid(geraet.uuid))!;
    expect((zusammen.hersteller, zusammen.seriennummer), ('Hersteller A', 'SN-B'));

    // Raumwechsel: ohne Bestätigung Konflikt, mit Bestätigung übernommen.
    await GeraeteRepository(a.db).save(zusammen.umgehaengt(kundeUuid: kunde.uuid, standortUuid: standort.uuid, raumUuid: raumB.uuid));
    expect((await a.engine.push()).konflikte, 1);
    final z = (await SyncKonfliktRepository(a.db).watchAlle().first).single;
    expect(z.art, 'zuordnung');
    await a.engine.aufloesen(z, {...z.server!, 'raumUuid': raumB.uuid}, zuordnungBestaetigt: true);
    expect((await a.engine.push()).konflikte, 0);

    // Prüfung abschließen, danach auf dem Server unveränderlich.
    final g = (await GeraeteRepository(a.db).getByUuid(geraet.uuid))!;
    final e = neuerEntwurf(g, prueferName: 'E2E Prüfer');
    final fertig = abschliessen(
      e.kopie(ergebnis: 'bestanden', punkte: [
        for (final x in e.punkte)
          x.istMessung ? x.kopie(messwert: x.vergleich == '<=' ? 0.05 : 100, bewertung: 'io') : x.kopie(bewertung: 'io'),
      ]),
      geraet: g,
      kunde: kunde.name,
      standort: standort.bezeichnung,
      raum: raumB.bezeichnung,
    );
    await GeraetePruefungenRepository(a.db).save(fertig);
    expect((await a.engine.push()).abgelehnt, 0);
    final manipuliert = await api('POST', '/sync', token: token, body: {
      'batches': [
        {
          'type': 'geraetepruefungen',
          'items': [
            {...fertig.kopie(ergebnis: 'nicht_bestanden', maengel: 'x').toJson(), '_basisVersion': 1},
          ],
        },
      ],
    });
    expect((manipuliert['abgelehnt'] as List).single['grund'], contains('unveränderlich'));

    // B bekommt Prüfung nach Auswahl des neuen Raums; Mandantengrenze hält.
    await SyncAuswahlRepository(b.db).setRaumAktiviert(raumB.uuid, true);
    await b.engine.pull();
    expect((await GeraetePruefungenRepository(b.db).getAlle()).single.bestanden, isTrue);
    final fremd = await testfirma('E2E Fremd ${DateTime.now().millisecondsSinceEpoch}');
    final fremdSicht = await api('GET', '/sync', token: fremd);
    expect([fremdSicht['geraete'], fremdSicht['raeume'], fremdSicht['geraetepruefungen']], everyElement(isEmpty));

    // Modul aus und wieder an: nichts gelöscht.
    await api('PUT', '/firma/module', token: token, body: {'geraetepruefung': false});
    expect((await api('GET', '/sync', token: token))['geraete'], hasLength(1));
    await api('PUT', '/firma/module', token: token, body: {'geraetepruefung': true});
  });
}

class _Geraet {
  _Geraet(this.db, this.engine);
  final Database db;
  final SyncEngine engine;

  static Future<_Geraet> neu(String url, String token, String name) async {
    final db = await databaseFactoryMemory.openDatabase('e2e-$name-${DateTime.now().microsecondsSinceEpoch}.db');
    return _Geraet(db, SyncEngine(db, transport: _HttpTransport(url, token), revision: _Revision()));
  }
}

class _HttpTransport implements SyncTransport {
  _HttpTransport(this.url, this.token);
  final String url;
  final String token;

  Map<String, String> get _kopf => {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};

  @override
  Future<Map<String, dynamic>> pull(Map<String, String> query) async {
    final r = await http.get(Uri.parse('$url/api/sync').replace(queryParameters: query), headers: _kopf);
    if (r.statusCode != 200) throw StateError('pull ${r.statusCode} ${r.body}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> push(List<Map<String, dynamic>> batches) async {
    final r = await http.post(Uri.parse('$url/api/sync'), headers: _kopf, body: jsonEncode({'batches': batches}));
    if (r.statusCode != 200) throw StateError('push ${r.statusCode} ${r.body}');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}

class _Revision implements RevisionSpeicher {
  final _werte = <String, int>{};
  @override
  Future<int?> lesen(String key) async => _werte[key];
  @override
  Future<void> schreiben(String key, int wert) async => _werte[key] = wert;
}

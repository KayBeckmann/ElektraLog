import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/kunde.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/providers/geraete_provider.dart';
import 'package:elektralog/core/providers/kunden_provider.dart';
import 'package:elektralog/core/providers/standorte_provider.dart';
import 'package:elektralog/core/providers/sync_auswahl_provider.dart';
import 'package:elektralog/core/sync/sync_engine.dart';
import 'package:elektralog/core/sync/sync_meta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Roadmap Geräteprüfung M3 (App-Seite): zwei Arbeitsgeräte gegen einen
/// Server mit denselben Versionsregeln wie `SyncEngine` im Server.
void main() {
  setUpAll(disableSembastCooperator);

  late FakeServer server;
  late Arbeitsgeraet a;
  late Arbeitsgeraet b;
  var n = 0;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = FakeServer();
    a = await Arbeitsgeraet.neu(server, 'a${n++}');
    b = await Arbeitsgeraet.neu(server, 'b${n++}');
    // Grunddaten auf A anlegen und verteilen.
    await KundenRepository(a.db).save(Kunde(uuid: 'k1', name: 'Kunde'));
    await StandorteRepository(a.db).save(Standort(uuid: 's1', kundeUuid: 'k1', bezeichnung: 'Werk'));
    await RaeumeRepository(a.db).save(Raum(uuid: 'rA', standortUuid: 's1', bezeichnung: 'Raum A'));
    await RaeumeRepository(a.db).save(Raum(uuid: 'rB', standortUuid: 's1', bezeichnung: 'Raum B'));
    await a.engine.push();
    await b.engine.pull();
  });

  Geraet geraet(String uuid, String raum) =>
      Geraet(uuid: uuid, kundeUuid: 'k1', standortUuid: 's1', raumUuid: raum, bezeichnung: 'Gerät $uuid');

  test('Konfliktfreie Änderung kommt still auf dem zweiten Gerät an', () async {
    final kunde = (await KundenRepository(b.db).getByUuid('k1'))!;
    expect(kunde.name, 'Kunde');
    await KundenRepository(a.db).save(kunde.copyWith(name: 'Kunde neu'));
    final p = await a.engine.push();
    expect((p.gesendet, p.konflikte), (1, 0), reason: 'nur der geänderte Datensatz');

    await b.engine.pull();
    expect((await KundenRepository(b.db).getByUuid('k1'))!.name, 'Kunde neu');
    expect(await b.konflikte(), isEmpty);
    expect((await b.engine.push()).gesendet, 0, reason: 'B hat nichts geändert');
  });

  test('Pull überschreibt keine noch nicht gesendete lokale Änderung', () async {
    final kunde = (await KundenRepository(b.db).getByUuid('k1'))!;
    await KundenRepository(b.db).save(kunde.copyWith(name: 'B offline'));
    await b.engine.pull();
    expect((await KundenRepository(b.db).getByUuid('k1'))!.name, 'B offline');
    await b.engine.push();
    expect(server.daten['kunden']!['k1']!.json['name'], 'B offline');
  });

  test('Divergierende Offline-Änderungen halten an, bis der Nutzer zusammenführt', () async {
    await GeraeteRepository(a.db).save(geraet('g1', 'rA'));
    await a.engine.push();
    await SyncAuswahlRepository(b.db).setGeraeteStandortAktiviert('s1', true);
    await b.engine.pull();

    final aSeite = (await GeraeteRepository(a.db).getByUuid('g1'))!;
    final bSeite = (await GeraeteRepository(b.db).getByUuid('g1'))!;
    await GeraeteRepository(a.db).save(aSeite.mitStammdaten(bezeichnung: 'Gerät g1', hersteller: 'Hersteller A'));
    await GeraeteRepository(b.db).save(bSeite.mitStammdaten(bezeichnung: 'Gerät g1', seriennummer: 'SN-B'));

    await a.engine.push();
    final pb = await b.engine.push();
    expect(pb.konflikte, 1);
    expect(server.daten['geraete']!['g1']!.json['seriennummer'], isNull, reason: 'B überschreibt A nicht still');

    // Pull und weitere Pushes lassen den Konflikt unangetastet.
    await b.engine.pull();
    expect((await GeraeteRepository(b.db).getByUuid('g1'))!.seriennummer, 'SN-B');
    expect((await b.engine.push()).gesendet, 0);

    final k = (await b.konflikte()).single;
    expect(k.art, 'konflikt');
    expect((k.lokal['seriennummer'], k.server!['hersteller']), ('SN-B', 'Hersteller A'));

    // Nutzer: Hersteller vom Server, Seriennummer von hier.
    await b.engine.aufloesen(k, {...k.server!, 'seriennummer': 'SN-B'});
    expect(await b.konflikte(), isEmpty);
    expect((await b.engine.push()).konflikte, 0);
    final s = server.daten['geraete']!['g1']!;
    expect((s.json['hersteller'], s.json['seriennummer'], s.version), ('Hersteller A', 'SN-B', 3));

    await SyncAuswahlRepository(a.db).setRaumAktiviert('rA', true);
    await a.engine.pull();
    expect((await GeraeteRepository(a.db).getByUuid('g1'))!.seriennummer, 'SN-B');
  });

  test('Ortswechsel ohne Bestätigung wird Konflikt, mit Bestätigung übernommen', () async {
    await GeraeteRepository(a.db).save(geraet('g1', 'rA'));
    await a.engine.push();
    final g = (await GeraeteRepository(a.db).getByUuid('g1'))!;

    // z. B. ältere/fehlerhafte Speicherung ohne Dialog
    await GeraeteRepository(a.db).save(g.umgehaengt(kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'rB'));
    expect((await a.engine.push()).konflikte, 1);
    final k = (await a.konflikte()).single;
    expect(k.art, 'zuordnung');
    expect(server.daten['geraete']!['g1']!.json['raumUuid'], 'rA');

    await a.engine.aufloesen(k, {...k.server!, 'raumUuid': 'rB'}, zuordnungBestaetigt: true);
    expect((await a.engine.push()).konflikte, 0);
    expect(server.daten['geraete']!['g1']!.json['raumUuid'], 'rB');

    // Über den Formularweg (bestätigter Dialog) direkt ohne Konflikt.
    final g2 = (await GeraeteRepository(a.db).getByUuid('g1'))!;
    await GeraeteRepository(a.db).saveUmgehaengt(g2.umgehaengt(kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'rA'));
    expect((await a.engine.push()).konflikte, 0);
    expect(server.daten['geraete']!['g1']!.json['raumUuid'], 'rA');
    expect(server.audit, 2);
  });

  test('Raum A / Raum B / ganzer Standort / Abwahl / Wiederanwahl', () async {
    await GeraeteRepository(a.db).save(geraet('gA', 'rA'));
    await GeraeteRepository(a.db).save(geraet('gB', 'rB'));
    await a.engine.push();
    final auswahl = SyncAuswahlRepository(b.db);
    Future<Set<String>> lokal() async => {for (final g in await GeraeteRepository(b.db).getAlle()) g.uuid};

    await b.engine.pull();
    expect(await lokal(), isEmpty, reason: 'frisches Gerät lädt keine Geräte');
    expect(await RaeumeRepository(b.db).getByStandort('s1'), hasLength(2), reason: 'Räume zum Auswählen');

    await auswahl.setRaumAktiviert('rA', true);
    await b.engine.pull();
    expect(await lokal(), {'gA'});

    await auswahl.setRaumAktiviert('rB', true);
    await b.engine.pull();
    expect(await lokal(), {'gA', 'gB'});

    await auswahl.setRaumAktiviert('rA', false);
    await auswahl.setRaumAktiviert('rB', false);
    await auswahl.setGeraeteStandortAktiviert('s1', true);
    await GeraeteRepository(a.db).save(geraet('gNeu', 'rB'));
    await a.engine.push();
    await b.engine.pull();
    expect(await lokal(), {'gA', 'gB', 'gNeu'});

    // Abwahl: Hochgeladenes verschwindet vom Gerät, die ausstehende
    // Änderung bleibt, bis sie gesendet ist.
    final gA = (await GeraeteRepository(b.db).getByUuid('gA'))!;
    await GeraeteRepository(b.db).save(gA.mitStammdaten(bezeichnung: 'offline geändert'));
    await auswahl.setGeraeteStandortAktiviert('s1', false);
    await b.engine.pull();
    expect(await lokal(), {'gA'}, reason: 'nur die ungesendete Änderung bleibt');
    await auswahl.setRaumAktiviert('rA', false); // Push wählt den Raum wieder aus …
    await b.engine.push();
    expect(server.daten['geraete']!['gA']!.json['bezeichnung'], 'offline geändert');
    expect(await auswahl.istRaumAktiviert('rA'), isTrue, reason: '… weil hier gearbeitet wurde');
    await auswahl.setRaumAktiviert('rA', false);
    await b.engine.pull();
    expect(await lokal(), isEmpty, reason: 'hochgeladen und abgewählt');

    // Wiederanwahl lädt den aktuellen Stand nach.
    final gB = server.daten['geraete']!['gB']!;
    server.daten['geraete']!['gB'] = (json: {...gB.json, 'bezeichnung': 'auf Server geändert'}, version: gB.version + 1);
    await b.engine.pull();
    expect(await GeraeteRepository(b.db).getByUuid('gB'), isNull, reason: 'nicht ausgewählt');
    await auswahl.setRaumAktiviert('rB', true);
    await b.engine.pull();
    expect((await GeraeteRepository(b.db).getByUuid('gB'))!.bezeichnung, 'auf Server geändert');
  });

  test('Web-App lädt den ganzen Bestand, ohne Auswahl und ohne Entfernen', () async {
    await GeraeteRepository(a.db).save(geraet('gA', 'rA'));
    await GeraeteRepository(a.db).save(geraet('gB', 'rB'));
    await a.engine.push();
    final web = SyncEngine(b.db, transport: server, revision: SpeicherRevision(), vollstaendig: true);
    await web.pull();
    await web.pull();
    expect({for (final g in await GeraeteRepository(b.db).getAlle()) g.uuid}, {'gA', 'gB'});
  });

  test('Erster Sync nach dem Update: gleicher Bestand erzeugt keine Konflikte', () async {
    final c = await Arbeitsgeraet.neu(server, 'c${n++}');
    // Alte App-Version: Daten lokal vorhanden, aber ohne Sync-Metadaten.
    await KundenRepository(c.db).save(Kunde(uuid: 'k1', name: 'Kunde', erstelltAm: DateTime.utc(2026)));
    await c.engine.push();
    expect(await c.konflikte(), isEmpty);
    await c.engine.pull();
    expect(await c.konflikte(), isEmpty);
    expect((await c.engine.push()).gesendet, 0);
  });

  test('Server-Restore erkannt: Merge übersprungen, lokale Daten werden neu gesendet', () async {
    await b.engine.pull();
    final vorher = server.revision;
    server.revision = 0;
    expect(await b.engine.pull(), isTrue);
    final p = await b.engine.push();
    expect(p.gesendet, greaterThan(0), reason: 'alles erneut hochladen');
    expect(p.konflikte, 0, reason: 'gleicher Inhalt löst sich selbst');
    server.revision = vorher + 10;
    expect(await b.engine.pull(), isFalse);
  });

  test('Vom Server abgelehnte Datensätze werden sichtbar statt still endlos gesendet', () async {
    server.ablehnen = {'kunden:k2'};
    await KundenRepository(a.db).save(Kunde(uuid: 'k2', name: 'Abgelehnt'));
    final p = await a.engine.push();
    expect(p.abgelehnt, 1);
    final k = (await a.konflikte()).single;
    expect((k.art, k.grund), ('abgelehnt', 'Testgrund'));
    expect((await a.engine.push()).gesendet, 0);
    await a.engine.verwerfen(k);
    expect(await KundenRepository(a.db).getByUuid('k2'), isNull);
  });
}

class Arbeitsgeraet {
  Arbeitsgeraet(this.db, this.engine);

  final Database db;
  final SyncEngine engine;

  static Future<Arbeitsgeraet> neu(FakeServer server, String name) async {
    final db = await databaseFactoryMemory.openDatabase('$name.db');
    return Arbeitsgeraet(db, SyncEngine(db, transport: server, revision: SpeicherRevision()));
  }

  Future<List<SyncKonflikt>> konflikte() => SyncKonfliktRepository(db).watchAlle().first;
}

class SpeicherRevision implements RevisionSpeicher {
  final werte = <String, int>{};
  @override
  Future<int?> lesen(String key) async => werte[key];
  @override
  Future<void> schreiben(String key, int wert) async => werte[key] = wert;
}

typedef Zeile = ({Map<String, dynamic> json, int version});

/// Bildet die Server-Regeln aus `packages/elektralog_server/lib/src/sync`
/// nach (Version, Konflikt, Zuordnung, Auswahl-Filter für Geräte).
class FakeServer implements SyncTransport {
  final daten = <String, Map<String, Zeile>>{};
  var revision = 1;
  var audit = 0;
  Set<String> ablehnen = {};

  static const _ort = ['kundeUuid', 'standortUuid', 'raumUuid'];

  @override
  Future<Map<String, dynamic>> push(List<Map<String, dynamic>> batches) async {
    final ergebnisse = [], konflikte = [], abgelehnt = [];
    for (final batch in batches) {
      final typ = batch['type'] as String;
      final tabelle = daten.putIfAbsent(typ, () => {});
      for (final raw in batch['items'] as List) {
        final item = (raw as Map).cast<String, dynamic>();
        final uuid = item['uuid'] as String;
        if (ablehnen.contains('$typ:$uuid')) {
          abgelehnt.add({'type': typ, 'uuid': uuid, 'grund': 'Testgrund'});
          continue;
        }
        final json = {...item}..removeWhere((k, _) => k.startsWith('_'));
        final zeile = tabelle[uuid];
        if (zeile == null) {
          tabelle[uuid] = (json: json, version: 1);
          ergebnisse.add({'type': typ, 'uuid': uuid, 'version': 1});
          continue;
        }
        Map<String, dynamic> konflikt(String art) =>
            {'type': typ, 'uuid': uuid, 'art': art, 'version': zeile.version, 'server': {...zeile.json, 'version': zeile.version}};
        if (item['_basisVersion'] != zeile.version) {
          konflikte.add(konflikt('konflikt'));
          continue;
        }
        if (typ == 'geraete' && _ort.any((f) => zeile.json[f] != json[f])) {
          if (item['_zuordnungBestaetigt'] != true) {
            konflikte.add(konflikt('zuordnung'));
            continue;
          }
          audit++;
        }
        tabelle[uuid] = (json: json, version: zeile.version + 1);
        ergebnisse.add({'type': typ, 'uuid': uuid, 'version': zeile.version + 1});
      }
    }
    revision++;
    return {'syncRevision': revision, 'ergebnisse': ergebnisse, 'konflikte': konflikte, 'abgelehnt': abgelehnt};
  }

  @override
  Future<Map<String, dynamic>> pull(Map<String, String> query) async {
    Set<String> liste(String k) => (query[k] ?? '').split(',').where((s) => s.isNotEmpty).toSet();
    final standorte = liste('geraeteStandorte');
    final raeume = liste('raeume');
    List<Map<String, dynamic>> alle(String typ) => [
          for (final z in (daten[typ] ?? const <String, Zeile>{}).values) {...z.json, 'version': z.version},
        ];
    return {
      'syncRevision': revision,
      for (final typ in ['kunden', 'standorte', 'verteiler', 'raeume']) typ: alle(typ),
      'geraete': [
        for (final g in alle('geraete'))
          if (query.isEmpty || standorte.contains(g['standortUuid']) || raeume.contains(g['raumUuid'])) g,
      ],
    };
  }
}

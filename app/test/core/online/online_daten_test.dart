import 'package:elektralog/core/api/api_service.dart';
import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/kunde.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/online/online_daten.dart';
import 'package:elektralog/core/online/online_repositories.dart';
import 'package:elektralog/core/providers/isar_provider.dart';
import 'package:elektralog/core/providers/module_provider.dart';
import 'package:elektralog/features/geraete/raum_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' hide Finder;
import 'package:shared_preferences/shared_preferences.dart';

/// Web-App online: Ansichten kommen vom Server, nichts lokal; Speichern
/// versioniert, schnelle Folgeänderungen zusammengefasst.
void main() {
  setUpAll(disableSembastCooperator);

  test('Ansicht lädt gefiltert, lädt nach eigenem Speichern neu, sendet Basisversion', () async {
    final server = _FakeServer();
    final d = OnlineDaten(server, abfrageIntervall: const Duration(hours: 1));
    addTearDown(d.dispose);
    final g = Geraet(uuid: 'g1', kundeUuid: 'k', standortUuid: 's', raumUuid: 'r1', bezeichnung: 'Lampe');
    server.daten['geraete'] = {'g1': (json: g.toJson(), version: 3)};

    final werte = <List<String>>[];
    final sub = OnlineGeraeteRepository(d).watchByRaum('r1').listen((l) => werte.add([for (final x in l) x.bezeichnung]));
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(werte, [
      ['Lampe'],
    ]);
    expect(server.anfragen.last, '/daten/geraete?raumUuid=r1');

    await OnlineGeraeteRepository(d).save(g.mitStammdaten(bezeichnung: 'Leuchte', schutzklasse: null));
    await pumpEventQueue();
    expect(server.gesendet.single['_basisVersion'], 3);
    expect(werte.last, ['Leuchte'], reason: 'Ansicht lädt nach dem Speichern neu');
  });

  test('Schnelle Folgeänderungen: nacheinander, nur die neueste wartende wird gesendet', () async {
    final server = _FakeServer()..verzoegerung = const Duration(milliseconds: 20);
    final d = OnlineDaten(server, abfrageIntervall: const Duration(hours: 1));
    addTearDown(d.dispose);
    final k = Kunde(uuid: 'k1', name: 'A');
    await Future.wait([for (final n in ['B', 'C', 'D', 'E']) OnlineKundenRepository(d).save(k.copyWith(name: n))]);
    expect([for (final x in server.gesendet) x['name']], ['B', 'E'], reason: 'C und D entfallen');
    expect(server.daten['kunden']!['k1']!.json['name'], 'E');
    expect(server.gesendet.last['_basisVersion'], 1, reason: 'Basis aus der vorherigen Antwort');
  });

  test('Konflikt: nichts überschrieben, Meldung für den Nutzer', () async {
    final server = _FakeServer();
    final d = OnlineDaten(server, abfrageIntervall: const Duration(hours: 1));
    addTearDown(d.dispose);
    server.daten['kunden'] = {'k1': (json: Kunde(uuid: 'k1', name: 'Server').toJson(), version: 2)};
    final meldungen = <String>[];
    d.meldungen.listen(meldungen.add);
    await OnlineKundenRepository(d).getByUuid('k1');
    server.daten['kunden']!['k1'] = (json: Kunde(uuid: 'k1', name: 'Anderer').toJson(), version: 3);
    await expectLater(
        OnlineKundenRepository(d).save(Kunde(uuid: 'k1', name: 'Ich')), throwsA(isA<OnlineSpeicherFehler>()));
    expect(server.daten['kunden']!['k1']!.json['name'], 'Anderer');
    await pumpEventQueue();
    expect(meldungen.single, contains('inzwischen von jemand anderem geändert'));
  });

  testWidgets('Raumseite zeigt Geräte vom Server, ohne lokale Daten', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final server = _FakeServer();
    server.daten['standorte'] = {'s1': (json: Standort(uuid: 's1', kundeUuid: 'k1', bezeichnung: 'Werk').toJson(), version: 1)};
    server.daten['raeume'] = {'r1': (json: Raum(uuid: 'r1', standortUuid: 's1', bezeichnung: 'Büro').toJson(), version: 1)};
    server.daten['geraete'] = {
      'g1': (json: Geraet(uuid: 'g1', kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'r1', bezeichnung: 'Lampe').toJson(), version: 1),
    };
    final leer = await databaseFactoryMemory.openDatabase('online-leer.db');
    final d = OnlineDaten(server, abfrageIntervall: const Duration(hours: 1));
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dbProvider.overrideWith((ref) async => leer),
        onlineDatenProvider.overrideWithValue(d),
        aktiveModuleProvider.overrideWithValue(const FirmenModule(anlagenpruefung: true, geraetepruefung: true)),
      ],
      child: const MaterialApp(home: RaumDetailScreen(kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'r1')),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('Lampe'), findsOneWidget);
    expect(find.text('Büro'), findsOneWidget);
    expect(server.anfragen, contains('/daten/geraete?raumUuid=r1'));
    await tester.pumpWidget(const SizedBox());
    d.dispose();
  });
}

typedef _Zeile = ({Map<String, dynamic> json, int version});

/// Server mit denselben Versionsregeln wie `SyncEngine` (vereinfacht).
class _FakeServer implements OnlineTransport {
  final daten = <String, Map<String, _Zeile>>{};
  final anfragen = <String>[];
  final gesendet = <Map<String, dynamic>>[];
  Duration verzoegerung = Duration.zero;

  @override
  Future<dynamic> get(String pfad, [Map<String, String>? query]) async {
    anfragen.add(query == null || query.isEmpty ? pfad : '$pfad?${query.entries.map((e) => '${e.key}=${e.value}').join('&')}');
    final teile = pfad.split('/'); // ['', 'daten', typ, (uuid)]
    final zeilen = daten[teile[2]] ?? {};
    Map<String, dynamic> mitVersion(_Zeile z) => {...z.json, 'version': z.version};
    if (teile.length == 4) {
      final z = zeilen[teile[3]];
      if (z == null) throw ApiException(404, 'Nicht gefunden');
      return mitVersion(z);
    }
    return [
      for (final z in zeilen.values)
        if (query == null || query.entries.every((e) => e.value.split(',').contains(z.json[e.key]))) mitVersion(z),
    ];
  }

  @override
  Future<Map<String, dynamic>> sync(List<Map<String, dynamic>> batches) async {
    await Future<void>.delayed(verzoegerung);
    final batch = batches.single;
    final typ = batch['type'] as String;
    final item = (batch['items'] as List).single as Map<String, dynamic>;
    gesendet.add(item);
    final zeilen = daten.putIfAbsent(typ, () => {});
    final uuid = item['uuid'] as String;
    final alt = zeilen[uuid];
    if (alt != null && item['_basisVersion'] != alt.version) {
      return {
        'ergebnisse': [],
        'konflikte': [
          {'type': typ, 'uuid': uuid, 'art': 'konflikt', 'server': alt.json, 'version': alt.version},
        ],
        'abgelehnt': [],
      };
    }
    final version = (alt?.version ?? 0) + 1;
    zeilen[uuid] = (json: {...item}..removeWhere((k, _) => k.startsWith('_')), version: version);
    return {
      'ergebnisse': [
        {'type': typ, 'uuid': uuid, 'version': version},
      ],
      'konflikte': [],
      'abgelehnt': [],
    };
  }

  @override
  Future<void> delete(String pfad) async {}
}

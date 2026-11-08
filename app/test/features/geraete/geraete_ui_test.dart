import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/kunde.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/providers/geraete_provider.dart';
import 'package:elektralog/core/providers/isar_provider.dart';
import 'package:elektralog/core/providers/kunden_provider.dart';
import 'package:elektralog/core/providers/module_provider.dart';
import 'package:elektralog/core/providers/standorte_provider.dart';
import 'package:elektralog/features/geraete/geraet_detail_screen.dart';
import 'package:elektralog/features/geraete/geraete_bereich.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M2: Räume und Geräte über die Oberfläche anlegen, suchen, inaktiv setzen
/// und nur mit Bestätigung umhängen — gegen eine echte In-Memory-Datenbank.
void main() {
  var n = 0;
  late Database db;

  // Sembast pausiert sonst mit echten Timern — in fake_async hängt das.
  setUpAll(disableSembastCooperator);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await databaseFactoryMemory.openDatabase('ui-${n++}.db');
    await KundenRepository(db).save(Kunde(uuid: 'k1', name: 'Kunde Eins'));
    await StandorteRepository(db).save(Standort(uuid: 's1', kundeUuid: 'k1', bezeichnung: 'Werk 1'));
  });

  Future<void> pump(WidgetTester tester, Widget child, {FirmenModule module = const FirmenModule(anlagenpruefung: true, geraetepruefung: true)}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dbProvider.overrideWith((ref) async => db),
        aktiveModuleProvider.overrideWithValue(module),
      ],
      child: MaterialApp(home: child),
    ));
    await tester.pumpAndSettle();
  }

  /// Wartet den entprellten Sync-Timer ab (2 s), damit kein Timer offen bleibt.
  Future<void> syncTimerAbwarten(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<List<Geraet>> geraete() => GeraeteRepository(db).getAlle();

  testWidgets('Raum anlegen, Gerät mit Pflichtprüfung anlegen und suchen', (tester) async {
    await pump(tester, const Scaffold(body: SingleChildScrollView(child: GeraeteBereich(kundeUuid: 'k1', standortUuid: 's1'))));
    expect(find.byKey(const Key('keine-raeume')), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('geraet-neu'))).onPressed, isNull,
        reason: 'ohne Raum kein Gerät');

    await tester.tap(find.byKey(const Key('raum-neu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('raum-speichern')));
    await tester.pumpAndSettle();
    expect(find.text('Bezeichnung ist ein Pflichtfeld'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('raum-bezeichnung')), 'Büro');
    await tester.tap(find.byKey(const Key('raum-speichern')));
    await syncTimerAbwarten(tester);
    expect(find.text('Büro'), findsOneWidget);

    await tester.tap(find.byKey(const Key('geraet-neu')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('geraet-speichern')));
    await tester.pumpAndSettle();
    expect(find.text('Bezeichnung ist ein Pflichtfeld'), findsOneWidget);
    expect(await geraete(), isEmpty);

    await tester.enterText(find.byKey(const Key('geraet-bezeichnung')), 'Wasserkocher');
    await tester.enterText(find.byKey(const Key('geraet-seriennummer')), 'SN-4711');
    await tester.tap(find.text('II'));
    await tester.tap(find.byKey(const Key('geraet-speichern')));
    await syncTimerAbwarten(tester);

    final g = (await geraete()).single;
    expect(g.bezeichnung, 'Wasserkocher');
    expect(g.schutzklasse, 'II');
    expect((g.kundeUuid, g.standortUuid), ('k1', 's1'));
    expect(g.letztePruefungErsatzwert, isTrue);
    expect(find.text('1 Gerät (lokal)'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('geraete-suche')), 'sn-47');
    await tester.pumpAndSettle();
    expect(find.text('1 Treffer'), findsOneWidget);
    expect(find.byKey(Key('geraet-${g.uuid}')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('geraete-suche')), 'gibtsnicht');
    await tester.pumpAndSettle();
    expect(find.text('0 Treffer'), findsOneWidget);
  });

  group('Gerätedetail', () {
    late Geraet geraet;

    setUp(() async {
      await RaeumeRepository(db).save(Raum(uuid: 'r1', standortUuid: 's1', bezeichnung: 'Büro'));
      await RaeumeRepository(db).save(Raum(uuid: 'r2', standortUuid: 's1', bezeichnung: 'Lager'));
      geraet = Geraet.neu(kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'r1', bezeichnung: 'Toaster');
      await GeraeteRepository(db).save(geraet);
    });

    testWidgets('Inaktiv setzen nur mit Grund, Reaktivieren behält Historie', (tester) async {
      await pump(tester, GeraetDetailScreen(geraetUuid: geraet.uuid));
      expect(find.text('Büro'), findsOneWidget);
      expect(find.textContaining('kein Prüfnachweis'), findsOneWidget);

      await tester.tap(find.byKey(const Key('geraet-menue')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inaktiv setzen'));
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(find.byKey(const Key('inaktiv-bestaetigen'))).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('inaktiv-grund')), 'defekt');
      await tester.pump();
      await tester.tap(find.byKey(const Key('inaktiv-bestaetigen')));
      await syncTimerAbwarten(tester);
      expect(find.byKey(const Key('geraet-inaktiv')), findsOneWidget);
      expect((await geraete()).single.inaktivGrund, 'defekt');

      await tester.tap(find.byKey(const Key('geraet-menue')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wieder aktiv setzen'));
      await syncTimerAbwarten(tester);
      final g = (await geraete()).single;
      expect(g.aktiv, isTrue);
      expect(g.statusHistorie, hasLength(2));
      expect(find.text('Statusverlauf'), findsOneWidget);
    });

    testWidgets('Raumwechsel nur nach Bestätigung mit altem und neuem Ort', (tester) async {
      await pump(tester, GeraetDetailScreen(geraetUuid: geraet.uuid));
      Future<void> raumWaehlen() async {
        await tester.tap(find.byKey(const Key('geraet-bearbeiten')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('geraet-raum')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lager').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('geraet-speichern')));
        await tester.pumpAndSettle();
      }

      await raumWaehlen();
      expect(find.byKey(const Key('zuordnung-dialog')), findsOneWidget);
      expect(find.text('Kunde Eins › Werk 1 › Büro'), findsOneWidget);
      expect(find.text('Kunde Eins › Werk 1 › Lager'), findsOneWidget);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect((await geraete()).single.raumUuid, 'r1', reason: 'ohne Bestätigung keine Umhängung');

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await raumWaehlen();
      await tester.tap(find.byKey(const Key('zuordnung-bestaetigen')));
      await syncTimerAbwarten(tester);
      expect((await geraete()).single.raumUuid, 'r2');
    });

    testWidgets('Modul aus: Gerät nicht erreichbar, auch nicht per Direktlink', (tester) async {
      await pump(tester, GeraetDetailScreen(geraetUuid: geraet.uuid), module: FirmenModule.bestand);
      expect(find.byKey(const Key('geraet-modul-aus')), findsOneWidget);
      expect(find.text('Büro'), findsNothing);
    });

    testWidgets('Unbekannte UUID zeigt sicheren Hinweis statt falschem Gerät', (tester) async {
      await pump(tester, const GeraetDetailScreen(geraetUuid: '00000000-0000-4000-8000-000000000000'));
      expect(find.byKey(const Key('geraet-unbekannt')), findsOneWidget);
    });
  });
}

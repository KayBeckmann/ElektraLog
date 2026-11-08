import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/geraete_faelligkeit.dart';
import 'package:elektralog/core/models/kunde.dart';
import 'package:elektralog/core/models/pruefmatrix.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/providers/geraete_provider.dart';
import 'package:elektralog/core/providers/isar_provider.dart';
import 'package:elektralog/core/providers/kunden_provider.dart';
import 'package:elektralog/core/providers/module_provider.dart';
import 'package:elektralog/core/providers/standorte_provider.dart';
import 'package:elektralog/features/geraete/geraete_bereich.dart';
import 'package:elektralog/features/geraete/raum_detail_screen.dart';
import 'package:elektralog/shared/widgets/status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' hide Finder;
import 'package:shared_preferences/shared_preferences.dart';

/// Wie bei den Verteilern: grün bestanden, rot nicht bestanden — und im
/// Raum „bestanden / gesamt“, damit Reparaturbedarf sofort auffällt.
void main() {
  setUpAll(disableSembastCooperator);

  Geraet geraet(String id, {bool aktiv = true}) => Geraet(
        uuid: id,
        kundeUuid: 'k1',
        standortUuid: 's1',
        raumUuid: 'r1',
        bezeichnung: 'Gerät $id',
        schutzklasse: 'II',
        aktiv: aktiv,
        inaktivGrund: aktiv ? null : 'ausgesondert',
      );
  final ok = geraet('ok'), kaputt = geraet('kaputt'), neu = geraet('neu'), aus = geraet('aus', aktiv: false);
  final nachweise = {
    'ok': PruefNachweis(datum: DateTime(2026, 10), bestanden: true),
    'kaputt': PruefNachweis(datum: DateTime(2026, 10), bestanden: false),
    'aus': PruefNachweis(datum: DateTime(2026, 1), bestanden: false),
  };

  test('Bilanz zählt aktive Geräte, Reihenfolge: Reparaturbedarf zuerst', () {
    expect(pruefBilanz([ok, kaputt, neu, aus], nachweise), (bestanden: 1, nichtBestanden: 1, gesamt: 3));
    expect([for (final g in nachPruefErgebnis([ok, aus, neu, kaputt], nachweise)) g.uuid], ['kaputt', 'neu', 'ok', 'aus']);
  });

  group('Oberfläche', () {
    var n = 0;
    late Database db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = await databaseFactoryMemory.openDatabase('badges-${n++}.db');
      await KundenRepository(db).save(Kunde(uuid: 'k1', name: 'Kunde'));
      await StandorteRepository(db).save(Standort(uuid: 's1', kundeUuid: 'k1', bezeichnung: 'Werk'));
      await RaeumeRepository(db).save(Raum(uuid: 'r1', standortUuid: 's1', bezeichnung: 'Büro'));
      for (final g in [ok, kaputt, neu, aus]) {
        await GeraeteRepository(db).save(g);
      }
      for (final (g, bestanden) in [(ok, true), (kaputt, false)]) {
        final e = neuerEntwurf(g, prueferName: 'Kay', heute: DateTime(2026, 11, 8));
        await GeraetePruefungenRepository(db).save(abschliessen(
          e.kopie(
            ergebnis: bestanden ? 'bestanden' : 'nicht_bestanden',
            maengel: bestanden ? null : 'Leitung beschädigt',
            intervallMonate: 12,
            punkte: [
              for (final x in e.punkte)
                x.istMessung
                    ? x.kopie(bewertung: 'na', begruendung: 'Test')
                    : x.kopie(bewertung: bestanden ? 'io' : 'nio', begruendung: 'Befund'),
            ],
          ),
          geraet: g,
          kunde: 'Kunde',
          standort: 'Werk',
          raum: 'Büro',
        ));
      }
    });

    Future<void> pump(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dbProvider.overrideWith((ref) async => db),
          aktiveModuleProvider.overrideWithValue(const FirmenModule(anlagenpruefung: true, geraetepruefung: true)),
        ],
        child: MaterialApp(home: child),
      ));
      await tester.pumpAndSettle();
    }

    PillStatus? pill(WidgetTester tester, String id) {
      final f = find.byKey(Key('pruefstatus-$id'));
      return f.evaluate().isEmpty ? null : tester.widget<StatusPill>(f).status;
    }

    testWidgets('Raum: Badges je Gerät, Bilanz, nicht bestandene zuerst', (tester) async {
      await pump(tester, const RaumDetailScreen(kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'r1'));
      expect(
        [pill(tester, 'ok'), pill(tester, 'kaputt'), pill(tester, 'neu'), pill(tester, 'aus')],
        [PillStatus.passed, PillStatus.failed, PillStatus.offen, null],
      );
      expect(find.text('1 / 3 bestanden'), findsOneWidget);
      expect(find.text('1 nicht bestanden'), findsOneWidget);
      final oben = [for (final id in ['kaputt', 'neu', 'ok', 'aus']) tester.getTopLeft(find.byKey(Key('geraet-$id'))).dy];
      expect(oben, orderedEquals([...oben]..sort()), reason: 'Reparaturbedarf zuerst');
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Raumübersicht im Standort: kleine Zahl bestanden / gesamt', (tester) async {
      await pump(tester, const Scaffold(body: SingleChildScrollView(child: GeraeteBereich(kundeUuid: 'k1', standortUuid: 's1'))));
      expect(find.text('1 / 3 bestanden'), findsOneWidget);
      expect(find.text('1 nicht bestanden'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });
  });
}

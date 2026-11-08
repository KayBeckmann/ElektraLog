import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/kunde.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/providers/geraete_provider.dart';
import 'package:elektralog/core/providers/isar_provider.dart';
import 'package:elektralog/core/providers/kunden_provider.dart';
import 'package:elektralog/core/providers/module_provider.dart';
import 'package:elektralog/core/providers/standorte_provider.dart';
import 'package:elektralog/features/dashboard/dashboard_screen.dart';
import 'package:elektralog/features/dashboard/geraete_termine_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M4: Dashboard mit getrennten Listen, Überfälliges gesondert, inaktive
/// Geräte und abgeschaltete Module ohne Fälligkeit.
void main() {
  setUpAll(disableSembastCooperator);
  var n = 0;
  late Database db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await databaseFactoryMemory.openDatabase('termine-${n++}.db');
    await KundenRepository(db).save(Kunde(uuid: 'k1', name: 'Bäckerei'));
    await StandorteRepository(db).save(Standort(uuid: 's1', kundeUuid: 'k1', bezeichnung: 'Filiale'));
    await RaeumeRepository(db).save(Raum(uuid: 'r1', standortUuid: 's1', bezeichnung: 'Backstube'));
    final repo = GeraeteRepository(db);
    Geraet g(String uuid, String letzte, {bool aktiv = true}) => Geraet(
          uuid: uuid,
          kundeUuid: 'k1',
          standortUuid: 's1',
          raumUuid: 'r1',
          bezeichnung: 'Gerät $uuid',
          pruefintervallMonate: 12,
          letztePruefungDatum: letzte,
          aktiv: aktiv,
          inaktivGrund: aktiv ? null : 'ausgesondert',
        );
    await repo.save(g('ueber', '2025-10-01'));
    await repo.save(g('bald', '2025-12-20'));
    await repo.save(g('spaeter', '2026-10-01'));
    await repo.save(g('inaktiv', '2024-01-01', aktiv: false));
  });

  Future<void> pump(WidgetTester tester, Widget child, FirmenModule module) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: [
        dbProvider.overrideWith((ref) async => db),
        aktiveModuleProvider.overrideWithValue(module),
      ],
      child: MaterialApp(home: child),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Überfällig getrennt, 90-Tage-Liste, nichts Inaktives oder Späteres', (tester) async {
    await pump(tester, Scaffold(body: GeraeteTermineCard(heute: DateTime(2026, 11, 8))), FirmenModule.bestand);
    expect(find.text('Überfällig (1)'), findsOneWidget);
    expect(find.text('Nächste 90 Tage (1)'), findsOneWidget);
    expect(find.text('Bäckerei — Filiale'), findsNWidgets(2));

    await tester.tap(find.text('Datum'));
    await tester.pumpAndSettle();
    expect(find.text('Gerät ueber'), findsOneWidget);
    expect(find.text('Gerät bald'), findsOneWidget);
    expect(find.text('Gerät spaeter'), findsNothing);
    expect(find.text('Gerät inaktiv'), findsNothing);
  });

  testWidgets('Dashboard: zwei Listen bei beiden Modulen, ohne Gerätemodul keine Geräte-Fälligkeit', (tester) async {
    await pump(tester, const DashboardScreen(), const FirmenModule(anlagenpruefung: true, geraetepruefung: true));
    expect(find.text('Anlagenmessungen (90 Tage)'), findsOneWidget);
    expect(find.byKey(const Key('geraete-termine')), findsOneWidget);

    await pump(tester, const DashboardScreen(), FirmenModule.bestand);
    expect(find.text('Anlagenmessungen (90 Tage)'), findsOneWidget);
    expect(find.byKey(const Key('geraete-termine')), findsNothing);

    await pump(tester, const DashboardScreen(), const FirmenModule(anlagenpruefung: false, geraetepruefung: true));
    expect(find.text('Anlagenmessungen (90 Tage)'), findsNothing);
    expect(find.byKey(const Key('geraete-termine')), findsOneWidget);
    expect(await GeraeteRepository(db).getAlle(), hasLength(4), reason: 'Modulwechsel löscht nichts');
  });

  test('Gleicher Bestand liefert unabhängig von Uhrzeit/Zeitzone dieselbe Liste', () {
    final geraete = [
      Geraet(
        uuid: 'x',
        kundeUuid: 'k',
        standortUuid: 's',
        raumUuid: 'r',
        bezeichnung: 'X',
        pruefintervallMonate: 3,
        letztePruefungDatum: '2026-09-01',
      ),
    ];
    List<String> liste(DateTime heute) => [
          for (final z in faelligeGeraete(
            geraete: geraete,
            nachweise: const {},
            kundenNamen: const {},
            standortNamen: const {},
            heute: heute,
          ))
            '${z.geraet.uuid}@${z.termin.faelligAm}',
        ];
    expect(liste(DateTime(2026, 11, 8, 8)), liste(DateTime.utc(2026, 11, 8, 22)));
    expect(liste(DateTime(2026, 11, 8)), ['x@2026-12-01 00:00:00.000Z']);
  });
}

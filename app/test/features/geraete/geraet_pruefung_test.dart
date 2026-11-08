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
import 'package:elektralog/features/geraete/geraet_pruefung_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart' hide Finder;
import 'package:shared_preferences/shared_preferences.dart';

/// M5 Abnahme: Gerät → passende Schutzklasse → Besichtigen/Messen/Erproben
/// → Bewertung → unveränderliches Ereignis; invalides Ergebnis lässt sich
/// nicht als bestanden abschließen; inaktive Geräte bekommen keine Prüfung.
void main() {
  setUpAll(disableSembastCooperator);
  var n = 0;
  late Database db;
  const uuid = 'a1b2c3d4-0000-4000-8000-000000000001';

  setUp(() async {
    SharedPreferences.setMockInitialValues({'einstellungen.pruefer': 'Kay'});
    db = await databaseFactoryMemory.openDatabase('pruefung-${n++}.db');
    await KundenRepository(db).save(Kunde(uuid: 'k1', name: 'Kunde'));
    await StandorteRepository(db).save(Standort(uuid: 's1', kundeUuid: 'k1', bezeichnung: 'Werk'));
    await RaeumeRepository(db).save(Raum(uuid: 'r1', standortUuid: 's1', bezeichnung: 'Büro'));
    await GeraeteRepository(db).save(
      Geraet(uuid: uuid, kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'r1', bezeichnung: 'Lampe', schutzklasse: 'II'),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(initialLocation: '/geraete/$uuid', routes: [
      GoRoute(
        path: '/geraete/:g',
        builder: (_, s) => GeraetDetailScreen(geraetUuid: s.pathParameters['g']!),
        routes: [
          GoRoute(
            path: 'pruefung/:p',
            builder: (_, s) => GeraetPruefungScreen(geraetUuid: s.pathParameters['g']!, pruefungUuid: s.pathParameters['p']!),
          ),
        ],
      ),
    ]);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dbProvider.overrideWith((ref) async => db),
        aktiveModuleProvider.overrideWithValue(const FirmenModule(anlagenpruefung: true, geraetepruefung: true)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> ende(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<void> tippe(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('Vollständige Prüfung Schutzklasse II bis zum unveränderlichen Ereignis', (tester) async {
    await pump(tester);
    await tippe(tester, find.byKey(const Key('pruefung-starten')));
    expect(find.byKey(const Key('pruefung-formular')), findsOneWidget);
    expect(find.textContaining('DGUV Vorschrift 3'), findsWidgets);
    expect(find.byKey(const Key('messung-rpe')), findsNothing, reason: 'SK II ohne Schutzleiter');
    expect(find.byKey(const Key('messung-riso')), findsOneWidget);

    // Abschluss ohne Eingaben zeigt, was fehlt.
    await tippe(tester, find.byKey(const Key('pruefung-abschliessen')));
    expect(find.byKey(const Key('abschluss-fehler')), findsOneWidget);

    for (final id in ['gehaeuse', 'leitung', 'zugentlastung', 'kennzeichnung', 'gebrauch', 'funktion']) {
      final io = find.descendant(of: find.byKey(Key('bewertung-$id')), matching: find.text('i. O.'));
      await tippe(tester, io);
    }
    await tester.enterText(find.byKey(const Key('messwert-riso')), '15,5');
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('mess-ergebnis-riso')), matching: find.text('i. O.')), findsOneWidget);

    // Berührungsstrom über Grenzwert → n. i. O. → „bestanden“ gesperrt.
    await tester.enterText(find.byKey(const Key('messwert-ib')), '0,8');
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const Key('mess-ergebnis-ib')), matching: find.text('n. i. O.')), findsOneWidget);
    expect(find.textContaining('„bestanden“ ist gesperrt'), findsOneWidget);
    await tippe(tester, find.text('Bestanden'));
    var p = (await GeraetePruefungenRepository(db).getAlle()).single;
    expect(p.ergebnis, isNull, reason: 'bestanden nicht wählbar');

    // Messung wiederholt, Wert in Ordnung.
    await tester.enterText(find.byKey(const Key('messwert-ib')), '0,05');
    await tester.pumpAndSettle();
    await tippe(tester, find.text('Bestanden'));
    await tippe(tester, find.byKey(const Key('pruefung-intervall-12')));
    await tippe(tester, find.byKey(const Key('pruefung-abschliessen')));
    await tippe(tester, find.byKey(const Key('abschluss-bestaetigen')));
    await ende(tester);

    expect(find.byKey(const Key('pruefung-abgeschlossen')), findsOneWidget);
    p = (await GeraetePruefungenRepository(db).getAlle()).single;
    expect((p.status, p.ergebnis, p.prueferName, p.schutzklasse), ('abgeschlossen', 'bestanden', 'Kay', 'II'));
    expect(p.punkte.firstWhere((x) => x.id == 'riso').messwert, 15.5);
    expect(p.ortSnapshot!['raum']['bezeichnung'], 'Büro');
    expect((await GeraeteRepository(db).getByUuid(uuid))!.pruefintervallMonate, 12, reason: 'Intervall des Messtechnikers');

    // Unveränderlich, auch am Repository vorbei an der Oberfläche.
    await expectLater(GeraetePruefungenRepository(db).save(p.kopie(ergebnis: 'nicht_bestanden')), throwsStateError);

    // Korrektur = neue Prüfung mit Verweis.
    await tippe(tester, find.byKey(const Key('pruefung-korrektur')));
    await ende(tester);
    final alle = await GeraetePruefungenRepository(db).getAlle();
    expect(alle, hasLength(2));
    expect(alle.where((x) => x.ersetztUuid == p.uuid).single.status, 'entwurf');
  });

  testWidgets('Entwurf bleibt erhalten und lässt sich fortsetzen', (tester) async {
    await pump(tester);
    await tippe(tester, find.byKey(const Key('pruefung-starten')));
    await tester.enterText(find.byKey(const Key('messwert-riso')), '3');
    await tester.pumpAndSettle();
    await ende(tester);

    await pump(tester);
    expect(find.byKey(const Key('pruefung-starten')), findsNothing);
    await tippe(tester, find.byKey(const Key('pruefung-fortsetzen')));
    expect(find.text('3.0'), findsOneWidget);
  });

  testWidgets('Inaktives Gerät: keine neue Prüfung', (tester) async {
    final g = (await GeraeteRepository(db).getByUuid(uuid))!;
    await GeraeteRepository(db).save(g.mitStatus(aktiv: false, grund: 'defekt'));
    await pump(tester);
    expect(find.byKey(const Key('pruefung-starten')), findsNothing);
    expect(find.textContaining('keine neue Prüfung'), findsOneWidget);
    await ende(tester);
  });
}

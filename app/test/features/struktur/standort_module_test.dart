import 'package:elektralog/core/models/kunde.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/providers/geraete_provider.dart';
import 'package:elektralog/core/providers/kunden_provider.dart';
import 'package:elektralog/core/providers/module_provider.dart';
import 'package:elektralog/core/providers/standorte_provider.dart';
import 'package:elektralog/core/providers/sync_auswahl_provider.dart';
import 'package:elektralog/core/providers/verteiler_provider.dart';
import 'package:elektralog/features/struktur/standort_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// M1: Standortansicht je nach aktiven Firmenmodulen — zwei Reiter, direkter
/// Inhalt oder Hinweis; der Standort bleibt in jedem Fall erreichbar.
void main() {
  final kunde = Kunde(uuid: 'k1', name: 'Kunde');
  final standort = Standort(uuid: 's1', kundeUuid: 'k1', bezeichnung: 'Halle 3');

  Future<void> pump(WidgetTester tester, FirmenModule module) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        aktiveModuleProvider.overrideWithValue(module),
        kundenProvider.overrideWith((ref) => Stream.value([kunde])),
        standorteByKundeProvider('k1').overrideWith((ref) => Stream.value([standort])),
        verteilerByStandortProvider('s1').overrideWith((ref) => Stream.value([])),
        standortSyncAktiviertProvider('s1').overrideWith((ref) => Stream.value(true)),
        raeumeByStandortProvider('s1').overrideWith((ref) => Stream.value([])),
        geraeteByStandortProvider('s1').overrideWith((ref) => Stream.value([])),
        geraeteStandortSyncAktiviertProvider('s1').overrideWith((ref) => Stream.value(false)),
      ],
      child: const MaterialApp(home: StandortDetailScreen(kundeUuid: 'k1', standortUuid: 's1')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Halle 3'), findsWidgets, reason: 'Standort immer erreichbar');
  }

  final anlagenInhalt = find.text('Noch keine Verteiler');
  final geraeteInhalt = find.byKey(const Key('geraete-bereich'));
  final keinModul = find.byKey(const Key('kein-modul-hinweis'));
  final reiter = find.byType(TabBar);
  final verteilerFab = find.widgetWithText(FloatingActionButton, 'Verteiler');

  testWidgets('Beide Module: zwei Reiter, Geräte-Reiter zeigt Räume/Geräte', (tester) async {
    await pump(tester, const FirmenModule(anlagenpruefung: true, geraetepruefung: true));
    expect(reiter, findsOneWidget);
    expect(anlagenInhalt, findsOneWidget);
    expect(verteilerFab, findsNothing);

    await tester.tap(find.byKey(const Key('tab-geraete')));
    await tester.pumpAndSettle();
    expect(geraeteInhalt, findsOneWidget);
  });

  testWidgets('Nur Anlagenprüfung: Inhalt direkt, ohne Reiter, wie bisher', (tester) async {
    await pump(tester, FirmenModule.bestand);
    expect(reiter, findsNothing);
    expect(anlagenInhalt, findsOneWidget);
    expect(verteilerFab, findsOneWidget);
    expect(find.byTooltip('Protokoll generieren'), findsOneWidget);
    expect(geraeteInhalt, findsNothing);
  });

  testWidgets('Nur Geräteprüfung: Geräte direkt, keine Verteiler-Aktionen', (tester) async {
    await pump(tester, const FirmenModule(anlagenpruefung: false, geraetepruefung: true));
    expect(reiter, findsNothing);
    expect(geraeteInhalt, findsOneWidget);
    expect(anlagenInhalt, findsNothing);
    expect(verteilerFab, findsNothing);
    expect(find.byTooltip('Protokoll generieren'), findsNothing);
  });

  testWidgets('Kein Modul: Standort erreichbar mit Hinweis', (tester) async {
    await pump(tester, const FirmenModule(anlagenpruefung: false, geraetepruefung: false));
    expect(keinModul, findsOneWidget);
    expect(anlagenInhalt, findsNothing);
    expect(geraeteInhalt, findsNothing);
    expect(verteilerFab, findsNothing);
  });
}

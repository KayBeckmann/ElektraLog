import 'package:elektralog/core/models/kunde.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/providers/kunden_provider.dart';
import 'package:elektralog/core/providers/standorte_provider.dart';
import 'package:elektralog/features/kunden/kunde_formular.dart';
import 'package:elektralog/features/struktur/standort_formular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Roadmap 20./21.11.2026: Ansprechpartner am Kunden, eigener Kontakt je
/// Standort — zwei Standorte desselben Kunden vermischen sich nicht.
void main() {
  test('JSON: neue Felder im Roundtrip, Altdaten ohne Felder bleiben lesbar', () {
    final s = Standort(
      kundeUuid: 'k',
      bezeichnung: 'Werk Nord',
      kontaktPerson: 'Herr Nord',
      kontaktEmail: 'nord@muster.invalid',
      kontaktTelefon: '0401',
    );
    final zurueck = Standort.fromJson(s.toJson());
    expect((zurueck.kontaktPerson, zurueck.kontaktEmail, zurueck.kontaktTelefon),
        ('Herr Nord', 'nord@muster.invalid', '0401'));
    final alt = Standort.fromJson({'uuid': 'u', 'kundeUuid': 'k', 'bezeichnung': 'Alt', 'erstelltAm': '2026-01-01T00:00:00Z'});
    expect((alt.kontaktPerson, alt.kontaktEmail), (null, null));

    final k = Kunde(name: 'Muster', ansprechpartner: 'Frau Zentral');
    expect(Kunde.fromJson(k.toJson()).ansprechpartner, 'Frau Zentral');
    expect(k.copyWith(name: 'Neu').ansprechpartner, 'Frau Zentral');
  });

  group('Formulare', () {
    late Database db;
    var n = 0;
    setUp(() async {
      // Ohne Token läuft der Sync-Timer nach dem Speichern leer aus.
      SharedPreferences.setMockInitialValues({});
      db = await databaseFactoryMemory.openDatabase('kontakte-${n++}.db');
    });

    /// Sync-Entprellung (2 s) nach dem Speichern auslaufen lassen.
    Future<void> syncAuslaufen(WidgetTester tester) => tester.pump(const Duration(seconds: 3));
    tearDown(() => db.close());

    Future<void> zeige(WidgetTester tester, Widget formular) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          standorteRepositoryProvider.overrideWithValue(StandorteRepository(db)),
          kundenRepositoryProvider.overrideWithValue(KundenRepository(db)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => formular,
                ),
                child: const Text('öffnen'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('öffnen'));
      await tester.pumpAndSettle();
    }

    testWidgets('Zwei Standorte desselben Kunden mit eigenen Kontakten; ungültige E-Mail blockiert', (tester) async {
      final repo = StandorteRepository(db);
      for (final (name, person, email) in [
        ('Werk Nord', 'Herr Nord', 'nord@muster.invalid'),
        ('Werk Süd', 'Frau Süd', 'sued@muster.invalid'),
      ]) {
        await zeige(tester, const StandortFormular(kundeUuid: 'kunde-1'));
        await tester.enterText(find.widgetWithText(TextFormField, 'Bezeichnung *'), name);
        await tester.enterText(find.byKey(const Key('standort-kontakt-person')), person);
        await tester.enterText(find.byKey(const Key('standort-kontakt-email')), 'ohne-at');
        await tester.ensureVisible(find.text('Standort anlegen'));
        await tester.tap(find.text('Standort anlegen'));
        await tester.pumpAndSettle();
        expect(find.text('Keine gültige E-Mail-Adresse'), findsOneWidget);

        await tester.enterText(find.byKey(const Key('standort-kontakt-email')), ' $email ');
        await tester.tap(find.text('Standort anlegen'));
        await tester.pumpAndSettle();
        expect(find.byType(StandortFormular), findsNothing);
      }

      final alle = await tester.runAsync(() => repo.getByKunde('kunde-1'));
      final nachName = {for (final s in alle!) s.bezeichnung: s};
      expect((nachName['Werk Nord']!.kontaktPerson, nachName['Werk Nord']!.kontaktEmail), ('Herr Nord', 'nord@muster.invalid'));
      expect((nachName['Werk Süd']!.kontaktPerson, nachName['Werk Süd']!.kontaktEmail), ('Frau Süd', 'sued@muster.invalid'));

      // Bearbeiten: vorbelegt, Leeren entfernt die Angabe.
      await zeige(tester, StandortFormular(kundeUuid: 'kunde-1', existingStandort: nachName['Werk Nord']));
      expect(find.widgetWithText(TextFormField, 'nord@muster.invalid'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('standort-kontakt-email')), '');
      await tester.ensureVisible(find.text('Speichern'));
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      final nord = await tester.runAsync(() => repo.getByUuid(nachName['Werk Nord']!.uuid));
      expect((nord!.kontaktEmail, nord.kontaktPerson), (null, 'Herr Nord'));
      await syncAuslaufen(tester);
    });

    testWidgets('Kunde: Ansprechpartner wird gespeichert', (tester) async {
      await zeige(tester, const KundeFormular());
      await tester.enterText(find.widgetWithText(TextFormField, 'Name *'), 'Muster GmbH');
      await tester.enterText(find.byKey(const Key('kunde-ansprechpartner')), 'Frau Zentral');
      await tester.enterText(find.byKey(const Key('kunde-email')), 'zentrale@muster.invalid');
      await tester.ensureVisible(find.text('Kunde anlegen'));
      await tester.tap(find.text('Kunde anlegen'));
      await tester.pumpAndSettle();
      final kunden = await tester.runAsync(() => KundenRepository(db).getAll());
      expect((kunden!.single.ansprechpartner, kunden.single.kontaktEmail), ('Frau Zentral', 'zentrale@muster.invalid'));
      await syncAuslaufen(tester);
    });
  });
}

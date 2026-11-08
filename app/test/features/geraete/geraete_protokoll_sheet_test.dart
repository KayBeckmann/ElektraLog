import 'dart:typed_data';

import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/geraete_protokoll.dart';
import 'package:elektralog/core/models/kunde.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/models/standort.dart';
import 'package:elektralog/core/providers/geraete_provider.dart';
import 'package:elektralog/core/providers/isar_provider.dart';
import 'package:elektralog/core/providers/kunden_provider.dart';
import 'package:elektralog/core/providers/standorte_provider.dart';
import 'package:elektralog/features/geraete/geraete_protokoll_sheet.dart';
import 'package:elektralog/features/pdf/geraete_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart' hide Finder;
import 'package:shared_preferences/shared_preferences.dart';

/// M6: Filter wählen → Übersicht mit Statusspalte → PDF; strikt getrennt.
void main() {
  setUpAll(disableSembastCooperator);
  var n = 0;
  late Database db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await databaseFactoryMemory.openDatabase('protokoll-${n++}.db');
    await KundenRepository(db).save(Kunde(uuid: 'k1', name: 'Kunde'));
    await StandorteRepository(db).save(Standort(uuid: 's1', kundeUuid: 'k1', bezeichnung: 'Werk'));
    await RaeumeRepository(db).save(Raum(uuid: 'r1', standortUuid: 's1', bezeichnung: 'Büro'));
    final repo = GeraeteRepository(db);
    await repo.save(Geraet(uuid: 'aktiv', kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'r1', bezeichnung: 'Lampe'));
    await repo.save(Geraet(
      uuid: 'inaktiv',
      kundeUuid: 'k1',
      standortUuid: 's1',
      raumUuid: 'r1',
      bezeichnung: 'Heizlüfter',
      aktiv: false,
      inaktivGrund: 'ausgesondert',
    ));
  });

  Future<List<Uint8List>> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ausgaben = <Uint8List>[];
    await tester.pumpWidget(ProviderScope(
      overrides: [dbProvider.overrideWith((ref) async => db)],
      child: MaterialApp(
        home: Scaffold(
          body: GeraeteProtokollSheet(
            umfang: ProtokollUmfang.standort,
            kundeUuid: 'k1',
            standortUuid: 's1',
            ausgabe: (bytes, name) async => ausgaben.add(bytes),
            schriften: PdfSchriften.standard(),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return ausgaben;
  }

  testWidgets('Alle: Übersicht zeigt inaktives Gerät mit Grund, null Prüfblätter', (tester) async {
    final ausgaben = await pump(tester);
    expect(find.byKey(const Key('uebersicht-inaktiv')), findsNothing, reason: 'erst Filter, dann Übersicht');
    await tester.tap(find.byKey(const Key('zur-uebersicht')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('uebersicht-inaktiv')), findsOneWidget);
    expect(find.text('Inaktiv: ausgesondert'), findsOneWidget);
    expect(find.text('nicht geprüft'), findsOneWidget);
    expect(find.text('2 Geräte in der Übersicht, 0 Prüfprotokolle. Inaktive erhalten kein Prüfprotokoll.'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('pdf-erzeugen')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(ausgaben, hasLength(1));
  });

  testWidgets('Nur aktive: kein inaktives Gerät in der Übersicht', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('filter-aktive')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('zur-uebersicht')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('uebersicht-aktiv')), findsOneWidget);
    expect(find.byKey(const Key('uebersicht-inaktiv')), findsNothing);
  });

  testWidgets('Manuell: nur die gewählte Menge', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('filter-manuell')));
    await tester.pumpAndSettle();
    expect(tester.widget<ElevatedButton>(find.byKey(const Key('zur-uebersicht'))).onPressed, isNull);
    await tester.tap(find.byKey(const Key('manuell-inaktiv')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('zur-uebersicht')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('uebersicht-inaktiv')), findsOneWidget);
    expect(find.byKey(const Key('uebersicht-aktiv')), findsNothing);
  });
}

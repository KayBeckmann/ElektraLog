import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/providers/geraete_provider.dart';
import 'package:elektralog/core/providers/isar_provider.dart';
import 'package:elektralog/core/sync/sync_meta.dart';
import 'package:elektralog/features/sync/konflikte_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M3: Konflikte in der Oberfläche feldweise zusammenführen.
void main() {
  setUpAll(disableSembastCooperator);
  var n = 0;
  late Database db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await databaseFactoryMemory.openDatabase('konflikte-${n++}.db');
    await RaeumeRepository(db).save(Raum(uuid: 'rA', standortUuid: 's1', bezeichnung: 'Büro'));
    await RaeumeRepository(db).save(Raum(uuid: 'rB', standortUuid: 's1', bezeichnung: 'Lager'));
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [dbProvider.overrideWith((ref) async => db)],
      child: const MaterialApp(home: KonflikteScreen()),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> konflikt(String art, Geraet lokal, Geraet server) async {
    await GeraeteRepository(db).save(lokal);
    await SyncKonfliktRepository(db).put(SyncKonflikt(
      typ: 'geraete',
      uuid: lokal.uuid,
      art: art,
      lokal: lokal.toJson(),
      server: server.toJson(),
      serverVersion: 4,
      erkanntAm: DateTime.utc(2026, 11, 8),
    ));
  }

  final basis = Geraet(uuid: 'g1', kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'rA', bezeichnung: 'Kocher');

  testWidgets('Ortswechsel: alter und neuer Raum sichtbar, Bestätigung übernimmt den neuen', (tester) async {
    await konflikt('zuordnung', basis.umgehaengt(kundeUuid: 'k1', standortUuid: 's1', raumUuid: 'rB'), basis);
    await pump(tester);
    await tester.tap(find.byKey(const Key('konflikt-g1')));
    await tester.pumpAndSettle();
    expect(find.text('Büro'), findsOneWidget);
    expect(find.text('Lager'), findsOneWidget);
    expect(find.text('Neuen Ort bestätigen'), findsOneWidget);

    await tester.tap(find.byKey(const Key('konflikt-uebernehmen')));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('keine-konflikte')), findsOneWidget);
    expect((await GeraeteRepository(db).getByUuid('g1'))!.raumUuid, 'rB');
    final meta = await SyncMetaRepository(db).get('geraete', 'g1');
    expect((meta!.version, meta.zuordnungBestaetigt), (4, true));
  });

  testWidgets('Feldkonflikt: je Feld wählbar, Serverwert behalten', (tester) async {
    await konflikt(
      'konflikt',
      basis.mitStammdaten(bezeichnung: 'Kocher', seriennummer: 'SN-lokal'),
      basis.mitStammdaten(bezeichnung: 'Wasserkocher'),
    );
    await pump(tester);
    await tester.tap(find.byKey(const Key('konflikt-g1')));
    await tester.pumpAndSettle();
    expect(find.text('SN-lokal'), findsOneWidget);
    expect(find.text('Wasserkocher'), findsOneWidget);

    await tester.tap(find.byKey(const Key('wahl-lokal-seriennummer')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('konflikt-uebernehmen')));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    final g = (await GeraeteRepository(db).getByUuid('g1'))!;
    expect((g.bezeichnung, g.seriennummer), ('Wasserkocher', 'SN-lokal'));
    expect((await SyncMetaRepository(db).get('geraete', 'g1'))!.zuordnungBestaetigt, isFalse);
  });
}

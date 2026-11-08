import 'dart:convert';

import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/raum.dart';
import 'package:elektralog/core/models/verteiler_komponente.dart';
import 'package:elektralog/core/providers/geraete_provider.dart';
import 'package:elektralog/core/providers/isar_provider.dart';
import 'package:elektralog/core/providers/komponenten_provider.dart';
import 'package:elektralog/core/providers/module_provider.dart';
import 'package:elektralog/features/geraete/geraet_scan_screen.dart';
import 'package:elektralog/features/pdf/geraete_pdf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sembast/sembast_memory.dart' hide Finder;
import 'package:shared_preferences/shared_preferences.dart';

/// M7: Etikett trägt die vollständige UUID im Code und lesbar darunter;
/// der Scan öffnet nur exakte Treffer, auch offline, nie ein ähnliches Gerät.
void main() {
  setUpAll(disableSembastCooperator);
  const uuid = '3f2a8c1e-5b7d-4e9a-8c6f-1d2e3f4a5b6c';
  final geraet = Geraet(uuid: uuid, kundeUuid: 'k', standortUuid: 's', raumUuid: 'r', bezeichnung: 'Kocher');

  test('UUID aus Scan: nur vollständige, exakte UUID', () {
    expect(uuidAusScan(uuid), uuid);
    expect(uuidAusScan('  ${uuid.toUpperCase()}\n'), uuid, reason: 'Handscanner schickt evtl. Großbuchstaben/Enter');
    for (final falsch in [uuid.substring(0, 35), 'Kocher', '$uuid x', 'https://x/$uuid', '']) {
      expect(uuidAusScan(falsch), isNull, reason: falsch);
    }
  });

  test('Etikett: vollständige UUID lesbar, ein Etikett je Gerät, A4 mit 24 je Seite', () async {
    final bytes = await etikettenPdf([geraet], schriften: PdfSchriften.standard(), komprimieren: false);
    final text = latin1.decode(bytes);
    expect(text, contains(uuid), reason: 'Klartext-UUID unter dem Code');
    int seiten(String t) => RegExp(r'/Type\s*/Page[^s]').allMatches(t).length;
    expect(seiten(text), 1);

    final viele = [for (var i = 0; i < 30; i++) Geraet(kundeUuid: 'k', standortUuid: 's', raumUuid: 'r', bezeichnung: 'G$i')];
    final bogen = latin1.decode(await etikettenPdf(viele, format: EtikettFormat.a4, schriften: PdfSchriften.standard(), komprimieren: false));
    expect(seiten(bogen), 2);
    final einzeln = latin1.decode(await etikettenPdf(viele, format: EtikettFormat.e62x29, schriften: PdfSchriften.standard(), komprimieren: false));
    expect(seiten(einzeln), 30);
    expect(viele.every((g) => einzeln.contains(g.uuid)), isTrue);

    final nachdruck = await etikettenPdf([geraet], schriften: PdfSchriften.standard(), komprimieren: false);
    expect(latin1.decode(nachdruck), contains(uuid), reason: 'Nachdruck: dieselbe UUID');
  });

  group('Scan', () {
    var n = 0;
    late Database db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = await databaseFactoryMemory.openDatabase('scan-${n++}.db');
      await RaeumeRepository(db).save(Raum(uuid: 'r', standortUuid: 's', bezeichnung: 'Büro'));
      await GeraeteRepository(db).save(geraet);
      await KomponentenRepository(db).save(VerteilerKomponente(
        uuid: '11111111-2222-4333-8444-555555555555',
        verteilerUuid: 'v',
        typ: 'rcd',
        zielbezeichnung: 'FI',
      ));
    });

    Future<void> pump(WidgetTester tester, {FirmenModule module = const FirmenModule(anlagenpruefung: true, geraetepruefung: true)}) async {
      final router = GoRouter(initialLocation: '/scan', routes: [
        GoRoute(path: '/scan', builder: (_, __) => const GeraetScanScreen(kamera: false)),
        GoRoute(path: '/geraete/:g', builder: (_, s) => Text('Gerät ${s.pathParameters['g']}')),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dbProvider.overrideWith((ref) async => db),
          aktiveModuleProvider.overrideWithValue(module),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> scanne(WidgetTester tester, String code) async {
      await tester.enterText(find.byKey(const Key('scan-eingabe')), code);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    }

    testWidgets('Exakter Treffer öffnet das Gerät (offline, lokal)', (tester) async {
      await pump(tester);
      await scanne(tester, uuid.toUpperCase());
      expect(find.text('Gerät $uuid'), findsOneWidget);
    });

    testWidgets('Unbekannte, ungültige und Komponenten-Codes geben sichere Hinweise', (tester) async {
      await pump(tester);
      await scanne(tester, '3f2a8c1e-5b7d-4e9a-8c6f-000000000000');
      expect(find.byKey(const Key('scan-unbekannt')), findsOneWidget);
      expect(find.textContaining('kein ähnliches Gerät'), findsOneWidget);
      await scanne(tester, 'Kocher');
      expect(find.byKey(const Key('scan-ungueltig')), findsOneWidget);
      await scanne(tester, '11111111-2222-4333-8444-555555555555');
      expect(find.byKey(const Key('scan-komponente')), findsOneWidget);
    });

    testWidgets('Modul aus: Scan öffnet nichts', (tester) async {
      await pump(tester, module: FirmenModule.bestand);
      expect(find.byKey(const Key('scan-modul-aus')), findsOneWidget);
      expect(find.byKey(const Key('scan-eingabe')), findsNothing);
    });
  });
}

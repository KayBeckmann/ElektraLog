import 'package:elektralog/core/providers/module_provider.dart';
import 'package:elektralog/features/einstellungen/module_einstellungen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApi implements ModuleApi {
  FirmenModule server = const FirmenModule(anlagenpruefung: true, geraetepruefung: true);
  final gespeichert = <FirmenModule>[];

  @override
  Future<FirmenModule?> laden() async => server;

  @override
  Future<FirmenModule> speichern(FirmenModule module) async {
    gespeichert.add(module);
    return server = module;
  }
}

void main() {
  late _FakeApi api;
  setUp(() => api = _FakeApi());

  Future<void> pump(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    await tester.pumpWidget(ProviderScope(
      overrides: [moduleApiProvider.overrideWithValue(api)],
      child: const MaterialApp(home: Scaffold(body: ModuleEinstellungen())),
    ));
    await tester.pumpAndSettle();
  }

  SwitchListTile schalter(WidgetTester tester, String key) =>
      tester.widget<SwitchListTile>(find.byKey(Key(key)));

  testWidgets('Firmenadmin schaltet sofort über den Server', (tester) async {
    await pump(tester, {'jwt_token': 't', 'ist_admin': true, 'rolle': 'Firmenadmin'});
    expect(schalter(tester, 'modul-geraetepruefung').value, isTrue);

    await tester.tap(find.byKey(const Key('modul-geraetepruefung')));
    await tester.pumpAndSettle();
    expect(api.gespeichert, [const FirmenModule(anlagenpruefung: true, geraetepruefung: false)]);
    expect(schalter(tester, 'modul-geraetepruefung').value, isFalse);
  });

  testWidgets('Projektleiter und Monteur sehen die Module, können sie aber nicht schalten', (tester) async {
    for (final rolle in ['Projektleiter', 'Monteur']) {
      await pump(tester, {'jwt_token': 't', 'ist_admin': false, 'rolle': rolle});
      expect(schalter(tester, 'modul-anlagenpruefung').onChanged, isNull, reason: rolle);
      expect(schalter(tester, 'modul-geraetepruefung').onChanged, isNull, reason: rolle);
      expect(find.text('Nur der Firmenadmin kann Module umschalten.'), findsOneWidget);
    }
    expect(api.gespeichert, isEmpty);
  });

  testWidgets('Solo-Modus: lokal schaltbar, kein Serveraufruf', (tester) async {
    await pump(tester, {});
    expect(schalter(tester, 'modul-geraetepruefung').value, isFalse, reason: 'Bestand');
    await tester.tap(find.byKey(const Key('modul-geraetepruefung')));
    await tester.pumpAndSettle();
    expect(schalter(tester, 'modul-geraetepruefung').value, isTrue);
    expect(api.gespeichert, isEmpty);
  });
}

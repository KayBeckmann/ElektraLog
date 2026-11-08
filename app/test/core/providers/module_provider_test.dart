import 'package:elektralog/core/api/api_service.dart';
import 'package:elektralog/core/providers/module_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApi implements ModuleApi {
  FirmenModule? server;
  bool offline = false;
  bool verboten = false;
  final gespeichert = <FirmenModule>[];

  @override
  Future<FirmenModule?> laden() async {
    if (offline) throw Exception('offline');
    return server;
  }

  @override
  Future<FirmenModule> speichern(FirmenModule module) async {
    if (verboten) throw ApiException(403, 'Nur der Firmenadmin kann Module umschalten');
    gespeichert.add(module);
    return server = module;
  }
}

const _beide = FirmenModule(anlagenpruefung: true, geraetepruefung: true);
const _keins = FirmenModule(anlagenpruefung: false, geraetepruefung: false);

void main() {
  late _FakeApi api;
  ProviderContainer container() {
    final c = ProviderContainer(overrides: [moduleApiProvider.overrideWithValue(api)]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() => api = _FakeApi());

  group('Solo-Modus', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('Bestehende Installation: nur Anlagenprüfung', () async {
      expect(await container().read(moduleProvider.future), FirmenModule.bestand);
    });

    test('Schalter wird lokal gespeichert, ohne Server', () async {
      await container().read(moduleProvider.future);
      final c = container();
      await c.read(moduleProvider.future);
      await c.read(moduleProvider.notifier).setzen(_beide);
      expect(api.gespeichert, isEmpty);
      expect(await container().read(moduleProvider.future), _beide, reason: 'nach Neustart');
    });
  });

  group('Company-Modus', () {
    setUp(() => SharedPreferences.setMockInitialValues({'jwt_token': 't'}));

    test('Stand kommt vom Server und bleibt offline erhalten', () async {
      api.server = _keins;
      expect(await container().read(moduleProvider.future), _keins);

      api.offline = true;
      expect(await container().read(moduleProvider.future), _keins, reason: 'zuletzt bekannter Firmenstand');
    });

    test('Firmenstand überschreibt die Solo-Einstellung nicht', () async {
      SharedPreferences.setMockInitialValues({'module.solo.geraetepruefung': true});
      final solo = container();
      expect((await solo.read(moduleProvider.future)).geraetepruefung, isTrue);

      SharedPreferences.setMockInitialValues({
        'module.solo.geraetepruefung': true,
        'jwt_token': 't',
      });
      api.server = _keins;
      expect(await container().read(moduleProvider.future), _keins);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('module.solo.geraetepruefung'), isTrue);
    });

    test('Umschalten geht über den Server; Ablehnung lässt den Stand unverändert', () async {
      api.server = FirmenModule.bestand;
      final c = container();
      await c.read(moduleProvider.future);
      await c.read(moduleProvider.notifier).setzen(_beide);
      expect(api.gespeichert, [_beide]);
      expect(c.read(aktiveModuleProvider), _beide);

      api.verboten = true;
      await expectLater(c.read(moduleProvider.notifier).setzen(_keins), throwsA(isA<ApiException>()));
      expect(c.read(aktiveModuleProvider), _beide);
    });
  });
}

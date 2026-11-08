import 'package:elektralog/core/providers/app_mode_provider.dart';
import 'package:elektralog/core/providers/isar_provider.dart';
import 'package:elektralog/core/sync/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Angemeldet: sofort alles hochladen (Login bzw. App-Start), nicht erst
/// bei der nächsten Änderung.
void main() {
  test('Anmeldung löst sofort einen Sync-Durchgang aus, Abmeldung stoppt', () async {
    SharedPreferences.setMockInitialValues({});
    final db = await databaseFactoryMemory.openDatabase('auto-sync.db');
    var laeufe = 0;
    final c = ProviderContainer(overrides: [
      dbProvider.overrideWith((ref) async => db),
      syncLaufProvider.overrideWithValue((_) async {
        laeufe++;
        return SyncResult.success;
      }),
    ]);
    addTearDown(c.dispose);
    final sub = c.listen(autoSyncProvider, (_, __) {});
    addTearDown(sub.close);
    await c.read(dbProvider.future);
    await c.read(appModusProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(laeufe, 0, reason: 'Solo-Modus synchronisiert nicht');

    await c.read(appModusProvider.notifier).setCompany('token', 'b1', 'f1', 'Kay');
    await Future<void>.delayed(Duration.zero);
    expect(laeufe, 1);

    await c.read(appModusProvider.notifier).logout();
    await Future<void>.delayed(Duration.zero);
    expect(laeufe, 1);
  });

  test('App-Start angemeldet: sofort ein Durchgang', () async {
    SharedPreferences.setMockInitialValues({'jwt_token': 't'});
    final db = await databaseFactoryMemory.openDatabase('auto-sync-2.db');
    var laeufe = 0;
    final c = ProviderContainer(overrides: [
      dbProvider.overrideWith((ref) async => db),
      syncLaufProvider.overrideWithValue((_) async {
        laeufe++;
        return SyncResult.success;
      }),
    ]);
    addTearDown(c.dispose);
    final sub = c.listen(autoSyncProvider, (_, __) {});
    addTearDown(sub.close);
    await c.read(dbProvider.future);
    await c.read(appModusProvider.future);
    await Future<void>.delayed(Duration.zero);
    expect(laeufe, 1);
  });
}

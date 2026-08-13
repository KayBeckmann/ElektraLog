import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_service.dart';
import 'core/router.dart';
import 'core/providers/einstellungen_provider.dart';
import 'core/providers/app_mode_provider.dart';
import 'core/providers/isar_provider.dart';
import 'core/sync/sync_service.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Einstellungen vor dem ersten Frame laden → ApiService.setServerUrl() gesetzt
  // bevor der erste API-Call (z.B. Login) passiert.
  final container = ProviderContainer();
  await container.read(einstellungenProvider.future);

  // Zentraler Hook: Jeder authentifizierte API-Call, der mit 401 antwortet
  // (z.B. abgelaufener Token nach längerer Abwesenheit), löst hier den
  // automatischen Logout aus und macht das für den Nutzer sichtbar — statt
  // dass Requests still fehlschlagen (siehe ApiService._checkSession).
  ApiService.onSessionExpired = () {
    container.read(appModusProvider.notifier).logout();
    container.read(sessionExpiredProvider.notifier).state = true;
  };

  // Im Company-Modus beim Start synchronisieren (Push + Pull).
  // Wenn keine Verbindung besteht, wird die Synchronisation still abgebrochen.
  final modus = container.read(appModusProvider).valueOrNull;
  if (modus == AppModus.company) {
    container.read(dbProvider.future).then((db) async {
      await SyncService.autoSync(db);
    }).catchError((e) {
      debugPrint('Startup-Sync fehlgeschlagen: $e');
    });
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ElektraLogApp(),
    ),
  );
}

class ElektraLogApp extends ConsumerWidget {
  const ElektraLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ElektraLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

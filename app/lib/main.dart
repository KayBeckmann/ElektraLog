import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // Im Company-Modus alle Rohdaten beim Start vom Backend holen
  final modus = container.read(appModusProvider).valueOrNull;
  if (modus == AppModus.company) {
    container.read(dbProvider.future).then((db) {
      SyncService.pullAll(db);
      // Auto-Pull alle 60 Sekunden damit mehrere Nutzer sich gegenseitig sehen
      Timer.periodic(const Duration(seconds: 60), (_) {
        SyncService.pullAll(db);
      });
    }).catchError((e) {
      debugPrint('Startup-Pull fehlgeschlagen: $e');
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

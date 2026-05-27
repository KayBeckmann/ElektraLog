import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/providers/einstellungen_provider.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Einstellungen vor dem ersten Frame laden → ApiService.setServerUrl() gesetzt
  // bevor der erste API-Call (z.B. Login) passiert.
  final container = ProviderContainer();
  await container.read(einstellungenProvider.future);

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

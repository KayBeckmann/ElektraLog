import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/kunden/kunden_screen.dart';
import '../features/struktur/struktur_screen.dart';
import '../features/historie/historie_screen.dart';
import '../features/signatur/signatur_screen.dart';
import '../shared/widgets/app_scaffold.dart';

part 'router.g.dart';

/// Route path constants
abstract final class AppRoutes {
  static const String dashboard = '/';
  static const String kunden = '/kunden';
  static const String struktur = '/struktur';
  static const String historie = '/historie';
  static const String signatur = '/signatur';
}

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: false,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.kunden,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: KundenScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.struktur,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: StrukturScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.historie,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistorieScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.signatur,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SignaturScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

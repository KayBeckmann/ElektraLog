import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/faelligkeit/faelligkeit_screen.dart';
import '../features/kunden/kunden_screen.dart';
import '../features/sichtpruefung/sichtpruefung_screen.dart';
import '../features/kunden/kunden_detail_screen.dart';
import '../features/struktur/struktur_screen.dart';
import '../features/struktur/standort_detail_screen.dart';
import '../features/struktur/verteiler_detail_screen.dart';
import '../features/historie/historie_screen.dart';
import '../features/signatur/signatur_screen.dart';
import '../features/auth/auth_screen.dart';
import '../shared/widgets/app_scaffold.dart';

part 'router.g.dart';

/// Route path constants
abstract final class AppRoutes {
  static const String dashboard = '/';
  static const String kunden = '/kunden';
  static const String kundeDetail = '/kunden/:kundeUuid';
  static const String standortDetail =
      '/kunden/:kundeUuid/standort/:standortUuid';
  static const String verteilerDetail =
      '/kunden/:kundeUuid/standort/:standortUuid/verteiler/:verteilerUuid';
  static const String struktur = '/struktur';
  static const String historie = '/historie';
  static const String signatur = '/signatur';
  static const String faelligkeit = '/faelligkeit';
  static const String sichtpruefung =
      '/kunden/:kundeUuid/standort/:standortUuid/verteiler/:verteilerUuid/sichtpruefung';
  static const String auth = '/auth';
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
            routes: [
              GoRoute(
                path: ':kundeUuid',
                pageBuilder: (context, state) {
                  final uuid = state.pathParameters['kundeUuid']!;
                  return NoTransitionPage(
                    child: KundenDetailScreen(kundeUuid: uuid),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'standort/:standortUuid',
                    pageBuilder: (context, state) {
                      final kundeUuid =
                          state.pathParameters['kundeUuid']!;
                      final standortUuid =
                          state.pathParameters['standortUuid']!;
                      return NoTransitionPage(
                        child: StandortDetailScreen(
                          kundeUuid: kundeUuid,
                          standortUuid: standortUuid,
                        ),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'verteiler/:verteilerUuid',
                        pageBuilder: (context, state) {
                          final kundeUuid =
                              state.pathParameters['kundeUuid']!;
                          final standortUuid =
                              state.pathParameters['standortUuid']!;
                          final verteilerUuid =
                              state.pathParameters['verteilerUuid']!;
                          return NoTransitionPage(
                            child: VerteilerDetailScreen(
                              kundeUuid: kundeUuid,
                              standortUuid: standortUuid,
                              verteilerUuid: verteilerUuid,
                            ),
                          );
                        },
                        routes: [
                          GoRoute(
                            path: 'sichtpruefung',
                            pageBuilder: (context, state) {
                              final verteilerUuid =
                                  state.pathParameters['verteilerUuid']!;
                              final bezeichnung = state.uri
                                  .queryParameters['bezeichnung'] ??
                                  'Verteiler';
                              return MaterialPage(
                                child: SichtpruefungScreen(
                                  verteilerUuid: verteilerUuid,
                                  verteilerBezeichnung: bezeichnung,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
          GoRoute(
            path: AppRoutes.faelligkeit,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FaelligkeitScreen(),
            ),
          ),
        ],
      ),
      // Auth screen is outside the shell (no nav drawer)
      GoRoute(
        path: AppRoutes.auth,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AuthScreen(),
        ),
      ),
    ],
  );
}

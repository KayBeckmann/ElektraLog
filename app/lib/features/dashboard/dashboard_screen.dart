import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/kunden_provider.dart';
import '../../core/providers/messungen_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';

// ── Mock appointment data ─────────────────────────────────────────────────────

class _Termin {
  const _Termin({
    required this.zeit,
    required this.firma,
    required this.adresse,
    required this.status,
  });

  final String zeit;
  final String firma;
  final String adresse;
  final _TerminStatus status;
}

enum _TerminStatus { offen, inBearbeitung, abgeschlossen }

const _mockTermine = [
  _Termin(
    zeit: '08:00',
    firma: 'Muster GmbH',
    adresse: 'Musterstraße 1, 12345 Berlin',
    status: _TerminStatus.abgeschlossen,
  ),
  _Termin(
    zeit: '10:30',
    firma: 'Beispiel AG',
    adresse: 'Beispielweg 42, 54321 Hamburg',
    status: _TerminStatus.inBearbeitung,
  ),
  _Termin(
    zeit: '14:00',
    firma: 'Test Elektro KG',
    adresse: 'Teststraße 7, 80333 München',
    status: _TerminStatus.offen,
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kundenAsync = ref.watch(kundenProvider);
    final messungenAsync = ref.watch(alleMessungenProvider);

    final today = DateTime.now();
    final dateStr =
        '${today.day.toString().padLeft(2, '0')}.${today.month.toString().padLeft(2, '0')}.${today.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ─────────────────────────────────────────────────
            _PageHeader(dateStr: dateStr),
            const SizedBox(height: 24),

            // ── Bento Grid KPI ───────────────────────────────────────────────
            LayoutBuilder(
              builder: (ctx, constraints) {
                final isDesktop = constraints.maxWidth >= 600;
                if (isDesktop) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _KpiGeraeteCard(
                            messungenAsync: messungenAsync,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _KpiLaufendePruefungCard(
                            kundenAsync: kundenAsync,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    _KpiGeraeteCard(messungenAsync: messungenAsync),
                    const SizedBox(height: 16),
                    _KpiLaufendePruefungCard(kundenAsync: kundenAsync),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Fälligkeiten Banner ───────────────────────────────────────────
            _FaelligkeitenBanner(messungenAsync: messungenAsync),
            const SizedBox(height: 16),

            // ── Termine ──────────────────────────────────────────────────────
            _TermineCard(),
          ],
        ),
      ),
    );
  }
}

// ── Page Header ───────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.dateStr});

  final String dateStr;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DASHBOARD',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.08 * 12,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Übersicht',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Text(
            dateStr,
            style: AppTheme.dataMono(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ── KPI — Geräte Geprüft ──────────────────────────────────────────────────────

class _KpiGeraeteCard extends StatelessWidget {
  const _KpiGeraeteCard({required this.messungenAsync});

  final AsyncValue<dynamic> messungenAsync;

  @override
  Widget build(BuildContext context) {
    final int total = messungenAsync.when(
      data: (list) => (list as List).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final int bestanden = messungenAsync.when(
      data: (list) =>
          (list as List).where((m) => m.ergebnis == 'bestanden').length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final double progress = total == 0 ? 0 : bestanden / total;

    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GERÄTE GEPRÜFT (HEUTE)',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.06 * 12,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$bestanden / $total',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.primary,
                  fontSize: 36,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Messungen abgeschlossen',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI — Laufende Prüfung ────────────────────────────────────────────────────

class _KpiLaufendePruefungCard extends StatelessWidget {
  const _KpiLaufendePruefungCard({required this.kundenAsync});

  final AsyncValue<dynamic> kundenAsync;

  @override
  Widget build(BuildContext context) {
    final int kundenAnzahl = kundenAsync.when(
      data: (list) => (list as List).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return _BentoCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Laufende Prüfung',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                    letterSpacing: 0.05 * 11,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine aktive Prüfung',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '$kundenAnzahl Kunden erfasst',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Termine ───────────────────────────────────────────────────────────────────

class _TermineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Anstehende Termine',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_mockTermine.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSecondaryContainer,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 4),
          ..._mockTermine.map(
            (t) => _TerminItem(termin: t),
          ),
        ],
      ),
    );
  }
}

class _TerminItem extends StatelessWidget {
  const _TerminItem({required this.termin});

  final _Termin termin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zeit
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Text(
              termin.zeit,
              style: AppTheme.dataMono(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  termin.firma,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  termin.adresse,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status Pill
          _StatusPill(status: termin.status),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final _TerminStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;
    String label;

    switch (status) {
      case _TerminStatus.abgeschlossen:
        bg = AppColors.successContainer;
        fg = AppColors.success;
        icon = Icons.check_circle_outline;
        label = 'Fertig';
      case _TerminStatus.inBearbeitung:
        bg = AppColors.secondaryContainer;
        fg = AppColors.secondary;
        icon = Icons.pending_outlined;
        label = 'Aktiv';
      case _TerminStatus.offen:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.onSurfaceVariant;
        icon = Icons.schedule_outlined;
        label = 'Offen';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fälligkeiten Banner ───────────────────────────────────────────────────────

class _FaelligkeitenBanner extends StatelessWidget {
  const _FaelligkeitenBanner({required this.messungenAsync});

  final AsyncValue<dynamic> messungenAsync;

  @override
  Widget build(BuildContext context) {
    final int ueberfaellig = messungenAsync.when(
      data: (list) {
        final now = DateTime.now();
        return (list as List)
            .where((m) {
              final datum = m.naechstePruefungDatum as DateTime?;
              return datum != null && datum.isBefore(now);
            })
            .length;
      },
      loading: () => 0,
      error: (_, __) => 0,
    );
    final int dieseWoche = messungenAsync.when(
      data: (list) {
        final now = DateTime.now();
        final wochenende = now.add(const Duration(days: 7));
        return (list as List)
            .where((m) {
              final datum = m.naechstePruefungDatum as DateTime?;
              return datum != null &&
                  !datum.isBefore(now) &&
                  datum.isBefore(wochenende);
            })
            .length;
      },
      loading: () => 0,
      error: (_, __) => 0,
    );

    final Color bgColor = ueberfaellig > 0
        ? AppColors.errorContainer
        : dieseWoche > 0
            ? AppColors.warningContainer
            : AppColors.successContainer;
    final Color borderColor = ueberfaellig > 0
        ? AppColors.error
        : dieseWoche > 0
            ? AppColors.warning
            : AppColors.success;
    final Color textColor = ueberfaellig > 0
        ? AppColors.onErrorContainer
        : dieseWoche > 0
            ? AppColors.onWarningContainer
            : AppColors.onSuccessContainer;

    String message;
    IconData icon;
    if (ueberfaellig > 0) {
      message = '$ueberfaellig überfällig${dieseWoche > 0 ? ' · $dieseWoche diese Woche' : ''}';
      icon = Icons.warning_amber_rounded;
    } else if (dieseWoche > 0) {
      message = '$dieseWoche Prüftermine diese Woche';
      icon = Icons.schedule;
    } else {
      message = 'Alle Prüftermine im grünen Bereich';
      icon = Icons.check_circle_outline;
    }

    return GestureDetector(
      onTap: () => context.go('/faelligkeit'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: textColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fälligkeiten',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: textColor),
          ],
        ),
      ),
    );
  }
}

// ── Shared Card ───────────────────────────────────────────────────────────────

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.child,
    this.highlighted = false,
  });

  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.surface : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted ? AppColors.primary : AppColors.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: child,
    );
  }
}

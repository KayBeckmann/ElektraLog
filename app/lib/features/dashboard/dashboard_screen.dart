import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/kunden_provider.dart';
import '../../core/providers/messungen_provider.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/pruefprotokoll_provider.dart';
import '../../core/providers/verteiler_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../core/models/pruefprotokoll.dart';
import '../../core/models/verteiler.dart';
import '../../core/models/standort.dart';
import '../../core/models/kunde.dart';
import '../../core/models/messung.dart';
import '../../core/router.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';

// ── KPI — Laufende Prüfung ────────────────────────────────────────────────────

class _KpiLaufendePruefungCard extends ConsumerWidget {
  const _KpiLaufendePruefungCard({required this.kundenAsync});

  final AsyncValue<dynamic> kundenAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int kundenAnzahl = kundenAsync.when(
      data: (list) => (list as List).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final messungenAsync = ref.watch(alleMessungenProvider);
    final protokolleAsync = ref.watch(allePruefprotokolleProvider);

    final int activeMessungenCount = messungenAsync.when(
      data: (list) {
        final messungen = list;
        final protokolle = protokolleAsync.valueOrNull ?? [];
        final gesperrteUuids = <String>{};
        for (final p in protokolle) {
          final raw = p.messdatenSnapshot;
          if (raw == null || raw.isEmpty) continue;
          try {
            final snapshot = jsonDecode(raw) as Map<String, dynamic>;
            final komponenten = snapshot['komponenten'] as List<dynamic>? ?? [];
            for (final k in komponenten) {
              final snapsMessungen = (k as Map<String, dynamic>)['messungen']
                      as List<dynamic>? ??
                  [];
              for (final m in snapsMessungen) {
                final uuid = (m as Map<String, dynamic>)['uuid'] as String?;
                if (uuid != null) gesperrteUuids.add(uuid);
              }
            }
          } catch (_) {}
        }
        return messungen.where((m) => !gesperrteUuids.contains(m.uuid)).length;
      },
      loading: () => 0,
      error: (_, __) => 0,
    );

    final bool hatAktivePruefung = activeMessungenCount > 0;

    return _BentoCard(
      highlighted: hatAktivePruefung,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hatAktivePruefung ? AppColors.primary : AppColors.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hatAktivePruefung ? 'Prüfung läuft' : 'Keine aktive Prüfung',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: hatAktivePruefung ? AppColors.onPrimary : AppColors.surface,
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
            hatAktivePruefung
                ? '$activeMessungenCount Messung(en) ohne Protokoll'
                : 'Bereit für neue Prüfungen',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: hatAktivePruefung ? AppColors.primary : AppColors.onSurfaceVariant,
                  fontWeight: hatAktivePruefung ? FontWeight.w600 : null,
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

class _TermineCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verteilerAsync = ref.watch(alleVerteilerProvider);
    final protokolleAsync = ref.watch(allePruefprotokolleProvider);
    final standorteAsync = ref.watch(alleStandorteProvider);
    final kundenAsync = ref.watch(kundenProvider);

    final dueVerteilers = <({
      Verteiler verteiler,
      DateTime naechste,
      String kundenName,
      String standortName,
      String kundeUuid,
      bool istUeberfaellig
    })>[];

    bool isLoading = verteilerAsync.isLoading ||
        protokolleAsync.isLoading ||
        standorteAsync.isLoading ||
        kundenAsync.isLoading;

    if (!isLoading &&
        verteilerAsync.hasValue &&
        protokolleAsync.hasValue &&
        standorteAsync.hasValue &&
        kundenAsync.hasValue) {
      final verteilers = verteilerAsync.value!;
      final protokolle = protokolleAsync.value!;
      final standorte = standorteAsync.value!;
      final kunden = kundenAsync.value!;

      final latestProtMap = <String, Pruefprotokoll>{};
      for (final p in protokolle) {
        final existing = latestProtMap[p.verteilerUuid];
        if (existing == null || p.protokollDatum.isAfter(existing.protokollDatum)) {
          latestProtMap[p.verteilerUuid] = p;
        }
      }

      final now = DateTime.now();
      final threshold = now.add(const Duration(days: 90));

      for (final v in verteilers) {
        final letztes = latestProtMap[v.uuid];
        if (letztes == null) continue;

        final naechste = DateTime(
          letztes.protokollDatum.year + v.pruefintervallJahre,
          letztes.protokollDatum.month,
          letztes.protokollDatum.day,
        );

        if (naechste.isBefore(threshold)) {
          final st = standorte.firstWhere((s) => s.uuid == v.standortUuid,
              orElse: () => Standort(kundeUuid: '', bezeichnung: 'Unbekannt'));
          final kd = kunden.firstWhere((k) => k.uuid == st.kundeUuid,
              orElse: () => Kunde(name: 'Unbekannt'));

          dueVerteilers.add((
            verteiler: v,
            naechste: naechste,
            kundenName: kd.name,
            standortName: st.bezeichnung,
            kundeUuid: st.kundeUuid,
            istUeberfaellig: naechste.isBefore(now),
          ));
        }
      }
      dueVerteilers.sort((a, b) => a.naechste.compareTo(b.naechste));
    }

    return _BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Anstehende Termine (90 Tage)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              if (!isLoading)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: dueVerteilers.isNotEmpty
                        ? (dueVerteilers.any((x) => x.istUeberfaellig)
                            ? AppColors.errorContainer
                            : AppColors.secondaryContainer)
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${dueVerteilers.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: dueVerteilers.isNotEmpty
                              ? (dueVerteilers.any((x) => x.istUeberfaellig)
                                  ? AppColors.error
                                  : AppColors.onSecondaryContainer)
                              : AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 4),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (dueVerteilers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Keine anstehenden Termine in den nächsten 90 Tagen',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else
            ...dueVerteilers.map(
              (t) => _TerminItem(
                titel: '${t.kundenName} — ${t.verteiler.bezeichnung}',
                subtitel: t.standortName,
                datum: '${t.naechste.day.toString().padLeft(2, '0')}.${t.naechste.month.toString().padLeft(2, '0')}.${t.naechste.year}',
                istUeberfaellig: t.istUeberfaellig,
                onTap: () {
                  context.go('${AppRoutes.kunden}/${t.kundeUuid}/standort/${t.verteiler.standortUuid}/verteiler/${t.verteiler.uuid}');
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TerminItem extends StatelessWidget {
  const _TerminItem({
    required this.titel,
    required this.subtitel,
    required this.datum,
    required this.istUeberfaellig,
    required this.onTap,
  });

  final String titel;
  final String subtitel;
  final String datum;
  final bool istUeberfaellig;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: istUeberfaellig ? AppColors.errorContainer : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: istUeberfaellig ? AppColors.error : AppColors.outlineVariant,
                ),
              ),
              child: Text(
                datum,
                style: AppTheme.dataMono(
                  fontSize: 11,
                  color: istUeberfaellig ? AppColors.error : AppColors.onSurfaceVariant,
                  fontWeight: istUeberfaellig ? FontWeight.bold : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _StatusPill(istUeberfaellig: istUeberfaellig),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.istUeberfaellig});

  final bool istUeberfaellig;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: istUeberfaellig ? AppColors.errorContainer : AppColors.warningContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            istUeberfaellig ? Icons.error_outline : Icons.schedule_outlined,
            size: 12,
            color: istUeberfaellig ? AppColors.error : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            istUeberfaellig ? 'Überfällig' : 'Fällig',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: istUeberfaellig ? AppColors.error : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Statistik Section ─────────────────────────────────────────────────────────

class _StatistikSection extends StatelessWidget {
  const _StatistikSection({
    required this.messungenAsync,
    required this.kundenAsync,
  });

  final AsyncValue<dynamic> messungenAsync;
  final AsyncValue<dynamic> kundenAsync;

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
    final int fehler = messungenAsync.when(
      data: (list) =>
          (list as List).where((m) => m.ergebnis == 'nicht_bestanden').length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final int kundenCount = kundenAsync.when(
      data: (list) => (list as List).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final int quotePercent = total == 0 ? 0 : (bestanden * 100 ~/ total);
    final int fehlerPercent = total == 0 ? 0 : (fehler * 100 ~/ total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATISTIKEN',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 0.08 * 12,
              ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatCard(
                label: 'Prüfquote',
                value: '$quotePercent%',
                subtitle: '$bestanden / $total Messungen',
                icon: Icons.fact_check_outlined,
                color: quotePercent >= 80
                    ? AppColors.success
                    : AppColors.warning,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Fehlerrate',
                value: '$fehlerPercent%',
                subtitle: '$fehler nicht bestanden',
                icon: Icons.error_outline,
                color: fehlerPercent > 10
                    ? AppColors.error
                    : AppColors.success,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Kunden',
                value: '$kundenCount',
                subtitle: 'aktiv',
                icon: Icons.business_center_outlined,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
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

// ── Protokoll-Karte (Company-Modus) ───────────────────────────────────────────

class _ProtokollCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(AppRoutes.protokolle),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.cloud_done_outlined,
                  color: AppColors.onSecondaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hochgeladene Protokolle',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      'Alle Prüfprotokolle im Backend anzeigen',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

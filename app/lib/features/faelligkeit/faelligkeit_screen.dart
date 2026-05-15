import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/messung.dart';
import '../../core/providers/messungen_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';

// ── Filter Enum ───────────────────────────────────────────────────────────────

enum FaelligkeitFilter {
  alle,
  dieseWoche,
  dieserMonat,
  naechste90Tage,
  ueberfaellig,
}

extension FaelligkeitFilterLabel on FaelligkeitFilter {
  String get label {
    switch (this) {
      case FaelligkeitFilter.alle:
        return 'Alle';
      case FaelligkeitFilter.dieseWoche:
        return 'Diese Woche';
      case FaelligkeitFilter.dieserMonat:
        return 'Dieser Monat';
      case FaelligkeitFilter.naechste90Tage:
        return 'Nächste 90 Tage';
      case FaelligkeitFilter.ueberfaellig:
        return 'Überfällig';
    }
  }
}

// ── Status Helper ─────────────────────────────────────────────────────────────

enum FaelligkeitStatus { ueberfaellig, dieseWoche, ok, keinDatum }

FaelligkeitStatus _statusFor(DateTime? datum) {
  if (datum == null) return FaelligkeitStatus.keinDatum;
  final now = DateTime.now();
  final diff = datum.difference(now).inDays;
  if (diff < 0) return FaelligkeitStatus.ueberfaellig;
  if (diff <= 7) return FaelligkeitStatus.dieseWoche;
  return FaelligkeitStatus.ok;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class FaelligkeitScreen extends ConsumerStatefulWidget {
  const FaelligkeitScreen({super.key});

  @override
  ConsumerState<FaelligkeitScreen> createState() => _FaelligkeitScreenState();
}

class _FaelligkeitScreenState extends ConsumerState<FaelligkeitScreen> {
  FaelligkeitFilter _filter = FaelligkeitFilter.alle;

  @override
  Widget build(BuildContext context) {
    final messungenAsync = ref.watch(alleMessungenProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FÄLLIGKEITEN',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.08 * 12,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prüftermine',
                      style:
                          Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: AppColors.primary,
                              ),
                    ),
                  ],
                ),
                const Spacer(),
                // Count badge
                messungenAsync.when(
                  data: (list) {
                    final ueberfaellig = list
                        .where((m) =>
                            _statusFor(m.naechstePruefungDatum) ==
                            FaelligkeitStatus.ueberfaellig)
                        .length;
                    if (ueberfaellig == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        '$ueberfaellig überfällig',
                        style: AppTheme.dataMono(
                          fontSize: 12,
                          color: AppColors.onErrorContainer,
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Filter Chips ─────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: FaelligkeitFilter.values.map((f) {
                  final selected = f == _filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f.label),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      backgroundColor: AppColors.surfaceContainerLow,
                      selectedColor: AppColors.secondaryContainer,
                      checkmarkColor: AppColors.primary,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : AppColors.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── List ─────────────────────────────────────────────────────
            messungenAsync.when(
              data: (list) => _buildList(list),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Fehler: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Messung> alle) {
    // Only messungen with naechstePruefungDatum
    final mitDatum = alle
        .where((m) => m.naechstePruefungDatum != null)
        .toList()
      ..sort((a, b) =>
          a.naechstePruefungDatum!.compareTo(b.naechstePruefungDatum!));

    final now = DateTime.now();

    List<Messung> gefiltert;
    switch (_filter) {
      case FaelligkeitFilter.alle:
        gefiltert = mitDatum;
      case FaelligkeitFilter.ueberfaellig:
        gefiltert =
            mitDatum.where((m) => m.naechstePruefungDatum!.isBefore(now)).toList();
      case FaelligkeitFilter.dieseWoche:
        final wochenende = now.add(const Duration(days: 7));
        gefiltert = mitDatum
            .where((m) =>
                !m.naechstePruefungDatum!.isBefore(now) &&
                m.naechstePruefungDatum!.isBefore(wochenende))
            .toList();
      case FaelligkeitFilter.dieserMonat:
        gefiltert = mitDatum
            .where((m) =>
                m.naechstePruefungDatum!.year == now.year &&
                m.naechstePruefungDatum!.month == now.month)
            .toList();
      case FaelligkeitFilter.naechste90Tage:
        final ende = now.add(const Duration(days: 90));
        gefiltert = mitDatum
            .where((m) =>
                !m.naechstePruefungDatum!.isBefore(now) &&
                m.naechstePruefungDatum!.isBefore(ende))
            .toList();
    }

    if (gefiltert.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 36, color: AppColors.outlineVariant),
              const SizedBox(height: 12),
              Text(
                'Keine Fälligkeiten',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Prüftermine werden bei DGUV-V3-Messungen erfasst.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: gefiltert.map((m) => _MessungFaelligkeitTile(messung: m)).toList(),
    );
  }
}

// ── Fälligkeit Badge ──────────────────────────────────────────────────────────

class FaelligkeitBadge extends StatelessWidget {
  const FaelligkeitBadge({super.key, required this.datum});

  final DateTime datum;

  @override
  Widget build(BuildContext context) {
    final status = _statusFor(datum);
    Color bg;
    Color fg;
    String label;
    IconData icon;

    final now = DateTime.now();
    final diff = datum.difference(now).inDays;

    switch (status) {
      case FaelligkeitStatus.ueberfaellig:
        bg = AppColors.errorContainer;
        fg = AppColors.onErrorContainer;
        icon = Icons.warning_amber_rounded;
        label = 'Überfällig';
      case FaelligkeitStatus.dieseWoche:
        bg = AppColors.warningContainer;
        fg = AppColors.onWarningContainer;
        icon = Icons.schedule;
        label = 'Diese Woche';
      case FaelligkeitStatus.ok:
        bg = AppColors.successContainer;
        fg = AppColors.onSuccessContainer;
        icon = Icons.check_circle_outline;
        label = 'In $diff Tagen';
      case FaelligkeitStatus.keinDatum:
        bg = AppColors.surfaceContainerHigh;
        fg = AppColors.onSurfaceVariant;
        icon = Icons.remove_circle_outline;
        label = 'Kein Datum';
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

// ── List Tile ─────────────────────────────────────────────────────────────────

class _MessungFaelligkeitTile extends StatelessWidget {
  const _MessungFaelligkeitTile({required this.messung});

  final Messung messung;

  @override
  Widget build(BuildContext context) {
    final datum = messung.naechstePruefungDatum!;
    final status = _statusFor(datum);

    Color bgColor;
    switch (status) {
      case FaelligkeitStatus.ueberfaellig:
        bgColor = AppColors.errorContainer;
      case FaelligkeitStatus.dieseWoche:
        bgColor = AppColors.warningContainer;
      case FaelligkeitStatus.ok:
      case FaelligkeitStatus.keinDatum:
        bgColor = AppColors.surfaceContainerLowest;
    }

    final dateStr =
        '${datum.day.toString().padLeft(2, '0')}.${datum.month.toString().padLeft(2, '0')}.${datum.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  messung.komponenteUuid ?? messung.geraetUuid ?? '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.assignment_outlined,
                        size: 12, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      messung.norm.toUpperCase().replaceAll('_', ' '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Nächste Prüfung: $dateStr',
                  style: AppTheme.dataMono(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FaelligkeitBadge(datum: datum),
        ],
      ),
    );
  }
}

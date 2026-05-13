import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/messung.dart';
import '../../core/providers/messungen_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';

// ── Filter type ───────────────────────────────────────────────────────────────

enum _HistorieFilter { alle, vde0701, dguvV3, vde0100 }

// ── Screen ────────────────────────────────────────────────────────────────────

class HistorieScreen extends ConsumerStatefulWidget {
  const HistorieScreen({super.key});

  @override
  ConsumerState<HistorieScreen> createState() => _HistorieScreenState();
}

class _HistorieScreenState extends ConsumerState<HistorieScreen> {
  _HistorieFilter _filter = _HistorieFilter.alle;

  @override
  Widget build(BuildContext context) {
    final messungenAsync = ref.watch(alleMessungenProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ───────────────────────────────────────────────
            Text(
              'HISTORIE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.08 * 12,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Messungshistorie',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 20),

            // ── Filter Chips ──────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Alle',
                    selected: _filter == _HistorieFilter.alle,
                    onSelected: () =>
                        setState(() => _filter = _HistorieFilter.alle),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'VDE 0701-0702',
                    selected: _filter == _HistorieFilter.vde0701,
                    onSelected: () => setState(
                        () => _filter = _HistorieFilter.vde0701),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'DGUV V3',
                    selected: _filter == _HistorieFilter.dguvV3,
                    onSelected: () => setState(
                        () => _filter = _HistorieFilter.dguvV3),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'VDE 0100',
                    selected: _filter == _HistorieFilter.vde0100,
                    onSelected: () => setState(
                        () => _filter = _HistorieFilter.vde0100),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Liste ─────────────────────────────────────────────────────
            Expanded(
              child: messungenAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(child: Text('Fehler: $e')),
                data: (messungen) {
                  final filtered = _applyFilter(messungen);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.history,
                              size: 64,
                              color: AppColors.outlineVariant),
                          const SizedBox(height: 16),
                          Text(
                            'Keine Messungen vorhanden',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color:
                                        AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group by date
                  final groups =
                      _groupByDate(filtered);

                  return ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final entry = groups[i];
                      return _DateGroup(
                        dateLabel: entry.key,
                        messungen: entry.value,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Messung> _applyFilter(List<Messung> all) {
    return switch (_filter) {
      _HistorieFilter.alle => all,
      _HistorieFilter.vde0701 =>
        all.where((m) => m.norm == 'vde_0701_0702').toList(),
      _HistorieFilter.dguvV3 =>
        all.where((m) => m.norm == 'dguv_v3').toList(),
      _HistorieFilter.vde0100 =>
        all.where((m) => m.norm == 'vde_0100').toList(),
    };
  }

  List<MapEntry<String, List<Messung>>> _groupByDate(
      List<Messung> messungen) {
    final map = <String, List<Messung>>{};
    for (final m in messungen) {
      final key =
          '${m.pruefungDatum.day.toString().padLeft(2, '0')}.${m.pruefungDatum.month.toString().padLeft(2, '0')}.${m.pruefungDatum.year}';
      map.putIfAbsent(key, () => []).add(m);
    }
    return map.entries.toList();
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? AppColors.onPrimaryContainer
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Date Group ────────────────────────────────────────────────────────────────

class _DateGroup extends StatelessWidget {
  const _DateGroup({
    required this.dateLabel,
    required this.messungen,
  });

  final String dateLabel;
  final List<Messung> messungen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            dateLabel,
            style: AppTheme.dataMono(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        ...messungen.map(
          (m) => _MessungHistorieTile(
            messung: m,
            onTap: () => _showDetail(context, m),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _showDetail(BuildContext context, Messung messung) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MesswertDetail(messung: messung),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _MessungHistorieTile extends StatelessWidget {
  const _MessungHistorieTile({
    required this.messung,
    required this.onTap,
  });

  final Messung messung;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final normLabel = switch (messung.norm) {
      'vde_0701_0702' => 'VDE 0701-0702',
      'dguv_v3' => 'DGUV V3',
      'vde_0100' => 'VDE 0100',
      _ => messung.norm,
    };

    final bool passed = messung.ergebnis == 'bestanden';
    final bool failed = messung.ergebnis == 'nicht_bestanden';

    Color pillBg;
    Color pillFg;
    IconData pillIcon;
    String pillLabel;

    if (passed) {
      pillBg = AppColors.successContainer;
      pillFg = AppColors.success;
      pillIcon = Icons.check_circle_outline;
      pillLabel = 'BESTANDEN';
    } else if (failed) {
      pillBg = AppColors.errorContainer;
      pillFg = AppColors.error;
      pillIcon = Icons.error_outline;
      pillLabel = 'FAILED';
    } else {
      pillBg = AppColors.surfaceContainerHigh;
      pillFg = AppColors.onSurfaceVariant;
      pillIcon = Icons.pending_outlined;
      pillLabel = 'OFFEN';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            // Norm Badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                normLabel,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    messung.komponenteUuid.substring(0, 8).toUpperCase(),
                    style: AppTheme.dataMono(
                      fontSize: 11,
                      color: AppColors.outline,
                    ),
                  ),
                  if (messung.prueferName != null)
                    Text(
                      messung.prueferName!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: AppColors.onSurfaceVariant),
                    ),
                ],
              ),
            ),

            // Status Pill
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(pillIcon, size: 11, color: pillFg),
                  const SizedBox(width: 4),
                  Text(
                    pillLabel,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: pillFg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Detail Sheet ──────────────────────────────────────────────────────────────

class _MesswertDetail extends StatelessWidget {
  const _MesswertDetail({required this.messung});

  final Messung messung;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? werte;
    if (messung.messwertJson != null) {
      try {
        werte =
            jsonDecode(messung.messwertJson!) as Map<String, dynamic>;
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Messwerte Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (werte != null)
            ...werte.entries
                .where((e) => e.value != null)
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: AppColors.onSurfaceVariant),
                            ),
                          ),
                          Text(
                            e.value.toString(),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ))
          else
            Text(
              'Keine Messwerte.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          if (messung.bemerkung != null) ...[
            const Divider(color: AppColors.outlineVariant),
            const SizedBox(height: 8),
            Text(
              'Bemerkung: ${messung.bemerkung}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

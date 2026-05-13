import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/messung.dart';
import '../../core/providers/messungen_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'messung_formular.dart';

class MessungenListe extends ConsumerWidget {
  const MessungenListe({
    super.key,
    required this.komponenteUuid,
  });

  final String komponenteUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messungenAsync =
        ref.watch(messungenByKomponenteProvider(komponenteUuid));

    return messungenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Fehler: $e'),
      data: (messungen) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Messungen',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showMessungFormular(context, null),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Messung'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (messungen.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Noch keine Messungen vorhanden',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ),
              )
            else
              ...messungen.map((m) => _MessungTile(
                    messung: m,
                    onTap: () =>
                        _showMesswertDetail(context, m),
                  )),
          ],
        );
      },
    );
  }

  Future<void> _showMessungFormular(
      BuildContext context, Messung? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MessungFormular(
        komponenteUuid: komponenteUuid,
        existingMessung: existing,
      ),
    );
  }

  void _showMesswertDetail(BuildContext context, Messung messung) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MesswertDetailSheet(messung: messung),
    );
  }
}

// ── Messung Tile ──────────────────────────────────────────────────────────────

class _MessungTile extends StatelessWidget {
  const _MessungTile({
    required this.messung,
    required this.onTap,
  });

  final Messung messung;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
      pillLabel = 'NICHT BESTANDEN';
    } else {
      pillBg = AppColors.surfaceContainerHigh;
      pillFg = AppColors.onSurfaceVariant;
      pillIcon = Icons.pending_outlined;
      pillLabel = 'NICHT GEPRÜFT';
    }

    final normLabel = switch (messung.norm) {
      'vde_0701_0702' => 'VDE 0701-0702',
      'dguv_v3' => 'DGUV V3',
      'vde_0100' => 'VDE 0100',
      _ => messung.norm,
    };

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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dateStr(messung.pruefungDatum),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      normLabel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(pillIcon, size: 12, color: pillFg),
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

  String _dateStr(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// ── Messwert Detail Sheet ─────────────────────────────────────────────────────

class _MesswertDetailSheet extends StatelessWidget {
  const _MesswertDetailSheet({required this.messung});

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
                'Messwerte',
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
              'Keine Messwerte gespeichert.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
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

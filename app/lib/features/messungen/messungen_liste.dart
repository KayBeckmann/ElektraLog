import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/messung.dart';
import '../../core/providers/messungen_provider.dart';
import '../../core/providers/pruefprotokoll_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'messung_formular.dart';

class MessungenListe extends ConsumerWidget {
  const MessungenListe({
    super.key,
    required this.komponenteUuid,
    this.verteilerUuid,
  });

  final String komponenteUuid;
  final String? verteilerUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messungenAsync =
        ref.watch(messungenByKomponenteProvider(komponenteUuid));

    // Protokolle beobachten wenn verteilerUuid gesetzt
    final protokolleAsync = verteilerUuid != null
        ? ref.watch(pruefprotokolleByVerteilerProvider(verteilerUuid!))
        : null;
    final keinProtokoll = protokolleAsync == null ||
        protokolleAsync.when(
          data: (list) => list.isEmpty,
          loading: () => false,
          error: (_, __) => false,
        );

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
                    keinProtokoll: keinProtokoll,
                    onTap: () => _showMesswertDetail(context, m),
                    onEditMessung: () =>
                        _showMessungFormular(context, m),
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

class _MessungTile extends ConsumerWidget {
  const _MessungTile({
    required this.messung,
    required this.keinProtokoll,
    required this.onTap,
    required this.onEditMessung,
  });

  final Messung messung;
  final bool keinProtokoll;
  final VoidCallback onTap;
  final VoidCallback onEditMessung;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            // Bemerkung bearbeiten
            IconButton(
              icon: const Icon(Icons.edit_note_outlined, size: 16),
              tooltip: 'Bemerkung bearbeiten',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              color: AppColors.onSurfaceVariant,
              onPressed: () => _showBemerkungSheet(context, ref),
            ),
            // Messung bearbeiten (nur wenn kein Protokoll erstellt)
            if (keinProtokoll)
              IconButton(
                icon: const Icon(Icons.open_in_new_outlined, size: 16),
                tooltip: 'Messung bearbeiten',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: AppColors.onSurfaceVariant,
                onPressed: () => _confirmEditMessung(context),
              ),
          ],
        ),
      ),
    );
  }

  void _showBemerkungSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _BemerkungEditSheet(messung: messung),
    );
  }

  Future<void> _confirmEditMessung(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Messung bearbeiten?'),
        content: const Text(
            'Änderungen können das Prüfprotokoll beeinflussen. Fortfahren?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Fortfahren'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      onEditMessung();
    }
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

// ── Bemerkung Edit Sheet ──────────────────────────────────────────────────────

class _BemerkungEditSheet extends ConsumerStatefulWidget {
  const _BemerkungEditSheet({required this.messung});
  final Messung messung;

  @override
  ConsumerState<_BemerkungEditSheet> createState() =>
      _BemerkungEditSheetState();
}

class _BemerkungEditSheetState extends ConsumerState<_BemerkungEditSheet> {
  late final TextEditingController _ctrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.messung.bemerkung ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bemerkung bearbeiten',
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
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: 'Bemerkung',
              hintText: 'Optionale Anmerkung zur Messung',
            ),
            maxLines: 4,
            minLines: 2,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.onPrimary),
                    )
                  : const Text('Speichern'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final trimmed = _ctrl.text.trim();
      final updated = widget.messung.copyWith(
        bemerkung: trimmed.isEmpty ? null : trimmed,
      );
      await ref.read(messungenRepositoryProvider).save(updated);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bemerkung gespeichert')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

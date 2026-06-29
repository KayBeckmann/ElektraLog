import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/messung.dart';
import '../../core/models/pruefprotokoll.dart';
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
    final gesperrteUuids = protokolleAsync?.when(
          data: _gesperrteMessungUuids,
          loading: () => const <String>{},
          error: (_, __) => const <String>{},
        ) ??
        const <String>{};

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
                    gesperrt: gesperrteUuids.contains(m.uuid),
                    onTap: () => _showMesswertDetail(context, m),
                    onEditMessung: () => _showMessungFormular(context, m),
                    onDelete: () => _deleteMessung(context, ref, m),
                  )),
          ],
        );
      },
    );
  }

  /// Sammelt die UUIDs aller Messungen, die in einem Messdaten-Snapshot
  /// (= bereits in ein Protokoll überführt) enthalten sind.
  static Set<String> _gesperrteMessungUuids(List<Pruefprotokoll> protokolle) {
    final result = <String>{};
    for (final p in protokolle) {
      final raw = p.messdatenSnapshot;
      if (raw == null || raw.isEmpty) continue;
      try {
        final snapshot = jsonDecode(raw) as Map<String, dynamic>;
        final komponenten = snapshot['komponenten'] as List<dynamic>? ?? [];
        for (final k in komponenten) {
          final messungen = (k as Map<String, dynamic>)['messungen']
                  as List<dynamic>? ??
              [];
          for (final m in messungen) {
            final uuid = (m as Map<String, dynamic>)['uuid'] as String?;
            if (uuid != null) result.add(uuid);
          }
        }
      } catch (_) {
        // Ungültiger Snapshot — ignorieren
      }
    }
    return result;
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

  Future<void> _deleteMessung(
      BuildContext context, WidgetRef ref, Messung messung) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Messung löschen?'),
        content: const Text(
            'Diese Messung wurde noch nicht in ein Protokoll übernommen und wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(messungenRepositoryProvider).delete(messung.uuid);
    }
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
    required this.gesperrt,
    required this.onTap,
    required this.onEditMessung,
    required this.onDelete,
  });

  final Messung messung;

  /// true, wenn diese Messung bereits in ein Prüfprotokoll überführt wurde
  /// und daher nicht mehr verändert werden darf.
  final bool gesperrt;
  final VoidCallback onTap;
  final VoidCallback onEditMessung;
  final VoidCallback onDelete;

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
            // Bemerkung bearbeiten (gesperrt sobald in einem Protokoll enthalten)
            IconButton(
              icon: const Icon(Icons.edit_note_outlined, size: 16),
              tooltip: gesperrt
                  ? 'Bereits in Protokoll enthalten — keine Änderung möglich'
                  : 'Bemerkung bearbeiten',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              color:
                  gesperrt ? AppColors.outlineVariant : AppColors.onSurfaceVariant,
              onPressed:
                  gesperrt ? null : () => _showBemerkungSheet(context, ref),
            ),
            // Messung bearbeiten / Lock-Icon (gesperrt)
            if (gesperrt)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.lock_outline,
                    size: 16, color: AppColors.outlineVariant),
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.open_in_new_outlined, size: 16),
                tooltip: 'Messung bearbeiten',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: AppColors.onSurfaceVariant,
                onPressed: () => _confirmEditMessung(context),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                tooltip: 'Messung löschen',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                color: AppColors.error,
                onPressed: onDelete,
              ),
            ],
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

    final phasen = werte?['phasen'] as List<dynamic>?;

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
          if (werte != null) ...[
            if (phasen != null && phasen.isNotEmpty) ...[
              Text(
                'Phasenmessungen (VDE 0100)',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: AppColors.outlineVariant, width: 0.5),
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(2.5),
                  2: FlexColumnWidth(2.5),
                  3: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: AppColors.surfaceContainerLow),
                    children: [
                      _headerCell('Phase'),
                      _headerCell('Schleife L-PE'),
                      _headerCell('Schleife L-N'),
                      _headerCell('Isolation'),
                    ],
                  ),
                  ...phasen.map((p) {
                    final pMap = p as Map<String, dynamic>;
                    final phase = pMap['phase']?.toString() ?? '—';
                    
                    final lpeOhm = pMap['schleifenimpedanz_l_pe_ohm'] ?? pMap['schleifenimpedanz_ohm'];
                    final lpeAmp = pMap['kurzschlussstrom_l_pe_a'] ?? pMap['kurzschlussstrom_a'];
                    String lpeStr = '—';
                    if (lpeOhm != null && lpeAmp != null) {
                      lpeStr = '$lpeOhm Ω / $lpeAmp A';
                    } else if (lpeOhm != null) {
                      lpeStr = '$lpeOhm Ω';
                    } else if (lpeAmp != null) {
                      lpeStr = '$lpeAmp A';
                    }
                    
                    final lnOhm = pMap['schleifenimpedanz_l_n_ohm'];
                    final lnAmp = pMap['kurzschlussstrom_l_n_a'];
                    String lnStr = '—';
                    if (lnOhm != null && lnAmp != null) {
                      lnStr = '$lnOhm Ω / $lnAmp A';
                    } else if (lnOhm != null) {
                      lnStr = '$lnOhm Ω';
                    } else if (lnAmp != null) {
                      lnStr = '$lnAmp A';
                    }

                    final iso = pMap['isolationswiderstand_mohm'];
                    final isoStr = iso != null ? '$iso MΩ' : '—';
                    
                    return TableRow(
                      children: [
                        _valueCell(phase, isBold: true),
                        _valueCell(lpeStr),
                        _valueCell(lnStr),
                        _valueCell(isoStr),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Sonstige Werte (RCD, Erdung, Drehfeld)
            Table(
              border: TableBorder.all(color: AppColors.outlineVariant, width: 0.5),
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
              },
              children: [
                if (werte['rcd_nenn_differenzstrom_ma'] != null)
                  _row('Nenn-Differenzstrom I∆n', '${werte['rcd_nenn_differenzstrom_ma']} mA'),
                if (werte['rcd_gemessen_differenzstrom_ma'] != null)
                  _row('Auslösestrom I∆', '${werte['rcd_gemessen_differenzstrom_ma']} mA'),
                if (werte['rcd_ausloesezeit_ms'] != null)
                  _row('Auslösezeit', '${werte['rcd_ausloesezeit_ms']} ms'),
                if (phasen == null && werte['schleifenimpedanz_ohm'] != null)
                  _row('Schleifenimpedanz Zs', '${werte['schleifenimpedanz_ohm']} Ω'),
                if (phasen == null && werte['isolationswiderstand_mohm'] != null)
                  _row('Isolationswiderstand', '${werte['isolationswiderstand_mohm']} MΩ'),
                if (werte['erdungswiderstand_ohm'] != null)
                  _row('Erdungswiderstand', '${werte['erdungswiderstand_ohm']} Ω'),
                if (werte['drehfeld_richtig'] != null)
                  _row('Drehfeldrichtung korrekt', werte['drehfeld_richtig'] == true ? 'Ja' : 'Nein'),
              ],
            ),
          ] else
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

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _valueCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: AppColors.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  TableRow _row(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/sichtpruefung.dart';
import '../../core/providers/sichtpruefung_provider.dart';
import '../../shared/theme/app_colors.dart';

// ── Checkliste Punkte ─────────────────────────────────────────────────────────

enum ChecklistePunkt {
  kennzeichnungVorhanden,
  schutzleiterAngeschlossen,
  leitungenOrdnungsgemaess,
  schutzeinrichtungenVorhanden,
  brandschutzabdichtung,
  beschriftungAbgaenge,
  zustandGehaeuse,
  verteilerAbschliessbar,
}

extension ChecklistePunktLabel on ChecklistePunkt {
  String get label {
    switch (this) {
      case ChecklistePunkt.kennzeichnungVorhanden:
        return 'Kennzeichnung vorhanden';
      case ChecklistePunkt.schutzleiterAngeschlossen:
        return 'Schutzleiter korrekt angeschlossen';
      case ChecklistePunkt.leitungenOrdnungsgemaess:
        return 'Leitungen ordnungsgemäß verlegt';
      case ChecklistePunkt.schutzeinrichtungenVorhanden:
        return 'Schutzeinrichtungen vorhanden und korrekt';
      case ChecklistePunkt.brandschutzabdichtung:
        return 'Brandschutzabdichtungen vorhanden';
      case ChecklistePunkt.beschriftungAbgaenge:
        return 'Beschriftung der Abgänge vollständig';
      case ChecklistePunkt.zustandGehaeuse:
        return 'Zustand des Gehäuses / Schranks';
      case ChecklistePunkt.verteilerAbschliessbar:
        return 'Verteiler abschließbar / abgeschlossen';
    }
  }

  String get key => name;
}

// ── Checkpunkt Status ─────────────────────────────────────────────────────────

/// Drei Zustände je Prüfpunkt:
/// - bestanden   → Punkt geprüft, i.O.
/// - durchgefallen → Mangel festgestellt
/// - nichtZutreffend → Punkt gilt nicht für diese Anlage (N/A)
enum PunktStatus { bestanden, durchgefallen, nichtZutreffend }

extension PunktStatusLabel on PunktStatus {
  String get key {
    switch (this) {
      case PunktStatus.bestanden:
        return 'bestanden';
      case PunktStatus.durchgefallen:
        return 'durchgefallen';
      case PunktStatus.nichtZutreffend:
        return 'nicht_zutreffend';
    }
  }

  String get label {
    switch (this) {
      case PunktStatus.bestanden:
        return 'Bestanden';
      case PunktStatus.durchgefallen:
        return 'Durchgefallen';
      case PunktStatus.nichtZutreffend:
        return 'N/A';
    }
  }

  static PunktStatus fromKey(String key) {
    switch (key) {
      case 'bestanden':
      case 'ok': // Rückwärtskompatibilität
        return PunktStatus.bestanden;
      case 'durchgefallen':
      case 'mangel': // Rückwärtskompatibilität
        return PunktStatus.durchgefallen;
      default:
        return PunktStatus.nichtZutreffend;
    }
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SichtpruefungScreen extends ConsumerStatefulWidget {
  const SichtpruefungScreen({
    super.key,
    required this.verteilerUuid,
    required this.verteilerBezeichnung,
  });

  final String verteilerUuid;
  final String verteilerBezeichnung;

  @override
  ConsumerState<SichtpruefungScreen> createState() =>
      _SichtpruefungScreenState();
}

class _SichtpruefungScreenState extends ConsumerState<SichtpruefungScreen> {
  final Map<ChecklistePunkt, PunktStatus> _checkliste = {
    for (final p in ChecklistePunkt.values) p: PunktStatus.nichtZutreffend,
  };
  final _maengelCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _maengelCtrl.dispose();
    super.dispose();
  }

  String _berechneErgebnis() {
    final values = _checkliste.values.toList();
    // Mindestens ein Durchgefallen → mit Mängeln
    if (values.any((v) => v == PunktStatus.durchgefallen)) {
      return 'mit_maengeln';
    }
    // Alles bestanden oder N/A → bestanden
    return 'bestanden';
  }

  /// Zyklus: N/A → Bestanden → Durchgefallen → N/A
  void _togglePunkt(ChecklistePunkt punkt) {
    setState(() {
      final current = _checkliste[punkt]!;
      _checkliste[punkt] = switch (current) {
        PunktStatus.nichtZutreffend => PunktStatus.bestanden,
        PunktStatus.bestanden => PunktStatus.durchgefallen,
        PunktStatus.durchgefallen => PunktStatus.nichtZutreffend,
      };
    });
  }

  Future<void> _abschliessen() async {
    setState(() => _isSaving = true);
    try {
      final checklisteMap = {
        for (final entry in _checkliste.entries)
          entry.key.key: entry.value.key,
      };
      final sichtpruefung = Sichtpruefung(
        verteilerUuid: widget.verteilerUuid,
        pruefungDatum: DateTime.now(),
        checklisteJson: jsonEncode(checklisteMap),
        maengel: _maengelCtrl.text.trim().isEmpty
            ? null
            : _maengelCtrl.text.trim(),
        ergebnis: _berechneErgebnis(),
      );
      final repo = ref.read(sichtpruefungRepositoryProvider);
      await repo.save(sichtpruefung);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sichtprüfung gespeichert'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sichtpruefungenAsync =
        ref.watch(sichtpruefungenByVerteilerProvider(widget.verteilerUuid));
    final ergebnis = _berechneErgebnis();
    final hatMaengel = _checkliste.values.any((v) => v == PunktStatus.durchgefallen);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sichtprüfung'),
            Text(
              widget.verteilerBezeichnung,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Vorherige Sichtprüfung Banner ──────────────────────────
            sichtpruefungenAsync.when(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                final letzte = list.first;
                final datStr =
                    '${letzte.pruefungDatum.day.toString().padLeft(2, '0')}.${letzte.pruefungDatum.month.toString().padLeft(2, '0')}.${letzte.pruefungDatum.year}';
                return _ErgebnisBanner(
                  ergebnis: letzte.ergebnis,
                  prefix: 'Letzte Prüfung: $datStr —',
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            if (sichtpruefungenAsync.hasValue &&
                (sichtpruefungenAsync.value?.isNotEmpty ?? false))
              const SizedBox(height: 12),

            // ── Section Header ─────────────────────────────────────────
            Text(
              'ZVEH-Checkliste',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tippen zum Umschalten:  N/A → ✓ Bestanden → ✗ Durchgefallen → N/A',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),

            // ── Checkliste ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                children: ChecklistePunkt.values.map((punkt) {
                  final isLast = punkt == ChecklistePunkt.values.last;
                  return _ChecklisteTile(
                    punkt: punkt,
                    status: _checkliste[punkt]!,
                    onTap: () => _togglePunkt(punkt),
                    showDivider: !isLast,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Mängeltext (nur sichtbar wenn min. 1 Mangel) ───────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: hatMaengel
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mängeltext',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _maengelCtrl,
                    maxLines: 4,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Beschreibung der festgestellten Mängel…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),

            // ── Ergebnis Banner ────────────────────────────────────────
            _ErgebnisBanner(ergebnis: ergebnis, prefix: 'Aktuelles Ergebnis:'),
            const SizedBox(height: 20),

            // ── Abschließen Button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _abschliessen,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outlined),
                label: const Text('Sichtprüfung abschließen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ergebnis Banner ───────────────────────────────────────────────────────────

class _ErgebnisBanner extends StatelessWidget {
  const _ErgebnisBanner({
    required this.ergebnis,
    required this.prefix,
  });

  final String ergebnis;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;
    IconData icon;
    String label;

    switch (ergebnis) {
      case 'bestanden':
        bg = AppColors.successContainer;
        border = AppColors.success;
        text = AppColors.onSuccessContainer;
        icon = Icons.check_circle_outline;
        label = 'Bestanden';
      case 'mit_maengeln':
        bg = AppColors.warningContainer;
        border = AppColors.warning;
        text = AppColors.onWarningContainer;
        icon = Icons.warning_amber_rounded;
        label = 'Mit Mängeln';
      default:
        bg = AppColors.errorContainer;
        border = AppColors.error;
        text = AppColors.onErrorContainer;
        icon = Icons.cancel_outlined;
        label = 'Nicht bestanden';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: text),
          const SizedBox(width: 10),
          Text(
            '$prefix $label',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Checkliste Tile ───────────────────────────────────────────────────────────

class _ChecklisteTile extends StatelessWidget {
  const _ChecklisteTile({
    required this.punkt,
    required this.status,
    required this.onTap,
    required this.showDivider,
  });

  final ChecklistePunkt punkt;
  final PunktStatus status;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (status) {
      case PunktStatus.bestanden:
        icon = Icons.check_circle;
        iconColor = AppColors.success;
      case PunktStatus.durchgefallen:
        icon = Icons.cancel;
        iconColor = AppColors.error;
      case PunktStatus.nichtZutreffend:
        icon = Icons.do_not_disturb_on_outlined;
        iconColor = AppColors.outlineVariant;
    }

    final isNa = status == PunktStatus.nichtZutreffend;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: iconColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    punkt.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isNa
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                        ),
                  ),
                ),
                // Status-Badge rechts
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: switch (status) {
                      PunktStatus.bestanden => AppColors.successContainer,
                      PunktStatus.durchgefallen => AppColors.errorContainer,
                      PunktStatus.nichtZutreffend =>
                        AppColors.surfaceContainerHigh,
                    },
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: switch (status) {
                        PunktStatus.bestanden => AppColors.success,
                        PunktStatus.durchgefallen => AppColors.error,
                        PunktStatus.nichtZutreffend =>
                          AppColors.onSurfaceVariant,
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 52,
            color: AppColors.outlineVariant,
          ),
      ],
    );
  }
}

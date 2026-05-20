import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/sichtpruefung.dart';
import '../../core/providers/sichtpruefung_provider.dart';
import '../../shared/theme/app_colors.dart';

// ── Sichtprüfung Checkpunkte ──────────────────────────────────────────────────

enum ChecklistePunkt {
  // Ursprüngliche ZVEH-Punkte
  kennzeichnungVorhanden,
  schutzleiterAngeschlossen,
  leitungenOrdnungsgemaess,
  schutzeinrichtungenVorhanden,
  brandschutzabdichtung,
  beschriftungAbgaenge,
  zustandGehaeuse,
  verteilerAbschliessbar,
  // Erweiterte Sichtprüfung (VDE 0100-600)
  schutzGegeDirektBeruehren,
  kennzeichnungNPE,
  leiterverbindungen,
  schutzUeberwachungseinrichtungen,
  zugaenglichkeit,
  ueberspannungsschutz,
  dokumentation,
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
      case ChecklistePunkt.schutzGegeDirektBeruehren:
        return 'Schutz gegen direktes Berühren';
      case ChecklistePunkt.kennzeichnungNPE:
        return 'Kennzeichnung N- und PE-Leiter';
      case ChecklistePunkt.leiterverbindungen:
        return 'Leiterverbindungen';
      case ChecklistePunkt.schutzUeberwachungseinrichtungen:
        return 'Schutz- und Überwachungseinrichtungen';
      case ChecklistePunkt.zugaenglichkeit:
        return 'Zugänglichkeit';
      case ChecklistePunkt.ueberspannungsschutz:
        return 'Überspannungsschutz';
      case ChecklistePunkt.dokumentation:
        return 'Dokumentation / Stromlaufplan / Legende';
    }
  }

  String get key => name;
}

// ── Erprobung Checkpunkte ─────────────────────────────────────────────────────

enum ErprobungPunkt {
  funktionspruefungAnlage,
  rcdErprobung,
  spannungsfall,
  spannungspolaritaet,
}

extension ErprobungPunktLabel on ErprobungPunkt {
  String get label {
    switch (this) {
      case ErprobungPunkt.funktionspruefungAnlage:
        return 'Funktionsprüfung der Anlage';
      case ErprobungPunkt.rcdErprobung:
        return 'RCD (FI-Schutzschalter)';
      case ErprobungPunkt.spannungsfall:
        return 'Überprüfung Spannungsfall';
      case ErprobungPunkt.spannungspolaritaet:
        return 'Spannungspolarität';
    }
  }

  String get key => name;
}

// ── Checkpunkt Status ─────────────────────────────────────────────────────────

enum PunktStatus { bestanden, durchgefallen, nichtZutreffend }

extension PunktStatusLabel on PunktStatus {
  String get key {
    switch (this) {
      case PunktStatus.bestanden:      return 'bestanden';
      case PunktStatus.durchgefallen:  return 'durchgefallen';
      case PunktStatus.nichtZutreffend: return 'nicht_zutreffend';
    }
  }

  String get label {
    switch (this) {
      case PunktStatus.bestanden:      return 'Bestanden';
      case PunktStatus.durchgefallen:  return 'Durchgefallen';
      case PunktStatus.nichtZutreffend: return 'N/A';
    }
  }

  static PunktStatus fromKey(String key) {
    switch (key) {
      case 'bestanden':
      case 'ok':
        return PunktStatus.bestanden;
      case 'durchgefallen':
      case 'mangel':
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
  final Map<ErprobungPunkt, PunktStatus> _erprobung = {
    for (final p in ErprobungPunkt.values) p: PunktStatus.nichtZutreffend,
  };
  final _maengelCtrl = TextEditingController();
  bool _isSaving = false;
  String? _editingUuid;
  DateTime? _naechstePruefung;

  @override
  void dispose() {
    _maengelCtrl.dispose();
    super.dispose();
  }

  void _loadForEdit(Sichtpruefung sp) {
    Map<String, dynamic> checklist = {};
    if (sp.checklisteJson != null) {
      try {
        checklist = jsonDecode(sp.checklisteJson!) as Map<String, dynamic>;
      } catch (_) {}
    }
    setState(() {
      _editingUuid = sp.uuid;
      _maengelCtrl.text = sp.maengel ?? '';
      _naechstePruefung = sp.naechstePruefungDatum;
      for (final p in ChecklistePunkt.values) {
        final raw = checklist[p.key] as String?;
        _checkliste[p] =
            raw != null ? PunktStatusLabel.fromKey(raw) : PunktStatus.nichtZutreffend;
      }
      for (final p in ErprobungPunkt.values) {
        final raw = checklist[p.key] as String?;
        _erprobung[p] =
            raw != null ? PunktStatusLabel.fromKey(raw) : PunktStatus.nichtZutreffend;
      }
    });
  }

  String _berechneErgebnis() {
    final allValues = [
      ..._checkliste.values,
      ..._erprobung.values,
    ];
    if (allValues.any((v) => v == PunktStatus.durchgefallen)) {
      return 'mit_maengeln';
    }
    return 'bestanden';
  }

  void _toggleSichtpruefung(ChecklistePunkt punkt) {
    setState(() {
      final current = _checkliste[punkt]!;
      _checkliste[punkt] = switch (current) {
        PunktStatus.nichtZutreffend => PunktStatus.bestanden,
        PunktStatus.bestanden => PunktStatus.durchgefallen,
        PunktStatus.durchgefallen => PunktStatus.nichtZutreffend,
      };
    });
  }

  void _toggleErprobung(ErprobungPunkt punkt) {
    setState(() {
      final current = _erprobung[punkt]!;
      _erprobung[punkt] = switch (current) {
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
        for (final e in _checkliste.entries) e.key.key: e.value.key,
        for (final e in _erprobung.entries) e.key.key: e.value.key,
      };
      final ergebnis = _berechneErgebnis();
      final sp = Sichtpruefung(
        uuid: _editingUuid,
        verteilerUuid: widget.verteilerUuid,
        pruefungDatum: DateTime.now(),
        checklisteJson: jsonEncode(checklisteMap),
        maengel: _maengelCtrl.text.trim().isEmpty
            ? null
            : _maengelCtrl.text.trim(),
        ergebnis: ergebnis,
        naechstePruefungDatum:
            ergebnis == 'bestanden' ? _naechstePruefung : null,
      );
      await ref.read(sichtpruefungRepositoryProvider).save(sp);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingUuid != null
                ? 'Sichtprüfung aktualisiert'
                : 'Sichtprüfung gespeichert'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _editingUuid = null;
          _naechstePruefung = null;
          for (final p in ChecklistePunkt.values) {
            _checkliste[p] = PunktStatus.nichtZutreffend;
          }
          for (final p in ErprobungPunkt.values) {
            _erprobung[p] = PunktStatus.nichtZutreffend;
          }
          _maengelCtrl.clear();
        });
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
    final hatMaengel = [
      ..._checkliste.values,
      ..._erprobung.values
    ].any((v) => v == PunktStatus.durchgefallen);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sichtprüfung & Erprobung'),
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
            // ── Letzte Prüfung Banner ──────────────────────────────────
            sichtpruefungenAsync.when(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                final letzte = list.first;
                final datStr = _datStr(letzte.pruefungDatum);
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

            // ═══════════════════════════════════════════════════════════
            //  SICHTPRÜFUNG
            // ═══════════════════════════════════════════════════════════
            _sectionHeader(context, 'SICHTPRÜFUNG',
                'Tippen: N/A → ✓ → ✗ → N/A'),
            const SizedBox(height: 12),
            _checklisteBox(
              context,
              items: ChecklistePunkt.values.map((p) => (
                label: p.label,
                status: _checkliste[p]!,
                onTap: () => _toggleSichtpruefung(p),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // ═══════════════════════════════════════════════════════════
            //  ERPROBUNG
            // ═══════════════════════════════════════════════════════════
            _sectionHeader(context, 'ERPROBUNG',
                'Funktionsprüfungen nach VDE 0100-610'),
            const SizedBox(height: 12),
            _checklisteBox(
              context,
              items: ErprobungPunkt.values.map((p) => (
                label: p.label,
                status: _erprobung[p]!,
                onTap: () => _toggleErprobung(p),
              )).toList(),
            ),
            const SizedBox(height: 16),

            // ── Mängeltext ────────────────────────────────────────────
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: hatMaengel
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mängeltext',
                      style: Theme.of(context).textTheme.titleSmall),
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

            // ── Nächste Prüfung (nur bei bestandener Prüfung) ─────────
            if (ergebnis == 'bestanden') ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.event_available_outlined,
                  color: _naechstePruefung != null
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                title: Text(
                  'Nächste Prüfung',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(
                  _naechstePruefung == null
                      ? 'Noch kein Datum gesetzt'
                      : _datStr(_naechstePruefung!),
                  style: _naechstePruefung != null
                      ? GoogleFonts.jetBrainsMono(
                          fontSize: 13, color: AppColors.primary)
                      : Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                ),
                trailing: OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _naechstePruefung ?? now.add(const Duration(days: 365 * 4)),
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365 * 10)),
                    );
                    if (picked != null) {
                      setState(() => _naechstePruefung = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 14),
                  label: const Text('Datum wählen'),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Ergebnis Banner ───────────────────────────────────────
            _ErgebnisBanner(ergebnis: ergebnis, prefix: 'Aktuelles Ergebnis:'),
            const SizedBox(height: 20),

            // ── Abschließen ───────────────────────────────────────────
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
                    : Icon(_editingUuid != null
                        ? Icons.save_outlined
                        : Icons.check_circle_outlined),
                label: Text(_editingUuid != null
                    ? 'Änderungen speichern'
                    : 'Prüfung abschließen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _editingUuid != null
                      ? AppColors.secondary
                      : AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ),
            if (_editingUuid != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _editingUuid = null;
                  _naechstePruefung = null;
                  for (final p in ChecklistePunkt.values) {
                    _checkliste[p] = PunktStatus.nichtZutreffend;
                  }
                  for (final p in ErprobungPunkt.values) {
                    _erprobung[p] = PunktStatus.nichtZutreffend;
                  }
                  _maengelCtrl.clear();
                }),
                child: const Text('Bearbeitung abbrechen'),
              ),
            ],

            // ── Verlauf ───────────────────────────────────────────────
            const SizedBox(height: 28),
            Text(
              'VERLAUF',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            sichtpruefungenAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Text(
                    'Noch keine Prüfungen vorhanden.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  );
                }
                return Column(
                  children: list
                      .map((sp) => _VerlaufTile(
                            sichtpruefung: sp,
                            isEditing: sp.uuid == _editingUuid,
                            onEdit: () => _loadForEdit(sp),
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Fehler: $e'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _checklisteBox(
    BuildContext context, {
    required List<({String label, PunktStatus status, VoidCallback onTap})> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: items.indexed.map(((int, ({String label, PunktStatus status, VoidCallback onTap})) indexed) {
          final i = indexed.$1;
          final item = indexed.$2;
          return _ChecklisteTile(
            label: item.label,
            status: item.status,
            onTap: item.onTap,
            showDivider: i < items.length - 1,
          );
        }).toList(),
      ),
    );
  }

  String _datStr(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

// ── Ergebnis Banner ───────────────────────────────────────────────────────────

class _ErgebnisBanner extends StatelessWidget {
  const _ErgebnisBanner({required this.ergebnis, required this.prefix});

  final String ergebnis;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    Color bg, border, text;
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
                fontSize: 14, fontWeight: FontWeight.w600, color: text),
          ),
        ],
      ),
    );
  }
}

// ── Checkliste Tile ───────────────────────────────────────────────────────────

class _ChecklisteTile extends StatelessWidget {
  const _ChecklisteTile({
    required this.label,
    required this.status,
    required this.onTap,
    required this.showDivider,
  });

  final String label;
  final PunktStatus status;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;
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
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isNa
                              ? AppColors.onSurfaceVariant
                              : AppColors.onSurface,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
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
              height: 1, indent: 52, color: AppColors.outlineVariant),
      ],
    );
  }
}

// ── Verlauf-Tile ──────────────────────────────────────────────────────────────

class _VerlaufTile extends StatelessWidget {
  const _VerlaufTile({
    required this.sichtpruefung,
    required this.isEditing,
    required this.onEdit,
  });

  final Sichtpruefung sichtpruefung;
  final bool isEditing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final sp = sichtpruefung;
    final datStr =
        '${sp.pruefungDatum.day.toString().padLeft(2, '0')}.${sp.pruefungDatum.month.toString().padLeft(2, '0')}.${sp.pruefungDatum.year}';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (sp.ergebnis) {
      case 'bestanden':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Bestanden';
      case 'mit_maengeln':
        statusColor = AppColors.warning;
        statusIcon = Icons.warning_amber_outlined;
        statusLabel = 'Mit Mängeln';
      default:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'Nicht bestanden';
    }

    String? subtitleText = sp.maengel;
    if (sp.naechstePruefungDatum != null) {
      final nd = sp.naechstePruefungDatum!;
      final ndStr =
          '${nd.day.toString().padLeft(2, '0')}.${nd.month.toString().padLeft(2, '0')}.${nd.year}';
      subtitleText =
          '${subtitleText != null ? '$subtitleText · ' : ''}Nächste: $ndStr';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isEditing
            ? AppColors.secondaryContainer
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEditing ? AppColors.secondary : AppColors.outlineVariant,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(statusIcon, color: statusColor, size: 20),
        title: Text(
          '$datStr — $statusLabel',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitleText != null
            ? Text(
                subtitleText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: sp.maengel != null
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                    ),
              )
            : null,
        trailing: isEditing
            ? Chip(
                label: const Text('In Bearbeitung'),
                backgroundColor: AppColors.secondaryContainer,
                labelStyle: const TextStyle(
                    fontSize: 11, color: AppColors.onSecondaryContainer),
              )
            : IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.onSurfaceVariant),
                tooltip: 'Bearbeiten',
                onPressed: onEdit,
              ),
      ),
    );
  }
}

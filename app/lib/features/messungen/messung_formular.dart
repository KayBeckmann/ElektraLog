import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/messung.dart';
import '../../core/providers/einstellungen_provider.dart';
import '../../core/providers/messungen_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';

// ── Public entry point ────────────────────────────────────────────────────────

class MessungFormular extends ConsumerStatefulWidget {
  const MessungFormular({
    super.key,
    required this.komponenteUuid,
    this.komponenteTyp,
    this.komponenteEigenschaften,
    this.existingMessung,
  });

  final String komponenteUuid;

  /// Typ der Komponente — steuert welche Felder angezeigt werden
  final String? komponenteTyp;

  /// Bereits geparste eigenschaftenJson der Komponente
  final Map<String, dynamic>? komponenteEigenschaften;

  final Messung? existingMessung;

  @override
  ConsumerState<MessungFormular> createState() => _MessungFormularState();
}

class _MessungFormularState extends ConsumerState<MessungFormular> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prüfung erfassen',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.komponenteTyp != null
                            ? _typLabel(widget.komponenteTyp!)
                            : 'DIN VDE 0100',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'DIN VDE 0100',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            _Vde0100Form(
              komponenteUuid: widget.komponenteUuid,
              existingMessung: widget.existingMessung,
              onSaved: () => Navigator.pop(context),
              komponenteTyp: widget.komponenteTyp,
              komponenteEigenschaften: widget.komponenteEigenschaften,
            ),
          ],
        ),
      ),
    );
  }

  String _typLabel(String typ) {
    const labels = {
      'rcd': 'RCD / FI-Schutzschalter',
      'fi_ls': 'FI/LS-Kombination',
      'ls_schalter': 'LS-Schalter',
      'vorsicherung': 'Vorsicherung',
      'nh_sicherung': 'NH-Sicherung',
      'neozed': 'NeoZed-Sicherung',
      'diazed': 'DiaZed-Sicherung',
      'hauptschalter': 'Hauptschalter',
      'sammelschiene': 'Sammelschiene',
      'ueberspannung': 'Überspannungsschutz',
    };
    return labels[typ] ?? typ;
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _LimitField extends StatelessWidget {
  const _LimitField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.limitHint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final String limitHint;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        helperText: limitHint,
        helperStyle: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      onChanged: onChanged,
      style: AppTheme.dataMono(fontSize: 14),
    );
  }
}

String _autoErgebnis(Map<String, dynamic> checks) {
  for (final ok in checks.values) {
    if (ok == false) return 'nicht_bestanden';
  }
  return 'bestanden';
}

// ── DIN VDE 0100 ──────────────────────────────────────────────────────────────

class _Vde0100Form extends ConsumerStatefulWidget {
  const _Vde0100Form({
    required this.komponenteUuid,
    required this.existingMessung,
    required this.onSaved,
    this.komponenteTyp,
    this.komponenteEigenschaften,
  });

  final String komponenteUuid;
  final Messung? existingMessung;
  final VoidCallback onSaved;
  final String? komponenteTyp;
  final Map<String, dynamic>? komponenteEigenschaften;

  @override
  ConsumerState<_Vde0100Form> createState() => _Vde0100FormState();
}

class _Vde0100FormState extends ConsumerState<_Vde0100Form> {
  final _rcdNennCtrl = TextEditingController();
  final _rcdGemessenCtrl = TextEditingController();
  final _rcdZeitCtrl = TextEditingController();
  final _erdungCtrl = TextEditingController();
  final _bemerkungCtrl = TextEditingController();

  // Pro Phase — L-PE (Pflicht) + L-N (optional) + Isolation
  late final List<TextEditingController> _ikLpeCtrls;
  late final List<TextEditingController> _zsLpeCtrls;
  late final List<TextEditingController> _ikLnCtrls;
  late final List<TextEditingController> _zsLnCtrls;
  late final List<TextEditingController> _isoCtrls;

  // L-L Paare (nur 3-phasig): L1-L2, L2-L3, L1-L3
  late final List<TextEditingController> _ikLlCtrls;

  bool _useIk = true;
  bool _drehfeldRichtig = true;
  bool _isSaving = false;

  // ── Komponenten-Eigenschaften ─────────────────────────────────────────────

  bool get _isRcd =>
      widget.komponenteTyp == 'rcd' || widget.komponenteTyp == 'fi_ls';

  bool get _isLs => const [
        'ls_schalter', 'vorsicherung', 'nh_sicherung',
        'neozed', 'diazed', 'hauptschalter', 'fi_ls',
      ].contains(widget.komponenteTyp);

  double? get _nennstrom {
    final v = widget.komponenteEigenschaften?['nennstrom'];
    if (v == null) return null;
    return (v as num).toDouble();
  }

  String get _charakteristik =>
      (widget.komponenteEigenschaften?['charakteristik'] as String?) ?? 'B';

  double? get _minIk {
    final n = _nennstrom;
    if (n == null) return null;
    final faktor = _charakteristik == 'C' ? 10.0
        : _charakteristik == 'D' ? 20.0 : 5.0;
    return n * faktor;
  }

  String? get _nennDifferenzstromFromKomponente {
    final v = widget.komponenteEigenschaften?['auslösestrom'];
    if (v == null) return null;
    return v.toString();
  }

  /// Anzahl der zu messenden Phasen aus Pole-Eigenschaft.
  /// 4-polige Schalter: 3 Phasen (N wird nicht separat gemessen).
  int get _poleCount {
    final p = (widget.komponenteEigenschaften?['pole'] as num?)?.toInt() ?? 1;
    return p >= 4 ? 3 : p;
  }

  /// Phasenbeschriftungen je nach Polzahl
  List<String> get _phaseLabels => switch (_poleCount) {
        1 => ['L'],
        2 => ['L1', 'L2'],
        _ => ['L1', 'L2', 'L3'],
      };

  /// Drehfeld nur sinnvoll bei 3-phasig
  bool get _showDrehfeld => _poleCount >= 3;

  static const _llPaare = ['L1-L2', 'L2-L3', 'L1-L3'];

  @override
  void initState() {
    super.initState();
    final count = _poleCount;
    _ikLpeCtrls = List.generate(count, (_) => TextEditingController());
    _zsLpeCtrls = List.generate(count, (_) => TextEditingController());
    _ikLnCtrls  = List.generate(count, (_) => TextEditingController());
    _zsLnCtrls  = List.generate(count, (_) => TextEditingController());
    _isoCtrls   = List.generate(count, (_) => TextEditingController());
    _ikLlCtrls  = List.generate(3, (_) => TextEditingController());

    final nennDiff = _nennDifferenzstromFromKomponente;
    if (nennDiff != null) _rcdNennCtrl.text = nennDiff;
  }

  String get _ergebnis {
    if (_isRcd && !_isLs) {
      final nenn    = double.tryParse(_rcdNennCtrl.text.replaceAll(',', '.'));
      final gemessen = double.tryParse(_rcdGemessenCtrl.text.replaceAll(',', '.'));
      final zeit    = double.tryParse(_rcdZeitCtrl.text.replaceAll(',', '.'));
      final stromOk = (nenn == null || gemessen == null)
          ? true
          : gemessen >= nenn * 0.5 && gemessen <= nenn;
      return _autoErgebnis({
        'rcd_auslösestrom': stromOk,
        'rcd_ausloesezeit': zeit == null || zeit <= 300,
      });
    } else if (_isLs && !_isRcd) {
      // Bewertung auf Basis der L-PE-Messung
      final minIk = _minIk;
      final checks = <String, bool>{};
      for (int i = 0; i < _poleCount; i++) {
        if (_useIk) {
          final ik = double.tryParse(_ikLpeCtrls[i].text.replaceAll(',', '.'));
          checks['phase_${i + 1}_l_pe'] =
              ik == null || minIk == null || ik >= minIk;
        } else {
          final zs = double.tryParse(_zsLpeCtrls[i].text.replaceAll(',', '.'));
          if (zs != null && zs > 0 && minIk != null) {
            checks['phase_${i + 1}_l_pe'] = 230.0 / zs >= minIk;
          }
        }
      }
      return _autoErgebnis(checks);
    } else {
      final zeit = double.tryParse(_rcdZeitCtrl.text.replaceAll(',', '.'));
      return _autoErgebnis({'rcd_ausloesezeit': zeit == null || zeit <= 300});
    }
  }

  @override
  void dispose() {
    _rcdNennCtrl.dispose();
    _rcdGemessenCtrl.dispose();
    _rcdZeitCtrl.dispose();
    _erdungCtrl.dispose();
    _bemerkungCtrl.dispose();
    for (final c in _ikLpeCtrls) c.dispose();
    for (final c in _zsLpeCtrls) c.dispose();
    for (final c in _ikLnCtrls) c.dispose();
    for (final c in _zsLnCtrls) c.dispose();
    for (final c in _isoCtrls) c.dispose();
    for (final c in _ikLlCtrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Schleifenimpedanz / Kurzschlussstrom (nur für LS/Sicherungen) ──
        if (_isLs) ...[
          const _SektionsHeader(
            label: 'Schleifenimpedanz',
            icon: Icons.loop_outlined,
          ),
          _SectionHeader(
            _poleCount > 1
                ? 'Kurzschlussschutz — $_poleCount Phasen'
                : 'Kurzschlussschutz',
          ),
          const SizedBox(height: 8),

          // Toggle Ik ↔ Zs
          Row(
            children: [
              const Text('Eingabe als:', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Ik (A)'),
                selected: _useIk,
                onSelected: (_) => setState(() => _useIk = true),
                selectedColor: AppColors.secondaryContainer,
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Zs (Ω)'),
                selected: !_useIk,
                onSelected: (_) => setState(() => _useIk = false),
                selectedColor: AppColors.secondaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Pro Phase ───────────────────────────────────────────────────
          for (int i = 0; i < _poleCount; i++)
            _PhaseBlock(
              label: _phaseLabels[i],
              index: i,
              showLabel: _poleCount > 1,
              children: [
                // ── L-PE ────────────────────────────────────────────────
                _SubLabel('Phase–PE (${_phaseLabels[i]}-PE)'),
                const SizedBox(height: 4),
                if (_useIk) ...[
                  _LimitField(
                    controller: _ikLpeCtrls[i],
                    label: 'Ik L-PE',
                    unit: 'A',
                    limitHint: _minIk != null
                        ? 'min. ${_minIk!.toStringAsFixed(0)} A'
                            ' (${_charakteristik}${_nennstrom?.toStringAsFixed(0) ?? '?'}: '
                            '${_charakteristik == 'C' ? '10' : _charakteristik == 'D' ? '20' : '5'}×)'
                        : 'Kurzschlussstrom L-PE',
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_minIk != null) ...[
                    const SizedBox(height: 3),
                    Builder(builder: (ctx) {
                      final ik = double.tryParse(
                          _ikLpeCtrls[i].text.replaceAll(',', '.'));
                      if (ik == null) return const SizedBox.shrink();
                      final ok = ik >= _minIk!;
                      return _InlineCheck(
                        ok: ok,
                        label: ok
                            ? 'i.O. (≥ ${_minIk!.toStringAsFixed(0)} A)'
                            : 'Zu gering! Min. ${_minIk!.toStringAsFixed(0)} A',
                      );
                    }),
                  ],
                ] else ...[
                  _LimitField(
                    controller: _zsLpeCtrls[i],
                    label: 'Zs L-PE',
                    unit: 'Ω',
                    limitHint: _minIk != null
                        ? 'max. ${(230.0 / _minIk!).toStringAsFixed(3)} Ω'
                        : 'Schleifenimpedanz L-PE',
                    onChanged: (_) => setState(() {}),
                  ),
                ],
                const SizedBox(height: 8),

                // ── L-N ─────────────────────────────────────────────────
                _SubLabel('Phase–N (${_phaseLabels[i]}-N) – optional'),
                const SizedBox(height: 4),
                if (_useIk)
                  _LimitField(
                    controller: _ikLnCtrls[i],
                    label: 'Ik L-N',
                    unit: 'A',
                    limitHint: 'Kurzschlussstrom L-N (optional)',
                  )
                else
                  _LimitField(
                    controller: _zsLnCtrls[i],
                    label: 'Zs L-N',
                    unit: 'Ω',
                    limitHint: 'Schleifenimpedanz L-N (optional)',
                  ),
                const SizedBox(height: 8),

                // ── Isolation ────────────────────────────────────────────
                _LimitField(
                  controller: _isoCtrls[i],
                  label: _poleCount > 1
                      ? 'Isolationswiderstand ${_phaseLabels[i]}'
                      : 'Isolationswiderstand (optional)',
                  unit: 'MΩ',
                  limitHint: 'min. 1 MΩ',
                ),
              ],
            ),

          // ── L-L Messungen (nur 3-phasig) ─────────────────────────────────
          if (_showDrehfeld) ...[
            _SectionHeader('Kurzschluss Phase–Phase (L-L) – optional'),
            const SizedBox(height: 8),
            for (int j = 0; j < 3; j++) ...[
              _LimitField(
                controller: _ikLlCtrls[j],
                label: 'Ik ${_llPaare[j]}',
                unit: 'A',
                limitHint: 'Kurzschlussstrom Phase–Phase',
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
          ],

          // Drehfeld: nur bei 3-phasig sinnvoll
          if (_showDrehfeld) ...[
            const _SektionsHeader(
              label: 'Weitere Prüfungen',
              icon: Icons.more_outlined,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Drehfeldrichtung korrekt'),
              value: _drehfeldRichtig,
              onChanged: (v) => setState(() => _drehfeldRichtig = v),
            ),
          ],

          _LimitField(
            controller: _erdungCtrl,
            label: 'Erdungswiderstand (optional)',
            unit: 'Ω',
            limitHint: 'optional',
          ),
          const SizedBox(height: 12),
        ],

        // ── RCD-Prüfung (nur für RCD / FI-Typen) ───────────────────────────
        if (_isRcd) ...[
          const _SektionsHeader(
            label: 'RCD-Prüfung',
            icon: Icons.gpp_good_outlined,
          ),
          _SectionHeader('RCD-Prüfung'),
          const SizedBox(height: 8),

          // Nenn-I∆n — vorbelegt aus Komponente, aber editierbar
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _LimitField(
                  controller: _rcdNennCtrl,
                  label: 'Nenn-Differenzstrom I∆n',
                  unit: 'mA',
                  limitHint: _nennDifferenzstromFromKomponente != null
                      ? 'Aus Bauteil übernommen'
                      : 'Sollwert aus Typenschild',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (_nennDifferenzstromFromKomponente != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message:
                      'Aus Bauteil: ${_nennDifferenzstromFromKomponente} mA',
                  child: const Icon(Icons.auto_fix_high,
                      size: 18, color: AppColors.secondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Gemessener Auslösestrom mit dynamischem Bereich
          Builder(builder: (ctx) {
            final nenn =
                double.tryParse(_rcdNennCtrl.text.replaceAll(',', '.'));
            final minMa = nenn != null ? nenn * 0.5 : null;
            final hint = nenn != null
                ? '${minMa!.toStringAsFixed(1)}–${nenn.toStringAsFixed(1)} mA  '
                    '(50 %–100 % von ${nenn.toStringAsFixed(0)} mA I∆n)'
                : '50 %–100 % von I∆n';
            return _LimitField(
              controller: _rcdGemessenCtrl,
              label: 'Gemessener Auslösestrom I∆',
              unit: 'mA',
              limitHint: hint,
              onChanged: (_) => setState(() {}),
            );
          }),
          // Live-Indikator für Auslösestrom
          Builder(builder: (ctx) {
            final nenn =
                double.tryParse(_rcdNennCtrl.text.replaceAll(',', '.'));
            final gemessen =
                double.tryParse(_rcdGemessenCtrl.text.replaceAll(',', '.'));
            if (nenn == null || gemessen == null) return const SizedBox();
            final ok = gemessen >= nenn * 0.5 && gemessen <= nenn;
            return Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(
                    ok
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 14,
                    color: ok ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ok
                        ? 'Im gültigen Bereich (${(nenn * 0.5).toStringAsFixed(1)}–${nenn.toStringAsFixed(1)} mA)'
                        : gemessen > nenn
                            ? 'Zu hoch! Max. ${nenn.toStringAsFixed(1)} mA (= 100 % I∆n)'
                            : 'Zu niedrig! Min. ${(nenn * 0.5).toStringAsFixed(1)} mA (= 50 % I∆n)',
                    style: TextStyle(
                      fontSize: 11,
                      color: ok ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),

          _LimitField(
            controller: _rcdZeitCtrl,
            label: 'Auslösezeit',
            unit: 'ms',
            limitHint: 'max. 300 ms',
            onChanged: (_) => setState(() {}),
          ),
          // Live-Indikator für Auslösezeit
          Builder(builder: (ctx) {
            final zeit =
                double.tryParse(_rcdZeitCtrl.text.replaceAll(',', '.'));
            if (zeit == null) return const SizedBox();
            final ok = zeit <= 300;
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle_outline : Icons.cancel_outlined,
                    size: 14,
                    color: ok ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ok
                        ? 'Auslösezeit i.O. (${zeit.toStringAsFixed(0)} ms ≤ 300 ms)'
                        : 'Zu langsam! ${zeit.toStringAsFixed(0)} ms > 300 ms',
                    style: TextStyle(
                      fontSize: 11,
                      color: ok ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
        ],

        // Generischer Fallback wenn kein Typ bekannt
        if (!_isLs && !_isRcd) ...[
          _LimitField(
            controller: _zsLpeCtrls[0],
            label: 'Schleifenimpedanz Zs',
            unit: 'Ω',
            limitHint: 'gemessener Wert',
          ),
          const SizedBox(height: 12),
          _LimitField(
            controller: _isoCtrls[0],
            label: 'Isolationswiderstand',
            unit: 'MΩ',
            limitHint: 'min. 1 MΩ',
          ),
          const SizedBox(height: 12),
          _LimitField(
            controller: _rcdZeitCtrl,
            label: 'RCD-Auslösezeit (optional)',
            unit: 'ms',
            limitHint: 'max. 300 ms',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
        ],

        TextFormField(
          controller: _bemerkungCtrl,
          decoration: const InputDecoration(labelText: 'Bemerkung'),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        _ErgebnisBanner(ergebnis: _ergebnis),
        const SizedBox(height: 16),

        _SaveButton(isSaving: _isSaving, onPressed: _save),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final prueferName =
        ref.read(einstellungenProvider).valueOrNull?.prueferName;
    final messung = Messung(
      komponenteUuid: widget.komponenteUuid,
      norm: 'vde_0100',
      pruefungDatum: DateTime.now(),
      prueferName: prueferName?.isEmpty == false ? prueferName : null,
      ergebnis: _ergebnis,
      bemerkung: _bemerkungCtrl.text.trim().isEmpty
          ? null
          : _bemerkungCtrl.text.trim(),
      messwertJson: jsonEncode({
        if (_isLs) ...{
          'eingabemodus': _useIk ? 'kurzschlussstrom' : 'schleifenimpedanz',
          'mindest_ik_a': _minIk,
          'nennstrom_a': _nennstrom,
          'charakteristik': _charakteristik,
          'pole': _poleCount,
          'phasen': [
            for (int i = 0; i < _poleCount; i++)
              {
                'phase': _phaseLabels[i],
                // L-PE (Pflicht-Messung für Kurzschlussschutznachweis)
                if (_useIk) ...{
                  'kurzschlussstrom_a':
                      double.tryParse(_ikLpeCtrls[i].text.replaceAll(',', '.')),
                  'kurzschlussstrom_l_pe_a':
                      double.tryParse(_ikLpeCtrls[i].text.replaceAll(',', '.')),
                  if (_ikLnCtrls[i].text.isNotEmpty)
                    'kurzschlussstrom_l_n_a':
                        double.tryParse(_ikLnCtrls[i].text.replaceAll(',', '.')),
                } else ...{
                  'schleifenimpedanz_ohm':
                      double.tryParse(_zsLpeCtrls[i].text.replaceAll(',', '.')),
                  'schleifenimpedanz_l_pe_ohm':
                      double.tryParse(_zsLpeCtrls[i].text.replaceAll(',', '.')),
                  if (_zsLnCtrls[i].text.isNotEmpty)
                    'schleifenimpedanz_l_n_ohm':
                        double.tryParse(_zsLnCtrls[i].text.replaceAll(',', '.')),
                },
                'isolationswiderstand_mohm': double.tryParse(
                    _isoCtrls[i].text.replaceAll(',', '.')),
              }
          ],
          if (_showDrehfeld) ...{
            'drehfeld_richtig': _drehfeldRichtig,
            'l_l_messungen': [
              for (int j = 0; j < 3; j++)
                if (_ikLlCtrls[j].text.isNotEmpty)
                  {
                    'phasen': _llPaare[j],
                    'kurzschlussstrom_a': double.tryParse(
                        _ikLlCtrls[j].text.replaceAll(',', '.')),
                  }
            ],
          },
          'erdungswiderstand_ohm': _erdungCtrl.text.isEmpty
              ? null
              : double.tryParse(_erdungCtrl.text.replaceAll(',', '.')),
        },
        if (_isRcd) ...{
          'rcd_nenn_differenzstrom_ma':
              double.tryParse(_rcdNennCtrl.text.replaceAll(',', '.')),
          'rcd_gemessen_differenzstrom_ma':
              double.tryParse(_rcdGemessenCtrl.text.replaceAll(',', '.')),
          'rcd_ausloesezeit_ms':
              double.tryParse(_rcdZeitCtrl.text.replaceAll(',', '.')),
        },
        if (!_isLs && !_isRcd) ...{
          'schleifenimpedanz_ohm':
              double.tryParse(_zsLpeCtrls[0].text.replaceAll(',', '.')),
          'isolationswiderstand_mohm':
              double.tryParse(_isoCtrls[0].text.replaceAll(',', '.')),
          'rcd_ausloesezeit_ms': _rcdZeitCtrl.text.isEmpty
              ? null
              : double.tryParse(_rcdZeitCtrl.text.replaceAll(',', '.')),
        },
      }),
    );
    await ref.read(messungenRepositoryProvider).save(messung);
    if (mounted) widget.onSaved();
  }
}

// ── Kleine Hilfs-Widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _SektionsHeader extends StatelessWidget {
  const _SektionsHeader({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(width: 8),
        const Expanded(
            child: Divider(color: AppColors.outlineVariant, height: 1)),
      ]),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onPressed});
  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : onPressed,
        child: isSaving
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.onPrimary),
              )
            : const Text('Messung speichern'),
      ),
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.3,
          ),
    );
  }
}

class _InlineCheck extends StatelessWidget {
  const _InlineCheck({required this.ok, required this.label});
  final bool ok;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(
        ok ? Icons.check_circle_outline : Icons.cancel_outlined,
        size: 14,
        color: ok ? AppColors.success : AppColors.error,
      ),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11, color: ok ? AppColors.success : AppColors.error)),
    ]);
  }
}

// ── Phase Block ───────────────────────────────────────────────────────────────

/// Visueller Container für eine Phase (L1, L2, L3) — alternierende Farben
/// und farbige linke Kante zur klaren Trennung mehrphasiger Messungen.
class _PhaseBlock extends StatelessWidget {
  const _PhaseBlock({
    required this.label,
    required this.index,
    required this.showLabel,
    required this.children,
  });

  final String label;
  final int index;
  final bool showLabel;
  final List<Widget> children;

  static const _borderColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.tertiary,
  ];

  static const _bgColors = [
    AppColors.surfaceContainerLowest,
    AppColors.surfaceContainerLow,
    AppColors.surfaceContainerLowest,
  ];

  @override
  Widget build(BuildContext context) {
    final borderColor = _borderColors[index % _borderColors.length];
    final bgColor = _bgColors[index % _bgColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
            top: BorderSide(color: AppColors.outlineVariant, width: 0.5),
            right: BorderSide(color: AppColors.outlineVariant, width: 0.5),
            bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLabel) ...[
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: borderColor,
                ),
              ),
              const SizedBox(height: 10),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ErgebnisBanner extends StatelessWidget {
  const _ErgebnisBanner({required this.ergebnis});
  final String ergebnis;

  @override
  Widget build(BuildContext context) {
    final bool passed = ergebnis == 'bestanden';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:
            passed ? AppColors.successContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_outline : Icons.error_outline,
            color: passed ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            passed
                ? 'Auto-Bewertung: BESTANDEN'
                : 'Auto-Bewertung: NICHT BESTANDEN',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: passed ? AppColors.success : AppColors.error,
                ),
          ),
        ],
      ),
    );
  }
}

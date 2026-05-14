import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/messung.dart';
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
  late String _norm;

  // RCD-Typen messen anders als LS/Sicherungen
  bool get _isRcd =>
      widget.komponenteTyp == 'rcd';

  bool get _isLsOderSicherung =>
      const ['ls_schalter', 'vorsicherung', 'nh_sicherung', 'neozed', 'diazed']
          .contains(widget.komponenteTyp);

  bool get _isFiLs => widget.komponenteTyp == 'fi_ls';

  static const _normen = [
    ('vde_0701_0702', 'DIN VDE 0701-0702'),
    ('dguv_v3', 'DGUV V3'),
    ('vde_0100', 'DIN VDE 0100'),
  ];

  @override
  void initState() {
    super.initState();
    // RCD → direkt VDE 0100 vorauswählen
    if (_isRcd || _isFiLs) {
      _norm = 'vde_0100';
    } else {
      _norm = widget.existingMessung?.norm ?? 'vde_0701_0702';
    }
  }

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
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messung erfassen',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (widget.komponenteTyp != null)
                        Text(
                          _typLabel(widget.komponenteTyp!),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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

            // Norm-Auswahl — bei reinem RCD nur VDE 0100 zeigen
            if (!_isRcd) ...[
              Text(
                'Prüfnorm',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _normen.map((n) {
                  final selected = _norm == n.$1;
                  return ChoiceChip(
                    label: Text(n.$2),
                    selected: selected,
                    onSelected: (_) => setState(() => _norm = n.$1),
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Formular je Norm
            if (_norm == 'vde_0701_0702')
              _Vde07010702Form(
                komponenteUuid: widget.komponenteUuid,
                existingMessung: widget.existingMessung,
                onSaved: () => Navigator.pop(context),
              ),
            if (_norm == 'dguv_v3')
              _DguvV3Form(
                komponenteUuid: widget.komponenteUuid,
                existingMessung: widget.existingMessung,
                onSaved: () => Navigator.pop(context),
              ),
            if (_norm == 'vde_0100')
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
    this.initialValue,
  });

  final TextEditingController controller;
  final String label;
  final String unit;
  final String limitHint;
  final void Function(String)? onChanged;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    if (initialValue != null && controller.text.isEmpty) {
      controller.text = initialValue!;
    }
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

// ── DIN VDE 0701-0702 ─────────────────────────────────────────────────────────

class _Vde07010702Form extends ConsumerStatefulWidget {
  const _Vde07010702Form({
    required this.komponenteUuid,
    required this.existingMessung,
    required this.onSaved,
  });

  final String komponenteUuid;
  final Messung? existingMessung;
  final VoidCallback onSaved;

  @override
  ConsumerState<_Vde07010702Form> createState() => _Vde07010702FormState();
}

class _Vde07010702FormState extends ConsumerState<_Vde07010702Form> {
  final _formKey = GlobalKey<FormState>();
  final _prueferCtrl = TextEditingController();
  final _schutzleiterCtrl = TextEditingController();
  final _isolationCtrl = TextEditingController();
  final _ableitstromCtrl = TextEditingController();
  final _beruehrungCtrl = TextEditingController();
  final _bemerkungCtrl = TextEditingController();

  bool _messbereichsendwert = false;
  bool _funktionspruefung = false;
  String _schutzklasse = 'I';
  bool _isSaving = false;

  String get _ergebnis {
    final schutzleiter =
        double.tryParse(_schutzleiterCtrl.text.replaceAll(',', '.'));
    final isolation = _messbereichsendwert
        ? true
        : (double.tryParse(_isolationCtrl.text.replaceAll(',', '.')) ?? 0) >=
            1.0;
    final maxAbleit = _schutzklasse == 'I' ? 0.5 : 1.0;
    final ableitstrom =
        double.tryParse(_ableitstromCtrl.text.replaceAll(',', '.'));
    return _autoErgebnis({
      'schutzleiter': schutzleiter == null || schutzleiter <= 0.3,
      'isolation': isolation,
      'ableitstrom': ableitstrom == null || ableitstrom <= maxAbleit,
      'funktion': _funktionspruefung,
    });
  }

  @override
  void dispose() {
    _prueferCtrl.dispose();
    _schutzleiterCtrl.dispose();
    _isolationCtrl.dispose();
    _ableitstromCtrl.dispose();
    _beruehrungCtrl.dispose();
    _bemerkungCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _prueferCtrl,
            decoration: const InputDecoration(labelText: 'Prüfer'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _schutzklasse,
            decoration: const InputDecoration(labelText: 'Schutzklasse'),
            items: const [
              DropdownMenuItem(value: 'I', child: Text('Schutzklasse I')),
              DropdownMenuItem(value: 'II', child: Text('Schutzklasse II')),
            ],
            onChanged: (v) => setState(() => _schutzklasse = v!),
          ),
          const SizedBox(height: 12),
          _LimitField(
            controller: _schutzleiterCtrl,
            label: 'Schutzleiterwiderstand',
            unit: 'Ω',
            limitHint: 'max. 0,3 Ω',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _LimitField(
            controller: _isolationCtrl,
            label: 'Isolationswiderstand',
            unit: 'MΩ',
            limitHint: 'min. 1 MΩ',
            onChanged: (_) => setState(() {}),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Messbereichsendwert erreicht (> Messbereich)',
                style: TextStyle(fontSize: 13)),
            value: _messbereichsendwert,
            onChanged: (v) => setState(() => _messbereichsendwert = v!),
          ),
          const SizedBox(height: 8),
          _LimitField(
            controller: _ableitstromCtrl,
            label: 'Ableitstrom',
            unit: 'mA',
            limitHint: 'SK I: max. 0,5 mA  |  SK II: max. 1,0 mA',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _LimitField(
            controller: _beruehrungCtrl,
            label: 'Berührungsstrom (optional)',
            unit: 'mA',
            limitHint: 'optional',
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Funktionsprüfung bestanden'),
            value: _funktionspruefung,
            onChanged: (v) => setState(() => _funktionspruefung = v),
          ),
          const SizedBox(height: 12),
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
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messung = Messung(
      komponenteUuid: widget.komponenteUuid,
      norm: 'vde_0701_0702',
      pruefungDatum: DateTime.now(),
      prueferName:
          _prueferCtrl.text.trim().isEmpty ? null : _prueferCtrl.text.trim(),
      ergebnis: _ergebnis,
      bemerkung: _bemerkungCtrl.text.trim().isEmpty
          ? null
          : _bemerkungCtrl.text.trim(),
      messwertJson: jsonEncode({
        'schutzklasse': _schutzklasse,
        'schutzleiterwiderstand_ohm':
            double.tryParse(_schutzleiterCtrl.text.replaceAll(',', '.')),
        'isolationswiderstand_mohm': _messbereichsendwert
            ? null
            : double.tryParse(_isolationCtrl.text.replaceAll(',', '.')),
        'messbereichsendwert': _messbereichsendwert,
        'ableitstrom_ma':
            double.tryParse(_ableitstromCtrl.text.replaceAll(',', '.')),
        'beruehrungsstrom_ma': _beruehrungCtrl.text.isEmpty
            ? null
            : double.tryParse(_beruehrungCtrl.text.replaceAll(',', '.')),
        'funktionspruefung': _funktionspruefung,
      }),
    );
    await ref.read(messungenRepositoryProvider).save(messung);
    if (mounted) widget.onSaved();
  }
}

// ── DGUV V3 ───────────────────────────────────────────────────────────────────

class _DguvV3Form extends ConsumerStatefulWidget {
  const _DguvV3Form({
    required this.komponenteUuid,
    required this.existingMessung,
    required this.onSaved,
  });

  final String komponenteUuid;
  final Messung? existingMessung;
  final VoidCallback onSaved;

  @override
  ConsumerState<_DguvV3Form> createState() => _DguvV3FormState();
}

class _DguvV3FormState extends ConsumerState<_DguvV3Form> {
  final _prueferCtrl = TextEditingController();
  final _schutzleiterCtrl = TextEditingController();
  final _isolationCtrl = TextEditingController();
  final _ableitstromCtrl = TextEditingController();
  final _bemerkungCtrl = TextEditingController();
  bool _funktionspruefung = false;
  bool _isSaving = false;
  DateTime? _naechstePruefung;

  String get _ergebnis {
    final sl = double.tryParse(_schutzleiterCtrl.text.replaceAll(',', '.'));
    final iso = double.tryParse(_isolationCtrl.text.replaceAll(',', '.'));
    final ab = double.tryParse(_ableitstromCtrl.text.replaceAll(',', '.'));
    return _autoErgebnis({
      'schutzleiter': sl == null || sl <= 0.3,
      'isolation': iso == null || iso >= 1.0,
      'ableitstrom': ab == null || ab <= 0.5,
      'funktion': _funktionspruefung,
    });
  }

  @override
  void dispose() {
    _prueferCtrl.dispose();
    _schutzleiterCtrl.dispose();
    _isolationCtrl.dispose();
    _ableitstromCtrl.dispose();
    _bemerkungCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _prueferCtrl,
          decoration: const InputDecoration(labelText: 'Prüfer'),
        ),
        const SizedBox(height: 12),
        _LimitField(
          controller: _schutzleiterCtrl,
          label: 'Schutzleiterwiderstand',
          unit: 'Ω',
          limitHint: 'max. 0,3 Ω',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _LimitField(
          controller: _isolationCtrl,
          label: 'Isolationswiderstand',
          unit: 'MΩ',
          limitHint: 'min. 1 MΩ',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _LimitField(
          controller: _ableitstromCtrl,
          label: 'Ableitstrom',
          unit: 'mA',
          limitHint: 'max. 0,5 mA',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Funktionsprüfung bestanden'),
          value: _funktionspruefung,
          onChanged: (v) => setState(() => _funktionspruefung = v),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Nächste Prüfung'),
          subtitle: Text(
            _naechstePruefung == null
                ? 'Nicht gesetzt'
                : '${_naechstePruefung!.day.toString().padLeft(2, '0')}.${_naechstePruefung!.month.toString().padLeft(2, '0')}.${_naechstePruefung!.year}',
            style: AppTheme.dataMono(
                fontSize: 13, color: AppColors.onSurfaceVariant),
          ),
          trailing: OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (date != null) setState(() => _naechstePruefung = date);
            },
            icon: const Icon(Icons.calendar_today, size: 14),
            label: const Text('Datum wählen'),
          ),
        ),
        const SizedBox(height: 12),
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
    final messung = Messung(
      komponenteUuid: widget.komponenteUuid,
      norm: 'dguv_v3',
      pruefungDatum: DateTime.now(),
      prueferName:
          _prueferCtrl.text.trim().isEmpty ? null : _prueferCtrl.text.trim(),
      ergebnis: _ergebnis,
      bemerkung: _bemerkungCtrl.text.trim().isEmpty
          ? null
          : _bemerkungCtrl.text.trim(),
      messwertJson: jsonEncode({
        'schutzleiterwiderstand_ohm':
            double.tryParse(_schutzleiterCtrl.text.replaceAll(',', '.')),
        'isolationswiderstand_mohm':
            double.tryParse(_isolationCtrl.text.replaceAll(',', '.')),
        'ableitstrom_ma':
            double.tryParse(_ableitstromCtrl.text.replaceAll(',', '.')),
        'funktionspruefung': _funktionspruefung,
        'naechste_pruefung': _naechstePruefung?.toIso8601String(),
      }),
    );
    await ref.read(messungenRepositoryProvider).save(messung);
    if (mounted) widget.onSaved();
  }
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
  final _prueferCtrl = TextEditingController();
  final _zsCtrl = TextEditingController();          // Schleifenimpedanz Ω
  final _ikCtrl = TextEditingController();          // Kurzschlussstrom A
  final _isolationCtrl = TextEditingController();
  final _rcdNennCtrl = TextEditingController();     // Nenn-I∆n mA
  final _rcdGemessenCtrl = TextEditingController(); // Gemessener I∆n mA
  final _rcdZeitCtrl = TextEditingController();     // Auslösezeit ms
  final _erdungCtrl = TextEditingController();
  final _bemerkungCtrl = TextEditingController();

  bool _useIk = true;   // true = Kurzschlussstrom, false = Schleifenimpedanz
  bool _drehfeldRichtig = true;
  bool _isSaving = false;

  // ── Ableitbare Werte aus Komponenten-Eigenschaften ────────────────────────

  bool get _isRcd =>
      widget.komponenteTyp == 'rcd' || widget.komponenteTyp == 'fi_ls';

  bool get _isLs => const [
        'ls_schalter',
        'vorsicherung',
        'nh_sicherung',
        'neozed',
        'diazed',
        'hauptschalter',
        'fi_ls',
      ].contains(widget.komponenteTyp);

  /// Nennstrom aus Komponenten-Eigenschaften (für Ik-Mindestwert)
  double? get _nennstrom {
    final v = widget.komponenteEigenschaften?['nennstrom'];
    if (v == null) return null;
    return (v as num).toDouble();
  }

  /// Auslöse-Charakteristik B/C/D aus Komponente
  String get _charakteristik =>
      (widget.komponenteEigenschaften?['charakteristik'] as String?) ?? 'B';

  /// Berechneter Mindest-Kurzschlussstrom: Ik_min = Faktor × Nennstrom
  /// B: 5×, C: 10×, D: 20×
  double? get _minIk {
    final n = _nennstrom;
    if (n == null) return null;
    final faktor = _charakteristik == 'C'
        ? 10.0
        : _charakteristik == 'D'
            ? 20.0
            : 5.0;
    return n * faktor;
  }

  /// Nenn-Differenzstrom aus RCD-Komponente (z.B. "30" → 30 mA)
  String? get _nennDifferenzstromFromKomponente {
    final v = widget.komponenteEigenschaften?['auslösestrom'];
    if (v == null) return null;
    return v.toString();
  }

  @override
  void initState() {
    super.initState();
    // Nenn-I∆n aus Komponente vorbelegen
    final nennDiff = _nennDifferenzstromFromKomponente;
    if (nennDiff != null) {
      _rcdNennCtrl.text = nennDiff;
    }
  }

  String get _ergebnis {
    if (_isRcd && !_isLs) {
      // Nur RCD: Auslösezeit prüfen
      final zeit = double.tryParse(_rcdZeitCtrl.text.replaceAll(',', '.'));
      return _autoErgebnis({
        'rcd_ausloesezeit': zeit == null || zeit <= 300,
      });
    } else if (_isLs && !_isRcd) {
      // Nur LS/Sicherung: Kurzschlussstrom prüfen
      if (_useIk) {
        final ik = double.tryParse(_ikCtrl.text.replaceAll(',', '.'));
        final minIk = _minIk;
        return _autoErgebnis({
          'kurzschlussstrom':
              ik == null || minIk == null || ik >= minIk,
        });
      } else {
        // Zs — Umrechnung: Ik = 230 / Zs, dann Mindestwert prüfen
        final zs = double.tryParse(_zsCtrl.text.replaceAll(',', '.'));
        final minIk = _minIk;
        if (zs != null && zs > 0 && minIk != null) {
          final ikFromZs = 230.0 / zs;
          return _autoErgebnis({'kurzschlussstrom': ikFromZs >= minIk});
        }
        return 'bestanden';
      }
    } else {
      // Generisch (kein Typ bekannt oder Kombination)
      final zeit = double.tryParse(_rcdZeitCtrl.text.replaceAll(',', '.'));
      return _autoErgebnis({
        'rcd_ausloesezeit': zeit == null || zeit <= 300,
      });
    }
  }

  @override
  void dispose() {
    _prueferCtrl.dispose();
    _zsCtrl.dispose();
    _ikCtrl.dispose();
    _isolationCtrl.dispose();
    _rcdNennCtrl.dispose();
    _rcdGemessenCtrl.dispose();
    _rcdZeitCtrl.dispose();
    _erdungCtrl.dispose();
    _bemerkungCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _prueferCtrl,
          decoration: const InputDecoration(labelText: 'Prüfer'),
        ),
        const SizedBox(height: 16),

        // ── Schleifenimpedanz / Kurzschlussstrom (nur für LS/Sicherungen) ──
        if (_isLs) ...[
          _SectionHeader('Kurzschlussschutz'),
          const SizedBox(height: 8),

          // Toggle Zs ↔ Ik
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

          if (_useIk) ...[
            // Kurzschlussstrom
            _LimitField(
              controller: _ikCtrl,
              label: 'Kurzschlussstrom Ik',
              unit: 'A',
              limitHint: _minIk != null
                  ? 'min. ${_minIk!.toStringAsFixed(0)} A  '
                      '(${_charakteristik}${_nennstrom?.toStringAsFixed(0) ?? '?'}: '
                      '${_charakteristik == 'C' ? '10' : _charakteristik == 'D' ? '20' : '5'}× '
                      '${_nennstrom?.toStringAsFixed(0) ?? '?'} A)'
                  : 'gemessener Kurzschlussstrom',
              onChanged: (_) => setState(() {}),
            ),
            // Live-Anzeige ob ausreichend
            if (_minIk != null) ...[
              const SizedBox(height: 4),
              Builder(builder: (ctx) {
                final ik =
                    double.tryParse(_ikCtrl.text.replaceAll(',', '.'));
                if (ik == null) return const SizedBox();
                final ok = ik >= _minIk!;
                return Row(
                  children: [
                    Icon(
                      ok ? Icons.check_circle_outline : Icons.cancel_outlined,
                      size: 14,
                      color: ok ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ok
                          ? 'Ausreichend (≥ ${_minIk!.toStringAsFixed(0)} A)'
                          : 'Zu gering! Mindestens ${_minIk!.toStringAsFixed(0)} A erforderlich',
                      style: TextStyle(
                        fontSize: 11,
                        color: ok ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ] else ...[
            // Schleifenimpedanz
            _LimitField(
              controller: _zsCtrl,
              label: 'Schleifenimpedanz Zs',
              unit: 'Ω',
              limitHint: _minIk != null
                  ? 'max. ${(230.0 / _minIk!).toStringAsFixed(3)} Ω  '
                      '(= 230 V ÷ ${_minIk!.toStringAsFixed(0)} A)'
                  : 'gemessener Wert',
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 12),

          _LimitField(
            controller: _isolationCtrl,
            label: 'Isolationswiderstand (optional)',
            unit: 'MΩ',
            limitHint: 'min. 1 MΩ',
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Drehfeldrichtung korrekt (optional)'),
            value: _drehfeldRichtig,
            onChanged: (v) => setState(() => _drehfeldRichtig = v),
          ),
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
                ),
              ),
              if (_nennDifferenzstromFromKomponente != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message:
                      'Aus Bauteil-Eigenschaften übernommen: ${_nennDifferenzstromFromKomponente} mA',
                  child: const Icon(
                    Icons.auto_fix_high,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          _LimitField(
            controller: _rcdGemessenCtrl,
            label: 'Gemessener Auslösestrom I∆',
            unit: 'mA',
            limitHint: 'Istwert — sollte ≤ I∆n sein',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          _LimitField(
            controller: _rcdZeitCtrl,
            label: 'Auslösezeit',
            unit: 'ms',
            limitHint: 'max. 300 ms (allgemein) / 40 ms (erhöhte Anforderung)',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
        ],

        // Generischer Fallback wenn kein Typ bekannt
        if (!_isLs && !_isRcd) ...[
          _LimitField(
            controller: _zsCtrl,
            label: 'Schleifenimpedanz Zs',
            unit: 'Ω',
            limitHint: 'gemessener Wert',
          ),
          const SizedBox(height: 12),
          _LimitField(
            controller: _isolationCtrl,
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
    final messung = Messung(
      komponenteUuid: widget.komponenteUuid,
      norm: 'vde_0100',
      pruefungDatum: DateTime.now(),
      prueferName:
          _prueferCtrl.text.trim().isEmpty ? null : _prueferCtrl.text.trim(),
      ergebnis: _ergebnis,
      bemerkung: _bemerkungCtrl.text.trim().isEmpty
          ? null
          : _bemerkungCtrl.text.trim(),
      messwertJson: jsonEncode({
        if (_isLs) ...{
          'eingabemodus': _useIk ? 'kurzschlussstrom' : 'schleifenimpedanz',
          if (_useIk)
            'kurzschlussstrom_a':
                double.tryParse(_ikCtrl.text.replaceAll(',', '.')),
          if (!_useIk)
            'schleifenimpedanz_ohm':
                double.tryParse(_zsCtrl.text.replaceAll(',', '.')),
          'mindest_ik_a': _minIk,
          'nennstrom_a': _nennstrom,
          'charakteristik': _charakteristik,
          'isolationswiderstand_mohm':
              double.tryParse(_isolationCtrl.text.replaceAll(',', '.')),
          'drehfeld_richtig': _drehfeldRichtig,
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
              double.tryParse(_zsCtrl.text.replaceAll(',', '.')),
          'isolationswiderstand_mohm':
              double.tryParse(_isolationCtrl.text.replaceAll(',', '.')),
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

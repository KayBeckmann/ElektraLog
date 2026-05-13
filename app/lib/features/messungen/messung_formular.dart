import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/messung.dart';
import '../../core/providers/messungen_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';

// ── Public entry point ────────────────────────────────────────────────────────

class MessungFormular extends ConsumerStatefulWidget {
  const MessungFormular({
    super.key,
    required this.komponenteUuid,
    this.existingMessung,
  });

  final String komponenteUuid;
  final Messung? existingMessung;

  @override
  ConsumerState<MessungFormular> createState() => _MessungFormularState();
}

class _MessungFormularState extends ConsumerState<MessungFormular> {
  String _norm = 'vde_0701_0702';

  static const _normen = [
    ('vde_0701_0702', 'DIN VDE 0701-0702'),
    ('dguv_v3', 'DGUV V3'),
    ('vde_0100', 'DIN VDE 0100'),
  ];

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
                Text(
                  'Messung hinzufügen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Norm-Auswahl
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

            // Dynamic form based on selected norm
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
              ),
          ],
        ),
      ),
    );
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
        helperStyle: TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
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
  ConsumerState<_Vde07010702Form> createState() =>
      _Vde07010702FormState();
}

class _Vde07010702FormState
    extends ConsumerState<_Vde07010702Form> {
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
        : (double.tryParse(_isolationCtrl.text.replaceAll(',', '.')) ??
                0) >=
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
    final ergebnis = _ergebnis;

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

          // Schutzklasse
          DropdownButtonFormField<String>(
            value: _schutzklasse,
            decoration:
                const InputDecoration(labelText: 'Schutzklasse'),
            items: const [
              DropdownMenuItem(value: 'I', child: Text('Schutzklasse I')),
              DropdownMenuItem(
                  value: 'II', child: Text('Schutzklasse II')),
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
            title: const Text(
              'Messbereichsendwert erreicht (> Messbereich)',
              style: TextStyle(fontSize: 13),
            ),
            value: _messbereichsendwert,
            onChanged: (v) =>
                setState(() => _messbereichsendwert = v!),
          ),
          const SizedBox(height: 8),

          _LimitField(
            controller: _ableitstromCtrl,
            label: 'Ableitstrom',
            unit: 'mA',
            limitHint:
                'SK I: max. 0,5 mA  |  SK II: max. 1,0 mA',
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
            onChanged: (v) =>
                setState(() => _funktionspruefung = v),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _bemerkungCtrl,
            decoration: const InputDecoration(labelText: 'Bemerkung'),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Auto-Ergebnis Banner
          _ErgebnisBanner(ergebnis: ergebnis),
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
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Text('Messung speichern'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messung = Messung()
      ..uuid = const Uuid().v4()
      ..komponenteUuid = widget.komponenteUuid
      ..norm = 'vde_0701_0702'
      ..pruefungDatum = DateTime.now()
      ..prueferName = _prueferCtrl.text.trim().isEmpty
          ? null
          : _prueferCtrl.text.trim()
      ..ergebnis = _ergebnis
      ..bemerkung = _bemerkungCtrl.text.trim().isEmpty
          ? null
          : _bemerkungCtrl.text.trim()
      ..erstelltAm = DateTime.now()
      ..messwertJson = jsonEncode({
        'schutzklasse': _schutzklasse,
        'schutzleiterwiderstand_ohm':
            double.tryParse(_schutzleiterCtrl.text.replaceAll(',', '.')),
        'isolationswiderstand_mohm': _messbereichsendwert
            ? null
            : double.tryParse(
                _isolationCtrl.text.replaceAll(',', '.')),
        'messbereichsendwert': _messbereichsendwert,
        'ableitstrom_ma':
            double.tryParse(_ableitstromCtrl.text.replaceAll(',', '.')),
        'beruehrungsstrom_ma': _beruehrungCtrl.text.isEmpty
            ? null
            : double.tryParse(
                _beruehrungCtrl.text.replaceAll(',', '.')),
        'funktionspruefung': _funktionspruefung,
      });

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
    final iso =
        double.tryParse(_isolationCtrl.text.replaceAll(',', '.'));
    final ab =
        double.tryParse(_ableitstromCtrl.text.replaceAll(',', '.'));
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

        // Nächste Prüfung
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
                initialDate: DateTime.now()
                    .add(const Duration(days: 365)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now()
                    .add(const Duration(days: 365 * 5)),
              );
              if (date != null) {
                setState(() => _naechstePruefung = date);
              }
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

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Messung speichern'),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messung = Messung()
      ..uuid = const Uuid().v4()
      ..komponenteUuid = widget.komponenteUuid
      ..norm = 'dguv_v3'
      ..pruefungDatum = DateTime.now()
      ..prueferName = _prueferCtrl.text.trim().isEmpty
          ? null
          : _prueferCtrl.text.trim()
      ..ergebnis = _ergebnis
      ..bemerkung = _bemerkungCtrl.text.trim().isEmpty
          ? null
          : _bemerkungCtrl.text.trim()
      ..erstelltAm = DateTime.now()
      ..messwertJson = jsonEncode({
        'schutzleiterwiderstand_ohm':
            double.tryParse(_schutzleiterCtrl.text.replaceAll(',', '.')),
        'isolationswiderstand_mohm':
            double.tryParse(_isolationCtrl.text.replaceAll(',', '.')),
        'ableitstrom_ma':
            double.tryParse(_ableitstromCtrl.text.replaceAll(',', '.')),
        'funktionspruefung': _funktionspruefung,
        'naechste_pruefung': _naechstePruefung?.toIso8601String(),
      });

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
  });

  final String komponenteUuid;
  final Messung? existingMessung;
  final VoidCallback onSaved;

  @override
  ConsumerState<_Vde0100Form> createState() => _Vde0100FormState();
}

class _Vde0100FormState extends ConsumerState<_Vde0100Form> {
  final _prueferCtrl = TextEditingController();
  final _schleifenimpedanzCtrl = TextEditingController();
  final _isolationCtrl = TextEditingController();
  final _rcdAusloeseStromCtrl = TextEditingController();
  final _rcdNennAusloeseStromCtrl = TextEditingController();
  final _rcdAusloeseZeitCtrl = TextEditingController();
  final _erdungCtrl = TextEditingController();
  final _bemerkungCtrl = TextEditingController();
  bool _drehfeldRichtig = true;
  bool _isSaving = false;

  String get _ergebnis {
    final rcdZeit = double.tryParse(
        _rcdAusloeseZeitCtrl.text.replaceAll(',', '.'));
    return _autoErgebnis({
      'rcd_ausloesezeit': rcdZeit == null || rcdZeit <= 300,
    });
  }

  @override
  void dispose() {
    _prueferCtrl.dispose();
    _schleifenimpedanzCtrl.dispose();
    _isolationCtrl.dispose();
    _rcdAusloeseStromCtrl.dispose();
    _rcdNennAusloeseStromCtrl.dispose();
    _rcdAusloeseZeitCtrl.dispose();
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
        const SizedBox(height: 12),

        _LimitField(
          controller: _schleifenimpedanzCtrl,
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

        Text(
          'RCD-Prüfung',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: _LimitField(
                controller: _rcdNennAusloeseStromCtrl,
                label: 'Nenn-I∆n',
                unit: 'mA',
                limitHint: 'Sollwert',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LimitField(
                controller: _rcdAusloeseStromCtrl,
                label: 'Gemessener I∆n',
                unit: 'mA',
                limitHint: 'Istwert',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _LimitField(
          controller: _rcdAusloeseZeitCtrl,
          label: 'RCD-Auslösezeit',
          unit: 'ms',
          limitHint: 'max. 300 ms',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Drehfeldrichtung korrekt (optional)'),
          value: _drehfeldRichtig,
          onChanged: (v) =>
              setState(() => _drehfeldRichtig = v),
        ),

        _LimitField(
          controller: _erdungCtrl,
          label: 'Erdungswiderstand (optional)',
          unit: 'Ω',
          limitHint: 'optional',
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

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Messung speichern'),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final messung = Messung()
      ..uuid = const Uuid().v4()
      ..komponenteUuid = widget.komponenteUuid
      ..norm = 'vde_0100'
      ..pruefungDatum = DateTime.now()
      ..prueferName = _prueferCtrl.text.trim().isEmpty
          ? null
          : _prueferCtrl.text.trim()
      ..ergebnis = _ergebnis
      ..bemerkung = _bemerkungCtrl.text.trim().isEmpty
          ? null
          : _bemerkungCtrl.text.trim()
      ..erstelltAm = DateTime.now()
      ..messwertJson = jsonEncode({
        'schleifenimpedanz_ohm': double.tryParse(
            _schleifenimpedanzCtrl.text.replaceAll(',', '.')),
        'isolationswiderstand_mohm':
            double.tryParse(_isolationCtrl.text.replaceAll(',', '.')),
        'rcd_nenn_auslösestrom_ma': double.tryParse(
            _rcdNennAusloeseStromCtrl.text.replaceAll(',', '.')),
        'rcd_gemessen_auslösestrom_ma': double.tryParse(
            _rcdAusloeseStromCtrl.text.replaceAll(',', '.')),
        'rcd_auslösezeit_ms': double.tryParse(
            _rcdAusloeseZeitCtrl.text.replaceAll(',', '.')),
        'drehfeld_richtig': _drehfeldRichtig,
        'erdungswiderstand_ohm': _erdungCtrl.text.isEmpty
            ? null
            : double.tryParse(_erdungCtrl.text.replaceAll(',', '.')),
      });

    await ref.read(messungenRepositoryProvider).save(messung);
    if (mounted) widget.onSaved();
  }
}

// ── Ergebnis Banner ───────────────────────────────────────────────────────────

class _ErgebnisBanner extends StatelessWidget {
  const _ErgebnisBanner({required this.ergebnis});

  final String ergebnis;

  @override
  Widget build(BuildContext context) {
    final bool passed = ergebnis == 'bestanden';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: passed
            ? AppColors.successContainer
            : AppColors.errorContainer,
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

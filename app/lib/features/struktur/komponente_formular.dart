import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/verteiler_komponente.dart';
import '../../core/providers/komponenten_provider.dart';
import '../../shared/theme/app_colors.dart';

class KomponenteFormular extends ConsumerStatefulWidget {
  const KomponenteFormular({
    super.key,
    required this.verteilerUuid,
    this.parentUuid,
    this.existingKomponente,
  });

  final String verteilerUuid;
  final String? parentUuid;
  final VerteilerKomponente? existingKomponente;

  @override
  ConsumerState<KomponenteFormular> createState() =>
      _KomponenteFormularState();
}

class _KomponenteFormularState
    extends ConsumerState<KomponenteFormular> {
  final _formKey = GlobalKey<FormState>();
  final _bezeichnungCtrl = TextEditingController();
  final _nennstromCtrl = TextEditingController();
  final _poleCtrl = TextEditingController();

  String _typ = 'ls_schalter';
  String? _charakteristik;
  String? _ausloeseStrom;
  String? _rcdTyp;
  String? _nhGroesse;
  bool _isSaving = false;

  static const _typen = [
    ('ls_schalter', 'LS-Schalter'),
    ('rcd', 'RCD (FI-Schalter)'),
    ('fi_ls', 'FI/LS-Kombination'),
    ('hauptschalter', 'Hauptschalter'),
    ('vorsicherung', 'Vorsicherung'),
    ('nh_sicherung', 'NH-Sicherung'),
    ('ueberspannung', 'Überspannungsschutz'),
    ('sammelschiene', 'Sammelschiene'),
    ('sonstige', 'Sonstige'),
  ];

  static const _charakteristiken = ['B', 'C', 'D'];
  static const _ausloeseStromOpts = ['10', '30', '100', '300'];
  static const _rcdTypen = ['A', 'B', 'F'];
  static const _nhGroessen = ['000', '00', '1', '2', '3'];

  @override
  void initState() {
    super.initState();
    final k = widget.existingKomponente;
    if (k != null) {
      _typ = k.typ;
      _bezeichnungCtrl.text = k.bezeichnung;
      if (k.eigenschaftenJson != null) {
        final data =
            jsonDecode(k.eigenschaftenJson!) as Map<String, dynamic>;
        _nennstromCtrl.text =
            (data['nennstrom'] as num?)?.toString() ?? '';
        _poleCtrl.text = (data['pole'] as num?)?.toString() ?? '';
        _charakteristik = data['charakteristik'] as String?;
        _ausloeseStrom = data['auslösestrom'] as String?;
        _rcdTyp = data['rcdTyp'] as String?;
        _nhGroesse = data['nhGroesse'] as String?;
      }
    }
  }

  @override
  void dispose() {
    _bezeichnungCtrl.dispose();
    _nennstromCtrl.dispose();
    _poleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingKomponente != null;
    final showCharakteristik =
        _typ == 'ls_schalter' || _typ == 'vorsicherung';
    final showAusloeseStrom = _typ == 'rcd' || _typ == 'fi_ls';
    final showRcdTyp = _typ == 'rcd' || _typ == 'fi_ls';
    final showNhGroesse = _typ == 'nh_sicherung';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEditing
                        ? 'Komponente bearbeiten'
                        : 'Neue Komponente',
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

              // ── Typ ─────────────────────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _typ,
                decoration: const InputDecoration(labelText: 'Typ *'),
                items: _typen
                    .map((e) => DropdownMenuItem(
                          value: e.$1,
                          child: Text(e.$2),
                        ))
                    .toList(),
                onChanged: (v) => setState(() {
                  _typ = v!;
                  _charakteristik = null;
                  _ausloeseStrom = null;
                  _rcdTyp = null;
                  _nhGroesse = null;
                }),
              ),
              const SizedBox(height: 12),

              // ── Bezeichnung ──────────────────────────────────────────────
              TextFormField(
                controller: _bezeichnungCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bezeichnung *',
                  hintText: 'z.B. L1, Licht EG, Klimaanlage',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
              ),
              const SizedBox(height: 12),

              // ── Nennstrom ────────────────────────────────────────────────
              TextFormField(
                controller: _nennstromCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nennstrom (A)',
                  hintText: 'z.B. 16',
                  suffixText: 'A',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.]')),
                ],
                textInputAction: TextInputAction.next,
                minLines: 1,
                maxLines: 1,
              ),
              const SizedBox(height: 12),

              // ── Pole ─────────────────────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _poleCtrl.text.isEmpty ? null : _poleCtrl.text,
                decoration:
                    const InputDecoration(labelText: 'Pole'),
                items: ['1', '2', '3', '4']
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text('$e-polig'),
                        ))
                    .toList(),
                onChanged: (v) => _poleCtrl.text = v ?? '',
              ),
              const SizedBox(height: 12),

              // ── Charakteristik (LS / Vorsicherung) ───────────────────────
              if (showCharakteristik) ...[
                DropdownButtonFormField<String>(
                  value: _charakteristik,
                  decoration: const InputDecoration(
                      labelText: 'Charakteristik'),
                  items: _charakteristiken
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('Typ $e'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _charakteristik = v),
                ),
                const SizedBox(height: 12),
              ],

              // ── Auslösestrom (RCD / FI-LS) ───────────────────────────────
              if (showAusloeseStrom) ...[
                DropdownButtonFormField<String>(
                  value: _ausloeseStrom,
                  decoration: const InputDecoration(
                      labelText: 'Auslösestrom I∆n'),
                  items: _ausloeseStromOpts
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('$e mA'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _ausloeseStrom = v),
                ),
                const SizedBox(height: 12),
              ],

              // ── RCD-Typ (RCD / FI-LS) ────────────────────────────────────
              if (showRcdTyp) ...[
                DropdownButtonFormField<String>(
                  value: _rcdTyp,
                  decoration:
                      const InputDecoration(labelText: 'RCD-Typ'),
                  items: _rcdTypen
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('Typ $e'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _rcdTyp = v),
                ),
                const SizedBox(height: 12),
              ],

              // ── NH-Größe ─────────────────────────────────────────────────
              if (showNhGroesse) ...[
                DropdownButtonFormField<String>(
                  value: _nhGroesse,
                  decoration:
                      const InputDecoration(labelText: 'NH-Größe'),
                  items: _nhGroessen
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text('Größe $e'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _nhGroesse = v),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 12),

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
                      : Text(isEditing
                          ? 'Speichern'
                          : 'Komponente anlegen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final existing = widget.existingKomponente;
    final bezeichnung = _bezeichnungCtrl.text.trim();

    final eigenschaften = <String, dynamic>{};
    if (_nennstromCtrl.text.isNotEmpty) {
      eigenschaften['nennstrom'] =
          double.tryParse(_nennstromCtrl.text) ?? _nennstromCtrl.text;
    }
    if (_poleCtrl.text.isNotEmpty) {
      eigenschaften['pole'] = int.tryParse(_poleCtrl.text);
    }
    if (_charakteristik != null) {
      eigenschaften['charakteristik'] = _charakteristik;
    }
    if (_ausloeseStrom != null) {
      eigenschaften['auslösestrom'] = _ausloeseStrom;
    }
    if (_rcdTyp != null) {
      eigenschaften['rcdTyp'] = _rcdTyp;
    }
    if (_nhGroesse != null) {
      eigenschaften['nhGroesse'] = _nhGroesse;
    }
    final eigenschaftenJson =
        eigenschaften.isEmpty ? null : jsonEncode(eigenschaften);

    final VerteilerKomponente k;
    if (existing != null) {
      k = VerteilerKomponente(
        uuid: existing.uuid,
        verteilerUuid: existing.verteilerUuid,
        parentUuid: existing.parentUuid,
        typ: _typ,
        bezeichnung: bezeichnung,
        position: existing.position,
        eigenschaftenJson: eigenschaftenJson,
        erstelltAm: existing.erstelltAm,
      );
    } else {
      k = VerteilerKomponente(
        verteilerUuid: widget.verteilerUuid,
        parentUuid: widget.parentUuid,
        typ: _typ,
        bezeichnung: bezeichnung,
        eigenschaftenJson: eigenschaftenJson,
      );
    }

    await ref.read(komponentenRepositoryProvider).save(k);

    if (mounted) Navigator.pop(context);
  }
}

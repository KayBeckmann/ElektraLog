import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/verteiler.dart';
import '../../core/providers/verteiler_provider.dart';
import '../../shared/theme/app_colors.dart';

class VerteilerFormular extends ConsumerStatefulWidget {
  const VerteilerFormular({
    super.key,
    required this.standortUuid,
    this.existingVerteiler,
  });

  final String standortUuid;
  final Verteiler? existingVerteiler;

  @override
  ConsumerState<VerteilerFormular> createState() =>
      _VerteilerFormularState();
}

class _VerteilerFormularState extends ConsumerState<VerteilerFormular> {
  final _formKey = GlobalKey<FormState>();
  final _bezeichnungCtrl = TextEditingController();
  final _bemerkungCtrl = TextEditingController();

  String _netzform = 'TN-S';
  String _nennspannung = '400V';
  String _frequenz = '50Hz';
  String _aussenleiter = '3';
  bool _isSaving = false;

  static const _netzformen = ['TN-C', 'TN-S', 'TN-CS', 'TT', 'IT'];
  static const _spannungen = ['230V', '400V'];
  static const _frequenzen = ['50Hz'];
  static const _aussenleiterOpts = ['1', '3'];

  @override
  void initState() {
    super.initState();
    final v = widget.existingVerteiler;
    if (v != null) {
      _bezeichnungCtrl.text = v.bezeichnung;
      _bemerkungCtrl.text = v.bemerkung ?? '';
      if (v.anlagendatenJson != null) {
        final data =
            jsonDecode(v.anlagendatenJson!) as Map<String, dynamic>;
        _netzform = data['netzform'] as String? ?? _netzform;
        _nennspannung = data['nennspannung'] as String? ?? _nennspannung;
        _frequenz = data['frequenz'] as String? ?? _frequenz;
        _aussenleiter = data['aussenleiter'] as String? ?? _aussenleiter;
      }
    }
  }

  @override
  void dispose() {
    _bezeichnungCtrl.dispose();
    _bemerkungCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingVerteiler != null;

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
                    isEditing ? 'Verteiler bearbeiten' : 'Neuer Verteiler',
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

              TextFormField(
                controller: _bezeichnungCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bezeichnung *',
                  hintText: 'z.B. Hauptverteiler EG, UV Büro 1',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _bemerkungCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bemerkung',
                  hintText: 'Optionale Anmerkungen',
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),

              // ── Anlagendaten ──────────────────────────────────────────
              Text(
                'Anlagendaten',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),

              // Netzform
              DropdownButtonFormField<String>(
                value: _netzform,
                decoration: const InputDecoration(labelText: 'Netzform'),
                items: _netzformen
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _netzform = v!),
              ),
              const SizedBox(height: 12),

              // Nennspannung
              DropdownButtonFormField<String>(
                value: _nennspannung,
                decoration:
                    const InputDecoration(labelText: 'Nennspannung'),
                items: _spannungen
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _nennspannung = v!),
              ),
              const SizedBox(height: 12),

              // Frequenz
              DropdownButtonFormField<String>(
                value: _frequenz,
                decoration: const InputDecoration(labelText: 'Frequenz'),
                items: _frequenzen
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _frequenz = v!),
              ),
              const SizedBox(height: 12),

              // Außenleiter
              DropdownButtonFormField<String>(
                value: _aussenleiter,
                decoration:
                    const InputDecoration(labelText: 'Außenleiter'),
                items: _aussenleiterOpts
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _aussenleiter = v!),
              ),
              const SizedBox(height: 24),

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
                      : Text(
                          isEditing ? 'Speichern' : 'Verteiler anlegen'),
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

    final existing = widget.existingVerteiler;
    final bezeichnung = _bezeichnungCtrl.text.trim();
    final bemerkung = _bemerkungCtrl.text.trim().isEmpty
        ? null
        : _bemerkungCtrl.text.trim();
    final anlagendatenJson = jsonEncode({
      'netzform': _netzform,
      'nennspannung': _nennspannung,
      'frequenz': _frequenz,
      'aussenleiter': _aussenleiter,
    });

    final Verteiler verteiler;
    if (existing != null) {
      verteiler = Verteiler(
        uuid: existing.uuid,
        standortUuid: existing.standortUuid,
        bezeichnung: bezeichnung,
        bemerkung: bemerkung,
        anlagendatenJson: anlagendatenJson,
        erstelltAm: existing.erstelltAm,
      );
    } else {
      verteiler = Verteiler(
        standortUuid: widget.standortUuid,
        bezeichnung: bezeichnung,
        bemerkung: bemerkung,
        anlagendatenJson: anlagendatenJson,
      );
    }

    await ref.read(verteilerRepositoryProvider).save(verteiler);

    if (mounted) Navigator.pop(context);
  }
}

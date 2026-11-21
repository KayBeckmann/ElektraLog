import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/standort.dart';
import '../../core/providers/standorte_provider.dart';
import '../../shared/email.dart';
import '../../shared/theme/app_colors.dart';

class StandortFormular extends ConsumerStatefulWidget {
  const StandortFormular({
    super.key,
    required this.kundeUuid,
    this.existingStandort,
  });

  final String kundeUuid;
  final Standort? existingStandort;

  @override
  ConsumerState<StandortFormular> createState() => _StandortFormularState();
}

class _StandortFormularState extends ConsumerState<StandortFormular> {
  final _formKey = GlobalKey<FormState>();
  final _bezeichnungCtrl = TextEditingController();
  final _strasseCtrl = TextEditingController();
  final _plzCtrl = TextEditingController();
  final _ortCtrl = TextEditingController();
  final _kontaktPersonCtrl = TextEditingController();
  final _kontaktEmailCtrl = TextEditingController();
  final _kontaktTelefonCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existingStandort;
    if (s != null) {
      _bezeichnungCtrl.text = s.bezeichnung;
      _strasseCtrl.text = s.strasse ?? '';
      _plzCtrl.text = s.plz ?? '';
      _ortCtrl.text = s.ort ?? '';
      _kontaktPersonCtrl.text = s.kontaktPerson ?? '';
      _kontaktEmailCtrl.text = s.kontaktEmail ?? '';
      _kontaktTelefonCtrl.text = s.kontaktTelefon ?? '';
    }
  }

  @override
  void dispose() {
    _bezeichnungCtrl.dispose();
    _strasseCtrl.dispose();
    _plzCtrl.dispose();
    _ortCtrl.dispose();
    _kontaktPersonCtrl.dispose();
    _kontaktEmailCtrl.dispose();
    _kontaktTelefonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingStandort != null;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEditing ? 'Standort bearbeiten' : 'Neuer Standort',
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
                  hintText: 'z.B. Hauptgebäude, Halle 2',
                ),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Bezeichnung ist ein Pflichtfeld';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _strasseCtrl,
                decoration: const InputDecoration(
                  labelText: 'Straße',
                  hintText: 'Musterstraße 1',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _plzCtrl,
                      decoration: const InputDecoration(
                        labelText: 'PLZ',
                        hintText: '12345',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _ortCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ort',
                        hintText: 'Berlin',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Eigener Kontakt des Standorts — wird nicht vom Kunden
              // übernommen; die E-Mail ist der Vorschlag beim Protokollversand.
              Text(
                'Kontakt vor Ort',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('standort-kontakt-person'),
                controller: _kontaktPersonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kontaktperson',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                  hintText: 'Vor- und Nachname',
                ),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('standort-kontakt-email'),
                controller: _kontaktEmailCtrl,
                validator: optionaleEmailPruefen,
                decoration: const InputDecoration(
                  labelText: 'E-Mail des Standorts',
                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                  hintText: 'haustechnik@example.de',
                  helperText: 'Empfängervorschlag für Prüfprotokolle',
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('standort-kontakt-telefon'),
                controller: _kontaktTelefonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                  hintText: '+49 30 123456',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
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
                      : Text(isEditing ? 'Speichern' : 'Standort anlegen'),
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

    final existing = widget.existingStandort;
    final bezeichnung = _bezeichnungCtrl.text.trim();
    final strasse =
        _strasseCtrl.text.trim().isEmpty ? null : _strasseCtrl.text.trim();
    final plz = _plzCtrl.text.trim().isEmpty ? null : _plzCtrl.text.trim();
    final ort = _ortCtrl.text.trim().isEmpty ? null : _ortCtrl.text.trim();
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    final Standort standort;
    if (existing != null) {
      standort = Standort(
        uuid: existing.uuid,
        kundeUuid: existing.kundeUuid,
        bezeichnung: bezeichnung,
        strasse: strasse,
        plz: plz,
        ort: ort,
        kontaktPerson: optional(_kontaktPersonCtrl),
        kontaktEmail: optional(_kontaktEmailCtrl),
        kontaktTelefon: optional(_kontaktTelefonCtrl),
        erstelltAm: existing.erstelltAm,
      );
    } else {
      standort = Standort(
        kundeUuid: widget.kundeUuid,
        bezeichnung: bezeichnung,
        strasse: strasse,
        plz: plz,
        ort: ort,
        kontaktPerson: optional(_kontaktPersonCtrl),
        kontaktEmail: optional(_kontaktEmailCtrl),
        kontaktTelefon: optional(_kontaktTelefonCtrl),
      );
    }

    await ref.read(standorteRepositoryProvider).save(standort);

    if (mounted) Navigator.pop(context);
  }
}

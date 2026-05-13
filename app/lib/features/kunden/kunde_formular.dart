import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/kunde.dart';
import '../../core/providers/kunden_provider.dart';
import '../../shared/theme/app_colors.dart';

class KundeFormular extends ConsumerStatefulWidget {
  const KundeFormular({super.key, this.existingKunde});

  final Kunde? existingKunde;

  @override
  ConsumerState<KundeFormular> createState() => _KundeFormularState();
}

class _KundeFormularState extends ConsumerState<KundeFormular> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _strasseCtrl = TextEditingController();
  final _plzCtrl = TextEditingController();
  final _ortCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final k = widget.existingKunde;
    if (k != null) {
      _nameCtrl.text = k.name;
      _strasseCtrl.text = k.strasse ?? '';
      _plzCtrl.text = k.plz ?? '';
      _ortCtrl.text = k.ort ?? '';
      _emailCtrl.text = k.kontaktEmail ?? '';
      _telefonCtrl.text = k.kontaktTelefon ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _strasseCtrl.dispose();
    _plzCtrl.dispose();
    _ortCtrl.dispose();
    _emailCtrl.dispose();
    _telefonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingKunde != null;

    return Padding(
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
            // Header
            Row(
              children: [
                Text(
                  isEditing ? 'Kunde bearbeiten' : 'Neuer Kunde',
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

            // Name (Pflicht)
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'Firmenname oder Kundenname',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Name ist ein Pflichtfeld';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Adresse
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
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
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
            const SizedBox(height: 12),

            // Kontakt
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                prefixIcon: Icon(Icons.email_outlined, size: 18),
                hintText: 'kontakt@example.de',
              ),
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _telefonCtrl,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                prefixIcon: Icon(Icons.phone_outlined, size: 18),
                hintText: '+49 30 123456',
              ),
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // Save button
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
                    : Text(isEditing ? 'Speichern' : 'Kunde anlegen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final existing = widget.existingKunde;
    final name = _nameCtrl.text.trim();
    final strasse =
        _strasseCtrl.text.trim().isEmpty ? null : _strasseCtrl.text.trim();
    final plz =
        _plzCtrl.text.trim().isEmpty ? null : _plzCtrl.text.trim();
    final ort =
        _ortCtrl.text.trim().isEmpty ? null : _ortCtrl.text.trim();
    final kontaktEmail =
        _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();
    final kontaktTelefon =
        _telefonCtrl.text.trim().isEmpty ? null : _telefonCtrl.text.trim();

    final Kunde kunde;
    if (existing != null) {
      kunde = Kunde(
        uuid: existing.uuid,
        name: name,
        strasse: strasse,
        plz: plz,
        ort: ort,
        kontaktEmail: kontaktEmail,
        kontaktTelefon: kontaktTelefon,
        erstelltAm: existing.erstelltAm,
      );
    } else {
      kunde = Kunde(
        name: name,
        strasse: strasse,
        plz: plz,
        ort: ort,
        kontaktEmail: kontaktEmail,
        kontaktTelefon: kontaktTelefon,
      );
    }

    await ref.read(kundenRepositoryProvider).save(kunde);

    if (mounted) Navigator.pop(context);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/raum.dart';
import '../../core/providers/geraete_provider.dart';

/// Raum anlegen oder umbenennen.
Future<void> zeigeRaumFormular(BuildContext context, {required String standortUuid, Raum? raum}) => showDialog<void>(
      context: context,
      builder: (_) => _RaumFormular(standortUuid: standortUuid, raum: raum),
    );

class _RaumFormular extends ConsumerStatefulWidget {
  const _RaumFormular({required this.standortUuid, this.raum});

  final String standortUuid;
  final Raum? raum;

  @override
  ConsumerState<_RaumFormular> createState() => _RaumFormularState();
}

class _RaumFormularState extends ConsumerState<_RaumFormular> {
  final _formKey = GlobalKey<FormState>();
  late final _bezeichnung = TextEditingController(text: widget.raum?.bezeichnung);
  late final _bemerkung = TextEditingController(text: widget.raum?.bemerkung);

  @override
  void dispose() {
    _bezeichnung.dispose();
    _bemerkung.dispose();
    super.dispose();
  }

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;
    final bemerkung = _bemerkung.text.trim();
    final bestehend = widget.raum;
    final raum = bestehend == null
        ? Raum(
            standortUuid: widget.standortUuid,
            bezeichnung: _bezeichnung.text.trim(),
            bemerkung: bemerkung.isEmpty ? null : bemerkung,
          )
        : Raum(
            uuid: bestehend.uuid,
            standortUuid: bestehend.standortUuid,
            bezeichnung: _bezeichnung.text.trim(),
            bemerkung: bemerkung.isEmpty ? null : bemerkung,
            erstelltAm: bestehend.erstelltAm,
          );
    await ref.read(raeumeRepositoryProvider).save(raum);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.raum == null ? 'Neuer Raum' : 'Raum bearbeiten'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('raum-bezeichnung'),
                controller: _bezeichnung,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Bezeichnung *', hintText: 'z.B. Büro 1.04, Werkstatt'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Bezeichnung ist ein Pflichtfeld' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bemerkung,
                decoration: const InputDecoration(labelText: 'Bemerkung'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            key: const Key('raum-speichern'),
            onPressed: _speichern,
            child: const Text('Speichern'),
          ),
        ],
      );
}

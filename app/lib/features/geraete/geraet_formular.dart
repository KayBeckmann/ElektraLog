import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/geraet.dart';
import '../../core/providers/geraete_provider.dart';
import '../../shared/theme/app_colors.dart';

class GeraetFormular extends ConsumerStatefulWidget {
  const GeraetFormular({
    super.key,
    required this.standortUuid,
    this.existingGeraet,
  });

  final String standortUuid;
  final Geraet? existingGeraet;

  @override
  ConsumerState<GeraetFormular> createState() => _GeraetFormularState();
}

class _GeraetFormularState extends ConsumerState<GeraetFormular> {
  final _formKey = GlobalKey<FormState>();
  final _bezeichnungCtrl = TextEditingController();
  final _seriennummerCtrl = TextEditingController();
  final _herstellerCtrl = TextEditingController();
  final _geraetetypCtrl = TextEditingController();
  int _pruefintervallMonate = 24;
  final _intervallCtrl = TextEditingController(text: '24');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.existingGeraet;
    if (g != null) {
      _bezeichnungCtrl.text = g.bezeichnung;
      _seriennummerCtrl.text = g.seriennummer ?? '';
      _herstellerCtrl.text = g.hersteller ?? '';
      _geraetetypCtrl.text = g.geraetetyp ?? '';
      _pruefintervallMonate = g.pruefintervallMonate;
      _intervallCtrl.text = g.pruefintervallMonate.toString();
    }
  }

  @override
  void dispose() {
    _bezeichnungCtrl.dispose();
    _seriennummerCtrl.dispose();
    _herstellerCtrl.dispose();
    _geraetetypCtrl.dispose();
    _intervallCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingGeraet != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    isEditing ? 'Gerät bearbeiten' : 'Gerät anlegen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              // Bezeichnung
              TextFormField(
                controller: _bezeichnungCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bezeichnung *',
                  hintText: 'z.B. Bohrmaschine Halle 3',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),

              // Gerätetyp
              TextFormField(
                controller: _geraetetypCtrl,
                decoration: const InputDecoration(
                  labelText: 'Gerätetyp',
                  hintText: 'z.B. Bohrmaschine, Verlängerungskabel, Schweißgerät',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),

              // Hersteller
              TextFormField(
                controller: _herstellerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Hersteller',
                  hintText: 'z.B. Bosch, Makita',
                ),
              ),
              const SizedBox(height: 12),

              // Seriennummer
              TextFormField(
                controller: _seriennummerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Seriennummer / Inventar-Nr.',
                ),
              ),
              const SizedBox(height: 16),

              // Prüfintervall
              Text(
                'PRÜFINTERVALL (DGUV V3)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 0.8,
                    ),
              ),
              const SizedBox(height: 8),
              // Schnellauswahl-Chips
              Wrap(
                spacing: 8,
                children: [6, 12, 18, 24].map((m) {
                  final selected = _pruefintervallMonate == m;
                  return ChoiceChip(
                    label: Text('$m M.'),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _pruefintervallMonate = m;
                      _intervallCtrl.text = m.toString();
                    }),
                    selectedColor: AppColors.secondaryContainer,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.onSecondaryContainer
                          : AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              // Freitexteingabe
              TextFormField(
                controller: _intervallCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prüfintervall in Monaten',
                  suffixText: 'Monate',
                  helperText: 'Min. 1 — Max. 24 Monate (DGUV V3)',
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Mindestens 1 Monat';
                  if (n > 24) return 'Maximum 24 Monate (DGUV V3)';
                  return null;
                },
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n >= 1 && n <= 24) {
                    setState(() => _pruefintervallMonate = n);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Speichern
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
                              color: AppColors.onPrimary),
                        )
                      : Text(isEditing ? 'Speichern' : 'Gerät anlegen'),
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

    final existing = widget.existingGeraet;
    final geraet = existing == null
        ? Geraet(
            standortUuid: widget.standortUuid,
            bezeichnung: _bezeichnungCtrl.text.trim(),
            seriennummer: _seriennummerCtrl.text.trim().isEmpty
                ? null
                : _seriennummerCtrl.text.trim(),
            hersteller: _herstellerCtrl.text.trim().isEmpty
                ? null
                : _herstellerCtrl.text.trim(),
            geraetetyp: _geraetetypCtrl.text.trim().isEmpty
                ? null
                : _geraetetypCtrl.text.trim(),
            pruefintervallMonate: _pruefintervallMonate,
          )
        : existing.copyWith(
            bezeichnung: _bezeichnungCtrl.text.trim(),
            seriennummer: _seriennummerCtrl.text.trim().isEmpty
                ? null
                : _seriennummerCtrl.text.trim(),
            hersteller: _herstellerCtrl.text.trim().isEmpty
                ? null
                : _herstellerCtrl.text.trim(),
            geraetetyp: _geraetetypCtrl.text.trim().isEmpty
                ? null
                : _geraetetypCtrl.text.trim(),
            pruefintervallMonate: _pruefintervallMonate,
          );

    await ref.read(geraeteRepositoryProvider).save(geraet);

    if (mounted) Navigator.pop(context);
  }
}

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
  int _pruefintervallJahre = 2;
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
      _pruefintervallJahre = g.pruefintervallJahre;
    }
  }

  @override
  void dispose() {
    _bezeichnungCtrl.dispose();
    _seriennummerCtrl.dispose();
    _herstellerCtrl.dispose();
    _geraetetypCtrl.dispose();
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
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1 Jahr')),
                  ButtonSegment(value: 2, label: Text('2 Jahre')),
                ],
                selected: {_pruefintervallJahre},
                onSelectionChanged: (s) =>
                    setState(() => _pruefintervallJahre = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.secondaryContainer,
                  selectedForegroundColor: AppColors.onSecondaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Max. 2 Jahre gemäß DGUV V3 / VDE 0701-0702',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
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
            pruefintervallJahre: _pruefintervallJahre,
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
            pruefintervallJahre: _pruefintervallJahre,
          );

    await ref.read(geraeteRepositoryProvider).save(geraet);

    if (mounted) Navigator.pop(context);
  }
}

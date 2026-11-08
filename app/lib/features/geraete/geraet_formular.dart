import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/geraet.dart';
import '../../core/providers/geraete_provider.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'geraete_widgets.dart';

/// Gerät anlegen oder bearbeiten. Bei einem bestehenden Gerät verlangt
/// jede Änderung von Kunde, Standort oder Raum eine ausdrückliche
/// Bestätigung mit altem und neuem Ort (Roadmap M2/M3).
Future<void> zeigeGeraetFormular(
  BuildContext context, {
  Geraet? geraet,
  String? kundeUuid,
  String? standortUuid,
  String? raumUuid,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => GeraetFormular(
        geraet: geraet,
        kundeUuid: kundeUuid,
        standortUuid: standortUuid,
        raumUuid: raumUuid,
      ),
    );

class GeraetFormular extends ConsumerStatefulWidget {
  const GeraetFormular({super.key, this.geraet, this.kundeUuid, this.standortUuid, this.raumUuid});

  final Geraet? geraet;
  final String? kundeUuid;
  final String? standortUuid;
  final String? raumUuid;

  @override
  ConsumerState<GeraetFormular> createState() => _GeraetFormularState();
}

class _GeraetFormularState extends ConsumerState<GeraetFormular> {
  final _formKey = GlobalKey<FormState>();
  late final Geraet? _alt = widget.geraet;
  late final _bezeichnung = TextEditingController(text: _alt?.bezeichnung);
  late final _hersteller = TextEditingController(text: _alt?.hersteller);
  late final _typ = TextEditingController(text: _alt?.typ);
  late final _seriennummer = TextEditingController(text: _alt?.seriennummer);
  late final _inventarnummer = TextEditingController(text: _alt?.inventarnummer);
  late final _schutzart = TextEditingController(text: _alt?.schutzart);
  late final _bemerkung = TextEditingController(text: _alt?.bemerkung);
  late String? _kunde = _alt?.kundeUuid ?? widget.kundeUuid;
  late String? _standort = _alt?.standortUuid ?? widget.standortUuid;
  late String? _raum = _alt?.raumUuid ?? widget.raumUuid;
  late String? _schutzklasse = _alt?.schutzklasse;
  DateTime? _letztePruefung;
  bool _speichert = false;

  @override
  void dispose() {
    for (final c in [_bezeichnung, _hersteller, _typ, _seriennummer, _inventarnummer, _schutzart, _bemerkung]) {
      c.dispose();
    }
    super.dispose();
  }

  static String? _wert(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _speichern() async {
    if (!_formKey.currentState!.validate()) return;
    final alt = _alt;
    Geraet geraet;
    if (alt == null) {
      geraet = Geraet.neu(
        kundeUuid: _kunde!,
        standortUuid: _standort!,
        raumUuid: _raum!,
        bezeichnung: _bezeichnung.text.trim(),
        hersteller: _wert(_hersteller),
        typ: _wert(_typ),
        seriennummer: _wert(_seriennummer),
        inventarnummer: _wert(_inventarnummer),
        schutzart: _wert(_schutzart),
        schutzklasse: _schutzklasse,
        letztePruefung: _letztePruefung,
        bemerkung: _wert(_bemerkung),
      );
    } else {
      geraet = alt.mitStammdaten(
        bezeichnung: _bezeichnung.text.trim(),
        hersteller: _wert(_hersteller),
        typ: _wert(_typ),
        seriennummer: _wert(_seriennummer),
        inventarnummer: _wert(_inventarnummer),
        schutzart: _wert(_schutzart),
        schutzklasse: _schutzklasse,
        pruefintervallMonate: alt.pruefintervallMonate,
        intervallBegruendung: alt.intervallBegruendung,
        bemerkung: _wert(_bemerkung),
      );
      final neu = geraet.umgehaengt(kundeUuid: _kunde!, standortUuid: _standort!, raumUuid: _raum!);
      if (!neu.gleicherOrt(alt)) {
        final bestaetigt = await bestaetigeZuordnung(context, ref, alt: alt, neu: neu);
        if (bestaetigt != true) return;
        geraet = neu;
      }
    }
    setState(() => _speichert = true);
    await ref.read(geraeteRepositoryProvider).save(geraet);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final kunden = ref.watch(kundenProvider).valueOrNull ?? const [];
    final standorte = _kunde == null ? const [] : ref.watch(standorteByKundeProvider(_kunde!)).valueOrNull ?? const [];
    final raeume =
        _standort == null ? const [] : ref.watch(raeumeByStandortProvider(_standort!)).valueOrNull ?? const [];

    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(_alt == null ? 'Neues Gerät' : 'Gerät bearbeiten',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('geraet-bezeichnung'),
                controller: _bezeichnung,
                decoration:
                    const InputDecoration(labelText: 'Bezeichnung *', hintText: 'z.B. Wasserkocher, Bohrmaschine'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Bezeichnung ist ein Pflichtfeld' : null,
              ),
              const SizedBox(height: 16),
              Text('Zuordnung', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              KeyedSubtree(
                key: ValueKey('kunden-${kunden.length}'),
                child: DropdownButtonFormField<String>(
                  key: const Key('geraet-kunde'),
                  initialValue: kunden.any((k) => k.uuid == _kunde) ? _kunde : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Kunde *'),
                  items: [for (final k in kunden) DropdownMenuItem(value: k.uuid, child: Text(k.name))],
                  onChanged: (v) => setState(() {
                    _kunde = v;
                    _standort = null;
                    _raum = null;
                  }),
                  validator: (v) => v == null ? 'Kunde ist Pflicht' : null,
                ),
              ),
              const SizedBox(height: 12),
              // KeyedSubtree: abhängige Auswahl beginnt neu, wenn sich die
              // übergeordnete ändert (initialValue greift nur beim Aufbau).
              KeyedSubtree(
                key: ValueKey('standorte-$_kunde-${standorte.length}'),
                child: DropdownButtonFormField<String>(
                  key: const Key('geraet-standort'),
                  initialValue: standorte.any((s) => s.uuid == _standort) ? _standort : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Standort *'),
                  items: [for (final s in standorte) DropdownMenuItem(value: s.uuid, child: Text(s.bezeichnung))],
                  onChanged: (v) => setState(() {
                    _standort = v;
                    _raum = null;
                  }),
                  validator: (v) => v == null ? 'Standort ist Pflicht' : null,
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: ValueKey('raeume-$_standort-${raeume.length}'),
                child: DropdownButtonFormField<String>(
                  key: const Key('geraet-raum'),
                  initialValue: raeume.any((r) => r.uuid == _raum) ? _raum : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Raum *',
                    helperText: _standort != null && raeume.isEmpty ? 'Erst einen Raum im Standort anlegen' : null,
                  ),
                  items: [for (final r in raeume) DropdownMenuItem(value: r.uuid, child: Text(r.bezeichnung))],
                  onChanged: (v) => setState(() => _raum = v),
                  validator: (v) => v == null ? 'Raum ist Pflicht' : null,
                ),
              ),
              const SizedBox(height: 16),
              Text('Stammdaten', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: TextFormField(
                          controller: _hersteller, decoration: const InputDecoration(labelText: 'Hersteller'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextFormField(controller: _typ, decoration: const InputDecoration(labelText: 'Type'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('geraet-seriennummer'),
                      controller: _seriennummer,
                      decoration: const InputDecoration(labelText: 'Seriennummer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('geraet-inventarnummer'),
                      controller: _inventarnummer,
                      decoration: const InputDecoration(labelText: 'Inventarnummer'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                  controller: _schutzart,
                  decoration: const InputDecoration(labelText: 'Schutzart', hintText: 'z.B. IP20, IP44')),
              const SizedBox(height: 12),
              Text('Schutzklasse', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              SegmentedButton<String>(
                key: const Key('geraet-schutzklasse'),
                segments: const [
                  ButtonSegment(value: '', label: Text('offen')),
                  ButtonSegment(value: 'I', label: Text('I')),
                  ButtonSegment(value: 'II', label: Text('II')),
                  ButtonSegment(value: 'III', label: Text('III')),
                ],
                selected: {_schutzklasse ?? ''},
                onSelectionChanged: (s) => setState(() => _schutzklasse = s.first.isEmpty ? null : s.first),
              ),
              if (_alt == null) ...[
                const SizedBox(height: 16),
                Text('Letzte Prüfung', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  key: const Key('geraet-letzte-pruefung'),
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(_letztePruefung == null ? 'Datum wählen (optional)' : datumDeutsch(_letztePruefung!)),
                  onPressed: () async {
                    final jetzt = DateTime.now();
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(jetzt.year - 10),
                      lastDate: jetzt,
                      initialDate: _letztePruefung ?? jetzt,
                    );
                    if (d != null) setState(() => _letztePruefung = d);
                  },
                ),
                Text(
                  _letztePruefung == null
                      ? 'Ohne Angabe wird das Erstellungsdatum als Ersatzwert eingetragen — '
                          'das ist kein Prüfnachweis, das Gerät gilt sofort als zu prüfen.'
                      : 'Datum einer Prüfung vor ElektraLog (ohne Protokoll in der App).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                  controller: _bemerkung, decoration: const InputDecoration(labelText: 'Bemerkung'), maxLines: 2),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('geraet-speichern'),
                onPressed: _speichert ? null : _speichern,
                child: Text(_alt == null ? 'Gerät anlegen' : 'Speichern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog „Zuordnung ändern?“ mit bisherigem und neuem Ort. Ohne
/// ausdrückliche Bestätigung bleibt das Gerät, wo es ist.
Future<bool?> bestaetigeZuordnung(BuildContext context, WidgetRef ref,
    {required Geraet alt, required Geraet neu}) async {
  Future<String> ort(Geraet g) async {
    final kunde = (await ref.read(kundenProvider.future)).where((k) => k.uuid == g.kundeUuid).firstOrNull;
    final standort = await ref.read(standorteRepositoryProvider).getByUuid(g.standortUuid);
    final raum = await ref.read(raeumeRepositoryProvider).getByUuid(g.raumUuid);
    return [kunde?.name ?? '?', standort?.bezeichnung ?? '?', raum?.bezeichnung ?? '?'].join(' › ');
  }

  final bisher = await ort(alt);
  final kuenftig = await ort(neu);
  if (!context.mounted) return false;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('zuordnung-dialog'),
      title: const Text('Zuordnung ändern?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('„${alt.bezeichnung}“ wird umgehängt.'),
          const SizedBox(height: 12),
          Text('Bisher', style: Theme.of(ctx).textTheme.labelLarge),
          Text(bisher),
          const SizedBox(height: 8),
          Text('Neu', style: Theme.of(ctx).textTheme.labelLarge),
          Text(kuenftig, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            'Abgeschlossene Prüfungen behalten ihren damaligen Ort.',
            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
        ElevatedButton(
          key: const Key('zuordnung-bestaetigen'),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Zuordnung ändern'),
        ),
      ],
    ),
  );
}

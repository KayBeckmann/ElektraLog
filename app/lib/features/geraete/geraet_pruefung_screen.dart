import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/geraet.dart';
import '../../core/models/geraete_faelligkeit.dart';
import '../../core/models/geraete_pruefung.dart';
import '../../core/models/pruefmatrix.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/geraete_provider.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/module_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'geraete_widgets.dart';

/// Prüferfassung eines Geräts (Roadmap M5): Besichtigen → Messen (je
/// Schutzklasse) → Erproben → Bewertung. Jede Eingabe wird sofort lokal
/// gespeichert (Entwurf, offline fortsetzbar). Abgeschlossene Prüfungen
/// sind nur lesbar; Korrekturen entstehen als neue Prüfung.
class GeraetPruefungScreen extends ConsumerWidget {
  const GeraetPruefungScreen({super.key, required this.geraetUuid, required this.pruefungUuid});

  final String geraetUuid;
  final String pruefungUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(aktiveModuleProvider);
    final geraet = ref.watch(geraetProvider(geraetUuid)).valueOrNull;
    final pruefungAsync = ref.watch(geraetePruefungProvider(pruefungUuid));
    final pruefung = pruefungAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/geraete/$geraetUuid')),
        title: Text(geraet == null ? 'Prüfung' : 'Prüfung: ${geraet.bezeichnung}'),
        backgroundColor: AppColors.surface,
      ),
      body: !module.geraetepruefung
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: GeraeteHinweis(
                icon: Icons.toggle_off_outlined,
                titel: 'Geräteprüfung ist ausgeschaltet',
                text: 'Der Firmenadmin kann das Modul unter Einstellungen → Module einschalten.',
              ),
            )
          : pruefung == null || geraet == null
              ? Center(
                  child: pruefungAsync.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Prüfung nicht gefunden'),
                )
              : _PruefungFormular(key: ValueKey(pruefung.uuid), geraet: geraet, start: pruefung),
    );
  }
}

class _PruefungFormular extends ConsumerStatefulWidget {
  const _PruefungFormular({super.key, required this.geraet, required this.start});

  final Geraet geraet;
  final GeraetePruefung start;

  @override
  ConsumerState<_PruefungFormular> createState() => _PruefungFormularState();
}

class _PruefungFormularState extends ConsumerState<_PruefungFormular> {
  late GeraetePruefung _p = widget.start;
  late final _pruefer = TextEditingController(text: _p.prueferName);
  late final _messgeraet = TextEditingController(text: _p.messgeraet);
  late final _maengel = TextEditingController(text: _p.maengel);
  late final _bemerkung = TextEditingController(text: _p.bemerkung);
  late final _intervallBegruendung = TextEditingController(text: widget.geraet.intervallBegruendung);
  final _texte = <String, TextEditingController>{};
  List<String> _fehler = const [];

  bool get _lesen => _p.abgeschlossen;

  TextEditingController _feld(String key, String? wert) =>
      _texte.putIfAbsent(key, () => TextEditingController(text: wert));

  @override
  void dispose() {
    for (final c in [_pruefer, _messgeraet, _maengel, _bemerkung, _intervallBegruendung, ..._texte.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _aendern(GeraetePruefung neu) async {
    setState(() {
      _p = neu;
      _fehler = const [];
    });
    await ref.read(geraetePruefungenRepositoryProvider).save(neu);
  }

  Future<void> _punkt(Pruefpunkt neu) =>
      _aendern(_p.kopie(punkte: [for (final x in _p.punkte) x.id == neu.id ? neu : x]));

  static double? _zahl(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _abschliessen() async {
    final fehler = abschlussFehler(_p);
    if (fehler.isNotEmpty) {
      setState(() => _fehler = fehler);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prüfung abschließen?'),
        content: Text(
          'Ergebnis: ${_p.bestanden ? 'bestanden' : 'nicht bestanden'}.\n'
          'Abgeschlossene Prüfungen lassen sich nicht mehr ändern — Korrekturen werden als neue Prüfung angelegt.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(
            key: const Key('abschluss-bestaetigen'),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abschließen'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final g = widget.geraet;
    final kunde = (await ref.read(kundenProvider.future)).where((k) => k.uuid == g.kundeUuid).firstOrNull;
    final standort = await ref.read(standorteRepositoryProvider).getByUuid(g.standortUuid);
    final raum = await ref.read(raeumeRepositoryProvider).getByUuid(g.raumUuid);
    final benutzer = (await ref.read(currentUserProvider.future))['name'] as String?;
    final abgeschlossen = abschliessen(
      _p,
      geraet: g,
      kunde: kunde?.name ?? '?',
      standort: standort?.bezeichnung ?? '?',
      raum: raum?.bezeichnung ?? '?',
    );
    await ref.read(geraetePruefungenRepositoryProvider).save(abgeschlossen);
    // Messtechniker legt das Intervall bei der Prüfung fest; festgestellte
    // Schutzklasse übernehmen, falls am Gerät noch offen.
    var aktualisiert = g.mitIntervall(
      abgeschlossen.intervallMonate ?? g.pruefintervallMonate,
      begruendung: _intervallBegruendung.text.trim().isEmpty ? null : _intervallBegruendung.text.trim(),
      benutzer: benutzer,
    );
    if (g.schutzklasse == null && abgeschlossen.schutzklasse != null) {
      aktualisiert = aktualisiert.mitStammdaten(
        bezeichnung: aktualisiert.bezeichnung,
        hersteller: aktualisiert.hersteller,
        typ: aktualisiert.typ,
        seriennummer: aktualisiert.seriennummer,
        inventarnummer: aktualisiert.inventarnummer,
        schutzart: aktualisiert.schutzart,
        schutzklasse: abgeschlossen.schutzklasse,
        pruefintervallMonate: aktualisiert.pruefintervallMonate,
        intervallBegruendung: aktualisiert.intervallBegruendung,
        bemerkung: aktualisiert.bemerkung,
      );
    }
    if (!identical(aktualisiert, g)) await ref.read(geraeteRepositoryProvider).save(aktualisiert);
    if (mounted) setState(() => _p = abgeschlossen);
  }

  Future<void> _korrektur() async {
    final neu = korrekturVon(_p);
    await ref.read(geraetePruefungenRepositoryProvider).save(neu);
    if (mounted) context.go('/geraete/${_p.geraetUuid}/pruefung/${neu.uuid}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final besichtigen = [
      for (final x in _p.punkte)
        if (x.schritt == 'besichtigen') x
    ];
    final messen = [
      for (final x in _p.punkte)
        if (x.schritt == 'messen') x
    ];
    final erproben = [
      for (final x in _p.punkte)
        if (x.schritt == 'erproben') x
    ];

    return ListView(
      key: const Key('pruefung-formular'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
      children: [
        if (_lesen)
          GeraeteHinweis(
            key: const Key('pruefung-abgeschlossen'),
            icon: _p.bestanden ? Icons.check_circle_outline : Icons.cancel_outlined,
            titel: 'Abgeschlossen: ${_p.bestanden ? 'bestanden' : 'nicht bestanden'}',
            text: 'Unveränderlich. Korrekturen werden als neue Prüfung mit Verweis angelegt.',
          ),
        if (_p.ersetztUuid != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_p.anlass ?? 'Korrektur', style: theme.textTheme.bodySmall),
          ),
        _Abschnitt('Allgemein', children: [
          Text(_p.pruefartText, key: const Key('pruefart-text'), style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _p.pruefart,
            decoration: const InputDecoration(labelText: 'Prüfart'),
            items: [for (final e in pruefarten.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: _lesen ? null : (v) => _aendern(_p.kopie(pruefart: v, pruefartText: pruefartText(v!))),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text('Prüfdatum: ${datumDeutsch(_p.datum)}'),
            onPressed: _lesen
                ? null
                : () async {
                    final d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDate: _p.datum,
                    );
                    if (d != null) await _aendern(_p.kopie(pruefungDatum: tagAlsText(d)));
                  },
          ),
          TextField(
            key: const Key('pruefer'),
            controller: _pruefer,
            enabled: !_lesen,
            decoration: const InputDecoration(labelText: 'Prüfer *'),
            onChanged: (v) => _aendern(_p.kopie(prueferName: v.trim())),
          ),
          TextField(
            controller: _messgeraet,
            enabled: !_lesen,
            decoration: const InputDecoration(labelText: 'Messgerät (Typ, Kennung, Kalibrierung)'),
            onChanged: (v) => _aendern(_p.kopie(messgeraet: v.trim())),
          ),
          const SizedBox(height: 12),
          Text('Schutzklasse (vor der Prüfung feststellen) *', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          SegmentedButton<String>(
            key: const Key('pruefung-schutzklasse'),
            segments: const [
              ButtonSegment(value: 'I', label: Text('I')),
              ButtonSegment(value: 'II', label: Text('II')),
              ButtonSegment(value: 'III', label: Text('III')),
            ],
            emptySelectionAllowed: true,
            selected: {if (_p.schutzklasse != null) _p.schutzklasse!},
            onSelectionChanged: _lesen
                ? null
                : (s) {
                    final sk = s.isEmpty ? null : s.first;
                    _aendern(_p.kopie(schutzklasse: sk, punkte: mitSchutzklasse(_p.punkte, sk)));
                  },
          ),
        ]),
        _Abschnitt('1 · Besichtigen', children: [for (final x in besichtigen) _bewertungsZeile(x)]),
        _Abschnitt('2 · Messen', children: [
          if (messen.isEmpty)
            Text(
              _p.schutzklasse == 'III'
                  ? 'Schutzklasse III: kein vorgegebener Messablauf (Sonderfall, nach Entscheidung der Prüfperson). '
                      'Messungen ggf. unter Bemerkung dokumentieren.'
                  : 'Erst die Schutzklasse feststellen.',
              style: theme.textTheme.bodySmall,
            ),
          for (final x in messen) _messZeile(x),
          if (messen.isNotEmpty)
            Text(
              'Grenzwerte sind Vorschläge ($regelVersion) und je Messung anpassbar.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
        ]),
        _Abschnitt('3 · Erproben', children: [for (final x in erproben) _bewertungsZeile(x)]),
        _Abschnitt('4 · Bewertung', children: [
          SegmentedButton<String>(
            key: const Key('pruefung-ergebnis'),
            segments: [
              ButtonSegment(value: 'bestanden', label: const Text('Bestanden'), enabled: bestandenMoeglich(_p)),
              const ButtonSegment(value: 'nicht_bestanden', label: Text('Nicht bestanden')),
            ],
            emptySelectionAllowed: true,
            selected: {if (_p.ergebnis != null) _p.ergebnis!},
            onSelectionChanged: _lesen
                ? null
                : (s) => _aendern(s.isEmpty ? _p.kopie(ergebnisLeeren: true) : _p.kopie(ergebnis: s.first)),
          ),
          if (!bestandenMoeglich(_p))
            Text(
              'Mindestens ein Punkt ist nicht in Ordnung — „bestanden“ ist gesperrt.',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          TextField(
            key: const Key('maengel'),
            controller: _maengel,
            enabled: !_lesen,
            maxLines: 2,
            decoration: InputDecoration(labelText: _p.ergebnis == 'nicht_bestanden' ? 'Mängel *' : 'Mängel'),
            onChanged: (v) => _aendern(_p.kopie(maengel: v)),
          ),
          TextField(
            controller: _bemerkung,
            enabled: !_lesen,
            decoration: const InputDecoration(labelText: 'Bemerkung'),
            onChanged: (v) => _aendern(_p.kopie(bemerkung: v)),
          ),
          const SizedBox(height: 12),
          Text('Prüfintervall (Messtechniker)', style: theme.textTheme.labelLarge),
          Wrap(
            spacing: 6,
            children: [
              for (final m in intervallVorauswahl)
                ChoiceChip(
                  key: Key('pruefung-intervall-$m'),
                  label: Text('$m Monate'),
                  selected: _p.intervallMonate == m,
                  onSelected: _lesen ? null : (_) => _aendern(_p.kopie(intervallMonate: m)),
                ),
              if (_p.intervallMonate != null && !intervallVorauswahl.contains(_p.intervallMonate))
                Chip(label: Text('${_p.intervallMonate} Monate')),
            ],
          ),
          if (!_lesen)
            TextField(
              key: const Key('pruefung-intervall-frei'),
              controller: _feld('intervall', null),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'oder freie Zahl (1–23 Monate)',
                errorText:
                    _feld('intervall', null).text.isEmpty ? null : pruefeFreiesIntervall(_feld('intervall', null).text),
              ),
              onChanged: (v) {
                setState(() {});
                if (pruefeFreiesIntervall(v) == null) _aendern(_p.kopie(intervallMonate: int.parse(v.trim())));
              },
            ),
          if (!_lesen)
            TextField(
              controller: _intervallBegruendung,
              decoration: const InputDecoration(labelText: 'Begründung des Intervalls'),
            ),
          if (_lesen && _p.naechstePruefung != null)
            Text('Nächste Prüfung: ${datumDeutsch(textAlsTag(_p.naechstePruefung!))}'),
        ]),
        if (_fehler.isNotEmpty)
          Container(
            key: const Key('abschluss-fehler'),
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final f in _fehler) Text('• $f', style: const TextStyle(color: AppColors.onErrorContainer))
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (_lesen)
          OutlinedButton.icon(
            key: const Key('pruefung-korrektur'),
            icon: const Icon(Icons.edit_note),
            label: const Text('Korrektur als neue Prüfung anlegen'),
            onPressed: _korrektur,
          )
        else ...[
          ElevatedButton(
            key: const Key('pruefung-abschliessen'),
            onPressed: _abschliessen,
            child: const Text('Prüfung abschließen'),
          ),
          const SizedBox(height: 8),
          Text(
            'Jede Eingabe ist bereits als Entwurf gespeichert und kann später fortgesetzt werden.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Widget _bewertung(Pruefpunkt x, {bool mitIo = true}) => SegmentedButton<String>(
        key: Key('bewertung-${x.id}'),
        showSelectedIcon: false,
        emptySelectionAllowed: true,
        segments: [
          if (mitIo) const ButtonSegment(value: 'io', label: Text('i. O.')),
          if (mitIo) const ButtonSegment(value: 'nio', label: Text('n. i. O.')),
          const ButtonSegment(value: 'na', label: Text('n. a.')),
        ],
        selected: {if (x.bewertung != null && (mitIo || x.bewertung == 'na')) x.bewertung!},
        onSelectionChanged: _lesen
            ? null
            : (s) {
                if (s.isEmpty) {
                  // „n. a.“ abwählen: Messpunkte bewerten sich wieder aus dem Wert.
                  _punkt(x.kopie(
                    bewertung: x.istMessung ? messBewertung(x.messwert, x.grenzwert, x.vergleich) : null,
                    bewertungLeeren: !x.istMessung || x.messwert == null,
                  ));
                } else {
                  _punkt(x.kopie(bewertung: s.first));
                }
              },
      );

  Widget _begruendung(Pruefpunkt x) => (x.bewertung == 'na' || x.bewertung == 'nio')
      ? TextField(
          key: Key('begruendung-${x.id}'),
          controller: _feld('begruendung-${x.id}', x.begruendung),
          enabled: !_lesen,
          decoration: InputDecoration(labelText: x.bewertung == 'na' ? 'Begründung (nicht anwendbar) *' : 'Befund *'),
          onChanged: (v) => _punkt(x.kopie(begruendung: v)),
        )
      : const SizedBox.shrink();

  Widget _bewertungsZeile(Pruefpunkt x) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(x.bezeichnung),
            const SizedBox(height: 4),
            _bewertung(x),
            _begruendung(x),
          ],
        ),
      );

  Widget _messZeile(Pruefpunkt x) {
    final na = x.bewertung == 'na';
    final ergebnis = na ? null : messBewertung(x.messwert, x.grenzwert, x.vergleich);
    return Container(
      key: Key('messung-${x.id}'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(x.bezeichnung, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (ergebnis != null)
                GeraetChip(
                  key: Key('mess-ergebnis-${x.id}'),
                  text: ergebnis == 'io' ? 'i. O.' : 'n. i. O.',
                  farbe: ergebnis == 'io' ? AppColors.success : AppColors.error,
                ),
            ],
          ),
          if (x.hinweis != null) Text(x.hinweis!, style: Theme.of(context).textTheme.bodySmall),
          if (!na)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('messwert-${x.id}'),
                    controller: _feld('wert-${x.id}', x.messwert?.toString()),
                    enabled: !_lesen,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Messwert', suffixText: x.einheit),
                    onChanged: (v) {
                      final wert = _zahl(v);
                      _punkt(x.kopie(
                        messwert: wert,
                        messwertLeeren: wert == null,
                        bewertung: messBewertung(wert, x.grenzwert, x.vergleich),
                        bewertungLeeren: wert == null,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: Key('grenzwert-${x.id}'),
                    controller: _feld('grenze-${x.id}', x.grenzwert?.toString()),
                    enabled: !_lesen,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Grenzwert (${x.vergleich == '<=' ? 'max.' : 'min.'})',
                      suffixText: x.einheit,
                    ),
                    onChanged: (v) {
                      final grenze = _zahl(v);
                      if (grenze == null) return;
                      _punkt(x.kopie(
                        grenzwert: grenze,
                        bewertung: messBewertung(x.messwert, grenze, x.vergleich),
                        bewertungLeeren: x.messwert == null,
                      ));
                    },
                  ),
                ),
              ],
            ),
          if (!na && x.methoden.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: x.methoden.contains(x.methode) ? x.methode : null,
              decoration: const InputDecoration(labelText: 'Messverfahren'),
              items: [for (final m in x.methoden) DropdownMenuItem(value: m, child: Text(m))],
              onChanged: _lesen ? null : (v) => _punkt(x.kopie(methode: v)),
            ),
          const SizedBox(height: 6),
          _bewertung(x, mitIo: false),
          _begruendung(x),
        ],
      ),
    );
  }
}

class _Abschnitt extends StatelessWidget {
  const _Abschnitt(this.titel, {required this.children});

  final String titel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/models/geraet.dart';
import '../../core/models/geraete_protokoll.dart';
import '../../core/models/geraete_pruefung.dart';
import '../../core/providers/einstellungen_provider.dart';
import '../../core/providers/geraete_provider.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../pdf/geraete_pdf.dart';
import 'geraete_widgets.dart';

/// Wird in Tests ersetzt, damit kein Druck-/Teilen-Dialog nötig ist.
typedef PdfAusgabe = Future<void> Function(Uint8List bytes, String dateiname);

Future<void> _teilen(Uint8List bytes, String dateiname) => Printing.sharePdf(bytes: bytes, filename: dateiname);

/// Protokolle für Gerät, Raum oder Standort (Roadmap M6). Ablauf strikt
/// getrennt: 1. Filter wählen → 2. Übersicht aller Geräte im Filter mit
/// Statusspalte prüfen → 3. PDF erzeugen (Übersicht + Prüfblätter nur für
/// aktive, tatsächlich geprüfte Geräte).
Future<void> zeigeGeraeteProtokoll(
  BuildContext context, {
  required ProtokollUmfang umfang,
  required String kundeUuid,
  required String standortUuid,
  String? raumUuid,
  String? geraetUuid,
  PdfAusgabe? ausgabe,
  PdfSchriften? schriften,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (_) => GeraeteProtokollSheet(
        umfang: umfang,
        kundeUuid: kundeUuid,
        standortUuid: standortUuid,
        raumUuid: raumUuid,
        geraetUuid: geraetUuid,
        ausgabe: ausgabe ?? _teilen,
        schriften: schriften,
      ),
    );

class GeraeteProtokollSheet extends ConsumerStatefulWidget {
  const GeraeteProtokollSheet({
    super.key,
    required this.umfang,
    required this.kundeUuid,
    required this.standortUuid,
    this.raumUuid,
    this.geraetUuid,
    required this.ausgabe,
    this.schriften,
  });

  final ProtokollUmfang umfang;
  final String kundeUuid;
  final String standortUuid;
  final String? raumUuid;
  final String? geraetUuid;
  final PdfAusgabe ausgabe;
  final PdfSchriften? schriften;

  @override
  ConsumerState<GeraeteProtokollSheet> createState() => _GeraeteProtokollSheetState();
}

class _GeraeteProtokollSheetState extends ConsumerState<GeraeteProtokollSheet> {
  ProtokollFilter _filter = ProtokollFilter.alle;
  final _manuell = <String>{};
  bool _uebersicht = false;
  bool _erzeugt = false;

  List<Geraet> _imUmfang(List<Geraet> standortGeraete) => switch (widget.umfang) {
        ProtokollUmfang.standort => standortGeraete,
        ProtokollUmfang.raum => [for (final g in standortGeraete) if (g.raumUuid == widget.raumUuid) g],
        ProtokollUmfang.geraet => [for (final g in standortGeraete) if (g.uuid == widget.geraetUuid) g],
      };

  @override
  Widget build(BuildContext context) {
    final standortGeraete = ref.watch(geraeteByStandortProvider(widget.standortUuid)).valueOrNull ?? const [];
    final pruefungen = ref.watch(allePruefungenProvider).valueOrNull ?? const <GeraetePruefung>[];
    final nachweise = ref.watch(geraetePruefNachweiseProvider).valueOrNull ?? const {};
    final raeume = <String, String>{
      for (final r in ref.watch(raeumeByStandortProvider(widget.standortUuid)).valueOrNull ?? const []) r.uuid: r.bezeichnung,
    };
    final imUmfang = _imUmfang(standortGeraete);
    final heute = DateTime.now();
    final auswahl = widget.umfang == ProtokollUmfang.geraet
        ? imUmfang
        : geraeteImFilter(imUmfang, _filter, nachweise: nachweise, heute: heute, manuell: _manuell);
    final jeGeraet = <String, List<GeraetePruefung>>{};
    for (final p in pruefungen) {
      jeGeraet.putIfAbsent(p.geraetUuid, () => []).add(p);
    }
    final titel = switch (widget.umfang) {
      ProtokollUmfang.standort => 'Geräteübersicht Standort',
      ProtokollUmfang.raum => 'Geräteübersicht Raum ${raeume[widget.raumUuid] ?? ''}',
      ProtokollUmfang.geraet => 'Geräteübersicht ${imUmfang.firstOrNull?.bezeichnung ?? ''}',
    };
    final inhalt = protokollInhalt(
      titel: titel,
      filter: widget.umfang == ProtokollUmfang.geraet ? ProtokollFilter.alle : _filter,
      geraete: auswahl,
      pruefungenJeGeraet: jeGeraet,
      raumNamen: raeume,
      heute: heute,
    );
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titel, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (!_uebersicht && widget.umfang != ProtokollUmfang.geraet) ...[
              Text('1 · Auswahl', style: theme.textTheme.titleSmall),
              RadioGroup<ProtokollFilter>(
                groupValue: _filter,
                onChanged: (v) => setState(() => _filter = v!),
                child: Column(
                  children: [
                    for (final f in ProtokollFilter.values)
                      RadioListTile<ProtokollFilter>(
                        key: Key('filter-${f.name}'),
                        value: f,
                        title: Text(f.bezeichnung),
                        dense: true,
                      ),
                  ],
                ),
              ),
              if (_filter == ProtokollFilter.manuell)
                for (final g in imUmfang)
                  CheckboxListTile(
                    key: Key('manuell-${g.uuid}'),
                    dense: true,
                    value: _manuell.contains(g.uuid),
                    title: Text(g.bezeichnung),
                    subtitle: Text(g.aktiv ? (raeume[g.raumUuid] ?? '') : 'Inaktiv: ${g.inaktivGrund ?? ''}'),
                    onChanged: (v) => setState(() => v! ? _manuell.add(g.uuid) : _manuell.remove(g.uuid)),
                  ),
              const SizedBox(height: 8),
              ElevatedButton(
                key: const Key('zur-uebersicht'),
                onPressed: auswahl.isEmpty ? null : () => setState(() => _uebersicht = true),
                child: Text('Übersicht ansehen (${auswahl.length} Geräte)'),
              ),
            ] else ...[
              Text('2 · Übersicht', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final z in inhalt.zeilen)
                Container(
                  key: Key('uebersicht-${z.geraet.uuid}'),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant))),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(z.geraet.bezeichnung, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(z.raum, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text(z.status, style: theme.textTheme.bodySmall)),
                      Expanded(
                        flex: 2,
                        child: Text(
                          z.letztePruefung == null
                              ? (z.geraet.aktiv ? 'nicht geprüft' : '–')
                              : '${datumDeutsch(z.letztePruefung!.datum)}\n'
                                  '${z.letztePruefung!.bestanden ? 'bestanden' : 'nicht bestanden'}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Icon(
                        z.mitProtokoll ? Icons.description_outlined : Icons.remove,
                        size: 18,
                        color: z.mitProtokoll ? AppColors.secondary : AppColors.outlineVariant,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '${inhalt.zeilen.length} Geräte in der Übersicht, ${inhalt.blaetter.length} Prüfprotokolle. '
                'Inaktive erhalten kein Prüfprotokoll.',
                key: const Key('uebersicht-zusammenfassung'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                key: const Key('pdf-erzeugen'),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('3 · PDF erzeugen'),
                onPressed: () => _erzeugen(inhalt),
              ),
              if (_erzeugt) const Text('PDF erzeugt.', key: Key('pdf-erzeugt')),
              if (widget.umfang != ProtokollUmfang.geraet)
                TextButton(onPressed: () => setState(() => _uebersicht = false), child: const Text('Auswahl ändern')),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _erzeugen(GeraeteProtokollInhalt inhalt) async {
    final e = await ref.read(einstellungenProvider.future);
    final kunde = (await ref.read(kundenProvider.future)).where((k) => k.uuid == widget.kundeUuid).firstOrNull;
    final standort = await ref.read(standorteRepositoryProvider).getByUuid(widget.standortUuid);
    final bytes = await geraeteProtokollPdf(
      inhalt,
      kopf: ProtokollKopf(
        firma: e.firma,
        firmaAdresse: e.firmaAdresse,
        kunde: kunde?.name,
        standort: standort?.bezeichnung,
      ),
      schriften: widget.schriften,
    );
    final datum = DateTime.now();
    await widget.ausgabe(
      bytes,
      'Geraetepruefung_${standort?.bezeichnung ?? 'Standort'}_${datum.year}-${datum.month}-${datum.day}.pdf'
          .replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_'),
    );
    if (mounted) setState(() => _erzeugt = true);
  }
}

/// Historisches Einzelprotokoll erneut ausgeben (aus dem Snapshot).
Future<void> einzelProtokollAusgeben(
  WidgetRef ref,
  GeraetePruefung p,
  Geraet geraet, {
  PdfAusgabe? ausgabe,
  PdfSchriften? schriften,
}) async {
  final e = await ref.read(einstellungenProvider.future);
  final bytes = await einzelProtokollPdf(
    p,
    geraet,
    kopf: ProtokollKopf(firma: e.firma, firmaAdresse: e.firmaAdresse),
    schriften: schriften,
  );
  await (ausgabe ?? _teilen)(bytes, 'Pruefprotokoll_${p.pruefungDatum}_${p.uuid.substring(0, 8)}.pdf');
}

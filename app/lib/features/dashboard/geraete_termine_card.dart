import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/geraet.dart';
import '../../core/models/geraete_faelligkeit.dart';
import '../../core/providers/geraete_provider.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../geraete/geraete_widgets.dart';

/// Ein fälliges Gerät mit Ort für die Terminliste.
typedef GeraetTerminZeile = ({Geraet geraet, GeraetTermin termin, String kunde, String standort});

/// Fällige Geräte (aktiv, überfällig oder in den nächsten 90 Tagen).
/// Inaktive Geräte erscheinen nie. Reine Funktion → testbar.
List<GeraetTerminZeile> faelligeGeraete({
  required List<Geraet> geraete,
  required Map<String, PruefNachweis> nachweise,
  required Map<String, String> kundenNamen,
  required Map<String, String> standortNamen,
  required DateTime heute,
}) {
  final zeilen = <GeraetTerminZeile>[
    for (final g in geraete)
      if (geraetTermin(g, letztePruefung: nachweise[g.uuid], heute: heute) case final t when t.inListe)
        (
          geraet: g,
          termin: t,
          kunde: kundenNamen[g.kundeUuid] ?? 'Unbekannt',
          standort: standortNamen[g.standortUuid] ?? 'Unbekannt',
        ),
  ];
  zeilen.sort((a, b) => a.termin.faelligAm!.compareTo(b.termin.faelligAm!));
  return zeilen;
}

/// Dashboard: Geräteprüfungen getrennt von den Anlagenmessungen (M4).
class GeraeteTermineCard extends ConsumerStatefulWidget {
  const GeraeteTermineCard({super.key, this.heute});

  /// Stichtag für Tests; sonst heute.
  final DateTime? heute;

  @override
  ConsumerState<GeraeteTermineCard> createState() => _GeraeteTermineCardState();
}

class _GeraeteTermineCardState extends ConsumerState<GeraeteTermineCard> {
  bool _nachOrt = true;

  @override
  Widget build(BuildContext context) {
    final geraete = ref.watch(alleGeraeteProvider).valueOrNull ?? const [];
    final nachweise = ref.watch(geraetePruefNachweiseProvider).valueOrNull ?? const {};
    final kunden = <String, String>{for (final k in ref.watch(kundenProvider).valueOrNull ?? const []) k.uuid: k.name};
    final standorte = <String, String>{
      for (final s in ref.watch(alleStandorteProvider).valueOrNull ?? const []) s.uuid: s.bezeichnung,
    };
    final zeilen = faelligeGeraete(
      geraete: geraete,
      nachweise: nachweise,
      kundenNamen: kunden,
      standortNamen: standorte,
      heute: widget.heute ?? DateTime.now(),
    );
    final ueberfaellig = [for (final z in zeilen) if (z.termin.status == GeraetTerminStatus.ueberfaellig) z];
    final bald = [for (final z in zeilen) if (z.termin.status == GeraetTerminStatus.faellig) z];
    final theme = Theme.of(context);

    return Container(
      key: const Key('geraete-termine'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Geräteprüfungen (90 Tage)', style: theme.textTheme.titleMedium)),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Ort')),
                  ButtonSegment(value: false, label: Text('Datum')),
                ],
                selected: {_nachOrt},
                onSelectionChanged: (s) => setState(() => _nachOrt = s.first),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (zeilen.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Keine fälligen Geräteprüfungen in den nächsten 90 Tagen',
                key: const Key('geraete-termine-leer'),
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          if (ueberfaellig.isNotEmpty) ...[
            _Abschnitt(key: const Key('geraete-ueberfaellig'), titel: 'Überfällig (${ueberfaellig.length})', rot: true),
            ..._liste(ueberfaellig),
          ],
          if (bald.isNotEmpty) ...[
            _Abschnitt(key: const Key('geraete-bald'), titel: 'Nächste 90 Tage (${bald.length})'),
            ..._liste(bald),
          ],
        ],
      ),
    );
  }

  List<Widget> _liste(List<GeraetTerminZeile> zeilen) {
    if (!_nachOrt) {
      return [
        for (final z in zeilen)
          _Zeile(
            datum: z.termin.faelligAm!,
            titel: z.geraet.bezeichnung,
            unterzeile: '${z.kunde} · ${z.standort}${z.termin.hinweis == null ? '' : ' · ${z.termin.hinweis}'}',
            rot: z.termin.status == GeraetTerminStatus.ueberfaellig,
            onTap: () => context.go('/geraete/${z.geraet.uuid}'),
          ),
      ];
    }
    // Je Kunde/Standort eine Zeile mit frühestem Termin und Anzahl.
    final gruppen = <String, List<GeraetTerminZeile>>{};
    for (final z in zeilen) {
      gruppen.putIfAbsent(z.geraet.standortUuid, () => []).add(z);
    }
    return [
      for (final g in gruppen.values)
        _Zeile(
          datum: g.first.termin.faelligAm!,
          titel: '${g.first.kunde} — ${g.first.standort}',
          unterzeile: g.length == 1 ? '1 Gerät: ${g.first.geraet.bezeichnung}' : '${g.length} Geräte',
          rot: g.first.termin.status == GeraetTerminStatus.ueberfaellig,
          onTap: () => context.go('/kunden/${g.first.geraet.kundeUuid}/standort/${g.first.geraet.standortUuid}'),
        ),
    ];
  }
}

class _Abschnitt extends StatelessWidget {
  const _Abschnitt({super.key, required this.titel, this.rot = false});

  final String titel;
  final bool rot;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          titel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: rot ? AppColors.error : null),
        ),
      );
}

class _Zeile extends StatelessWidget {
  const _Zeile({
    required this.datum,
    required this.titel,
    required this.unterzeile,
    required this.rot,
    required this.onTap,
  });

  final DateTime datum;
  final String titel;
  final String unterzeile;
  final bool rot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rot ? AppColors.errorContainer : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: rot ? AppColors.error : AppColors.outlineVariant),
                ),
                child: Text(
                  datumDeutsch(datum),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: rot ? AppColors.error : null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titel, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(unterzeile, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

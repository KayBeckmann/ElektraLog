import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/raum.dart';
import '../../core/providers/geraete_provider.dart';
import '../../core/providers/isar_provider.dart';
import '../../core/providers/sync_auswahl_provider.dart';
import '../../core/sync/sync_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../core/models/geraete_protokoll.dart';
import 'geraet_formular.dart';
import 'geraete_protokoll_sheet.dart';
import 'geraete_widgets.dart';
import 'raum_formular.dart';

/// Geräteprüfung eines Standorts: Räume, Suche, Geräte-Sync-Auswahl.
class GeraeteBereich extends ConsumerStatefulWidget {
  const GeraeteBereich({super.key, required this.kundeUuid, required this.standortUuid});

  final String kundeUuid;
  final String standortUuid;

  @override
  ConsumerState<GeraeteBereich> createState() => _GeraeteBereichState();
}

class _GeraeteBereichState extends ConsumerState<GeraeteBereich> {
  String _suche = '';

  @override
  Widget build(BuildContext context) {
    final raeume = ref.watch(raeumeByStandortProvider(widget.standortUuid)).valueOrNull ?? const <Raum>[];
    final geraete = ref.watch(geraeteByStandortProvider(widget.standortUuid)).valueOrNull ?? const [];
    final treffer = _suche.trim().isEmpty ? null : geraete.where((g) => g.passtZu(_suche)).toList();
    final raumNamen = {for (final r in raeume) r.uuid: r.bezeichnung};

    return Column(
      key: const Key('geraete-bereich'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Räume', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            OutlinedButton.icon(
              key: const Key('raum-neu'),
              onPressed: () => zeigeRaumFormular(context, standortUuid: widget.standortUuid),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Raum'),
            ),
            IconButton(
              key: const Key('scan'),
              tooltip: 'Etikett scannen',
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.go('/scan'),
            ),
            IconButton(
              key: const Key('protokoll-standort'),
              tooltip: 'Geräteprotokoll',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: geraete.isEmpty
                  ? null
                  : () => zeigeGeraeteProtokoll(
                        context,
                        umfang: ProtokollUmfang.standort,
                        kundeUuid: widget.kundeUuid,
                        standortUuid: widget.standortUuid,
                      ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: const Key('geraet-neu'),
              onPressed: raeume.isEmpty
                  ? null
                  : () => zeigeGeraetFormular(
                        context,
                        kundeUuid: widget.kundeUuid,
                        standortUuid: widget.standortUuid,
                        raumUuid: raeume.length == 1 ? raeume.single.uuid : null,
                      ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Gerät'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _SyncCheckbox(
          key: const Key('sync-geraete-standort'),
          wert: ref.watch(geraeteStandortSyncAktiviertProvider(widget.standortUuid)).valueOrNull ?? false,
          text: 'Alle Geräte dieses Standorts auf dieses Gerät synchronisieren',
          setzen: (repo, v) => repo.setGeraeteStandortAktiviert(widget.standortUuid, v),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('geraete-suche'),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Suche: Bezeichnung, UUID, Serien- oder Inventarnummer',
          ),
          onChanged: (v) => setState(() => _suche = v),
        ),
        const SizedBox(height: 12),
        if (treffer != null) ...[
          Text('${treffer.length} Treffer', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          for (final g in treffer)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GeraetTile(
                geraet: g,
                unterzeile: 'Raum: ${raumNamen[g.raumUuid] ?? '?'}',
                onTap: () => context.go('/geraete/${g.uuid}'),
              ),
            ),
        ] else if (raeume.isEmpty)
          const GeraeteHinweis(
            key: Key('keine-raeume'),
            icon: Icons.meeting_room_outlined,
            titel: 'Noch keine Räume',
            text: 'Jedes Gerät gehört zu einem Raum. Lege zuerst einen Raum an.',
          )
        else
          for (final r in raeume)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RaumTile(
                raum: r,
                anzahl: geraete.where((g) => g.raumUuid == r.uuid).length,
                onTap: () => context.go('/kunden/${widget.kundeUuid}/standort/${widget.standortUuid}/raum/${r.uuid}'),
              ),
            ),
      ],
    );
  }
}

class _RaumTile extends ConsumerWidget {
  const _RaumTile({required this.raum, required this.anzahl, required this.onTap});

  final Raum raum;
  final int anzahl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standortAktiv = ref.watch(geraeteStandortSyncAktiviertProvider(raum.standortUuid)).valueOrNull ?? false;
    final raumAktiv = ref.watch(raumSyncAktiviertProvider(raum.uuid)).valueOrNull ?? false;
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            key: Key('raum-${raum.uuid}'),
            onTap: onTap,
            leading: const Icon(Icons.meeting_room_outlined, color: AppColors.secondary),
            title: Text(raum.bezeichnung),
            subtitle: Text(anzahl == 1 ? '1 Gerät (lokal)' : '$anzahl Geräte (lokal)'),
            trailing: const Icon(Icons.arrow_forward, size: 16),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: _SyncCheckbox(
              key: Key('sync-raum-${raum.uuid}'),
              wert: standortAktiv || raumAktiv,
              gesperrt: standortAktiv,
              text: standortAktiv ? 'Synchronisiert (ganzer Standort gewählt)' : 'Diesen Raum synchronisieren',
              setzen: (repo, v) => repo.setRaumAktiviert(raum.uuid, v),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lokale Geräte-Sync-Auswahl. Abwählen stoppt nur künftige Downloads —
/// lokale Daten und ausstehende Uploads bleiben erhalten.
class _SyncCheckbox extends ConsumerWidget {
  const _SyncCheckbox({super.key, required this.wert, required this.text, required this.setzen, this.gesperrt = false});

  final bool wert;
  final bool gesperrt;
  final String text;
  final Future<void> Function(SyncAuswahlRepository repo, bool wert) setzen;

  Future<void> _toggle(WidgetRef ref, bool v) async {
    await setzen(ref.read(syncAuswahlRepositoryProvider), v);
    if (v) {
      final db = await ref.read(dbProvider.future);
      unawaited(SyncService.pullAll(db));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Row(
        children: [
          Checkbox(value: wert, onChanged: gesperrt ? null : (v) => _toggle(ref, v ?? false)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      );
}

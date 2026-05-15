import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/geraet.dart';
import '../../core/models/verteiler.dart';
import '../../core/providers/geraete_provider.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../core/providers/verteiler_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'package:printing/printing.dart';
import '../../core/providers/komponenten_provider.dart';
import '../../core/providers/messungen_provider.dart';
import '../../core/providers/sichtpruefung_provider.dart';
import '../../features/geraete/geraet_formular.dart';
import '../../features/messungen/messung_formular.dart';
import '../../features/pdf/pdf_options_sheet.dart';
import '../../features/pdf/pdf_service.dart';
import 'verteiler_formular.dart';
import 'standort_formular.dart';

class StandortDetailScreen extends ConsumerWidget {
  const StandortDetailScreen({
    super.key,
    required this.kundeUuid,
    required this.standortUuid,
  });

  final String kundeUuid;
  final String standortUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standorteAsync = ref.watch(standorteByKundeProvider(kundeUuid));
    final geraeteAsync = ref.watch(geraeteByStandortProvider(standortUuid));
    final verteilerAsync =
        ref.watch(verteilerByStandortProvider(standortUuid));
    final kundenAsync = ref.watch(kundenProvider);

    final standort = standorteAsync.when(
      data: (list) =>
          list.where((s) => s.uuid == standortUuid).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );

    final kundenName = kundenAsync.when(
      data: (list) =>
          list.where((k) => k.uuid == kundeUuid).firstOrNull?.name,
      loading: () => null,
      error: (_, __) => null,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go('/kunden/$kundeUuid'),
        ),
        title: Text(standort?.bezeichnung ?? 'Standort'),
        backgroundColor: AppColors.surface,
        actions: [
          // ── Protokoll-Auswahl für Verteiler dieses Standorts ──────────
          Tooltip(
            message: 'Protokoll generieren',
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _showProtokollAuswahl(
                  context, ref, verteilerAsync.value ?? [],
                  kundenName: kundenName,
                  standortBezeichnung: standort?.bezeichnung),
            ),
          ),
          if (standort != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => StandortFormular(
                  kundeUuid: kundeUuid,
                  existingStandort: standort,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVerteilerFormular(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Verteiler'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Standortinfo ──────────────────────────────────────────────
            if (standort != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 20, color: AppColors.secondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            standort.bezeichnung,
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                          if (standort.ort != null ||
                              standort.strasse != null)
                            Text(
                              [
                                if (standort.strasse != null)
                                  standort.strasse!,
                                if (standort.plz != null &&
                                    standort.ort != null)
                                  '${standort.plz} ${standort.ort}'
                                else if (standort.ort != null)
                                  standort.ort!,
                              ].join(', '),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: AppColors.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ── Verteiler ─────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Verteiler',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showVerteilerFormular(context, ref, null),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Neu'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            verteilerAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Fehler: $e'),
              data: (verteilerList) {
                if (verteilerList.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.electrical_services_outlined,
                            size: 48,
                            color: AppColors.outlineVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Noch keine Verteiler',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: verteilerList.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 8),
                  itemBuilder: (_, i) => _VerteilerTile(
                    verteiler: verteilerList[i],
                    kundeUuid: kundeUuid,
                    standortUuid: standortUuid,
                    onEdit: () => _showVerteilerFormular(
                        context, ref, verteilerList[i]),
                    onDelete: () => _deleteVerteiler(
                        context, ref, verteilerList[i]),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // ── Geräte ────────────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Geräte',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showGeraetFormular(context, ref, null),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Gerät'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            geraeteAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Fehler: $e'),
              data: (geraeteList) {
                if (geraeteList.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Center(
                      child: Text(
                        'Noch keine Geräte — z.B. Bohrmaschinen, Verlängerungskabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: geraeteList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _GeraetTile(
                    geraet: geraeteList[i],
                    onEdit: () =>
                        _showGeraetFormular(context, ref, geraeteList[i]),
                    onDelete: () =>
                        _deleteGeraet(context, ref, geraeteList[i]),
                    onPruefung: () =>
                        _showGeraetPruefung(context, geraeteList[i].uuid),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGeraetPruefung(
      BuildContext context, String geraetUuid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MessungFormular(geraetUuid: geraetUuid),
    );
  }

  Future<void> _showGeraetFormular(
      BuildContext context, WidgetRef ref, Geraet? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => GeraetFormular(
        standortUuid: standortUuid,
        existingGeraet: existing,
      ),
    );
  }

  Future<void> _deleteGeraet(
      BuildContext context, WidgetRef ref, Geraet g) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerät löschen'),
        content: Text('Möchtest du "${g.bezeichnung}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(geraeteRepositoryProvider).delete(g.uuid);
    }
  }

  Future<void> _showVerteilerFormular(
      BuildContext context, WidgetRef ref, Verteiler? existing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => VerteilerFormular(
        standortUuid: standortUuid,
        existingVerteiler: existing,
      ),
    );
  }

  Future<void> _deleteVerteiler(
      BuildContext context, WidgetRef ref, Verteiler v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verteiler löschen'),
        content: Text('Möchtest du "${v.bezeichnung}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(verteilerRepositoryProvider).delete(v.uuid);
    }
  }

  /// Zeigt ein BottomSheet zur Verteiler-Auswahl, dann generiert PDF
  Future<void> _showProtokollAuswahl(
    BuildContext context,
    WidgetRef ref,
    List<Verteiler> verteiler, {
    String? kundenName,
    String? standortBezeichnung,
  }) async {
    if (verteiler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Keine Verteiler vorhanden'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Protokoll generieren',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Verteiler auswählen:',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 12),
            ...verteiler.map((v) => ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined,
                      color: AppColors.primary),
                  title: Text(v.bezeichnung),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(ctx);
                    _generatePdfForVerteiler(context, ref, v,
                        kundenName: kundenName,
                        standortBezeichnung: standortBezeichnung);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdfForVerteiler(
    BuildContext context,
    WidgetRef ref,
    Verteiler v, {
    String? kundenName,
    String? standortBezeichnung,
  }) async {
    final opts = await PdfOptionsSheet.show(context, titel: v.bezeichnung);
    if (opts == null || !context.mounted) return;

    try {
      final kompList =
          await ref.read(komponentenByVerteilerProvider(v.uuid).future);
      final kompUuids = kompList.map((k) => k.uuid).toList();
      final messungen = await ref
          .read(messungenRepositoryProvider)
          .getByKomponenteUuids(kompUuids);
      final sichtpruefungen =
          await ref.read(sichtpruefungenByVerteilerProvider(v.uuid).future);

      final bytes = await PdfService.generateProtokoll(
        prueferName: opts.prueferName,
        firma: opts.firma,
        pruefgeraet: opts.pruefgeraet,
        datumOrt: opts.datumOrt,
        kundenName: kundenName,
        standortBezeichnung: standortBezeichnung,
        verteiler: v,
        sichtpruefungen: sichtpruefungen,
        komponenten: kompList,
        messungen: messungen,
        signaturPng: opts.signaturPng,
      );
      await Printing.layoutPdf(
          onLayout: (_) async => bytes, name: 'Protokoll_${v.bezeichnung}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('PDF-Fehler: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }
}

class _VerteilerTile extends StatelessWidget {
  const _VerteilerTile({
    required this.verteiler,
    required this.kundeUuid,
    required this.standortUuid,
    required this.onEdit,
    required this.onDelete,
  });

  final Verteiler verteiler;
  final String kundeUuid;
  final String standortUuid;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(
        '/kunden/$kundeUuid/standort/$standortUuid/verteiler/${verteiler.uuid}',
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(Icons.electrical_services_outlined,
                size: 20, color: AppColors.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verteiler.bezeichnung,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (verteiler.bemerkung != null)
                    Text(
                      verteiler.bemerkung!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: AppColors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 18, color: AppColors.onSurfaceVariant),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Bearbeiten'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outlined,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text('Löschen',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
            ),
            const Icon(Icons.arrow_forward,
                size: 16, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _GeraetTile extends StatelessWidget {
  const _GeraetTile({
    required this.geraet,
    required this.onEdit,
    required this.onDelete,
    required this.onPruefung,
  });

  final Geraet geraet;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPruefung;

  @override
  Widget build(BuildContext context) {
    final naechste = geraet.naechstePruefung;
    final isUeberfaellig = geraet.isUeberfaellig;
    final naechsteStr = naechste == null
        ? 'Noch nicht geprüft'
        : '${naechste.day.toString().padLeft(2, '0')}.${naechste.month.toString().padLeft(2, '0')}.${naechste.year}';

    return Container(
      decoration: BoxDecoration(
        color: isUeberfaellig
            ? AppColors.errorContainer
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isUeberfaellig ? AppColors.error : AppColors.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.electrical_services_outlined,
            size: 20,
            color: isUeberfaellig ? AppColors.error : AppColors.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(geraet.bezeichnung,
                    style: Theme.of(context).textTheme.titleSmall),
                if (geraet.seriennummer != null)
                  Text(geraet.seriennummer!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          )),
                Row(
                  children: [
                    Icon(
                      isUeberfaellig
                          ? Icons.warning_amber_outlined
                          : Icons.calendar_today_outlined,
                      size: 12,
                      color: isUeberfaellig
                          ? AppColors.error
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Nächste Prüfung: $naechsteStr',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isUeberfaellig
                                ? AppColors.error
                                : AppColors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${geraet.intervallLabel})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.outline,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                size: 16, color: AppColors.onSurfaceVariant),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'pruefung',
                  child: Row(children: [
                    Icon(Icons.science_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Prüfung hinterlegen'),
                  ])),
              const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Bearbeiten'),
                  ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 16),
                    SizedBox(width: 8),
                    Text('Löschen', style: TextStyle(color: AppColors.error)),
                  ])),
            ],
            onSelected: (v) {
              if (v == 'pruefung') onPruefung();
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }
}

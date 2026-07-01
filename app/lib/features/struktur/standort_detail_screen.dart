import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_service.dart';
import '../../core/models/verteiler.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/permission_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../core/providers/verteiler_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'package:printing/printing.dart';
import '../../core/providers/komponenten_provider.dart';
import '../../core/providers/messungen_provider.dart';
import '../../core/providers/sichtpruefung_provider.dart';
import '../../core/providers/pruefprotokoll_provider.dart';
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

    final berechtigungen = ref.watch(berechtigungenProvider).valueOrNull ??
        const Berechtigungen(rolleMonteur);
    final hatVerteiler = verteilerAsync.value?.isNotEmpty ?? false;
    final standortBearbeitbar = berechtigungen.kannBearbeitenOderLoeschen(
      hatAbhaengigeDaten: hatVerteiler,
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
          if (standort != null && standortBearbeitbar) ...[
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
            IconButton(
              icon: const Icon(Icons.delete_outlined, color: AppColors.error),
              onPressed: () => _deleteStandort(context, ref, standortUuid),
            ),
          ],
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
          ],
        ),
      ),
    );
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
      // Server informieren — fire-and-forget; 401 im Offline-Modus ist erwartet
      ApiService.deleteVerteiler(v.uuid).catchError((_) {});
    }
  }

  Future<void> _deleteStandort(
      BuildContext context, WidgetRef ref, String standortUuid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Standort löschen'),
        content: const Text('Möchtest du diesen Standort wirklich löschen?'),
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
      await ref.read(standorteRepositoryProvider).delete(standortUuid);
      // Server informieren — fire-and-forget; 401 im Offline-Modus ist erwartet
      ApiService.deleteStandort(standortUuid).catchError((_) {});
      if (context.mounted) context.go('/kunden/$kundeUuid');
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

      final protokolle = await ref
          .read(pruefprotokollRepositoryProvider)
          .getByVerteiler(v.uuid);

      final gefilterteMessungen =
          PdfService.filterMessungenForProtokoll(messungen, protokolle);

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
        messungen: gefilterteMessungen,
        signaturPng: opts.signaturPng,
      );
      await Printing.sharePdf(
          bytes: bytes, filename: 'Protokoll_${v.bezeichnung}.pdf');
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

class _VerteilerTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final berechtigungen = ref.watch(berechtigungenProvider).valueOrNull ??
        const Berechtigungen(rolleMonteur);
    final komponentenAsync =
        ref.watch(komponentenByVerteilerProvider(verteiler.uuid));
    final hatKomponenten = komponentenAsync.value?.isNotEmpty ?? false;
    final bearbeitbar = berechtigungen.kannBearbeitenOderLoeschen(
      hatAbhaengigeDaten: hatKomponenten,
    );

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
            if (bearbeitbar)
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


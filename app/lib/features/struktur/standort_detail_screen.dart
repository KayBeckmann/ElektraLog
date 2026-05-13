import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/verteiler.dart';
import '../../core/providers/standorte_provider.dart';
import '../../core/providers/verteiler_provider.dart';
import '../../shared/theme/app_colors.dart';
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

    final standort = standorteAsync.when(
      data: (list) =>
          list.where((s) => s.uuid == standortUuid).firstOrNull,
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

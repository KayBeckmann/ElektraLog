import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/standort.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import '../struktur/standort_formular.dart';

class KundenDetailScreen extends ConsumerWidget {
  const KundenDetailScreen({super.key, required this.kundeUuid});

  final String kundeUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kundenAsync = ref.watch(kundenProvider);
    final standorteAsync =
        ref.watch(standorteByKundeProvider(kundeUuid));

    final kunde = kundenAsync.when(
      data: (list) =>
          list.where((k) => k.uuid == kundeUuid).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/kunden')),
        title: Text(kunde?.name ?? 'Kunde'),
        backgroundColor: AppColors.surface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStandortFormular(context, ref, kundeUuid),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Standort'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Kundeninfo ────────────────────────────────────────────────
            if (kunde != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kunde.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${kunde.uuid.substring(0, 8).toUpperCase()}',
                      style: AppTheme.dataMono(
                          fontSize: 12, color: AppColors.outline),
                    ),
                    if (kunde.strasse != null || kunde.ort != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            [
                              if (kunde.strasse != null) kunde.strasse!,
                              if (kunde.plz != null && kunde.ort != null)
                                '${kunde.plz} ${kunde.ort}'
                              else if (kunde.ort != null)
                                kunde.ort!,
                            ].join(', '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                    if (kunde.kontaktEmail != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              size: 14,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            kunde.kontaktEmail!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                    if (kunde.kontaktTelefon != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 14,
                              color: AppColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            kunde.kontaktTelefon!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ── Standorte ─────────────────────────────────────────────────
            Text(
              'Standorte',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            standorteAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Fehler: $e'),
              data: (standorte) {
                if (standorte.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.outlineVariant,
                          style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.location_off_outlined,
                            size: 48,
                            color: AppColors.outlineVariant),
                        const SizedBox(height: 8),
                        Text(
                          'Noch keine Standorte',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => _showStandortFormular(
                              context, ref, kundeUuid),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Standort hinzufügen'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: standorte.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _StandortTile(
                    standort: standorte[i],
                    kundeUuid: kundeUuid,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStandortFormular(
      BuildContext context, WidgetRef ref, String kundeUuid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StandortFormular(
        kundeUuid: kundeUuid,
        existingStandort: null,
      ),
    );
  }
}

class _StandortTile extends StatelessWidget {
  const _StandortTile(
      {required this.standort, required this.kundeUuid});

  final Standort standort;
  final String kundeUuid;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(
          '/kunden/$kundeUuid/standort/${standort.uuid}'),
      child: Container(
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
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (standort.ort != null || standort.strasse != null)
                    Text(
                      [
                        if (standort.strasse != null) standort.strasse!,
                        if (standort.plz != null && standort.ort != null)
                          '${standort.plz} ${standort.ort}'
                        else if (standort.ort != null)
                          standort.ort!,
                      ].join(', '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward,
                size: 16, color: AppColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

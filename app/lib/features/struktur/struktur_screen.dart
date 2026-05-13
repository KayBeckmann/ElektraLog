import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/kunden_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../core/providers/verteiler_provider.dart';
import '../../shared/theme/app_colors.dart';

/// Top-level Struktur screen: lets the user navigate to a Verteiler.
/// Displays a 3-level accordion: Kunden → Standorte → Verteiler.
class StrukturScreen extends ConsumerWidget {
  const StrukturScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kundenAsync = ref.watch(kundenProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STRUKTUR',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.08 * 12,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              'Struktur-Editor',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary,
                  ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: kundenAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Fehler: $e'),
                data: (kunden) {
                  if (kunden.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_tree_outlined,
                              size: 64,
                              color: AppColors.outlineVariant),
                          const SizedBox(height: 16),
                          Text(
                            'Noch keine Kunden vorhanden',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/kunden'),
                            icon: const Icon(Icons.business_center,
                                size: 16),
                            label: const Text('Zu Kunden'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: kunden.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _KundeAccordion(kunde: kunden[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KundeAccordion extends ConsumerStatefulWidget {
  const _KundeAccordion({required this.kunde});

  final dynamic kunde;

  @override
  ConsumerState<_KundeAccordion> createState() =>
      _KundeAccordionState();
}

class _KundeAccordionState extends ConsumerState<_KundeAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final standorteAsync =
        ref.watch(standorteByKundeProvider(widget.kunde.uuid as String));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.business_center_outlined,
                color: AppColors.secondary),
            title: Text(
              widget.kunde.name as String,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            standorteAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Fehler: $e'),
              ),
              data: (standorte) {
                if (standorte.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Keine Standorte',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  );
                }
                return Column(
                  children: standorte
                      .map((s) => _StandortAccordion(
                            standort: s,
                            kundeUuid: widget.kunde.uuid as String,
                          ))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StandortAccordion extends ConsumerStatefulWidget {
  const _StandortAccordion(
      {required this.standort, required this.kundeUuid});

  final dynamic standort;
  final String kundeUuid;

  @override
  ConsumerState<_StandortAccordion> createState() =>
      _StandortAccordionState();
}

class _StandortAccordionState
    extends ConsumerState<_StandortAccordion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final verteilerAsync = ref.watch(
        verteilerByStandortProvider(widget.standort.uuid as String));

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
                color: AppColors.outlineVariant, width: 2),
          ),
        ),
        child: Column(
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.location_on_outlined,
                  size: 18, color: AppColors.secondary),
              title: Text(
                widget.standort.bezeichnung as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              trailing: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded)
              verteilerAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Fehler: $e'),
                data: (verteilerList) {
                  if (verteilerList.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        'Keine Verteiler',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: AppColors.onSurfaceVariant),
                      ),
                    );
                  }
                  return Column(
                    children: verteilerList
                        .map((v) => ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.only(
                                  left: 32, right: 8),
                              leading: const Icon(
                                  Icons.electrical_services_outlined,
                                  size: 16,
                                  color: AppColors.secondary),
                              title: Text(
                                v.bezeichnung,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600),
                              ),
                              trailing: const Icon(Icons.arrow_forward,
                                  size: 14,
                                  color: AppColors.onSurfaceVariant),
                              onTap: () => context.go(
                                '/kunden/${widget.kundeUuid}/standort/${widget.standort.uuid}/verteiler/${v.uuid}',
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

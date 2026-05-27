import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/kunde.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';
import 'kunde_formular.dart';

class KundenScreen extends ConsumerStatefulWidget {
  const KundenScreen({super.key});

  @override
  ConsumerState<KundenScreen> createState() => _KundenScreenState();
}

class _KundenScreenState extends ConsumerState<KundenScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kundenAsync = ref.watch(kundenProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page Header ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KUNDEN',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  letterSpacing: 0.08 * 12,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kundenverwaltung',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  color: AppColors.primary,
                                ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showKundeFormular(context, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Neuer Kunde'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Search + Filter ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Kunden suchen …',
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        fillColor: Colors.transparent,
                        filled: false,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 16),
                    label: const Text('Filter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.sort, size: 16),
                    label: const Text('Sort'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Grid ─────────────────────────────────────────────────────
            Expanded(
              child: kundenAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text('Fehler: $e'),
                ),
                data: (kunden) {
                  final filtered = _searchQuery.isEmpty
                      ? kunden
                      : kunden
                          .where((k) => k.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.business_center_outlined,
                            size: 64,
                            color: AppColors.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Noch keine Kunden angelegt',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showKundeFormular(context, null),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Ersten Kunden anlegen'),
                          ),
                        ],
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (ctx, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth >= 900) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth >= 600) {
                        crossAxisCount = 2;
                      }

                      return GridView.builder(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2.2,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          return _KundeCard(
                            kunde: filtered[i],
                            onEdit: () =>
                                _showKundeFormular(context, filtered[i]),
                            onDelete: () =>
                                _deleteKunde(context, filtered[i]),
                            onTap: () => context.go(
                              '/kunden/${filtered[i].uuid}',
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showKundeFormular(BuildContext context, Kunde? kunde) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => KundeFormular(existingKunde: kunde),
    );
  }

  Future<void> _deleteKunde(BuildContext context, Kunde kunde) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kunde löschen'),
        content: Text(
          'Möchtest du "${kunde.name}" wirklich löschen?',
        ),
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
    if (confirmed == true && mounted) {
      await ref.read(kundenRepositoryProvider).delete(kunde.uuid);
    }
  }
}

// ── KundeCard ─────────────────────────────────────────────────────────────────

class _KundeCard extends ConsumerWidget {
  const _KundeCard({
    required this.kunde,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Kunde kunde;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standorteAsync =
        ref.watch(standorteByKundeProvider(kunde.uuid));
    final standortCount = standorteAsync.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    kunde.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${kunde.uuid.substring(0, 8).toUpperCase()}',
                    style: AppTheme.dataMono(
                      fontSize: 11,
                      color: AppColors.outline,
                    ),
                  ),
                  if (kunde.ort != null || kunde.strasse != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _adresse(kunde),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Right side: standort badge + menu + arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$standortCount ${standortCount == 1 ? 'Standort' : 'Standorte'}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _MoreMenu(onEdit: onEdit, onDelete: onDelete),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _adresse(Kunde k) {
    final parts = <String>[];
    if (k.strasse != null) parts.add(k.strasse!);
    if (k.plz != null && k.ort != null) {
      parts.add('${k.plz} ${k.ort}');
    } else if (k.ort != null) {
      parts.add(k.ort!);
    }
    return parts.join(', ');
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 18,
        color: AppColors.onSurfaceVariant,
      ),
      padding: EdgeInsets.zero,
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
              Text(
                'Löschen',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_theme.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final protokolleProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ApiService.getProtokolle();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ProtokollUebersichtScreen extends ConsumerWidget {
  const ProtokollUebersichtScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(protokolleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
          tooltip: 'Zurück',
        ),
        title: const Text('Hochgeladene Protokolle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(protokolleProvider),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppColors.outline),
              const SizedBox(height: 12),
              Text(
                'Protokolle konnten nicht geladen werden',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                e.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.outline,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_outlined,
                      size: 48, color: AppColors.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Noch keine Protokolle hochgeladen',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ProtokollTile(data: list[i]),
          );
        },
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _ProtokollTile extends StatelessWidget {
  const _ProtokollTile({required this.data});

  final Map<String, dynamic> data;

  Future<void> _downloadPdf() async {
    final id = data['id'] as String?;
    if (id == null) return;
    final url = Uri.parse(ApiService.protokollPdfUrl(id));
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  String _formatDate(String? iso) {
    if (iso == null) return '–';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}.'
          '${d.month.toString().padLeft(2, '0')}.'
          '${d.year}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verteiler = data['verteilerBezeichnung'] as String? ?? '–';
    final kunde = data['kundenBezeichnung'] as String?;
    final standort = data['standortBezeichnung'] as String?;
    final datum = _formatDate(data['protokollDatum'] as String?);
    final pruefer = data['prueferName'] as String?;

    return Card(
      elevation: 0,
      color: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.description,
                color: AppColors.onSecondaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    verteiler,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (kunde != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      kunde,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                  if (standort != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      standort,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.outline,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  datum,
                  style: AppTheme.dataMono(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (pruefer != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    pruefer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.outline,
                          fontSize: 11,
                        ),
                  ),
                ],
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.download_outlined,
                      size: 18, color: AppColors.primary),
                  tooltip: 'PDF herunterladen',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _downloadPdf,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

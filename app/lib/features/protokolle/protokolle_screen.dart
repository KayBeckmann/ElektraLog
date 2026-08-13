import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../core/api/api_service.dart';
import '../../core/providers/isar_provider.dart';
import '../../core/providers/pruefprotokoll_provider.dart';
import '../../core/sync/sync_service.dart';
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
      body: Column(
        children: [
          const _PendingUploadsBanner(),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off,
                        size: 48, color: AppColors.outline),
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          ),
        ],
      ),
    );
  }
}

// ── Ausstehende Uploads ──────────────────────────────────────────────────────

/// Zeigt lokal noch nicht hochgeladene Prüfprotokolle an (z.B. weil der
/// Monteur beim Erstellen keinen Empfang hatte oder der Token abgelaufen
/// war) und bietet einen manuellen Retry an — ergänzt den automatischen
/// Retry in [SyncService.autoSync], der erst beim nächsten Sync greift.
class _PendingUploadsBanner extends ConsumerStatefulWidget {
  const _PendingUploadsBanner();

  @override
  ConsumerState<_PendingUploadsBanner> createState() =>
      _PendingUploadsBannerState();
}

class _PendingUploadsBannerState extends ConsumerState<_PendingUploadsBanner> {
  bool _uploading = false;

  Future<void> _jetztHochladen() async {
    setState(() => _uploading = true);
    try {
      final db = await ref.read(dbProvider.future);
      await SyncService.retryAusstehendeProtokolle(db);
      ref.invalidate(protokolleProvider);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ausstehendAsync = ref.watch(allePruefprotokolleProvider);
    final ausstehend = ausstehendAsync.valueOrNull
            ?.where((p) => p.backendUuid == null && p.pdfBase64 != null)
            .toList() ??
        const [];

    if (ausstehend.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: AppColors.warningContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined,
              size: 20, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ausstehend.length == 1
                  ? '1 Protokoll wurde noch nicht hochgeladen'
                  : '${ausstehend.length} Protokolle wurden noch nicht hochgeladen',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          _uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.warning,
                  ),
                )
              : TextButton(
                  onPressed: _jetztHochladen,
                  style: TextButton.styleFrom(foregroundColor: AppColors.warning),
                  child: const Text('Jetzt hochladen'),
                ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _ProtokollTile extends StatelessWidget {
  const _ProtokollTile({required this.data});

  final Map<String, dynamic> data;

  Future<void> _downloadPdf(BuildContext context) async {
    final id = data['id'] as String?;
    if (id == null) return;
    try {
      final bytes = await ApiService.getProtokollPdf(id);
      final verteiler = data['verteilerBezeichnung'] as String? ?? 'Protokoll';
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Protokoll_$verteiler.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF-Fehler: $e')),
        );
      }
    }
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
                  onPressed: () => _downloadPdf(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

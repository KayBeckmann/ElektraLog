import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/verteiler_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/sichtpruefung_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'komponenten_baum_widget.dart';
import 'komponente_formular.dart';

class VerteilerDetailScreen extends ConsumerWidget {
  const VerteilerDetailScreen({
    super.key,
    required this.kundeUuid,
    required this.standortUuid,
    required this.verteilerUuid,
  });

  final String kundeUuid;
  final String standortUuid;
  final String verteilerUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verteilerAsync =
        ref.watch(verteilerByStandortProvider(standortUuid));
    final standorteAsync =
        ref.watch(standorteByKundeProvider(kundeUuid));
    final kundenAsync = ref.watch(kundenProvider);
    final sichtpruefungenAsync =
        ref.watch(sichtpruefungenByVerteilerProvider(verteilerUuid));

    final verteiler = verteilerAsync.when(
      data: (list) =>
          list.where((v) => v.uuid == verteilerUuid).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );

    final standort = standorteAsync.when(
      data: (list) =>
          list.where((s) => s.uuid == standortUuid).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );

    final kunde = kundenAsync.when(
      data: (list) => list.where((k) => k.uuid == kundeUuid).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );

    // Check if a valid Sichtprüfung exists (bestanden or mit_maengeln)
    final hatGueltigeSichtpruefung = sichtpruefungenAsync.when(
      data: (list) => list.any((s) =>
          s.ergebnis == 'bestanden' || s.ergebnis == 'mit_maengeln'),
      loading: () => true, // don't block while loading
      error: (_, __) => true,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context
              .go('/kunden/$kundeUuid/standort/$standortUuid'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verteiler?.bezeichnung ?? 'Verteiler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (verteiler != null && verteiler.anlagendatenJson != null)
              _AnlagendatenBadge(
                  json: verteiler.anlagendatenJson!),
          ],
        ),
        backgroundColor: AppColors.surface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showKomponenteFormular(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Komponente'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Column(
        children: [
          // ── Sichtprüfung Lock Banner ─────────────────────────────────────
          if (!hatGueltigeSichtpruefung)
            _SichtpruefungLockBanner(
              verteilerUuid: verteilerUuid,
              verteilerBezeichnung: verteiler?.bezeichnung ?? 'Verteiler',
              kundeUuid: kundeUuid,
              standortUuid: standortUuid,
            ),

          // ── Breadcrumb ──────────────────────────────────────────────────
          Container(
            color: AppColors.surfaceContainerLow,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _BreadcrumbItem(
                  label: kunde?.name ?? '…',
                  onTap: () => context.go('/kunden/$kundeUuid'),
                ),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.onSurfaceVariant),
                _BreadcrumbItem(
                  label: standort?.bezeichnung ?? '…',
                  onTap: () => context
                      .go('/kunden/$kundeUuid/standort/$standortUuid'),
                ),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.onSurfaceVariant),
                Text(
                  verteiler?.bezeichnung ?? '…',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // ── Komponenten Baum ────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: KomponentenBaumWidget(
                verteilerUuid: verteilerUuid,
                onAddKomponente: (parentUuid) =>
                    _showKomponenteFormular(context, parentUuid),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showKomponenteFormular(
      BuildContext context, String? parentUuid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => KomponenteFormular(
        verteilerUuid: verteilerUuid,
        parentUuid: parentUuid,
      ),
    );
  }
}

class _BreadcrumbItem extends StatelessWidget {
  const _BreadcrumbItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _SichtpruefungLockBanner extends StatelessWidget {
  const _SichtpruefungLockBanner({
    required this.verteilerUuid,
    required this.verteilerBezeichnung,
    required this.kundeUuid,
    required this.standortUuid,
  });

  final String verteilerUuid;
  final String verteilerBezeichnung;
  final String kundeUuid;
  final String standortUuid;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(
        '/kunden/$kundeUuid/standort/$standortUuid/verteiler/$verteilerUuid/sichtpruefung',
        extra: {'bezeichnung': verteilerBezeichnung},
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.errorContainer,
        child: Row(
          children: [
            const Icon(Icons.lock_outline,
                size: 18, color: AppColors.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Keine gültige Sichtprüfung. Messung erfassen gesperrt. '
                'Tippen zum Starten.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.onErrorContainer),
          ],
        ),
      ),
    );
  }
}

class _AnlagendatenBadge extends StatelessWidget {
  const _AnlagendatenBadge({required this.json});

  final String json;

  @override
  Widget build(BuildContext context) {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final netzform = data['netzform'] as String? ?? '';
      final spannung = data['nennspannung'] as String? ?? '';
      return Text(
        '$netzform · $spannung',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

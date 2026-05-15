import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../core/providers/verteiler_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/sichtpruefung_provider.dart';
import '../../core/providers/komponenten_provider.dart';
import '../../core/models/messung.dart';
import '../../core/providers/messungen_provider.dart';
import '../../core/providers/geraete_provider.dart';
import '../../features/pdf/pdf_options_sheet.dart';
import '../../features/pdf/pdf_service.dart';
import '../../shared/theme/app_colors.dart';
import 'komponenten_baum_widget.dart';
import 'komponente_formular.dart';

class VerteilerDetailScreen extends ConsumerStatefulWidget {
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
  ConsumerState<VerteilerDetailScreen> createState() =>
      _VerteilerDetailScreenState();
}

class _VerteilerDetailScreenState
    extends ConsumerState<VerteilerDetailScreen> {
  bool _pdfLoading = false;

  @override
  Widget build(BuildContext context) {
    final verteilerAsync =
        ref.watch(verteilerByStandortProvider(widget.standortUuid));
    final standorteAsync =
        ref.watch(standorteByKundeProvider(widget.kundeUuid));
    final kundenAsync = ref.watch(kundenProvider);
    final sichtpruefungenAsync =
        ref.watch(sichtpruefungenByVerteilerProvider(widget.verteilerUuid));

    final verteiler = verteilerAsync.when(
      data: (list) =>
          list.where((v) => v.uuid == widget.verteilerUuid).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );
    final standort = standorteAsync.when(
      data: (list) =>
          list.where((s) => s.uuid == widget.standortUuid).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );
    final kunde = kundenAsync.when(
      data: (list) =>
          list.where((k) => k.uuid == widget.kundeUuid).firstOrNull,
      loading: () => null,
      error: (_, __) => null,
    );
    final hatGueltigeSichtpruefung = sichtpruefungenAsync.when(
      data: (list) => list.any((s) =>
          s.ergebnis == 'bestanden' || s.ergebnis == 'mit_maengeln'),
      loading: () => true,
      error: (_, __) => true,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.go(
              '/kunden/${widget.kundeUuid}/standort/${widget.standortUuid}'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verteiler?.bezeichnung ?? 'Verteiler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (verteiler != null && verteiler.anlagendatenJson != null)
              _AnlagendatenBadge(json: verteiler.anlagendatenJson!),
          ],
        ),
        backgroundColor: AppColors.surface,
        actions: [
          // ── PDF-Protokoll generieren ────────────────────────────────
          Tooltip(
            message: 'Prüfprotokoll generieren',
            child: _pdfLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: verteiler == null
                        ? null
                        : () => _generatePdf(
                              context,
                              sichtpruefungen: sichtpruefungenAsync.value ?? [],
                              kundenName: kunde?.name,
                              standortBezeichnung: standort?.bezeichnung,
                            ),
                  ),
          ),
        ],
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
          if (!hatGueltigeSichtpruefung)
            _SichtpruefungLockBanner(
              verteilerUuid: widget.verteilerUuid,
              verteilerBezeichnung: verteiler?.bezeichnung ?? 'Verteiler',
              kundeUuid: widget.kundeUuid,
              standortUuid: widget.standortUuid,
            ),
          Container(
            color: AppColors.surfaceContainerLow,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _BreadcrumbItem(
                  label: kunde?.name ?? '…',
                  onTap: () =>
                      context.go('/kunden/${widget.kundeUuid}'),
                ),
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.onSurfaceVariant),
                _BreadcrumbItem(
                  label: standort?.bezeichnung ?? '…',
                  onTap: () => context.go(
                      '/kunden/${widget.kundeUuid}/standort/${widget.standortUuid}'),
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: KomponentenBaumWidget(
                verteilerUuid: widget.verteilerUuid,
                onAddKomponente: (parentUuid) =>
                    _showKomponenteFormular(context, parentUuid),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePdf(
    BuildContext context, {
    required List sichtpruefungen,
    String? kundenName,
    String? standortBezeichnung,
  }) async {
    final verteilerList =
        await ref.read(verteilerByStandortProvider(widget.standortUuid).future);
    final verteiler =
        verteilerList.where((v) => v.uuid == widget.verteilerUuid).firstOrNull;
    if (verteiler == null || !mounted) return;

    final opts = await PdfOptionsSheet.show(
      context,
      titel: verteiler.bezeichnung,
    );
    if (opts == null || !mounted) return;

    setState(() => _pdfLoading = true);
    try {
      final kompList = await ref
          .read(komponentenByVerteilerProvider(widget.verteilerUuid).future);
      final kompUuids = kompList.map((k) => k.uuid).toList();
      final messungen = await ref
          .read(messungenRepositoryProvider)
          .getByKomponenteUuids(kompUuids);

      final geraete = await ref
          .read(geraeteByStandortProvider(widget.standortUuid).future);
      final messRepo = ref.read(messungenRepositoryProvider);
      final geraeteMessungen = <Messung>[];
      for (final g in geraete) {
        geraeteMessungen.addAll(await messRepo.getByGeraet(g.uuid));
      }

      final bytes = await PdfService.generateProtokoll(
        prueferName: opts.prueferName,
        firma: opts.firma,
        pruefgeraet: opts.pruefgeraet,
        datumOrt: opts.datumOrt,
        kundenName: kundenName,
        standortBezeichnung: standortBezeichnung,
        verteiler: verteiler,
        sichtpruefungen: sichtpruefungen.cast(),
        komponenten: kompList,
        messungen: messungen,
        geraete: geraete,
        geraeteMessungen: geraeteMessungen,
        signaturPng: opts.signaturPng,
      );

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Protokoll_${verteiler.bezeichnung}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF-Fehler: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
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
        verteilerUuid: widget.verteilerUuid,
        parentUuid: parentUuid,
      ),
    );
  }
}

// ── Hilfs-Widgets ─────────────────────────────────────────────────────────────

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
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.errorContainer,
        child: Row(
          children: [
            const Icon(Icons.lock_outline,
                size: 18, color: AppColors.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Keine gültige Sichtprüfung — Messung gesperrt. Tippen zum Starten.',
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

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
import '../../core/api/api_service.dart';
import '../../core/models/geraet.dart';
import '../../core/models/messung.dart';
import '../../core/models/pruefprotokoll.dart';
import '../../core/models/sichtpruefung.dart';
import '../../core/models/verteiler_komponente.dart';
import '../../core/providers/messungen_provider.dart';
import '../../core/providers/geraete_provider.dart';
import '../../core/providers/pruefprotokoll_provider.dart';
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Prüfverlauf-Karte ─────────────────────────────────
                  _PruefverlaufKarte(
                    verteilerUuid: widget.verteilerUuid,
                    pruefintervallJahre: verteiler?.pruefintervallJahre ?? 4,
                  ),
                  const SizedBox(height: 16),
                  // ── Sichtprüfung-Karte ────────────────────────────────
                  _SichtpruefungKarte(
                    verteilerUuid: widget.verteilerUuid,
                    verteilerBezeichnung:
                        verteiler?.bezeichnung ?? 'Verteiler',
                    kundeUuid: widget.kundeUuid,
                    standortUuid: widget.standortUuid,
                    sichtpruefungenAsync: sichtpruefungenAsync,
                    hatGueltigeSichtpruefung: hatGueltigeSichtpruefung,
                  ),
                  const SizedBox(height: 16),
                  KomponentenBaumWidget(
                    verteilerUuid: widget.verteilerUuid,
                    onAddKomponente: (parentUuid) =>
                        _showKomponenteFormular(context, parentUuid),
                  ),
                ],
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

      // Messdaten-Snapshot einfrieren
      final snapshot = _buildSnapshot(
        komponenten: kompList,
        messungen: messungen,
        sichtpruefungen: sichtpruefungen.cast(),
        geraete: geraete,
        geraeteMessungen: geraeteMessungen,
      );

      // Protokoll-Eintrag im Verlauf speichern
      final protokoll = Pruefprotokoll(
        verteilerUuid: widget.verteilerUuid,
        protokollDatum: DateTime.now(),
        prueferName: opts.prueferName.isEmpty ? null : opts.prueferName,
        firma: (opts.firma?.isEmpty ?? true) ? null : opts.firma,
        verteilerBezeichnung: verteiler.bezeichnung,
        standortBezeichnung: standortBezeichnung,
        kundenBezeichnung: kundenName,
        messdatenSnapshot: snapshot,
      );
      final repo = ref.read(pruefprotokollRepositoryProvider);
      await repo.save(protokoll);

      // Im Hintergrund ins Backend hochladen (non-blocking, offline-tolerant)
      ApiService.uploadProtokoll(
        pdfBytes: bytes,
        verteilerBezeichnung: verteiler.bezeichnung,
        standortBezeichnung: standortBezeichnung,
        kundenBezeichnung: kundenName,
        prueferName: opts.prueferName.isEmpty ? null : opts.prueferName,
        firmaName: opts.firma?.isEmpty ?? true ? null : opts.firma,
        protokollDatum: protokoll.protokollDatum,
        messdatenJson: snapshot,
      ).then((backendUuid) async {
        if (backendUuid != null) {
          await repo.save(protokoll.mitBackendUuid(backendUuid));
        }
      });

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

  /// Baut einen unveränderlichen Messdaten-Snapshot für den Prüfverlauf.
  static String _buildSnapshot({
    required List<VerteilerKomponente> komponenten,
    required List<Messung> messungen,
    required List<Sichtpruefung> sichtpruefungen,
    required List<Geraet> geraete,
    required List<Messung> geraeteMessungen,
  }) {
    final messungenByKomponente = <String, List<Map<String, dynamic>>>{};
    for (final m in messungen) {
      if (m.komponenteUuid != null) {
        messungenByKomponente
            .putIfAbsent(m.komponenteUuid!, () => [])
            .add({
          'uuid': m.uuid,
          'norm': m.norm,
          'pruefungDatum': m.pruefungDatum.toIso8601String(),
          'prueferName': m.prueferName,
          'ergebnis': m.ergebnis,
          'messwertJson': m.messwertJson,
          'bemerkung': m.bemerkung,
        });
      }
    }

    final messungenByGeraet = <String, List<Map<String, dynamic>>>{};
    for (final m in geraeteMessungen) {
      if (m.geraetUuid != null) {
        messungenByGeraet
            .putIfAbsent(m.geraetUuid!, () => [])
            .add({
          'uuid': m.uuid,
          'norm': m.norm,
          'pruefungDatum': m.pruefungDatum.toIso8601String(),
          'prueferName': m.prueferName,
          'ergebnis': m.ergebnis,
          'messwertJson': m.messwertJson,
          'bemerkung': m.bemerkung,
        });
      }
    }

    final latestSichtpruefung =
        sichtpruefungen.isEmpty ? null : sichtpruefungen.first;

    return jsonEncode({
      'komponenten': [
        for (final k in komponenten)
          if ((messungenByKomponente[k.uuid] ?? []).isNotEmpty)
            {
              'uuid': k.uuid,
              'bezeichnung': k.bezeichnung,
              'typ': k.typ,
              'parentUuid': k.parentUuid,
              'eigenschaftenJson': k.eigenschaftenJson,
              'messungen': messungenByKomponente[k.uuid],
            }
      ],
      'sichtpruefung': latestSichtpruefung == null
          ? null
          : {
              'uuid': latestSichtpruefung.uuid,
              'pruefungDatum':
                  latestSichtpruefung.pruefungDatum.toIso8601String(),
              'prueferName': latestSichtpruefung.prueferName,
              'ergebnis': latestSichtpruefung.ergebnis,
              'checklisteJson': latestSichtpruefung.checklisteJson,
              'maengel': latestSichtpruefung.maengel,
            },
      'geraete': [
        for (final g in geraete)
          if ((messungenByGeraet[g.uuid] ?? []).isNotEmpty)
            {
              'uuid': g.uuid,
              'bezeichnung': g.bezeichnung,
              'geraetetyp': g.geraetetyp,
              'hersteller': g.hersteller,
              'seriennummer': g.seriennummer,
              'messungen': messungenByGeraet[g.uuid],
            }
      ],
    });
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

// ── Sichtprüfung-Karte ────────────────────────────────────────────────────────

class _SichtpruefungKarte extends StatelessWidget {
  const _SichtpruefungKarte({
    required this.verteilerUuid,
    required this.verteilerBezeichnung,
    required this.kundeUuid,
    required this.standortUuid,
    required this.sichtpruefungenAsync,
    required this.hatGueltigeSichtpruefung,
  });

  final String verteilerUuid;
  final String verteilerBezeichnung;
  final String kundeUuid;
  final String standortUuid;
  final AsyncValue<List<Sichtpruefung>> sichtpruefungenAsync;
  final bool hatGueltigeSichtpruefung;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final sichtpruefungen = sichtpruefungenAsync.valueOrNull ?? [];
    final latest = sichtpruefungen.isEmpty ? null : sichtpruefungen.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sektions-Header ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                color: AppColors.primary,
                margin: const EdgeInsets.only(right: 6),
              ),
              Text(
                'SICHTPRÜFUNG',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
              ),
            ],
          ),
        ),

        // ── Letztes Ergebnis (wenn gültige SP vorhanden) ─────────────
        if (hatGueltigeSichtpruefung && latest != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.successContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bestanden am ${_fmt(latest.pruefungDatum)}'
                    '${latest.prueferName != null ? " · ${latest.prueferName}" : ""}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // ── Neue Sichtprüfung starten ──────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(
              '/kunden/$kundeUuid/standort/$standortUuid'
              '/verteiler/$verteilerUuid/sichtpruefung'
              '?bezeichnung=${Uri.encodeComponent(verteilerBezeichnung)}',
            ),
            icon: const Icon(Icons.search_outlined, size: 18),
            label: const Text('Neue Sichtprüfung starten'),
          ),
        ),
      ],
    );
  }
}

// ── Prüfverlauf-Karte ─────────────────────────────────────────────────────────

class _PruefverlaufKarte extends ConsumerWidget {
  const _PruefverlaufKarte({
    required this.verteilerUuid,
    required this.pruefintervallJahre,
  });

  final String verteilerUuid;
  final int pruefintervallJahre;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protokolleAsync =
        ref.watch(pruefprotokolleByVerteilerProvider(verteilerUuid));

    return protokolleAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (protokolle) {
        final letztes = protokolle.isEmpty ? null : protokolle.first;
        final naechste = letztes == null
            ? null
            : DateTime(
                letztes.protokollDatum.year + pruefintervallJahre,
                letztes.protokollDatum.month,
                letztes.protokollDatum.day,
              );
        final istUeberfaellig =
            naechste != null && naechste.isBefore(DateTime.now());
        final istBaldFaellig = naechste != null &&
            !istUeberfaellig &&
            naechste.isBefore(DateTime.now().add(const Duration(days: 90)));

        Color borderColor = AppColors.outlineVariant;
        Color bgColor = AppColors.surfaceContainerLowest;
        if (istUeberfaellig) {
          borderColor = AppColors.error;
          bgColor = AppColors.errorContainer;
        } else if (istBaldFaellig) {
          borderColor = AppColors.warning;
          bgColor = AppColors.warningContainer;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nächste-Prüfung-Statusleiste ─────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    istUeberfaellig
                        ? Icons.warning_amber_outlined
                        : Icons.history_outlined,
                    size: 20,
                    color: istUeberfaellig
                        ? AppColors.error
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (letztes == null)
                          Text(
                            'Noch kein Prüfprotokoll erstellt',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          )
                        else ...[
                          Text(
                            'Letztes Protokoll: ${_fmt(letztes.protokollDatum)}'
                            '${letztes.prueferName != null ? " · ${letztes.prueferName}" : ""}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (naechste != null)
                            Text(
                              istUeberfaellig
                                  ? 'Prüfung überfällig seit ${_fmt(naechste)}!'
                                  : 'Nächste Prüfung: ${_fmt(naechste)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: istUeberfaellig
                                        ? AppColors.error
                                        : istBaldFaellig
                                            ? AppColors.warning
                                            : AppColors.onSurfaceVariant,
                                    fontWeight: istUeberfaellig
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  if (protokolle.length > 1)
                    Text(
                      '${protokolle.length}×',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),

            // ── Verlaufs-Liste ────────────────────────────────────────
            if (protokolle.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...protokolle.map((p) => _ProtokollVerlaufTile(protokoll: p)),
            ],
          ],
        );
      },
    );
  }
}

// ── Protokoll-Verlauf-Tile ────────────────────────────────────────────────────

class _ProtokollVerlaufTile extends StatefulWidget {
  const _ProtokollVerlaufTile({required this.protokoll});
  final Pruefprotokoll protokoll;

  @override
  State<_ProtokollVerlaufTile> createState() => _ProtokollVerlaufTileState();
}

class _ProtokollVerlaufTileState extends State<_ProtokollVerlaufTile> {
  bool _expanded = false;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final p = widget.protokoll;
    final hasSnapshot = p.messdatenSnapshot != null;

    Map<String, dynamic>? snapshot;
    if (hasSnapshot) {
      try {
        snapshot = jsonDecode(p.messdatenSnapshot!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final komponenten = (snapshot?['komponenten'] as List<dynamic>?) ?? [];
    final geraete = (snapshot?['geraete'] as List<dynamic>?) ?? [];
    final sichtpruefung = snapshot?['sichtpruefung'] as Map<String, dynamic>?;
    final istSynced = p.backendUuid != null;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: hasSnapshot
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fmt(p.protokollDatum),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (p.prueferName != null)
                          Text(
                            p.prueferName!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  // Sync-Status
                  Tooltip(
                    message: istSynced
                        ? 'Im Backend archiviert'
                        : 'Noch nicht synchronisiert',
                    child: Icon(
                      istSynced
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                      size: 16,
                      color: istSynced
                          ? AppColors.success
                          : AppColors.outlineVariant,
                    ),
                  ),
                  if (hasSnapshot) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Aufgeklappte Messdaten ──────────────────────────────────
          if (_expanded && snapshot != null) ...[
            const Divider(height: 1, color: AppColors.outlineVariant),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sichtprüfung
                  if (sichtpruefung != null) ...[
                    _SnapshotSection(
                      label: 'Sichtprüfung',
                      ergebnis: sichtpruefung['ergebnis'] as String? ?? '—',
                      datum: sichtpruefung['pruefungDatum'] as String?,
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Komponenten
                  if (komponenten.isNotEmpty) ...[
                    Text(
                      'ANLAGE — ${komponenten.length} Komponente(n)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.6,
                          ),
                    ),
                    const SizedBox(height: 4),
                    ...komponenten.map((k) {
                      final kMap = k as Map<String, dynamic>;
                      final messungen =
                          (kMap['messungen'] as List<dynamic>?) ?? [];
                      return _SnapshotKomponenteRow(
                        bezeichnung: kMap['bezeichnung'] as String? ?? '—',
                        typ: kMap['typ'] as String? ?? '',
                        messungen: messungen
                            .map((m) => m as Map<String, dynamic>)
                            .toList(),
                      );
                    }),
                  ],
                  // Geräte
                  if (geraete.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'GERÄTE — ${geraete.length} Gerät(e)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.6,
                          ),
                    ),
                    const SizedBox(height: 4),
                    ...geraete.map((g) {
                      final gMap = g as Map<String, dynamic>;
                      final messungen =
                          (gMap['messungen'] as List<dynamic>?) ?? [];
                      return _SnapshotKomponenteRow(
                        bezeichnung: gMap['bezeichnung'] as String? ?? '—',
                        typ: gMap['geraetetyp'] as String? ?? 'Gerät',
                        messungen: messungen
                            .map((m) => m as Map<String, dynamic>)
                            .toList(),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SnapshotSection extends StatelessWidget {
  const _SnapshotSection({
    required this.label,
    required this.ergebnis,
    this.datum,
  });
  final String label;
  final String ergebnis;
  final String? datum;

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (ergebnis) {
      case 'bestanden':
        color = AppColors.success;
        icon = Icons.check_circle_outline;
      case 'mit_maengeln':
        color = AppColors.warning;
        icon = Icons.warning_amber_outlined;
      default:
        color = AppColors.error;
        icon = Icons.cancel_outlined;
    }
    String? datumStr;
    if (datum != null) {
      try {
        final d = DateTime.parse(datum!);
        datumStr =
            '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
      } catch (_) {}
    }
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          '$label${datumStr != null ? " · $datumStr" : ""}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SnapshotKomponenteRow extends StatelessWidget {
  const _SnapshotKomponenteRow({
    required this.bezeichnung,
    required this.typ,
    required this.messungen,
  });
  final String bezeichnung;
  final String typ;
  final List<Map<String, dynamic>> messungen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              bezeichnung,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          ...messungen.map((m) {
            final ergebnis = m['ergebnis'] as String? ?? '';
            final norm = m['norm'] as String? ?? '';
            final normShort = switch (norm) {
              'vde_0100' => '0100',
              'vde_0701_0702' => '0701',
              'dguv_v3' => 'DGUV',
              _ => norm,
            };
            final ok = ergebnis == 'bestanden';
            return Container(
              margin: const EdgeInsets.only(left: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: ok
                    ? AppColors.successContainer
                    : AppColors.errorContainer,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '$normShort ${ok ? '✓' : '✗'}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: ok ? AppColors.success : AppColors.error,
                ),
              ),
            );
          }),
        ],
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

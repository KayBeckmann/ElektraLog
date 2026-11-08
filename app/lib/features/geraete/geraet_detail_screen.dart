import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_service.dart';
import '../../core/models/geraet.dart';
import '../../core/models/geraete_faelligkeit.dart';
import '../../core/models/pruefmatrix.dart';
import '../../core/providers/einstellungen_provider.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/geraete_provider.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/module_provider.dart';
import '../../core/providers/permission_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../core/models/geraete_protokoll.dart';
import 'geraet_formular.dart';
import 'etiketten_dialog.dart';
import 'geraete_protokoll_sheet.dart';
import 'geraete_widgets.dart';

/// Gerätedetail — auch Ziel des Etiketten-Scans (`/geraete/<uuid>`).
class GeraetDetailScreen extends ConsumerWidget {
  const GeraetDetailScreen({super.key, required this.geraetUuid});

  final String geraetUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final module = ref.watch(aktiveModuleProvider);
    final geraetAsync = ref.watch(geraetProvider(geraetUuid));
    final geraet = geraetAsync.valueOrNull;

    Widget body;
    if (!module.geraetepruefung) {
      // Kein Weg am Modulschalter vorbei, auch nicht per Scan.
      body = const GeraeteHinweis(
        key: Key('geraet-modul-aus'),
        icon: Icons.toggle_off_outlined,
        titel: 'Geräteprüfung ist ausgeschaltet',
        text: 'Der Firmenadmin kann das Modul unter Einstellungen → Module einschalten. Daten bleiben erhalten.',
      );
    } else if (geraetAsync.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (geraet == null) {
      body = const GeraeteHinweis(
        key: Key('geraet-unbekannt'),
        icon: Icons.help_outline,
        titel: 'Gerät nicht auf diesem Gerät vorhanden',
        text: 'Der Raum ist evtl. nicht für die Synchronisation ausgewählt. Raum oder Standort auswählen, '
            'synchronisieren und erneut versuchen.',
      );
    } else {
      body = _Inhalt(geraet: geraet);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => geraet == null
              ? context.go('/')
              : context.go('/kunden/${geraet.kundeUuid}/standort/${geraet.standortUuid}/raum/${geraet.raumUuid}'),
        ),
        title: Text(geraet?.bezeichnung ?? 'Gerät'),
        backgroundColor: AppColors.surface,
        actions: [
          if (geraet != null && module.geraetepruefung) ...[
            IconButton(
              key: const Key('geraet-bearbeiten'),
              tooltip: 'Bearbeiten',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => zeigeGeraetFormular(context, geraet: geraet),
            ),
            _Menue(geraet: geraet),
          ],
        ],
      ),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: body),
    );
  }
}

class _Menue extends ConsumerWidget {
  const _Menue({required this.geraet});

  final Geraet geraet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mit Prüfungen nur noch inaktiv setzen — die Historie bleibt (wie Server: 409).
    final hatPruefungen = ref.watch(pruefungenByGeraetProvider(geraet.uuid)).valueOrNull?.isNotEmpty ?? true;
    final darfLoeschen = !hatPruefungen && (ref.watch(berechtigungenProvider).valueOrNull?.hatVollzugriff ?? false);
    return PopupMenuButton<String>(
      key: const Key('geraet-menue'),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'status',
          child: Text(geraet.aktiv ? 'Inaktiv setzen' : 'Wieder aktiv setzen'),
        ),
        const PopupMenuItem(value: 'etikett', child: Text('Etikett drucken')),
        const PopupMenuItem(value: 'protokoll', child: Text('Protokoll (PDF)')),
        const PopupMenuItem(value: 'uuid', child: Text('UUID kopieren')),
        if (darfLoeschen) const PopupMenuItem(value: 'loeschen', child: Text('Löschen')),
      ],
      onSelected: (v) async {
        switch (v) {
          case 'status':
            await statusWechseln(context, ref, geraet);
          case 'etikett':
            await zeigeEtikettenDialog(context, [geraet]);
          case 'protokoll':
            await zeigeGeraeteProtokoll(
              context,
              umfang: ProtokollUmfang.geraet,
              kundeUuid: geraet.kundeUuid,
              standortUuid: geraet.standortUuid,
              geraetUuid: geraet.uuid,
            );
          case 'uuid':
            await Clipboard.setData(ClipboardData(text: geraet.uuid));
          case 'loeschen':
            await _loeschen(context, ref);
        }
      },
    );
  }

  Future<void> _loeschen(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerät löschen'),
        content: const Text('Nicht mehr genutzte Geräte besser inaktiv setzen — dann bleibt die Historie sichtbar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: AppColors.onError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(geraeteRepositoryProvider).delete(geraet.uuid);
    ApiService.deleteGeraet(geraet.uuid).catchError((_) {});
    if (context.mounted) {
      context.go('/kunden/${geraet.kundeUuid}/standort/${geraet.standortUuid}/raum/${geraet.raumUuid}');
    }
  }
}

/// Aktiv ↔ inaktiv. Inaktiv verlangt einen Grund; der Wechsel ist keine
/// Prüfung und verschiebt keinen Prüftermin.
Future<void> statusWechseln(BuildContext context, WidgetRef ref, Geraet geraet) async {
  final benutzer = (await ref.read(currentUserProvider.future))['name'] as String?;
  if (!context.mounted) return;
  if (geraet.aktiv) {
    final grund = await showDialog<String>(context: context, builder: (_) => const _GrundDialog());
    if (grund == null) return;
    await ref.read(geraeteRepositoryProvider).save(geraet.mitStatus(aktiv: false, grund: grund, benutzer: benutzer));
  } else {
    await ref.read(geraeteRepositoryProvider).save(geraet.mitStatus(aktiv: true, benutzer: benutzer));
  }
}

class _GrundDialog extends StatefulWidget {
  const _GrundDialog();

  @override
  State<_GrundDialog> createState() => _GrundDialogState();
}

class _GrundDialogState extends State<_GrundDialog> {
  final _grund = TextEditingController();
  static const _vorschlaege = ['Defekt / in Reparatur', 'Ausgesondert', 'Nicht in Verwendung'];

  @override
  void dispose() {
    _grund.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Gerät inaktiv setzen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inaktive Geräte werden nicht geprüft und erscheinen in keiner Terminliste. '
                'Der Grund steht in der Geräteübersicht des Protokolls.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: [
                for (final v in _vorschlaege)
                  ActionChip(label: Text(v), onPressed: () => setState(() => _grund.text = v)),
              ],
            ),
            TextField(
              key: const Key('inaktiv-grund'),
              controller: _grund,
              decoration: const InputDecoration(labelText: 'Grund *'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
          ElevatedButton(
            key: const Key('inaktiv-bestaetigen'),
            onPressed: _grund.text.trim().isEmpty ? null : () => Navigator.pop(context, _grund.text.trim()),
            child: const Text('Inaktiv setzen'),
          ),
        ],
      );
}

class _Inhalt extends ConsumerWidget {
  const _Inhalt({required this.geraet});

  final Geraet geraet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kunde =
        (ref.watch(kundenProvider).valueOrNull ?? const []).where((k) => k.uuid == geraet.kundeUuid).firstOrNull;
    final standort = (ref.watch(standorteByKundeProvider(geraet.kundeUuid)).valueOrNull ?? const [])
        .where((s) => s.uuid == geraet.standortUuid)
        .firstOrNull;
    final raum = (ref.watch(raeumeByStandortProvider(geraet.standortUuid)).valueOrNull ?? const [])
        .where((r) => r.uuid == geraet.raumUuid)
        .firstOrNull;
    final letzte = geraet.letztePruefungDatum;
    final nachweis = ref.watch(geraetPruefNachweisProvider(geraet.uuid)).valueOrNull;
    final termin = geraetTermin(geraet, letztePruefung: nachweis, heute: DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!geraet.aktiv)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GeraeteHinweis(
              key: const Key('geraet-inaktiv'),
              icon: Icons.pause_circle_outline,
              titel: 'Inaktiv',
              text: '${geraet.inaktivGrund ?? ''}\nWird aktuell nicht geprüft.',
            ),
          ),
        _Karte(titel: 'Ort', zeilen: [
          ('Kunde', kunde?.name ?? '?'),
          ('Standort', standort?.bezeichnung ?? '?'),
          ('Raum', raum?.bezeichnung ?? '?'),
        ]),
        const SizedBox(height: 12),
        _Karte(titel: 'Stammdaten', zeilen: [
          ('Hersteller', geraet.hersteller),
          ('Type', geraet.typ),
          ('Seriennummer', geraet.seriennummer),
          ('Inventarnummer', geraet.inventarnummer),
          ('Schutzart', geraet.schutzart),
          ('Schutzklasse', geraet.schutzklasse ?? 'nicht festgestellt'),
          ('Bemerkung', geraet.bemerkung),
          ('UUID', geraet.uuid),
        ]),
        const SizedBox(height: 12),
        _Karte(titel: 'Prüfung', zeilen: [
          (
            'Letzte Prüfung',
            nachweis != null
                ? '${datumDeutsch(nachweis.datum)} (${nachweis.bestanden ? 'bestanden' : 'nicht bestanden'})'
                : letzte == null
                    ? '–'
                    : geraet.letztePruefungErsatzwert
                        ? '${datumDeutsch(textAlsTag(letzte))} (Erstellungsdatum, kein Prüfnachweis)'
                        : '${datumDeutsch(textAlsTag(letzte))} (vor ElektraLog)',
          ),
          (
            'Intervall',
            geraet.pruefintervallMonate == null ? 'nicht festgelegt' : '${geraet.pruefintervallMonate} Monate',
          ),
          ('Begründung', geraet.intervallBegruendung),
          (
            'Nächste Prüfung',
            switch (termin.status) {
              GeraetTerminStatus.inaktiv => 'keine (inaktiv)',
              GeraetTerminStatus.ueberfaellig => 'überfällig seit ${datumDeutsch(termin.faelligAm!)}',
              _ => datumDeutsch(termin.faelligAm!),
            },
          ),
          ('Hinweis', termin.hinweis),
        ]),
        _Pruefungen(geraet: geraet),
        const SizedBox(height: 12),
        if (geraet.verlauf.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Karte(titel: 'Verlauf', zeilen: [
            for (final e in geraet.verlauf.reversed)
              (
                datumDeutsch(e.zeit.toLocal()) + (e.benutzer == null ? '' : ' · ${e.benutzer}'),
                switch (e.art) {
                  'intervall' => 'Intervall ${e.intervall == null ? 'offen' : '${e.intervall} Monate'}'
                      '${e.begruendung == null ? '' : ' — ${e.begruendung}'}',
                  _ => e.aktiv == true ? 'wieder aktiv' : 'inaktiv: ${e.grund ?? ''}',
                },
              ),
          ]),
        ],
      ],
    );
  }
}

/// Prüfhistorie und Start einer neuen Prüfung (M5).
class _Pruefungen extends ConsumerWidget {
  const _Pruefungen({required this.geraet});

  final Geraet geraet;

  Future<void> _starten(BuildContext context, WidgetRef ref) async {
    final einstellungen = await ref.read(einstellungenProvider.future);
    final benutzer = (await ref.read(currentUserProvider.future))['name'] as String?;
    final entwurf = neuerEntwurf(
      geraet,
      prueferName: einstellungen.prueferName ?? benutzer,
      messgeraet: einstellungen.pruefgeraet,
    );
    await ref.read(geraetePruefungenRepositoryProvider).save(entwurf);
    if (context.mounted) context.go('/geraete/${geraet.uuid}/pruefung/${entwurf.uuid}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pruefungen = ref.watch(pruefungenByGeraetProvider(geraet.uuid)).valueOrNull ?? const [];
    final entwurf = pruefungen.where((p) => !p.abgeschlossen).firstOrNull;
    final ersetzt = {
      for (final p in pruefungen)
        if (p.ersetztUuid != null && p.abgeschlossen) p.ersetztUuid!
    };
    final theme = Theme.of(context);

    return Material(
      key: const Key('pruefungen-karte'),
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Prüfungen', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            if (!geraet.aktiv)
              Text(
                'Inaktiv — keine neue Prüfung. Bei Reaktivierung mit überschrittenem Termin ist eine Prüfung fällig.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
              )
            else if (entwurf != null)
              ElevatedButton.icon(
                key: const Key('pruefung-fortsetzen'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Entwurf fortsetzen'),
                onPressed: () => context.go('/geraete/${geraet.uuid}/pruefung/${entwurf.uuid}'),
              )
            else
              ElevatedButton.icon(
                key: const Key('pruefung-starten'),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Prüfung starten'),
                onPressed: () => _starten(context, ref),
              ),
            if (pruefungen.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Noch keine Prüfung in ElektraLog.', style: theme.textTheme.bodySmall),
              ),
            for (final p in pruefungen)
              ListTile(
                key: Key('pruefung-${p.uuid}'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  !p.abgeschlossen
                      ? Icons.edit_note
                      : p.bestanden
                          ? Icons.check_circle
                          : Icons.cancel,
                  color: !p.abgeschlossen
                      ? AppColors.outline
                      : p.bestanden
                          ? AppColors.success
                          : AppColors.error,
                ),
                title: Text('${datumDeutsch(p.datum)} · ${pruefarten[p.pruefart] ?? p.pruefart}'),
                subtitle: Text([
                  if (!p.abgeschlossen) 'Entwurf' else p.bestanden ? 'bestanden' : 'nicht bestanden',
                  if (p.prueferName != null) p.prueferName!,
                  if (ersetzt.contains(p.uuid)) 'durch Korrektur ersetzt',
                  if (p.ersetztUuid != null) 'Korrektur',
                ].join(' · ')),
                trailing: const Icon(Icons.arrow_forward, size: 16),
                onTap: () => context.go('/geraete/${geraet.uuid}/pruefung/${p.uuid}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Karte extends StatelessWidget {
  const _Karte({required this.titel, required this.zeilen});

  final String titel;
  final List<(String, String?)> zeilen;

  @override
  Widget build(BuildContext context) {
    final sichtbar = zeilen.where((e) => e.$2 != null && e.$2!.isNotEmpty);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titel, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final e in sichtbar)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(e.$1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                  ),
                  Expanded(child: SelectableText(e.$2!)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

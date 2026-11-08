import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_service.dart';
import '../../core/models/geraet.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/geraete_provider.dart';
import '../../core/providers/kunden_provider.dart';
import '../../core/providers/module_provider.dart';
import '../../core/providers/permission_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'geraet_formular.dart';
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
    final darfLoeschen = ref.watch(berechtigungenProvider).valueOrNull?.hatVollzugriff ?? false;
    return PopupMenuButton<String>(
      key: const Key('geraet-menue'),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'status',
          child: Text(geraet.aktiv ? 'Inaktiv setzen' : 'Wieder aktiv setzen'),
        ),
        const PopupMenuItem(value: 'uuid', child: Text('UUID kopieren')),
        if (darfLoeschen) const PopupMenuItem(value: 'loeschen', child: Text('Löschen')),
      ],
      onSelected: (v) async {
        switch (v) {
          case 'status':
            await statusWechseln(context, ref, geraet);
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
        _Karte(titel: 'Ort', zeilen: {
          'Kunde': kunde?.name ?? '?',
          'Standort': standort?.bezeichnung ?? '?',
          'Raum': raum?.bezeichnung ?? '?',
        }),
        const SizedBox(height: 12),
        _Karte(titel: 'Stammdaten', zeilen: {
          'Hersteller': geraet.hersteller,
          'Type': geraet.typ,
          'Seriennummer': geraet.seriennummer,
          'Inventarnummer': geraet.inventarnummer,
          'Schutzart': geraet.schutzart,
          'Schutzklasse': geraet.schutzklasse ?? 'nicht festgestellt',
          'Bemerkung': geraet.bemerkung,
          'UUID': geraet.uuid,
        }),
        const SizedBox(height: 12),
        _Karte(titel: 'Prüfung', zeilen: {
          'Letzte Prüfung': letzte == null
              ? '–'
              : geraet.letztePruefungErsatzwert
                  ? '${datumDeutsch(textAlsTag(letzte))} (Erstellungsdatum, kein Prüfnachweis)'
                  : '${datumDeutsch(textAlsTag(letzte))} (vor ElektraLog)',
        }),
        if (geraet.statusHistorie.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Karte(titel: 'Statusverlauf', zeilen: {
            for (final e in geraet.statusHistorie.reversed)
              datumDeutsch(e.zeit.toLocal()) + (e.benutzer == null ? '' : ' · ${e.benutzer}'):
                  e.aktiv ? 'wieder aktiv' : 'inaktiv: ${e.grund ?? ''}',
          }),
        ],
      ],
    );
  }
}

class _Karte extends StatelessWidget {
  const _Karte({required this.titel, required this.zeilen});

  final String titel;
  final Map<String, String?> zeilen;

  @override
  Widget build(BuildContext context) {
    final sichtbar = zeilen.entries.where((e) => e.value != null && e.value!.isNotEmpty);
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
                    child: Text(e.key,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
                  ),
                  Expanded(child: SelectableText(e.value!)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

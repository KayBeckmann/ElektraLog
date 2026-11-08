import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_service.dart';
import '../../core/providers/geraete_provider.dart';
import '../../core/providers/standorte_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../core/models/geraete_protokoll.dart';
import 'geraet_formular.dart';
import 'geraete_protokoll_sheet.dart';
import 'geraete_widgets.dart';
import 'raum_formular.dart';

class RaumDetailScreen extends ConsumerWidget {
  const RaumDetailScreen({super.key, required this.kundeUuid, required this.standortUuid, required this.raumUuid});

  final String kundeUuid;
  final String standortUuid;
  final String raumUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raum = (ref.watch(raeumeByStandortProvider(standortUuid)).valueOrNull ?? const [])
        .where((r) => r.uuid == raumUuid)
        .firstOrNull;
    final standort = (ref.watch(standorteByKundeProvider(kundeUuid)).valueOrNull ?? const [])
        .where((s) => s.uuid == standortUuid)
        .firstOrNull;
    final geraete = ref.watch(geraeteByRaumProvider(raumUuid)).valueOrNull ?? const [];
    final aktiv = geraete.where((g) => g.aktiv).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/kunden/$kundeUuid/standort/$standortUuid')),
        title: Text(raum?.bezeichnung ?? 'Raum'),
        backgroundColor: AppColors.surface,
        actions: [
          if (raum != null) ...[
            IconButton(
              key: const Key('protokoll-raum'),
              tooltip: 'Geräteprotokoll',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: geraete.isEmpty
                  ? null
                  : () => zeigeGeraeteProtokoll(
                        context,
                        umfang: ProtokollUmfang.raum,
                        kundeUuid: kundeUuid,
                        standortUuid: standortUuid,
                        raumUuid: raumUuid,
                      ),
            ),
            IconButton(
              tooltip: 'Raum bearbeiten',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => zeigeRaumFormular(context, standortUuid: standortUuid, raum: raum),
            ),
            IconButton(
              tooltip: 'Raum löschen',
              icon: const Icon(Icons.delete_outlined, color: AppColors.error),
              onPressed: () => _loeschen(context, ref),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('raum-geraet-neu'),
        onPressed: () =>
            zeigeGeraetFormular(context, kundeUuid: kundeUuid, standortUuid: standortUuid, raumUuid: raumUuid),
        icon: const Icon(Icons.add),
        label: const Text('Gerät'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        children: [
          Text(
            [standort?.bezeichnung, '${geraete.length} Geräte, davon $aktiv aktiv'].whereType<String>().join(' · '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (geraete.isEmpty)
            const GeraeteHinweis(
              icon: Icons.power_outlined,
              titel: 'Keine Geräte in diesem Raum',
              text: 'Neue Geräte über „Gerät“ anlegen. Nicht synchronisierte Räume zeigen nur lokal vorhandene Geräte.',
            ),
          for (final g in geraete)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GeraetTile(geraet: g, onTap: () => context.go('/geraete/${g.uuid}')),
            ),
        ],
      ),
    );
  }

  Future<void> _loeschen(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Raum löschen'),
        content: const Text('Nur leere Räume lassen sich löschen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok != true) return;
    final geloescht = await ref.read(raeumeRepositoryProvider).deleteWennLeer(raumUuid);
    if (!context.mounted) return;
    if (!geloescht) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Raum enthält noch Geräte — erst umhängen oder löschen.')),
      );
      return;
    }
    ApiService.deleteRaum(raumUuid).catchError((_) {});
    context.go('/kunden/$kundeUuid/standort/$standortUuid');
  }
}

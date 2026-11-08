import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/geraet.dart';
import '../../core/models/geraete_faelligkeit.dart';
import '../../core/providers/geraete_provider.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/widgets/status_pill.dart';

/// Gemeinsame Bausteine der Geräteprüfung.

class GeraeteHinweis extends StatelessWidget {
  const GeraeteHinweis({super.key, required this.icon, required this.titel, required this.text});

  final IconData icon;
  final String titel;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.outlineVariant),
            const SizedBox(height: 8),
            Text(titel, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      );
}

/// Kleines Etikett „Inaktiv: Grund“ bzw. Schutzklasse.
class GeraetChip extends StatelessWidget {
  const GeraetChip({super.key, required this.text, this.farbe = AppColors.secondary});

  final String text;
  final Color farbe;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: farbe.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: farbe, fontWeight: FontWeight.w700),
        ),
      );
}

/// Liste von Geräten mit Prüfstatus-Badge (PASSED / FAILED / OFFEN wie bei
/// den Verteilern); inaktive Geräte ohne Badge.
class GeraetTile extends ConsumerWidget {
  const GeraetTile({super.key, required this.geraet, required this.onTap, this.unterzeile, this.trailing});

  final Geraet geraet;
  final VoidCallback onTap;
  final String? unterzeile;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ergebnis = pruefErgebnis(geraet, ref.watch(geraetPruefNachweisProvider(geraet.uuid)).valueOrNull);
    final details = [
      if (geraet.hersteller != null) geraet.hersteller!,
      if (geraet.typ != null) geraet.typ!,
      if (geraet.inventarnummer != null) 'Inv. ${geraet.inventarnummer}',
      if (geraet.seriennummer != null) 'SN ${geraet.seriennummer}',
    ].join(' · ');
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        // Nicht bestanden: roter Rahmen — muss repariert und nachgeprüft werden.
        side: BorderSide(
          color: ergebnis == GeraetPruefErgebnis.nichtBestanden ? AppColors.error : AppColors.outlineVariant,
        ),
      ),
      child: ListTile(
        key: Key('geraet-${geraet.uuid}'),
        onTap: onTap,
        leading: Icon(
          Icons.power_outlined,
          color: geraet.aktiv ? AppColors.secondary : AppColors.outlineVariant,
        ),
        title: Text(geraet.bezeichnung),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details.isNotEmpty) Text(details),
            if (unterzeile != null) Text(unterzeile!),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (switch (ergebnis) {
                  GeraetPruefErgebnis.bestanden => PillStatus.passed,
                  GeraetPruefErgebnis.nichtBestanden => PillStatus.failed,
                  GeraetPruefErgebnis.ungeprueft => PillStatus.offen,
                  GeraetPruefErgebnis.inaktiv => null,
                }
                    case final status?)
                  StatusPill(key: Key('pruefstatus-${geraet.uuid}'), status: status),
                if (geraet.schutzklasse != null) GeraetChip(text: 'SK ${geraet.schutzklasse}'),
                if (!geraet.aktiv) GeraetChip(text: 'Inaktiv: ${geraet.inaktivGrund ?? ''}', farbe: AppColors.outline),
              ],
            ),
          ],
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward, size: 16),
      ),
    );
  }
}

String datumDeutsch(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Kleine Zahl „bestanden / gesamt“ (aktive Geräte), rot ergänzt um die
/// Zahl nicht bestandener Geräte — wie die Zähler bei den Verteilern.
class PruefBilanzAnzeige extends StatelessWidget {
  const PruefBilanzAnzeige({super.key, required this.bilanz});

  final ({int bestanden, int nichtBestanden, int gesamt}) bilanz;

  @override
  Widget build(BuildContext context) {
    final alle = bilanz.gesamt > 0 && bilanz.bestanden == bilanz.gesamt;
    final stil = Theme.of(context).textTheme.labelMedium;
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '${bilanz.bestanden} / ${bilanz.gesamt} bestanden',
          key: const Key('pruef-bilanz'),
          style: stil?.copyWith(
            color: alle ? AppColors.success : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (bilanz.nichtBestanden > 0)
          Text(
            '${bilanz.nichtBestanden} nicht bestanden',
            key: const Key('pruef-bilanz-fehler'),
            style: stil?.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}

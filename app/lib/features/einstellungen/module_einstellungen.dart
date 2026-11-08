import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/module_provider.dart';
import '../../shared/theme/app_colors.dart';

/// Schalter für die Prüfmodule (Roadmap Geräteprüfung M1). Wirkt sofort,
/// nicht erst über „Einstellungen speichern“. Im Company-Modus nur für den
/// Firmenadmin bedienbar — der Server setzt das zusätzlich durch.
class ModuleEinstellungen extends ConsumerStatefulWidget {
  const ModuleEinstellungen({super.key});

  @override
  ConsumerState<ModuleEinstellungen> createState() => _ModuleEinstellungenState();
}

class _ModuleEinstellungenState extends ConsumerState<ModuleEinstellungen> {
  bool _speichert = false;

  Future<void> _setzen(FirmenModule neu) async {
    setState(() => _speichert = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(moduleProvider.notifier).setzen(neu);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Module nicht geändert: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _speichert = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = ref.watch(aktiveModuleProvider);
    final isCompany = ref.watch(appModusProvider).valueOrNull == AppModus.company;
    final isAdmin = ref.watch(isAdminProvider).valueOrNull ?? false;
    final bedienbar = (!isCompany || isAdmin) && !_speichert;

    // Material statt dekoriertem Container, damit die Schalter ihre
    // Tipp-Rückmeldung zeigen.
    return Material(
      color: AppColors.surfaceContainerLowest,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            key: const Key('modul-anlagenpruefung'),
            title: const Text('Anlagenprüfung'),
            subtitle: const Text('Verteiler, Komponenten, Messungen'),
            value: module.anlagenpruefung,
            onChanged: bedienbar
                ? (v) => _setzen(FirmenModule(
                    anlagenpruefung: v, geraetepruefung: module.geraetepruefung))
                : null,
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          SwitchListTile(
            key: const Key('modul-geraetepruefung'),
            title: const Text('Geräteprüfung'),
            subtitle: const Text('Ortsveränderliche Geräte (in Vorbereitung)'),
            value: module.geraetepruefung,
            onChanged: bedienbar
                ? (v) => _setzen(FirmenModule(
                    anlagenpruefung: module.anlagenpruefung, geraetepruefung: v))
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              isCompany && !isAdmin
                  ? 'Nur der Firmenadmin kann Module umschalten.'
                  : 'Abschalten blendet ein Modul nur aus — Daten bleiben '
                      'erhalten und werden weiter synchronisiert.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

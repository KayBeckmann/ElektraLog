import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/providers/geraete_provider.dart';
import '../../core/providers/isar_provider.dart';
import '../../core/providers/komponenten_provider.dart';
import '../../core/providers/module_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'geraete_widgets.dart';

enum ScanArt { gefunden, ungueltig, unbekannt, komponente }

final _uuidMuster = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

/// Liest eine Geräte-UUID aus einem Scan oder einer Eingabe. Nur ein
/// exakter Treffer öffnet ein Gerät — nie ein „ähnliches“.
String? uuidAusScan(String roh) {
  final s = roh.trim().toLowerCase();
  return _uuidMuster.hasMatch(s) ? s : null;
}

/// Wohin führt der Code? Lokal nachgeschlagen, funktioniert offline.
Future<(ScanArt, String?)> scanAufloesen(String roh, Future<bool> Function(String uuid) istGeraet,
    Future<bool> Function(String uuid) istKomponente) async {
  final uuid = uuidAusScan(roh);
  if (uuid == null) return (ScanArt.ungueltig, null);
  if (await istGeraet(uuid)) return (ScanArt.gefunden, uuid);
  if (await istKomponente(uuid)) return (ScanArt.komponente, uuid);
  return (ScanArt.unbekannt, uuid);
}

/// Etikett scannen → Gerät öffnen (Roadmap M7). Kamera auf Mobilgeräten,
/// daneben ein Eingabefeld für Bluetooth-Handscanner (Tastatureingabe)
/// oder abgetippte UUIDs.
class GeraetScanScreen extends ConsumerStatefulWidget {
  const GeraetScanScreen({super.key, this.kamera = true});

  /// In Tests ohne Kamera.
  final bool kamera;

  @override
  ConsumerState<GeraetScanScreen> createState() => _GeraetScanScreenState();
}

class _GeraetScanScreenState extends ConsumerState<GeraetScanScreen> {
  final _eingabe = TextEditingController();
  (ScanArt, String?)? _ergebnis;
  bool _sucht = false;

  @override
  void dispose() {
    _eingabe.dispose();
    super.dispose();
  }

  Future<void> _pruefen(String roh) async {
    if (_sucht) return;
    _sucht = true;
    try {
      await ref.read(dbProvider.future); // lokale Datenbank (Endgeräte) bereit
      final ergebnis = await scanAufloesen(
        roh,
        (uuid) async => await ref.read(geraeteRepositoryProvider).getByUuid(uuid) != null,
        (uuid) async => await ref.read(komponentenRepositoryProvider).getByUuid(uuid) != null,
      );
      if (!mounted) return;
      if (ergebnis.$1 == ScanArt.gefunden) {
        context.go('/geraete/${ergebnis.$2}');
        return;
      }
      setState(() => _ergebnis = ergebnis);
    } finally {
      _sucht = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final module = ref.watch(aktiveModuleProvider);
    final kamera = widget.kamera &&
        (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('Etikett scannen'),
        backgroundColor: AppColors.surface,
      ),
      body: !module.geraetepruefung
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: GeraeteHinweis(
                key: Key('scan-modul-aus'),
                icon: Icons.toggle_off_outlined,
                titel: 'Geräteprüfung ist ausgeschaltet',
                text: 'Ein Scan öffnet keine Geräte, solange das Modul ausgeschaltet ist.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (kamera)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 280,
                      child: MobileScanner(
                        onDetect: (capture) {
                          final wert = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
                          if (wert != null) _pruefen(wert);
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('scan-eingabe'),
                  controller: _eingabe,
                  autofocus: !kamera,
                  decoration: const InputDecoration(
                    labelText: 'UUID eingeben oder Handscanner nutzen',
                    prefixIcon: Icon(Icons.qr_code_scanner),
                  ),
                  onSubmitted: _pruefen,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  key: const Key('scan-oeffnen'),
                  onPressed: () => _pruefen(_eingabe.text),
                  child: const Text('Gerät öffnen'),
                ),
                const SizedBox(height: 16),
                if (_ergebnis case (final art, final uuid))
                  GeraeteHinweis(
                    key: Key('scan-${art.name}'),
                    icon: Icons.help_outline,
                    titel: switch (art) {
                      ScanArt.ungueltig => 'Kein gültiger Geräte-Code',
                      ScanArt.komponente => 'Code einer Verteiler-Komponente',
                      _ => 'Gerät nicht auf diesem Arbeitsgerät',
                    },
                    text: switch (art) {
                      ScanArt.ungueltig => 'Erwartet wird die vollständige UUID (36 Zeichen) vom ElektraLog-Etikett.',
                      ScanArt.komponente => 'Dieser Code gehört zur Anlagenprüfung, nicht zu einem Gerät.',
                      _ => '$uuid ist lokal unbekannt. Ist der Raum für die Synchronisation ausgewählt? '
                          'Raum oder Standort auswählen, synchronisieren und erneut scannen. '
                          'Es wird kein ähnliches Gerät geöffnet.',
                    },
                  ),
              ],
            ),
    );
  }
}

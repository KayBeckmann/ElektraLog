import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/models/verteiler_komponente.dart';
import '../../shared/theme/app_colors.dart';
import '../pdf/pdf_service.dart';

class QrScreen extends ConsumerWidget {
  const QrScreen({super.key, required this.komponenteUuid});

  final String komponenteUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try to find the component from any verteiler
    // We use a FutureProvider approach inline since we only have uuid
    return _QrScreenBody(komponenteUuid: komponenteUuid);
  }
}

class _QrScreenBody extends ConsumerWidget {
  const _QrScreenBody({required this.komponenteUuid});

  final String komponenteUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrData = 'elektralog://komponente/$komponenteUuid';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'QR-Code Etikett',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── QR Code ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    komponenteUuid.substring(0, 8).toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    qrData,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Info ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KOMPONENTEN-UUID',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.onSecondaryContainer,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    komponenteUuid,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Actions ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _printSingle(context, komponenteUuid),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Drucken / Teilen'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _generateSheet(context, ref),
                icon: const Icon(Icons.grid_view_outlined, size: 18),
                label: const Text('Etikettenblatt (A4, 8 Etiketten)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printSingle(BuildContext context, String uuid) async {
    final komponente = VerteilerKomponente(
      uuid: uuid,
      verteilerUuid: '',
      typ: 'sonstige',
      bezeichnung: uuid.substring(0, 8),
    );
    try {
      final bytes = await PdfService.generateEtiketten([komponente]);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Druckfehler: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _generateSheet(BuildContext context, WidgetRef ref) async {
    // Erzeuge Demo-Etiketten wenn keine realen Daten verfügbar
    final komponente = VerteilerKomponente(
      uuid: komponenteUuid,
      verteilerUuid: '',
      typ: 'sonstige',
      bezeichnung: 'Komponente',
    );
    try {
      final bytes =
          await PdfService.generateEtiketten(List.filled(8, komponente));
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Standalone helper: QR Etikettenblatt für alle Komponenten ─────────────────

Future<Uint8List> generateKomponentenEtiketten(
    List<VerteilerKomponente> komponenten) async {
  return PdfService.generateEtiketten(komponenten);
}

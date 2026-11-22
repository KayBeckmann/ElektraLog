import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/models/pruefprotokoll.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/providers/pruefprotokoll_provider.dart';
import '../../shared/theme/app_colors.dart';
import 'protokoll_versand_dialog.dart';

/// Ausgabe eines PDFs (ansehen, teilen); in Tests ersetzbar.
typedef PdfAusgabe = Future<void> Function(Uint8List bytes, String dateiname);

Future<void> pdfVorschau(Uint8List bytes, String dateiname) =>
    Printing.layoutPdf(onLayout: (_) async => bytes, name: dateiname);

Future<void> pdfTeilen(Uint8List bytes, String dateiname) =>
    Printing.sharePdf(bytes: bytes, filename: dateiname);

/// Ergebnis nach dem Erzeugen eines Anlagen- oder Geräteprotokolls
/// (Roadmap 22.11.2026): PDF ansehen, teilen und — im Company-Modus —
/// direkt per E-Mail senden, ohne Umweg über die Dokumentenablage.
///
/// Gesendet wird nie automatisch und nur die archivierte Fassung: erst
/// wenn der Upload bestätigt ist und die Prüfsumme des Archivs mit dem
/// gerade erzeugten PDF übereinstimmt. Solange der Upload fehlt (offline,
/// abgelaufener Login), bleibt das PDF lokal anseh- und teilbar.
Future<void> zeigeProtokollErgebnis(
  BuildContext context, {
  required String titel,
  required String dateiname,
  required Uint8List bytes,
  required Pruefprotokoll protokoll,
  ProtokollAblage? ablage,
  String? ablageFehler,
  PdfAusgabe ansehen = pdfVorschau,
  PdfAusgabe teilen = pdfTeilen,
  ProtokollUpload? upload,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => ProtokollErgebnisDialog(
        titel: titel,
        dateiname: dateiname,
        bytes: bytes,
        protokoll: protokoll,
        ablage: ablage,
        ablageFehler: ablageFehler,
        ansehen: ansehen,
        teilen: teilen,
        upload: upload,
      ),
    );

class ProtokollErgebnisDialog extends ConsumerStatefulWidget {
  const ProtokollErgebnisDialog({
    super.key,
    required this.titel,
    required this.dateiname,
    required this.bytes,
    required this.protokoll,
    this.ablage,
    this.ablageFehler,
    this.ansehen = pdfVorschau,
    this.teilen = pdfTeilen,
    this.upload,
  });

  final String titel;
  final String dateiname;
  final Uint8List bytes;

  /// Das erzeugte Protokoll — Grundlage für einen erneuten Upload, wenn
  /// [ablage] fehlt (Web-App: Upload ist gescheitert).
  final Pruefprotokoll protokoll;
  final ProtokollAblage? ablage;
  final String? ablageFehler;
  final PdfAusgabe ansehen;
  final PdfAusgabe teilen;
  final ProtokollUpload? upload;

  @override
  ConsumerState<ProtokollErgebnisDialog> createState() => _ProtokollErgebnisDialogState();
}

class _ProtokollErgebnisDialogState extends ConsumerState<ProtokollErgebnisDialog> {
  late Pruefprotokoll _stand = widget.ablage?.lokal ?? widget.protokoll;
  late String? _fehler = widget.ablageFehler;
  bool _laedtHoch = false;
  String? _gesendetAn;
  late final String _hash = sha256.convert(widget.bytes).toString();

  @override
  void initState() {
    super.initState();
    final ablage = widget.ablage;
    if (ablage != null && ablage.lokal.backendUuid == null) _warten(ablage.upload);
  }

  Future<void> _warten(Future<Pruefprotokoll> upload) async {
    setState(() => _laedtHoch = true);
    try {
      final p = await upload;
      if (!mounted) return;
      setState(() {
        _stand = p;
        _fehler = p.backendUuid == null
            ? 'Noch nicht in der Dokumentenablage (offline, nicht angemeldet oder Serverfehler). '
                'Das PDF bleibt gespeichert und wird beim nächsten Sync hochgeladen.'
            : null;
      });
    } catch (e) {
      if (mounted) setState(() => _fehler = 'Nicht in der Dokumentenablage gespeichert: $e');
    } finally {
      if (mounted) setState(() => _laedtHoch = false);
    }
  }

  Future<void> _erneutHochladen() async {
    setState(() {
      _laedtHoch = true;
      _fehler = null;
    });
    try {
      final a = await ref.read(pruefprotokollRepositoryProvider).ablegen(_stand, widget.bytes, upload: widget.upload);
      if (!mounted) return;
      setState(() => _stand = a.lokal);
      await _warten(a.upload);
    } catch (e) {
      if (mounted) {
        setState(() {
          _fehler = 'Nicht in der Dokumentenablage gespeichert: $e';
          _laedtHoch = false;
        });
      }
    }
  }

  Future<void> _ausgeben(PdfAusgabe aktion) async {
    try {
      await aktion(widget.bytes, widget.dateiname);
    } catch (e) {
      if (mounted) setState(() => _fehler = 'PDF-Ausgabe fehlgeschlagen: $e');
    }
  }

  Future<void> _perEmail() async {
    final id = _stand.backendUuid!;
    final an = await showDialog<String>(
      context: context,
      builder: (_) => ProtokollVersandDialog(
        protokollId: id,
        titel: widget.titel,
        erwarteterPdfHash: _hash,
        pdfAnzeigen: widget.ansehen,
      ),
    );
    if (an != null && mounted) setState(() => _gesendetAn = an);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final company = ref.watch(appModusProvider).valueOrNull == AppModus.company;
    final abgelegt = _stand.backendUuid != null;
    final klein = theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant);

    return AlertDialog(
      title: const Text('Protokoll erstellt'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.titel, style: theme.textTheme.titleSmall),
              Text(widget.dateiname, style: klein),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const Key('ergebnis-ansehen'),
                    onPressed: () => _ausgeben(widget.ansehen),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('PDF ansehen'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('ergebnis-teilen'),
                    onPressed: () => _ausgeben(widget.teilen),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('PDF teilen'),
                  ),
                  if (company)
                    FilledButton.icon(
                      key: const Key('ergebnis-email'),
                      onPressed: abgelegt && !_laedtHoch ? _perEmail : null,
                      icon: const Icon(Icons.forward_to_inbox_outlined, size: 18),
                      label: const Text('Per E-Mail senden …'),
                    ),
                ],
              ),
              if (company) ...[
                const SizedBox(height: 12),
                if (_laedtHoch)
                  const Row(
                    key: Key('ergebnis-laedt'),
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Expanded(child: Text('Wird in die Dokumentenablage hochgeladen …')),
                    ],
                  )
                else if (abgelegt)
                  Text(
                    'In der Dokumentenablage gespeichert — dort ist der Versand auch später möglich.',
                    key: const Key('ergebnis-abgelegt'),
                    style: klein,
                  ),
                if (_fehler != null && !_laedtHoch) ...[
                  Text(_fehler!, key: const Key('ergebnis-fehler'), style: const TextStyle(color: AppColors.error)),
                  if (!abgelegt)
                    TextButton.icon(
                      key: const Key('ergebnis-erneut-hochladen'),
                      onPressed: _erneutHochladen,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Erneut hochladen'),
                    ),
                ],
                if (_gesendetAn != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Per E-Mail an $_gesendetAn gesendet.',
                      key: const Key('ergebnis-gesendet'),
                      style: const TextStyle(color: AppColors.success),
                    ),
                  ),
              ] else if (widget.ablageFehler != null) ...[
                const SizedBox(height: 12),
                Text(widget.ablageFehler!, style: const TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('ergebnis-schliessen'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Fertig'),
        ),
      ],
    );
  }
}

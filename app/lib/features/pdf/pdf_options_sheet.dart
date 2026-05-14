import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../shared/theme/app_colors.dart';
import '../signatur/signature_pad.dart';

// ── Ergebnis-Klasse ───────────────────────────────────────────────────────────

class PdfOptions {
  const PdfOptions({
    required this.prueferName,
    this.firma,
    this.pruefgeraet,
    required this.datumOrt,
    this.signaturPng,
  });

  final String prueferName;
  final String? firma;
  final String? pruefgeraet;
  final String datumOrt;
  final Uint8List? signaturPng;
}

// ── Bottom-Sheet ──────────────────────────────────────────────────────────────

class PdfOptionsSheet extends StatefulWidget {
  const PdfOptionsSheet({super.key, required this.titel});

  final String titel;

  /// Öffnet das Sheet und gibt [PdfOptions] zurück, oder null bei Abbruch.
  static Future<PdfOptions?> show(
    BuildContext context, {
    required String titel,
  }) =>
      showModalBottomSheet<PdfOptions>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => PdfOptionsSheet(titel: titel),
      );

  @override
  State<PdfOptionsSheet> createState() => _PdfOptionsSheetState();
}

class _PdfOptionsSheetState extends State<PdfOptionsSheet> {
  final _prueferCtrl = TextEditingController();
  final _firmaCtrl = TextEditingController();
  final _pruefgeraetCtrl = TextEditingController();
  final _datumOrtCtrl = TextEditingController();
  final _signatureKey = GlobalKey();
  final List<Offset?> _points = [];
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _datumOrtCtrl.text =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }

  @override
  void dispose() {
    _prueferCtrl.dispose();
    _firmaCtrl.dispose();
    _pruefgeraetCtrl.dispose();
    _datumOrtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prüfprotokoll generieren',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(widget.titel,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // ── Auftragnehmer ────────────────────────────────────────────────
            _SectionLabel('AUFTRAGNEHMER'),
            const SizedBox(height: 8),
            TextField(
              controller: _firmaCtrl,
              decoration: const InputDecoration(
                labelText: 'Firma / Unternehmen',
                hintText: 'Elektro Mustermann GmbH',
                prefixIcon: Icon(Icons.business_outlined, size: 18),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _prueferCtrl,
              decoration: const InputDecoration(
                labelText: 'Prüfer *',
                hintText: 'Max Mustermann',
                prefixIcon: Icon(Icons.person_outline, size: 18),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // ── Prüfung ──────────────────────────────────────────────────────
            _SectionLabel('PRÜFUNG'),
            const SizedBox(height: 8),
            TextField(
              controller: _datumOrtCtrl,
              decoration: const InputDecoration(
                labelText: 'Datum / Ort',
                hintText: 'TT.MM.JJJJ, Musterstadt',
                prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pruefgeraetCtrl,
              decoration: const InputDecoration(
                labelText: 'Prüfgerät',
                hintText: 'z.B. Metrel MI 3152 / Fluke 1664 FC',
                prefixIcon: Icon(Icons.device_hub_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 16),

            // ── Unterschrift ─────────────────────────────────────────────────
            Row(
              children: [
                _SectionLabel('UNTERSCHRIFT PRÜFER'),
                const Spacer(),
                if (_points.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => setState(() => _points.clear()),
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Löschen'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              key: _signatureKey,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.outlineVariant,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SignaturePad(
                  points: _points,
                  onChanged: (pts) => setState(() {
                    _points
                      ..clear()
                      ..addAll(pts);
                  }),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Hier unterschreiben',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 20),

            // ── Generieren ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _onGenerate,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: Text(_isGenerating ? 'Wird erstellt…' : 'PDF generieren'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onGenerate() async {
    setState(() => _isGenerating = true);
    try {
      Uint8List? sigPng;
      if (_points.isNotEmpty && _points.any((p) => p != null)) {
        final box = _signatureKey.currentContext?.findRenderObject()
            as RenderBox?;
        final w = box?.size.width ?? 400.0;
        const h = 140.0;
        sigPng = await _signatureToPng(_points, w, h);
      }
      if (mounted) {
        Navigator.pop(
          context,
          PdfOptions(
            prueferName: _prueferCtrl.text.trim().isEmpty
                ? 'Unbekannt'
                : _prueferCtrl.text.trim(),
            firma: _firmaCtrl.text.trim().isEmpty
                ? null
                : _firmaCtrl.text.trim(),
            pruefgeraet: _pruefgeraetCtrl.text.trim().isEmpty
                ? null
                : _pruefgeraetCtrl.text.trim(),
            datumOrt: _datumOrtCtrl.text.trim(),
            signaturPng: sigPng,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

// ── Signatur → PNG ────────────────────────────────────────────────────────────

Future<Uint8List?> _signatureToPng(
    List<Offset?> points, double width, double height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, width, height),
  );

  // weißer Hintergrund
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width, height),
    Paint()..color = const Color(0xFFFFFFFF),
  );

  final paint = Paint()
    ..color = const Color(0xFF091426)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final path = Path();
  bool penDown = false;
  for (final point in points) {
    if (point == null) {
      penDown = false;
      continue;
    }
    if (!penDown) {
      path.moveTo(point.dx, point.dy);
      penDown = true;
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  canvas.drawPath(path, paint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(width.toInt(), height.toInt());
  final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}

// ── Hilfs-Widget ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      );
}

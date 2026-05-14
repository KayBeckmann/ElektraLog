import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/models/messung.dart';
import '../../core/models/sichtpruefung.dart';
import '../../core/models/verteiler.dart';
import '../../core/models/verteiler_komponente.dart';

class PdfService {
  /// Generiert ein ZVEH-angelehtes Prüfprotokoll als PDF-Bytes
  static Future<Uint8List> generateProtokoll({
    required String prueferName,
    required String datumOrt,
    required Verteiler verteiler,
    required List<Sichtpruefung> sichtpruefungen,
    required List<VerteilerKomponente> komponenten,
    required List<Messung> messungen,
    List<int>? signaturPng,
  }) async {
    final doc = pw.Document();

    // Farben (Industrial Precision System)
    final primaryColor = PdfColor.fromHex('#091426');
    final surfaceColor = PdfColor.fromHex('#F5F3F4');
    final errorColor = PdfColor.fromHex('#BA1A1A');
    final successColor = PdfColor.fromHex('#1A6B2E');

    // Schriftarten
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontMono = await PdfGoogleFonts.jetBrainsMonoRegular();

    // Anlagendaten aus JSON
    Map<String, dynamic> anlagendaten = {};
    if (verteiler.anlagendatenJson != null) {
      try {
        anlagendaten =
            jsonDecode(verteiler.anlagendatenJson!) as Map<String, dynamic>;
      } catch (_) {}
    }

    // Sichtprüfungs-Ergebnis (neueste)
    final latestSichtpruefung = sichtpruefungen.isEmpty
        ? null
        : (sichtpruefungen
              ..sort((a, b) => b.pruefungDatum.compareTo(a.pruefungDatum)))
            .first;

    // Messungen nach Komponente gruppieren
    final messungenByKomponente = <String, List<Messung>>{};
    for (final m in messungen) {
      messungenByKomponente.putIfAbsent(m.komponenteUuid, () => []).add(m);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (ctx) =>
            _buildHeader(ctx, primaryColor, fontBold, verteiler.bezeichnung),
        footer: (ctx) => _buildFooter(ctx, fontMono),
        build: (ctx) => [
          // ── Prüfinformationen ────────────────────────────────────────────
          _sectionTitle('Prüfinformationen', primaryColor, fontBold),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              _tableRow('Prüfer', prueferName, fontRegular, fontMono),
              _tableRow('Datum / Ort', datumOrt, fontRegular, fontMono),
              _tableRow(
                  'Verteiler', verteiler.bezeichnung, fontRegular, fontMono),
            ],
          ),
          pw.SizedBox(height: 16),

          // ── Anlagendaten ─────────────────────────────────────────────────
          _sectionTitle('Anlagendaten', primaryColor, fontBold),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              _tableRow(
                'Nennspannung',
                '${anlagendaten['nennspannung'] ?? anlagendaten['nennspannung_v'] ?? '—'}',
                fontRegular,
                fontMono,
              ),
              _tableRow(
                'Frequenz',
                '${anlagendaten['frequenz'] ?? anlagendaten['frequenz_hz'] ?? '50 Hz'}',
                fontRegular,
                fontMono,
              ),
              _tableRow(
                'Netzform',
                '${anlagendaten['netzform'] ?? '—'}',
                fontRegular,
                fontMono,
              ),
              _tableRow(
                'Außenleiter',
                '${anlagendaten['aussenleiter'] ?? anlagendaten['anzahl_aussenleiter'] ?? '—'}',
                fontRegular,
                fontMono,
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // ── Sichtprüfung ─────────────────────────────────────────────────
          _sectionTitle('Sichtprüfung', primaryColor, fontBold),
          if (latestSichtpruefung != null) ...[
            _resultBadge(
                latestSichtpruefung.ergebnis, successColor, errorColor, fontBold),
            pw.SizedBox(height: 4),
            if (latestSichtpruefung.maengel != null &&
                latestSichtpruefung.maengel!.isNotEmpty)
              pw.Text(
                'Mängel: ${latestSichtpruefung.maengel}',
                style: pw.TextStyle(
                    font: fontRegular, fontSize: 10, color: errorColor),
              ),
          ] else
            pw.Text(
              'Keine Sichtprüfung vorhanden',
              style: pw.TextStyle(
                  font: fontRegular, fontSize: 10, color: PdfColors.grey),
            ),
          pw.SizedBox(height: 16),

          // ── Messwerte ────────────────────────────────────────────────────
          _sectionTitle('Messwerte', primaryColor, fontBold),
          if (komponenten.isEmpty)
            pw.Text(
              'Keine Komponenten vorhanden',
              style: pw.TextStyle(
                  font: fontRegular, fontSize: 10, color: PdfColors.grey),
            )
          else
            ...komponenten.map((k) {
              final kMessungen = messungenByKomponente[k.uuid] ?? [];
              return _komponenteSection(k, kMessungen, surfaceColor, errorColor,
                  successColor, fontRegular, fontBold, fontMono);
            }),
          pw.SizedBox(height: 24),

          // ── Unterschrift ─────────────────────────────────────────────────
          _sectionTitle('Unterschrift', primaryColor, fontBold),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (signaturPng != null)
                      pw.Image(
                          pw.MemoryImage(Uint8List.fromList(signaturPng)),
                          height: 60)
                    else
                      pw.Container(
                          height: 60,
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColors.grey)))),
                    pw.Text(prueferName,
                        style:
                            pw.TextStyle(font: fontRegular, fontSize: 10)),
                    pw.Text('Prüfer',
                        style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 8,
                            color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.SizedBox(width: 32),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                        height: 60,
                        decoration: pw.BoxDecoration(
                            border: pw.Border(
                                bottom: pw.BorderSide(
                                    color: PdfColors.grey)))),
                    pw.Text('Auftraggeber',
                        style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 8,
                            color: PdfColors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Generiert A4-Etikettenblatt mit QR-Codes (2×4 = 8 Etiketten je Seite)
  static Future<Uint8List> generateEtiketten(
      List<VerteilerKomponente> komponenten) async {
    final doc = pw.Document();
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontMono = await PdfGoogleFonts.jetBrainsMonoRegular();
    final primaryColor = PdfColor.fromHex('#091426');

    // 8 Etiketten je Seite, 2 Spalten × 4 Zeilen
    const etiquettenProSeite = 8;
    for (var pageStart = 0;
        pageStart < komponenten.length;
        pageStart += etiquettenProSeite) {
      final pageKomponenten =
          komponenten.skip(pageStart).take(etiquettenProSeite).toList();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (ctx) {
            final rows = <pw.Widget>[];
            for (var i = 0; i < pageKomponenten.length; i += 2) {
              final left = _etikett(
                pageKomponenten[i],
                fontRegular,
                fontBold,
                fontMono,
                primaryColor,
              );
              final right = i + 1 < pageKomponenten.length
                  ? _etikett(
                      pageKomponenten[i + 1],
                      fontRegular,
                      fontBold,
                      fontMono,
                      primaryColor,
                    )
                  : pw.SizedBox();
              rows.add(
                pw.Row(
                  children: [
                    pw.Expanded(child: left),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: right),
                  ],
                ),
              );
              rows.add(pw.SizedBox(height: 8));
            }
            return pw.Column(children: rows);
          },
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _etikett(
    VerteilerKomponente k,
    pw.Font regular,
    pw.Font bold,
    pw.Font mono,
    PdfColor primary,
  ) {
    final qrData = 'elektralog://komponente/${k.uuid}';
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: qrData,
            width: 64,
            height: 64,
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  k.bezeichnung,
                  style: pw.TextStyle(font: bold, fontSize: 10, color: primary),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  k.typ.toUpperCase().replaceAll('_', ' '),
                  style: pw.TextStyle(
                      font: regular,
                      fontSize: 8,
                      color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  k.uuid.substring(0, 8),
                  style: pw.TextStyle(
                      font: mono, fontSize: 7, color: PdfColors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeader(
    pw.Context ctx,
    PdfColor primary,
    pw.Font bold,
    String verteiler,
  ) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: primary, width: 2)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'ElektraLog — Prüfprotokoll',
              style: pw.TextStyle(font: bold, fontSize: 16, color: primary),
            ),
            pw.Text(
              verteiler,
              style: pw.TextStyle(font: bold, fontSize: 10, color: primary),
            ),
          ],
        ),
      );

  static pw.Widget _buildFooter(pw.Context ctx, pw.Font mono) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(top: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generiert von ElektraLog',
              style: pw.TextStyle(
                  font: mono, fontSize: 8, color: PdfColors.grey),
            ),
            pw.Text(
              'Seite ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(
                  font: mono, fontSize: 8, color: PdfColors.grey),
            ),
          ],
        ),
      );

  static pw.Widget _sectionTitle(
          String title, PdfColor color, pw.Font bold) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
              font: bold,
              fontSize: 11,
              color: color,
              letterSpacing: 0.8),
        ),
      );

  static pw.TableRow _tableRow(
    String label,
    String value,
    pw.Font regular,
    pw.Font mono,
  ) =>
      pw.TableRow(children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(
            label,
            style: pw.TextStyle(
                font: regular, fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Text(
            value,
            style: pw.TextStyle(font: mono, fontSize: 10),
          ),
        ),
      ]);

  static pw.Widget _resultBadge(
    String ergebnis,
    PdfColor success,
    PdfColor error,
    pw.Font bold,
  ) {
    final isGood = ergebnis == 'bestanden';
    final isMaengel = ergebnis == 'mit_maengeln';
    final color = isGood ? success : error;
    final label = isGood
        ? 'BESTANDEN'
        : isMaengel
            ? 'MIT MAENGELN'
            : 'NICHT BESTANDEN';
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Text(
        label,
        style: pw.TextStyle(
            font: bold, fontSize: 10, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _komponenteSection(
    VerteilerKomponente k,
    List<Messung> kMessungen,
    PdfColor surface,
    PdfColor error,
    PdfColor success,
    pw.Font regular,
    pw.Font bold,
    pw.Font mono,
  ) {
    if (kMessungen.isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            color: surface,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: pw.Text(
              '${k.typ.toUpperCase()} — ${k.bezeichnung}',
              style: pw.TextStyle(font: bold, fontSize: 10),
            ),
          ),
          ...kMessungen.map((m) {
            final passed = m.ergebnis == 'bestanden';
            return pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, top: 4),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${m.norm} — ${_formatDatum(m.pruefungDatum)}',
                    style:
                        pw.TextStyle(font: regular, fontSize: 9),
                  ),
                  pw.Text(
                    passed ? 'OK' : 'FEHLER',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 10,
                      color: passed ? success : error,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _formatDatum(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

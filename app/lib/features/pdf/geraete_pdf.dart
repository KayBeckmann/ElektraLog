import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/models/geraet.dart';
import '../../core/models/geraete_protokoll.dart';
import '../../core/models/geraete_pruefung.dart';

/// Schriften fürs PDF. Inter enthält Ω, ≤, ≥; ohne Netz (erster Abruf)
/// fällt die Erzeugung auf die eingebauten Schriften zurück, statt zu
/// scheitern.
class PdfSchriften {
  const PdfSchriften(this.regular, this.bold, this.mono);
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font mono;

  static Future<PdfSchriften> laden() async {
    try {
      return PdfSchriften(
        await PdfGoogleFonts.interRegular(),
        await PdfGoogleFonts.interBold(),
        await PdfGoogleFonts.jetBrainsMonoRegular(),
      );
    } catch (e) {
      debugPrint('PDF-Schriften nicht ladbar, nutze Standardschriften: $e');
      return standard();
    }
  }

  static PdfSchriften standard() => PdfSchriften(pw.Font.helvetica(), pw.Font.helveticaBold(), pw.Font.courier());
}

/// Absender/Kopf der Protokolle.
class ProtokollKopf {
  const ProtokollKopf({this.firma, this.firmaAdresse, this.kunde, this.standort});
  final String? firma;
  final String? firmaAdresse;
  final String? kunde;
  final String? standort;
}

/// Unterschrift beim Erzeugen des PDFs (wie bei der Anlagenprüfung).
class PdfUnterschrift {
  const PdfUnterschrift({required this.name, this.datumOrt, this.pruefgeraet, this.bild});
  final String name;

  /// z. B. „08.11.2026, Musterstadt“.
  final String? datumOrt;

  /// Für die Übersicht; die Prüfblätter zeigen das Prüfgerät der Prüfung.
  final String? pruefgeraet;

  /// Unterschrift als PNG; ohne Bild bleibt die Linie zum Unterschreiben.
  final Uint8List? bild;

  /// Das Prüfblatt trägt die Unterschrift nur, wenn der Unterzeichner die
  /// Prüfung selbst durchgeführt hat — sonst bleibt die Linie leer.
  bool unterschreibt(GeraetePruefung p) =>
      p.prueferName == null || p.prueferName!.trim().toLowerCase() == name.trim().toLowerCase();
}

final _primary = PdfColor.fromHex('#091426');
final _grau = PdfColor.fromHex('#C5C6CD');
final _flaeche = PdfColor.fromHex('#F5F3F4');
final _gut = PdfColor.fromHex('#1A6B2E');
final _schlecht = PdfColor.fromHex('#BA1A1A');

String _datum(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

String _zahl(double? v) {
  if (v == null) return '–';
  final s = v == v.roundToDouble() ? v.toStringAsFixed(v.abs() < 10 ? 1 : 0) : v.toString();
  return s.replaceAll('.', ',');
}

/// Geräteübersicht (immer zuerst) und danach je aktivem, geprüftem Gerät
/// ein Prüfblatt — inaktive Geräte erscheinen nur in der Übersicht.
Future<Uint8List> geraeteProtokollPdf(
  GeraeteProtokollInhalt inhalt, {
  required ProtokollKopf kopf,
  PdfSchriften? schriften,
  DateTime? erstellt,
  PdfUnterschrift? unterschrift,
}) async {
  final s = schriften ?? await PdfSchriften.laden();
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: s.regular, bold: s.bold));
  final jetzt = erstellt ?? DateTime.now();

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4.landscape,
    margin: const pw.EdgeInsets.all(28),
    footer: (ctx) => _fuss(ctx, s),
    build: (ctx) => [
      _kopfzeile(s, inhalt.titel, kopf, 'Erstellt am ${_datum(jetzt)} · Auswahl: ${inhalt.filter.bezeichnung}'),
      pw.SizedBox(height: 12),
      _uebersicht(inhalt.zeilen, s),
      pw.SizedBox(height: 8),
      pw.Text(
        '${inhalt.zeilen.length} Geräte, davon ${inhalt.blaetter.length} mit Prüfprotokoll. '
        'Inaktive Geräte sind mit Grund aufgeführt und erhalten kein Prüfprotokoll; '
        'aktive Geräte ohne abgeschlossene Prüfung sind als „nicht geprüft“ gekennzeichnet.',
        style: const pw.TextStyle(fontSize: 8),
      ),
      if (unterschrift?.pruefgeraet?.isNotEmpty ?? false) ...[
        pw.SizedBox(height: 4),
        pw.Text('Prüfgerät: ${unterschrift!.pruefgeraet}', style: const pw.TextStyle(fontSize: 8)),
      ],
      pw.SizedBox(height: 24),
      _unterschriftBlock(
        name: unterschrift?.name,
        datumOrt: unterschrift?.datumOrt,
        bild: unterschrift?.bild,
      ),
    ],
  ));

  for (final b in inhalt.blaetter) {
    _blatt(doc, s, kopf, b.geraet, b.pruefung, unterschrift: unterschrift);
  }
  return doc.save();
}

/// Nachdruck eines einzelnen, historischen Prüfprotokolls — ausschließlich
/// aus dem bei Abschluss gespeicherten Snapshot.
Future<Uint8List> einzelProtokollPdf(GeraetePruefung p, Geraet geraet,
    {required ProtokollKopf kopf, PdfSchriften? schriften, PdfUnterschrift? unterschrift}) async {
  final s = schriften ?? await PdfSchriften.laden();
  final doc = pw.Document(theme: pw.ThemeData.withFont(base: s.regular, bold: s.bold));
  _blatt(doc, s, kopf, geraet, p, unterschrift: unterschrift);
  return doc.save();
}

pw.Widget _kopfzeile(PdfSchriften s, String titel, ProtokollKopf kopf, String unterzeile) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 1.5))),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(titel, style: pw.TextStyle(font: s.bold, fontSize: 15, color: _primary)),
              if (kopf.kunde != null || kopf.standort != null)
                pw.Text([kopf.kunde, kopf.standort].whereType<String>().join(' · '),
                    style: const pw.TextStyle(fontSize: 10)),
              pw.Text(unterzeile, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ]),
          ),
          if (kopf.firma != null)
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(kopf.firma!, style: pw.TextStyle(font: s.bold, fontSize: 10)),
              if (kopf.firmaAdresse != null && kopf.firmaAdresse!.isNotEmpty)
                pw.Text(kopf.firmaAdresse!, style: const pw.TextStyle(fontSize: 8)),
            ]),
        ],
      ),
    );

pw.Widget _fuss(pw.Context ctx, PdfSchriften s) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Generiert von ElektraLog', style: pw.TextStyle(font: s.mono, fontSize: 7, color: PdfColors.grey)),
        pw.Text('Seite ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(font: s.mono, fontSize: 7, color: PdfColors.grey)),
      ],
    );

pw.Widget _zelle(String text, {pw.Font? font, PdfColor? farbe, double size = 8}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: size, color: farbe)),
    );

pw.Widget _tabelle(PdfSchriften s, List<String> kopf, List<List<pw.Widget>> zeilen,
        {Map<int, pw.TableColumnWidth>? breiten}) =>
    pw.Table(
      border: pw.TableBorder.all(color: _grau, width: 0.5),
      columnWidths: breiten,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _flaeche),
          children: [for (final k in kopf) _zelle(k, font: s.bold)],
        ),
        for (final z in zeilen) pw.TableRow(children: z),
      ],
    );

pw.Widget _uebersicht(List<UebersichtZeile> zeilen, PdfSchriften s) => _tabelle(
      s,
      ['Nr.', 'Gerät', 'Inventar-/Seriennr.', 'SK', 'Raum', 'Status', 'Letzte Prüfung', 'Nächste Prüfung'],
      [
        for (final (i, z) in zeilen.indexed)
          [
            _zelle('${i + 1}'),
            _zelle([z.geraet.bezeichnung, z.geraet.hersteller, z.geraet.typ].whereType<String>().join(' · ')),
            _zelle([z.geraet.inventarnummer, z.geraet.seriennummer].whereType<String>().join(' / ')),
            _zelle(z.geraet.schutzklasse ?? '–'),
            _zelle(z.raum),
            _zelle(z.status, farbe: z.geraet.aktiv ? null : PdfColors.grey700),
            _zelle(z.letztePruefung == null
                ? (z.geraet.aktiv ? 'nicht geprüft' : '–')
                : '${_datum(z.letztePruefung!.datum)} · ${pruefartKurz(z.letztePruefung!)} · '
                    '${z.letztePruefung!.bestanden ? 'bestanden' : 'nicht bestanden'}'),
            _zelle(z.naechstePruefung == null ? '–' : _datum(z.naechstePruefung!)),
          ],
      ],
      breiten: const {0: pw.FixedColumnWidth(24), 3: pw.FixedColumnWidth(26)},
    );

/// Unterschriftsfeld: Bild (falls vorhanden) über der Linie, darunter
/// Name und Datum/Ort.
pw.Widget _unterschriftBlock({String? name, String? datumOrt, Uint8List? bild}) => pw.Row(children: [
      pw.Expanded(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
            height: 48,
            decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
            child: bild == null ? null : pw.Image(pw.MemoryImage(bild), fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            [
              if (datumOrt?.isNotEmpty ?? false) datumOrt,
              'Unterschrift Prüfer${name == null || name.isEmpty ? '' : ' ($name)'}',
            ].join(' · '),
            style: const pw.TextStyle(fontSize: 8),
          ),
        ]),
      ),
      pw.SizedBox(width: 120),
    ]);

void _blatt(pw.Document doc, PdfSchriften s, ProtokollKopf kopf, Geraet aktuell, GeraetePruefung p,
    {PdfUnterschrift? unterschrift}) {
  final snap = p.ortSnapshot ?? const {};
  final stamm = (snap['geraet'] as Map?)?.cast<String, dynamic>() ?? aktuell.toJson();
  String? ort(String k, String f) => (snap[k] as Map?)?[f] as String?;
  final ortKopf = ProtokollKopf(
    firma: kopf.firma,
    firmaAdresse: kopf.firmaAdresse,
    kunde: ort('kunde', 'name') ?? kopf.kunde,
    standort: [ort('standort', 'bezeichnung'), ort('raum', 'bezeichnung')].whereType<String>().join(' › '),
  );

  List<List<pw.Widget>> bewertungen(String schritt) => [
        for (final x in p.punkte)
          if (x.schritt == schritt)
            [
              _zelle(x.bezeichnung),
              _zelle(bewertungText(x.bewertung), font: s.bold, farbe: x.bewertung == 'nio' ? _schlecht : null),
              _zelle(x.begruendung ?? ''),
            ],
      ];

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(32),
    footer: (ctx) => _fuss(ctx, s),
    build: (ctx) => [
      _kopfzeile(s, 'Prüfprotokoll: ${stamm['bezeichnung']}', ortKopf, 'Gerät ${p.geraetUuid}'),
      pw.SizedBox(height: 10),
      // Tatsächliche Prüfart, gut sichtbar (Praxisanforderung).
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(8),
        color: _flaeche,
        child: pw.Text(p.pruefartText, style: pw.TextStyle(font: s.bold, fontSize: 11, color: _primary)),
      ),
      if (p.ersetztUuid != null)
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text('${p.anlass ?? 'Korrektur'} — ersetzt die frühere Fassung.',
              style: const pw.TextStyle(fontSize: 8)),
        ),
      pw.SizedBox(height: 10),
      _tabelle(s, [
        'Angabe',
        'Wert'
      ], [
        for (final (k, v) in [
          ('Prüfdatum', _datum(p.datum)),
          ('Prüfer', p.prueferName ?? '–'),
          ('Prüfgerät', p.messgeraet ?? '–'),
          ('Schutzklasse', p.schutzklasse ?? '–'),
          ('Hersteller / Type', [stamm['hersteller'], stamm['typ']].whereType<String>().join(' / ')),
          ('Seriennummer', '${stamm['seriennummer'] ?? '–'}'),
          ('Inventarnummer', '${stamm['inventarnummer'] ?? '–'}'),
          ('Schutzart', '${stamm['schutzart'] ?? '–'}'),
          ('Regelwerk / Grenzwerte', p.regelVersion),
        ])
          [_zelle(k), _zelle(v)],
      ], breiten: const {
        0: pw.FixedColumnWidth(130)
      }),
      pw.SizedBox(height: 12),
      pw.Text('1 · Besichtigen', style: pw.TextStyle(font: s.bold, fontSize: 10)),
      pw.SizedBox(height: 4),
      _tabelle(s, ['Prüfpunkt', 'Bewertung', 'Befund / Begründung'], bewertungen('besichtigen'),
          breiten: const {1: pw.FixedColumnWidth(60)}),
      pw.SizedBox(height: 10),
      pw.Text('2 · Messen', style: pw.TextStyle(font: s.bold, fontSize: 10)),
      pw.SizedBox(height: 4),
      if (p.punkte.every((x) => !x.istMessung))
        pw.Text('Kein vorgegebener Messablauf (Schutzklasse ${p.schutzklasse ?? '–'}).',
            style: const pw.TextStyle(fontSize: 8))
      else
        _tabelle(s, [
          'Messgröße',
          'Messwert',
          'Grenzwert',
          'Verfahren',
          'Bewertung',
          'Begründung'
        ], [
          for (final x in p.punkte)
            if (x.istMessung)
              [
                _zelle(x.bezeichnung),
                _zelle(x.bewertung == 'na' ? '–' : '${_zahl(x.messwert)} ${x.einheit ?? ''}', font: s.mono),
                _zelle('${x.vergleich == '<=' ? '≤' : '≥'} ${_zahl(x.grenzwert)} ${x.einheit ?? ''}', font: s.mono),
                _zelle(x.methode ?? ''),
                _zelle(bewertungText(x.bewertung), font: s.bold, farbe: x.bewertung == 'nio' ? _schlecht : null),
                _zelle(x.begruendung ?? ''),
              ],
        ]),
      pw.SizedBox(height: 10),
      pw.Text('3 · Erproben', style: pw.TextStyle(font: s.bold, fontSize: 10)),
      pw.SizedBox(height: 4),
      _tabelle(s, ['Prüfpunkt', 'Bewertung', 'Befund / Begründung'], bewertungen('erproben'),
          breiten: const {1: pw.FixedColumnWidth(60)}),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: p.bestanden ? _gut : _schlecht, width: 1.5)),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(
            'Ergebnis: ${p.bestanden ? 'bestanden' : 'nicht bestanden'}',
            style: pw.TextStyle(font: s.bold, fontSize: 12, color: p.bestanden ? _gut : _schlecht),
          ),
          if ((p.maengel ?? '').isNotEmpty) pw.Text('Mängel: ${p.maengel}', style: const pw.TextStyle(fontSize: 9)),
          if ((p.bemerkung ?? '').isNotEmpty)
            pw.Text('Bemerkung: ${p.bemerkung}', style: const pw.TextStyle(fontSize: 9)),
          pw.Text(
            'Prüfintervall: ${p.intervallMonate == null ? '–' : '${p.intervallMonate} Monate'} · '
            'Nächste Prüfung: ${p.naechstePruefung == null ? (p.bestanden ? '–' : 'nach Mängelbeseitigung') : _datum(textAlsTag(p.naechstePruefung!))}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ]),
      ),
      pw.SizedBox(height: 20),
      if (unterschrift != null && unterschrift.unterschreibt(p))
        _unterschriftBlock(name: p.prueferName ?? unterschrift.name, datumOrt: unterschrift.datumOrt, bild: unterschrift.bild)
      else
        _unterschriftBlock(name: p.prueferName, datumOrt: 'Datum'),
    ],
  ));
}

// ── Etiketten (Roadmap M7) ───────────────────────────────────────────────────

/// Etikettenformate. Kein Drucker ist festgelegt (Gate 5): Ausgabe als PDF
/// für den Systemdruck; Bluetooth-Direktdruck erst mit getestetem Gerät.
enum EtikettFormat {
  e50x30('50 × 30 mm', 50, 30),
  e62x29('62 × 29 mm', 62, 29),
  e40x30('40 × 30 mm', 40, 30),
  a4('A4-Bogen 70 × 37 mm (3 × 8)', 70, 37);

  const EtikettFormat(this.bezeichnung, this.breiteMm, this.hoeheMm);
  final String bezeichnung;
  final double breiteMm;
  final double hoeheMm;
}

/// Ein Etikett: QR-Code mit der **vollständigen** Geräte-UUID und dieselbe
/// UUID lesbar darunter — keine Kunden- oder Ortsangaben im Code.
pw.Widget _etikett(Geraet g, EtikettFormat f, PdfSchriften s, {required bool mitBezeichnung}) {
  final breite = f.breiteMm * PdfPageFormat.mm;
  final hoehe = f.hoeheMm * PdfPageFormat.mm;
  const rand = 2 * PdfPageFormat.mm;
  // Monospace: Zeichenbreite ≈ 0,6 × Schriftgröße; 36 Zeichen sollen passen.
  final textGroesse = ((breite - 2 * rand) / (36 * 0.6)).clamp(3.5, 8.0);
  final textHoehe = textGroesse * 1.3 + (mitBezeichnung ? textGroesse * 1.4 : 0);
  return pw.Container(
    width: breite,
    height: hoehe,
    padding: const pw.EdgeInsets.all(rand),
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
          data: g.uuid,
          width: hoehe - 2 * rand - textHoehe - 2,
          height: hoehe - 2 * rand - textHoehe - 2,
          drawText: false,
        ),
        pw.SizedBox(height: 2),
        pw.Text(g.uuid, style: pw.TextStyle(font: s.mono, fontSize: textGroesse)),
        if (mitBezeichnung)
          pw.Text(g.bezeichnung, maxLines: 1, style: pw.TextStyle(font: s.bold, fontSize: textGroesse * 1.1)),
      ],
    ),
  );
}

/// Etiketten für ein oder mehrere Geräte. Nachdruck ergibt dieselbe UUID.
Future<Uint8List> etikettenPdf(
  List<Geraet> geraete, {
  EtikettFormat format = EtikettFormat.e50x30,
  bool mitBezeichnung = false,
  PdfSchriften? schriften,
  bool komprimieren = true,
}) async {
  final s = schriften ?? await PdfSchriften.laden();
  final doc = pw.Document(compress: komprimieren);
  if (format == EtikettFormat.a4) {
    const proSeite = 24;
    for (var i = 0; i < geraete.length; i += proSeite) {
      final seite = geraete.skip(i).take(proSeite).toList();
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(marginLeft: 0, marginRight: 0, marginTop: 0, marginBottom: 0),
        build: (_) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 0.5 * PdfPageFormat.cm),
          child: pw.Wrap(children: [for (final g in seite) _etikett(g, format, s, mitBezeichnung: mitBezeichnung)]),
        ),
      ));
    }
  } else {
    for (final g in geraete) {
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat(format.breiteMm * PdfPageFormat.mm, format.hoeheMm * PdfPageFormat.mm),
        build: (_) => _etikett(g, format, s, mitBezeichnung: mitBezeichnung),
      ));
    }
  }
  return doc.save();
}

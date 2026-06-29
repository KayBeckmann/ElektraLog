import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/models/messung.dart';
import '../../core/models/pruefprotokoll.dart';
import '../../core/models/sichtpruefung.dart';
import '../../core/models/verteiler.dart';
import '../../core/models/verteiler_komponente.dart';

// Sichtprüfung Checkpunkte
const _sichtpruefungLabels = <String, String>{
  'kennzeichnungVorhanden':          'Kennzeichnung vorhanden',
  'schutzleiterAngeschlossen':       'Schutzleiter korrekt angeschlossen',
  'leitungenOrdnungsgemaess':        'Leitungen ordnungsgemäß verlegt',
  'schutzeinrichtungenVorhanden':    'Schutzeinrichtungen vorhanden und korrekt',
  'brandschutzabdichtung':           'Brandschutzabdichtungen vorhanden',
  'beschriftungAbgaenge':            'Beschriftung der Abgänge vollständig',
  'zustandGehaeuse':                 'Zustand des Gehäuses / Schranks',
  'verteilerAbschliessbar':          'Verteiler abschließbar / abgeschlossen',
  'schutzGegeDirektBerühren':        'Schutz gegen direktes Berühren',
  'kennzeichnungNPE':                'Kennzeichnung N- und PE-Leiter',
  'leiterverbindungen':              'Leiterverbindungen',
  'schutzUeberwachungseinrichtungen':'Schutz- und Überwachungseinrichtungen',
  'zugaenglichkeit':                 'Zugänglichkeit',
  'ueberspannungsschutz':            'Überspannungsschutz',
  'dokumentation':                   'Dokumentation / Stromlaufplan / Legende',
};

// Erprobung Checkpunkte
const _erprobungLabels = <String, String>{
  'funktionspruefungAnlage': 'Funktionsprüfung der Anlage',
  'rcdErprobung':            'RCD (FI-Schutzschalter)',
  'spannungsfall':           'Überprüfung Spannungsfall',
  'spannungspolaritaet':     'Spannungspolarität',
};

class PdfService {
  /// Filtert Messungen für ein neues Protokoll:
  /// 1. Schließt Messungen aus, die bereits in früheren Protokollen archiviert sind.
  /// 2. Behält nur den neuesten Messwert pro Komponente (BMK).
  static List<Messung> filterMessungenForProtokoll(
      List<Messung> messungen, List<Pruefprotokoll> protokolle) {
    final gesperrteUuids = <String>{};
    for (final p in protokolle) {
      final raw = p.messdatenSnapshot;
      if (raw == null || raw.isEmpty) continue;
      try {
        final snapshot = jsonDecode(raw) as Map<String, dynamic>;
        final komponenten = snapshot['komponenten'] as List<dynamic>? ?? [];
        for (final k in komponenten) {
          final snapsMessungen = (k as Map<String, dynamic>)['messungen']
                  as List<dynamic>? ??
              [];
          for (final m in snapsMessungen) {
            final uuid = (m as Map<String, dynamic>)['uuid'] as String?;
            if (uuid != null) gesperrteUuids.add(uuid);
          }
        }
      } catch (_) {}
    }

    final active = messungen.where((m) => !gesperrteUuids.contains(m.uuid)).toList();

    final newestByKomp = <String, Messung>{};
    for (final m in active) {
      if (m.komponenteUuid == null) continue;
      final existing = newestByKomp[m.komponenteUuid!];
      if (existing == null || m.pruefungDatum.isAfter(existing.pruefungDatum)) {
        newestByKomp[m.komponenteUuid!] = m;
      }
    }

    return newestByKomp.values.toList();
  }

  /// Generiert ein ZVEH-angelehtes Prüfprotokoll.
  ///
  /// Seite 1: Deckblatt mit Auftragnehmer, Prüfobjekt, Anlagendaten,
  ///          Sichtprüfungs-Checkliste und Unterschrift.
  /// Seite 2+: Detaillierte Messwerte je Komponente mit Grenzwerten.
  static Future<Uint8List> generateProtokoll({
    required String prueferName,
    String? firma,
    String? firmaStrasse,
    String? firmaPlz,
    String? firmaOrt,
    String? pruefgeraet,
    required String datumOrt,
    String? kundenName,
    String? standortBezeichnung,
    required Verteiler verteiler,
    required List<Sichtpruefung> sichtpruefungen,
    required List<VerteilerKomponente> komponenten,
    required List<Messung> messungen,
    Uint8List? signaturPng,
    String? bemerkung,
  }) async {
    final doc = pw.Document();

    // ── Farben ────────────────────────────────────────────────────────────────
    final primary = PdfColor.fromHex('#091426');
    final primaryLight = PdfColor.fromHex('#1E3A5F');
    final surface = PdfColor.fromHex('#F5F3F4');
    final success = PdfColor.fromHex('#1A6B2E');
    final successBg = PdfColor.fromHex('#B7F0CB');
    final error = PdfColor.fromHex('#BA1A1A');
    final errorBg = PdfColor.fromHex('#FFDAD6');
    final warning = PdfColor.fromHex('#7A5700');
    final warningBg = PdfColor.fromHex('#FFDEA0');
    final greyLight = PdfColor.fromHex('#C5C6CD');

    // ── Schriftarten ──────────────────────────────────────────────────────────
    final fontR = await PdfGoogleFonts.interRegular();
    final fontB = await PdfGoogleFonts.interBold();
    final fontM = await PdfGoogleFonts.jetBrainsMonoRegular();

    // ── Daten vorbereiten ─────────────────────────────────────────────────────
    Map<String, dynamic> anlagendaten = {};
    if (verteiler.anlagendatenJson != null) {
      try {
        anlagendaten =
            jsonDecode(verteiler.anlagendatenJson!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final latestSichtpruefung = sichtpruefungen.isEmpty
        ? null
        : (List<Sichtpruefung>.from(sichtpruefungen)
              ..sort((a, b) =>
                  b.pruefungDatum.compareTo(a.pruefungDatum)))
            .first;

    final messungenByKomponente = <String, List<Messung>>{};
    for (final m in messungen) {
      if (m.komponenteUuid != null) {
        messungenByKomponente.putIfAbsent(m.komponenteUuid!, () => []).add(m);
      }
    }

    // Komponenten in Baumreihenfolge (depth-first) sortieren
    final geordnet = _flattenTree(komponenten);

    // Datum und Ort trennen (Format: "TT.MM.JJJJ, Ort" oder nur Datum)
    String datum = datumOrt;
    String ort = '';
    final commaIdx = datumOrt.indexOf(',');
    if (commaIdx != -1) {
      datum = datumOrt.substring(0, commaIdx).trim();
      ort = datumOrt.substring(commaIdx + 1).trim();
    }

    // Unterschrift-Block: steht direkt unter ERPROBUNG auf Seite 2 (oder auf
    // Seite 1, falls keine Sichtprüfung/Erprobung existiert, siehe unten).
    final unterschriftSection = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('UNTERSCHRIFT', primary, fontB),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (signaturPng != null)
                    pw.Container(
                      height: 56,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                            bottom: pw.BorderSide(color: primary, width: 1)),
                      ),
                      child: pw.Image(
                        pw.MemoryImage(signaturPng),
                        fit: pw.BoxFit.contain,
                      ),
                    )
                  else
                    pw.Container(
                      height: 56,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                            bottom: pw.BorderSide(color: primary, width: 1)),
                      ),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text(prueferName,
                      style: pw.TextStyle(font: fontR, fontSize: 9)),
                  pw.Text('Prüfer',
                      style: pw.TextStyle(
                          font: fontR, fontSize: 8,
                          color: PdfColors.grey600)),
                ],
              ),
            ),
            pw.SizedBox(width: 32),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 56,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey400, width: 1)),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Auftraggeber',
                      style: pw.TextStyle(
                          font: fontR, fontSize: 8,
                          color: PdfColors.grey600)),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    // ── Dokument bauen ────────────────────────────────────────────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 40),
        theme: pw.ThemeData.withFont(base: fontR, bold: fontB),
        header: (ctx) => _pageHeader(ctx, primary, fontB, fontM, verteiler.bezeichnung),
        footer: (ctx) => _pageFooter(ctx, fontM),
        build: (ctx) => [
          // ══════════════════════════════════════════════════════════════
          //  SEITE 1 — DECKBLATT
          // ══════════════════════════════════════════════════════════════

          // Titel-Block
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: primary,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ELEKTRISCHES PRÜFPROTOKOLL',
                  style: pw.TextStyle(
                    font: fontB, fontSize: 16, color: PdfColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Erstellt mit ElektraLog',
                  style: pw.TextStyle(
                    font: fontR, fontSize: 8,
                    color: PdfColor.fromHex('#8590A6'),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Auftragnehmer | Prüfobjekt
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: greyLight, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _blockTitle('AUFTRAGNEHMER', primaryLight, fontB),
                      pw.SizedBox(height: 6),
                      if (firma != null && firma.isNotEmpty)
                        _infoRow('Firma', firma, fontR, fontM),
                      if (firmaStrasse != null && firmaStrasse.isNotEmpty)
                        _infoRow('Straße', firmaStrasse, fontR, fontM),
                      if ((firmaPlz?.isNotEmpty == true) ||
                          (firmaOrt?.isNotEmpty == true))
                        _infoRow(
                          'PLZ / Ort',
                          [
                            if (firmaPlz?.isNotEmpty == true) firmaPlz!,
                            if (firmaOrt?.isNotEmpty == true) firmaOrt!,
                          ].join(' '),
                          fontR,
                          fontM,
                        ),
                      _infoRow('Prüfer', prueferName, fontR, fontM),
                      _infoRow('Datum', datum, fontR, fontM),
                      if (ort.isNotEmpty)
                        _infoRow('Ort', ort, fontR, fontM),
                      if (pruefgeraet != null && pruefgeraet.isNotEmpty)
                        _infoRow('Prüfgerät', pruefgeraet, fontR, fontM),
                      if (bemerkung != null && bemerkung.isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 8),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Bemerkung', style: pw.TextStyle(font: fontB, fontSize: 8, color: PdfColors.grey700)),
                              pw.SizedBox(height: 2),
                              pw.Text(bemerkung, style: pw.TextStyle(font: fontR, fontSize: 9)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: greyLight, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _blockTitle('PRÜFOBJEKT', primaryLight, fontB),
                      pw.SizedBox(height: 6),
                      if (kundenName != null && kundenName.isNotEmpty)
                        _infoRow('Kunde', kundenName, fontR, fontM),
                      if (standortBezeichnung != null &&
                          standortBezeichnung.isNotEmpty)
                        _infoRow('Standort', standortBezeichnung, fontR, fontM),
                      _infoRow('Verteiler/Anlage', verteiler.bezeichnung,
                          fontR, fontM),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // Anlagendaten
          _sectionTitle('ANLAGENDATEN', primary, fontB),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: greyLight, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: surface),
                  children: [
                    _anlagCell('Netzform', _str(anlagendaten, 'netzform'), fontR, fontM),
                    _anlagCell('Nennspannung',
                        _str(anlagendaten, 'nennspannung') ?? _str(anlagendaten, 'nennspannung_v') ?? '—',
                        fontR, fontM),
                    _anlagCell('Frequenz',
                        _str(anlagendaten, 'frequenz') ?? _str(anlagendaten, 'frequenz_hz') ?? '50 Hz',
                        fontR, fontM),
                    _anlagCell('Außenleiter',
                        _str(anlagendaten, 'aussenleiter') ?? _str(anlagendaten, 'anzahl_aussenleiter') ?? '—',
                        fontR, fontM),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _anlagCell('Schutzleiterart',
                        _str(anlagendaten, 'schutzleiterart') ?? '—',
                        fontR, fontM),
                    _anlagCell('Max. Ik',
                        _str(anlagendaten, 'max_kurzschlussstrom') != null
                            ? '${_str(anlagendaten, "max_kurzschlussstrom")} A'
                            : '—',
                        fontR, fontM),
                    _anlagCell('Bemerkung',
                        _str(anlagendaten, 'bemerkung') ?? '—',
                        fontR, fontM, span: true),
                    pw.SizedBox(),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // Sichtprüfung
          _sectionTitle('SICHTPRÜFUNG', primary, fontB),
          if (latestSichtpruefung != null) ...[
            pw.Row(
              children: [
                _ergebnisBadge(
                    latestSichtpruefung.ergebnis, success, successBg,
                    error, errorBg, warning, warningBg, fontB),
                pw.SizedBox(width: 10),
                pw.Text(
                  'Geprüft am ${_formatDatum(latestSichtpruefung.pruefungDatum)}'
                  '${latestSichtpruefung.prueferName != null ? " · ${latestSichtpruefung.prueferName}" : ""}',
                  style: pw.TextStyle(font: fontR, fontSize: 9,
                      color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            // Checkliste
            _checklisteTable(latestSichtpruefung, _sichtpruefungLabels,
                fontR, fontB, fontM, success, error, surface, greyLight),
            if (latestSichtpruefung.maengel != null &&
                latestSichtpruefung.maengel!.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: errorBg,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Mängel / Bemerkungen:',
                        style: pw.TextStyle(
                            font: fontB, fontSize: 9, color: error)),
                    pw.SizedBox(height: 3),
                    pw.Text(latestSichtpruefung.maengel!,
                        style: pw.TextStyle(
                            font: fontR, fontSize: 9, color: error)),
                  ],
                ),
              ),
            ],
            if (latestSichtpruefung.naechstePruefungDatum != null) ...[
              pw.SizedBox(height: 6),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EAF4FB'),
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(
                      color: PdfColor.fromHex('#1565C0'), width: 0.5),
                ),
                child: pw.Row(
                  children: [
                    pw.Text('Nächste Prüfung: ',
                        style: pw.TextStyle(
                            font: fontB,
                            fontSize: 9,
                            color: PdfColor.fromHex('#1565C0'))),
                    pw.Text(
                      _formatDatum(latestSichtpruefung.naechstePruefungDatum!),
                      style: pw.TextStyle(
                          font: fontM,
                          fontSize: 9,
                          color: PdfColor.fromHex('#1565C0')),
                    ),
                  ],
                ),
              ),
            ],
          ] else
            pw.Text('Keine Sichtprüfung erfasst.',
                style: pw.TextStyle(
                    font: fontR, fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 14),

          // Unterschrift bleibt auf Seite 1, falls keine Erprobung folgt
          // (sonst steht sie auf Seite 2 direkt unter ERPROBUNG, s.u.)
          if (latestSichtpruefung == null) ...[
            unterschriftSection,
          ],

          // ══════════════════════════════════════════════════════════════
          //  SEITENUMBRUCH → SEITE 2: ERPROBUNG + UNTERSCHRIFT + MESSWERTE
          // ══════════════════════════════════════════════════════════════
          if (latestSichtpruefung != null || geordnet.isNotEmpty) ...[
            pw.NewPage(),
            if (latestSichtpruefung != null) ...[
              pw.Inseparable(
                child: pw.Column(children: [
                  _sectionTitle('ERPROBUNG', primary, fontB),
                  pw.SizedBox(height: 8),
                  _checklisteTable(latestSichtpruefung, _erprobungLabels,
                      fontR, fontB, fontM, success, error, surface, greyLight),
                  pw.SizedBox(height: 14),
                  unterschriftSection,
                ]),
              ),
              pw.SizedBox(height: 14),
            ],
            if (geordnet.isNotEmpty) ...[
              _sectionTitle('MESSWERTE — DETAILAUSWERTUNG', primary, fontB),
              pw.SizedBox(height: 4),
              pw.Text(
                '${geordnet.length} Strukturelement(e) · '
                'Verteiler: ${verteiler.bezeichnung}',
                style: pw.TextStyle(
                    font: fontR, fontSize: 9, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 12),
              ...geordnet.expand((entry) {
                final kMessungen =
                    messungenByKomponente[entry.komponente.uuid] ?? [];
                final header = _komponenteHeader(
                  entry.komponente, entry.depth,
                  primary, surface, fontR, fontB,
                );

                if (kMessungen.isEmpty) {
                  return [
                    pw.Inseparable(child: pw.Column(children: [header])),
                    pw.SizedBox(height: 12),
                  ];
                }

                // Header + erste Messung zusammen halten
                final result = <pw.Widget>[
                  pw.Inseparable(
                    child: pw.Column(children: [
                      header,
                      _messungBlock(
                        kMessungen.first,
                        success, successBg, error, errorBg,
                        greyLight, surface, fontR, fontB, fontM,
                      ),
                    ]),
                  ),
                ];

                // Weitere Messungen: jeweils mit Mini-Header (Komponente als Kontext)
                for (final m in kMessungen.skip(1)) {
                  result.add(pw.Inseparable(
                    child: pw.Column(children: [
                      _komponenteFortsContinuedHeader(
                          entry.komponente, fontR, fontB),
                      _messungBlock(
                        m, success, successBg, error, errorBg,
                        greyLight, surface, fontR, fontB, fontM,
                      ),
                    ]),
                  ));
                }
                result.add(pw.SizedBox(height: 12));
                return result;
              }),
            ],
          ],
        ],
      ),
    );

    return doc.save();
  }

  // ── Baum-Helfer ───────────────────────────────────────────────────────────

  static List<({VerteilerKomponente komponente, int depth})> _flattenTree(
      List<VerteilerKomponente> alle) {
    final result = <({VerteilerKomponente komponente, int depth})>[];

    void visit(String? parentUuid, int depth) {
      final kinder = alle
          .where((k) => k.parentUuid == parentUuid)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      for (final k in kinder) {
        result.add((komponente: k, depth: depth));
        visit(k.uuid, depth + 1);
      }
    }

    visit(null, 0);
    return result;
  }

  // ── Etiketten-PDF (unverändert) ───────────────────────────────────────────

  static Future<Uint8List> generateEtiketten(
      List<VerteilerKomponente> komponenten) async {
    final doc = pw.Document();
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontMono = await PdfGoogleFonts.jetBrainsMonoRegular();
    final primaryColor = PdfColor.fromHex('#091426');

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
              final left = _etikett(pageKomponenten[i], fontRegular,
                  fontBold, fontMono, primaryColor);
              final right = i + 1 < pageKomponenten.length
                  ? _etikett(pageKomponenten[i + 1], fontRegular,
                      fontBold, fontMono, primaryColor)
                  : pw.SizedBox();
              rows.add(pw.Row(children: [
                pw.Expanded(child: left),
                pw.SizedBox(width: 8),
                pw.Expanded(child: right),
              ]));
              rows.add(pw.SizedBox(height: 8));
            }
            return pw.Column(children: rows);
          },
        ),
      );
    }
    return doc.save();
  }

  // ── Etikett ───────────────────────────────────────────────────────────────

  static pw.Widget _etikett(
    VerteilerKomponente k,
    pw.Font regular,
    pw.Font bold,
    pw.Font mono,
    PdfColor primary,
  ) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Row(children: [
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: 'elektralog://komponente/${k.uuid}',
            width: 64, height: 64,
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(k.bezeichnung,
                    style: pw.TextStyle(
                        font: bold, fontSize: 10, color: primary)),
                pw.SizedBox(height: 2),
                pw.Text(
                  k.typ.toUpperCase().replaceAll('_', ' '),
                  style: pw.TextStyle(
                      font: regular, fontSize: 8,
                      color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 4),
                pw.Text(k.uuid.substring(0, 8),
                    style: pw.TextStyle(
                        font: mono, fontSize: 7,
                        color: PdfColors.grey)),
              ],
            ),
          ),
        ]),
      );

  // ── Seiten-Header / Footer ────────────────────────────────────────────────

  static pw.Widget _pageHeader(
    pw.Context ctx,
    PdfColor primary,
    pw.Font bold,
    pw.Font mono,
    String verteiler,
  ) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: primary, width: 1.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('ElektraLog — Prüfprotokoll',
                style: pw.TextStyle(font: bold, fontSize: 10, color: primary)),
            pw.Text(verteiler,
                style: pw.TextStyle(
                    font: mono, fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      );

  static pw.Widget _pageFooter(pw.Context ctx, pw.Font mono) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generiert von ElektraLog',
                style: pw.TextStyle(
                    font: mono, fontSize: 7, color: PdfColors.grey)),
            pw.Text('Seite ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(
                    font: mono, fontSize: 7, color: PdfColors.grey)),
          ],
        ),
      );

  // ── Prüf-Checkliste (Sichtprüfung / Erprobung) ────────────────────────────

  static pw.Widget _checklisteTable(
    Sichtpruefung sp,
    Map<String, String> labels,
    pw.Font fontR,
    pw.Font fontB,
    pw.Font fontM,
    PdfColor success,
    PdfColor error,
    PdfColor surface,
    PdfColor grey,
  ) {
    Map<String, dynamic> checkliste = {};
    if (sp.checklisteJson != null) {
      try {
        checkliste = jsonDecode(sp.checklisteJson!) as Map<String, dynamic>;
      } catch (_) {}
    }

    pw.TableRow buildRow(String key, String label, bool alt) {
      final rawStatus = checkliste[key] as String? ?? 'nicht_zutreffend';
      final status = _normalizePunktStatus(rawStatus);
      return pw.TableRow(
        decoration: alt
            ? pw.BoxDecoration(color: PdfColor.fromHex('#F5F3F4'))
            : null,
        children: [
          _td(label, fontR),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: pw.Center(
              child: _punktStatusBadge(status, success, error, fontB, fontM),
            ),
          ),
        ],
      );
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: pw.BoxDecoration(color: surface),
        children: [
          _th('Prüfpunkt', fontB),
          _th('Ergebnis', fontB, align: pw.TextAlign.center),
        ],
      ),
    ];

    bool alt = false;
    for (final entry in labels.entries) {
      rows.add(buildRow(entry.key, entry.value, alt));
      alt = !alt;
    }

    return pw.Table(
      tableWidth: pw.TableWidth.max,
      border: pw.TableBorder.all(color: grey, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  // ── Komponenten-Header ────────────────────────────────────────────────────

  static pw.Widget _komponenteHeader(
    VerteilerKomponente k,
    int depth,
    PdfColor primary,
    PdfColor surface,
    pw.Font fontR,
    pw.Font fontB,
  ) {
    Map<String, dynamic> props = {};
    if (k.eigenschaftenJson != null) {
      try {
        props = jsonDecode(k.eigenschaftenJson!) as Map<String, dynamic>;
      } catch (_) {}
    }
    final propParts = <String>[];
    if (props['nennstrom'] != null)   propParts.add('${props["nennstrom"]} A');
    if (props['pole'] != null)         propParts.add('${props["pole"]}-polig');
    if (props['charakteristik'] != null)
      propParts.add('Char. ${props["charakteristik"]}');
    if (props['auslösestrom'] != null)
      propParts.add('I∆n ${props["auslösestrom"]} mA');
    if (props['sicherungGroesse'] != null)
      propParts.add(props['sicherungGroesse'].toString());

    final indentColor = depth == 0
        ? primary
        : depth == 1
            ? PdfColor.fromHex('#1E3A5F')
            : PdfColor.fromHex('#2E5C8A');
    final leftIndent = depth * 12.0;

    final bmk = k.betriebsmittelkennzeichen.isNotEmpty
        ? k.betriebsmittelkennzeichen
        : null;

    return pw.Padding(
      padding: pw.EdgeInsets.only(left: leftIndent),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (depth > 0)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              color: PdfColor.fromHex('#EEF2F7'),
              child: pw.Text(
                '${List.filled(depth, '  ').join()}↳ Unterkomponente (Ebene $depth)',
                style: pw.TextStyle(
                    font: fontR, fontSize: 7, color: PdfColors.grey600),
              ),
            ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: indentColor,
            child: pw.Row(
              children: [
                pw.Text(
                  _typLabel(k.typ).toUpperCase(),
                  style: pw.TextStyle(
                      font: fontB, fontSize: 8,
                      color: PdfColor.fromHex('#8590A6'),
                      letterSpacing: 0.5),
                ),
                if (bmk != null) ...[
                  pw.SizedBox(width: 6),
                  pw.Text(
                    bmk,
                    style: pw.TextStyle(
                        font: fontB, fontSize: 9,
                        color: PdfColor.fromHex('#B0C4DE')),
                  ),
                ],
                pw.SizedBox(width: 8),
                pw.Text(
                  k.zielbezeichnung.isNotEmpty
                      ? k.zielbezeichnung
                      : k.bezeichnung,
                  style: pw.TextStyle(
                      font: fontB, fontSize: 11, color: PdfColors.white),
                ),
              ],
            ),
          ),
          if (propParts.isNotEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: PdfColor.fromHex('#1E3A5F'),
              child: pw.Text(
                propParts.join('  ·  '),
                style: pw.TextStyle(
                    font: fontR, fontSize: 8,
                    color: PdfColor.fromHex('#B0C4DE')),
              ),
            ),
        ],
      ),
    );
  }

  /// Mini-Header für Folgemessungen derselben Komponente auf neuer Seite
  static pw.Widget _komponenteFortsContinuedHeader(
    VerteilerKomponente k,
    pw.Font fontR,
    pw.Font fontB,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      color: PdfColor.fromHex('#EEF2F7'),
      child: pw.Text(
        '${_typLabel(k.typ).toUpperCase()}  ${k.bezeichnung}  (Fortsetzung)',
        style: pw.TextStyle(
            font: fontR, fontSize: 8, color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  static pw.Widget _messungBlock(
    Messung m,
    PdfColor success,
    PdfColor successBg,
    PdfColor error,
    PdfColor errorBg,
    PdfColor grey,
    PdfColor surface,
    pw.Font fontR,
    pw.Font fontB,
    pw.Font fontM,
  ) {
    Map<String, dynamic> mw = {};
    if (m.messwertJson != null) {
      try {
        mw = jsonDecode(m.messwertJson!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final passed = m.ergebnis == 'bestanden';
    final rows = <_MwRow>[];

    switch (m.norm) {
      case 'vde_0100':
        _parseVde0100(mw, rows);
        break;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 1),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Norm-Zeile
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            color: surface,
            child: pw.Row(
              children: [
                pw.Text(_normLabel(m.norm),
                    style: pw.TextStyle(
                        font: fontB, fontSize: 9)),
                pw.SizedBox(width: 10),
                pw.Text(_formatDatum(m.pruefungDatum),
                    style: pw.TextStyle(
                        font: fontM, fontSize: 8,
                        color: PdfColors.grey600)),
                pw.Spacer(),
                _ergebnisBadgeSmall(passed, success, successBg,
                    error, errorBg, fontB),
              ],
            ),
          ),
          // Messwert-Tabelle
          if (rows.isNotEmpty)
            pw.Table(
              tableWidth: pw.TableWidth.max,
              border: pw.TableBorder(
                bottom: pw.BorderSide(color: grey, width: 0.5),
                left: pw.BorderSide(color: grey, width: 0.5),
                right: pw.BorderSide(color: grey, width: 0.5),
                horizontalInside: pw.BorderSide(
                    color: PdfColor.fromHex('#E8E8E8'), width: 0.3),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5), // Messgröße
                1: const pw.FlexColumnWidth(1.2), // Gemessen
                2: const pw.FlexColumnWidth(1.4), // Grenzwert
                3: const pw.FlexColumnWidth(0.6), // OK?
              },
              children: [
                // Spalten-Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#E8E8E8')),
                  children: [
                    _th('Messgröße', fontB),
                    _th('Gemessen', fontB, align: pw.TextAlign.right),
                    _th('Grenzwert', fontB),
                    _th('', fontB, align: pw.TextAlign.center),
                  ],
                ),
                ...rows.map((r) => pw.TableRow(children: [
                  _td(r.label, fontR),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    child: pw.Text(r.value,
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: fontM, fontSize: 9)),
                  ),
                  _td(r.limit, fontR, color: PdfColors.grey700),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    child: pw.Center(
                      child: r.ok == null
                          ? pw.Text('—',
                              style: pw.TextStyle(
                                  font: fontR, fontSize: 9,
                                  color: PdfColors.grey))
                          : pw.Text(
                              r.ok! ? '✓' : '✗',
                              style: pw.TextStyle(
                                  font: fontB,
                                  fontSize: 10,
                                  color: r.ok! ? success : error),
                            ),
                    ),
                  ),
                ])),
              ],
            ),
          // Bemerkung
          if (m.bemerkung != null && m.bemerkung!.isNotEmpty)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: grey, width: 0.5),
              ),
              child: pw.Text(
                'Bemerkung: ${m.bemerkung}',
                style: pw.TextStyle(
                    font: fontR, fontSize: 8,
                    color: PdfColors.grey700),
              ),
            ),
        ],
      ),
    );
  }

  // ── Messwert-Parser ───────────────────────────────────────────────────────

  static void _parseVde0100(Map<String, dynamic> mw, List<_MwRow> rows) {
    final minIk = mw['mindest_ik_a'];
    final char = mw['charakteristik'] as String? ?? 'B';
    final nenn = mw['nennstrom_a'];
    final eingabe = mw['eingabemodus'] as String? ?? 'kurzschlussstrom';
    final phasen = mw['phasen'] as List<dynamic>?;

    if (phasen != null) {
      for (final ph in phasen) {
        final phase = ph['phase'] as String? ?? '';
        final suffix = phase.isEmpty ? '' : ' ($phase)';

        // L-PE
        if (eingabe == 'kurzschlussstrom') {
          final ik = ph['kurzschlussstrom_l_pe_a'] ?? ph['kurzschlussstrom_a'];
          if (ik != null) {
            final minLabel = minIk != null
                ? '≥ ${_fmt(minIk)} A ($char${nenn != null ? _fmt(nenn) : '?'}: '
                    '${char == 'C' ? '10' : char == 'D' ? '20' : '5'}×)'
                : '—';
            rows.add(_MwRow(
              'Ik L-PE$suffix',
              '${_fmt(ik)} A',
              minLabel,
              ik is num && minIk is num ? ik >= minIk : null,
            ));
          }
        } else {
          final zs = ph['schleifenimpedanz_l_pe_ohm'] ?? ph['schleifenimpedanz_ohm'];
          if (zs != null) {
            final maxZs = (minIk is num && minIk > 0)
                ? 230.0 / minIk
                : null;
            rows.add(_MwRow(
              'Zs L-PE$suffix',
              '${_fmt(zs)} Ω',
              maxZs != null ? '≤ ${maxZs.toStringAsFixed(3)} Ω' : '—',
              zs is num && maxZs != null ? zs <= maxZs : null,
            ));
          }
        }

        // L-N (optional)
        if (eingabe == 'kurzschlussstrom') {
          final ikLn = ph['kurzschlussstrom_l_n_a'];
          if (ikLn != null)
            rows.add(_MwRow('Ik L-N$suffix', '${_fmt(ikLn)} A', '—', null));
        } else {
          final zsLn = ph['schleifenimpedanz_l_n_ohm'];
          if (zsLn != null)
            rows.add(_MwRow('Zs L-N$suffix', '${_fmt(zsLn)} Ω', '—', null));
        }

        final iso = ph['isolationswiderstand_mohm'];
        if (iso != null)
          rows.add(_MwRow(
            'Isolationswiderstand$suffix',
            '${_fmt(iso)} MΩ',
            '≥ 1 MΩ',
            iso is num ? iso >= 1.0 : null,
          ));
      }
    }

    // L-L Messungen (3-phasig)
    final llMessungen = mw['l_l_messungen'] as List<dynamic>?;
    if (llMessungen != null) {
      for (final ll in llMessungen) {
        final phasen = ll['phasen'] as String? ?? '';
        final ik = ll['kurzschlussstrom_a'];
        if (ik != null)
          rows.add(_MwRow('Ik $phasen', '${_fmt(ik)} A', '—', null));
      }
    }

    final drehfeld = mw['drehfeld_richtig'];
    if (drehfeld != null)
      rows.add(_MwRow(
        'Drehfeldrichtung',
        drehfeld == true ? 'korrekt' : 'falsch',
        '—',
        drehfeld == true,
      ));

    final erd = mw['erdungswiderstand_ohm'];
    if (erd != null)
      rows.add(
          _MwRow('Erdungswiderstand', '${_fmt(erd)} Ω', 'optional', null));

    // RCD
    final nennDiff = mw['rcd_nenn_differenzstrom_ma'];
    final gemDiff = mw['rcd_gemessen_differenzstrom_ma'];
    final zeit = mw['rcd_ausloesezeit_ms'];

    if (nennDiff != null)
      rows.add(
          _MwRow('Nenn-I∆n', '${_fmt(nennDiff)} mA', '—', null));

    if (gemDiff != null) {
      final minMa = nennDiff is num ? nennDiff * 0.5 : null;
      final maxMa = nennDiff is num ? nennDiff : null;
      final ok = (minMa != null && maxMa != null && gemDiff is num)
          ? gemDiff >= minMa && gemDiff <= maxMa
          : null;
      final limitStr = minMa != null
          ? '${_fmt(minMa)}–${_fmt(nennDiff)} mA (50–100 % I∆n)'
          : '50–100 % I∆n';
      rows.add(_MwRow('Gemessener Auslösestrom I∆',
          '${_fmt(gemDiff)} mA', limitStr, ok));
    }

    if (zeit != null)
      rows.add(_MwRow(
        'Auslösezeit',
        '${_fmt(zeit)} ms',
        '≤ 300 ms',
        zeit is num ? zeit <= 300 : null,
      ));

    // Fallback (kein Typ bekannt)
    final zsGeneric = mw['schleifenimpedanz_ohm'];
    if (zsGeneric != null && phasen == null)
      rows.add(_MwRow(
          'Schleifenimpedanz Zs', '${_fmt(zsGeneric)} Ω', '—', null));

    final isoGeneric = mw['isolationswiderstand_mohm'];
    if (isoGeneric != null && phasen == null)
      rows.add(_MwRow(
        'Isolationswiderstand',
        '${_fmt(isoGeneric)} MΩ',
        '≥ 1 MΩ',
        isoGeneric is num ? isoGeneric >= 1.0 : null,
      ));

    final zeitGeneric = mw['rcd_ausloesezeit_ms'];
    if (zeitGeneric != null && nennDiff == null && phasen == null)
      rows.add(_MwRow(
        'RCD-Auslösezeit',
        '${_fmt(zeitGeneric)} ms',
        '≤ 300 ms',
        zeitGeneric is num ? zeitGeneric <= 300 : null,
      ));
  }

  // ── Kleine Bau-Blöcke ────────────────────────────────────────────────────

  static pw.Widget _sectionTitle(
          String t, PdfColor c, pw.Font bold) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(children: [
          pw.Container(
              width: 3, height: 14, color: c,
              margin: const pw.EdgeInsets.only(right: 6)),
          pw.Text(t,
              style: pw.TextStyle(
                  font: bold, fontSize: 10, color: c,
                  letterSpacing: 0.6)),
        ]),
      );

  static pw.Widget _blockTitle(
          String t, PdfColor c, pw.Font bold) =>
      pw.Text(t,
          style: pw.TextStyle(
              font: bold, fontSize: 8, color: c,
              letterSpacing: 0.6));

  static pw.Widget _infoRow(
    String label,
    String value,
    pw.Font fontR,
    pw.Font fontM,
  ) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 3),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 70,
              child: pw.Text(label,
                  style: pw.TextStyle(
                      font: fontR, fontSize: 9,
                      color: PdfColors.grey600)),
            ),
            pw.Expanded(
              child: pw.Text(value,
                  style: pw.TextStyle(font: fontM, fontSize: 9)),
            ),
          ],
        ),
      );

  static pw.Widget _anlagCell(
    String label,
    String? value,
    pw.Font fontR,
    pw.Font fontM, {
    bool span = false,
  }) =>
      pw.Padding(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    font: fontR, fontSize: 7,
                    color: PdfColors.grey600)),
            pw.SizedBox(height: 1),
            pw.Text(value ?? '—',
                style: pw.TextStyle(font: fontM, fontSize: 9)),
          ],
        ),
      );

  static pw.Widget _ergebnisBadge(
    String ergebnis,
    PdfColor success,
    PdfColor successBg,
    PdfColor error,
    PdfColor errorBg,
    PdfColor warning,
    PdfColor warningBg,
    pw.Font fontB,
  ) {
    final PdfColor fg;
    final PdfColor bg;
    final String label;
    if (ergebnis == 'bestanden') {
      fg = success; bg = successBg; label = 'BESTANDEN';
    } else if (ergebnis == 'mit_maengeln') {
      fg = warning; bg = warningBg; label = 'MIT MÄNGELN';
    } else {
      fg = error; bg = errorBg; label = 'NICHT BESTANDEN';
    }
    return pw.Container(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
          color: bg, borderRadius: pw.BorderRadius.circular(3)),
      child: pw.Text(label,
          style: pw.TextStyle(font: fontB, fontSize: 9, color: fg)),
    );
  }

  static pw.Widget _ergebnisBadgeSmall(
    bool passed,
    PdfColor success,
    PdfColor successBg,
    PdfColor error,
    PdfColor errorBg,
    pw.Font fontB,
  ) =>
      pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: pw.BoxDecoration(
          color: passed ? successBg : errorBg,
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Text(
          passed ? 'BESTANDEN' : 'NICHT BESTANDEN',
          style: pw.TextStyle(
              font: fontB,
              fontSize: 7,
              color: passed ? success : error),
        ),
      );

  static pw.Widget _punktStatusBadge(
    String status,
    PdfColor success,
    PdfColor error,
    pw.Font fontB,
    pw.Font fontM,
  ) {
    if (status == 'bestanden') {
      return pw.Text('✓ Bestanden',
          style: pw.TextStyle(font: fontB, fontSize: 8, color: success));
    } else if (status == 'durchgefallen') {
      return pw.Text('✗ Durchgefallen',
          style: pw.TextStyle(font: fontB, fontSize: 8, color: error));
    } else {
      return pw.Text('— N/A',
          style: pw.TextStyle(
              font: fontM, fontSize: 8, color: PdfColors.grey));
    }
  }

  static pw.Widget _th(String t, pw.Font bold,
      {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(t,
            textAlign: align,
            style: pw.TextStyle(font: bold, fontSize: 8)),
      );

  static pw.Widget _td(String t, pw.Font font,
      {PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: pw.Text(t,
            style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: color)),
      );

  // ── Hilfsfunktionen ───────────────────────────────────────────────────────

  static String? _str(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) return null;
    return v.toString();
  }

  static String _fmt(dynamic v) {
    if (v == null) return '—';
    if (v is double) {
      // Keine unnötigen Nullen
      if (v == v.truncateToDouble()) return v.toInt().toString();
      return v.toStringAsFixed(v.abs() < 10 ? 2 : 1);
    }
    return v.toString();
  }

  static String _normLabel(String norm) {
    return norm == 'vde_0100' ? 'DIN VDE 0100' : norm;
  }

  static String _typLabel(String typ) {
    const labels = {
      'rcd': 'RCD / FI-Schutzschalter',
      'fi_ls': 'FI/LS-Kombination',
      'ls_schalter': 'LS-Schalter',
      'vorsicherung': 'Vorsicherung',
      'nh_sicherung': 'NH-Sicherung',
      'neozed': 'NeoZed-Sicherung',
      'diazed': 'DiaZed-Sicherung',
      'hauptschalter': 'Hauptschalter',
      'sammelschiene': 'Sammelschiene',
      'ueberspannung': 'Überspannungsschutz',
      'sonstige': 'Sonstige',
    };
    return labels[typ] ?? typ;
  }

  static String _normalizePunktStatus(String s) {
    switch (s) {
      case 'bestanden':
      case 'ok':
        return 'bestanden';
      case 'durchgefallen':
      case 'mangel':
        return 'durchgefallen';
      default:
        return 'nicht_zutreffend';
    }
  }

  static String _formatDatum(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

// ── Hilfsdatenklasse für Messwert-Zeilen ──────────────────────────────────────

class _MwRow {
  const _MwRow(this.label, this.value, this.limit, this.ok);
  final String label;
  final String value;
  final String limit;
  final bool? ok;
}

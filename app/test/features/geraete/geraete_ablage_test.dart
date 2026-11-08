import 'dart:convert';
import 'dart:typed_data';

import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/pruefprotokoll.dart';
import 'package:elektralog/core/models/pruefmatrix.dart';
import 'package:elektralog/core/providers/pruefprotokoll_provider.dart';
import 'package:elektralog/features/geraete/geraete_ablage.dart';
import 'package:elektralog/features/pdf/geraete_pdf.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

/// Geräteprotokolle: Unterschrift im PDF, Ablage wie bei der Anlagenprüfung
/// (lokal + Dokumentenablage, offline später nachgeholt).
void main() {
  var n = 0;
  late Database db;
  setUp(() async => db = await databaseFactoryMemory.openDatabase('ablage-${n++}.db'));

  final pdf = Uint8List.fromList(utf8.encode('%PDF-1.4 test'));

  Future<List<Pruefprotokoll>> alle() async => [
        for (final r in await (stringMapStoreFactory.store('pruefprotokolle')).find(db))
          Pruefprotokoll.fromJson(r.value.cast<String, dynamic>()),
      ];

  test('mit Verbindung: abgelegt, lokales PDF verworfen, Art „geraete“', () async {
    String? hochgeladenArt;
    final r = await geraeteProtokollAblegen(db,
        bezugUuid: 'r1',
        titel: 'Geräteübersicht Raum Büro',
        bytes: pdf,
        snapshot: '{}',
        pruefer: 'Kay', upload: (p, bytes) async {
      hochgeladenArt = p.art;
      expect(bytes, pdf);
      return 'backend-1';
    });
    expect(r.lokal.pdfBase64, isNotNull, reason: 'erst lokal, dann Upload');
    final abgelegt = await r.upload;
    expect((hochgeladenArt, abgelegt.backendUuid, abgelegt.pdfBase64), ('geraete', 'backend-1', null));
    expect((await alle()).single.backendUuid, 'backend-1');
  });

  test('ohne Verbindung: bleibt mit PDF ausstehend und wird später hochgeladen', () async {
    final r = await geraeteProtokollAblegen(db,
        bezugUuid: 'g1', titel: 'Prüfprotokoll Lampe', bytes: pdf, snapshot: '{}', upload: (_, __) async => null);
    await r.upload;
    final ausstehend = await PruefprotokollRepository(db).getAusstehende();
    expect(ausstehend.single.art, 'geraete');
    expect(base64Decode(ausstehend.single.pdfBase64!), pdf);

    final fehler = await geraeteProtokollAblegen(db,
        bezugUuid: 'g2', titel: 'X', bytes: pdf, snapshot: '{}', upload: (_, __) => Future.error('kein Netz'));
    expect((await fehler.upload).backendUuid, isNull);
    expect(await PruefprotokollRepository(db).getAusstehende(), hasLength(2));
  });

  test('alte Protokolle ohne Art gelten als Anlagenprotokoll', () {
    final json = Pruefprotokoll(verteilerUuid: 'v', protokollDatum: DateTime(2026)).toJson()..remove('art');
    expect(Pruefprotokoll.fromJson(json).art, 'anlage');
  });

  group('Unterschrift im PDF', () {
    final g =
        Geraet(uuid: 'g', kundeUuid: 'k', standortUuid: 's', raumUuid: 'r', bezeichnung: 'Lampe', schutzklasse: 'II');
    final e = neuerEntwurf(g, prueferName: 'Kay', heute: DateTime(2026, 11, 8));
    final p = abschliessen(
      e.kopie(ergebnis: 'bestanden', intervallMonate: 12, punkte: [
        for (final x in e.punkte)
          x.istMessung ? x.kopie(bewertung: 'na', begruendung: 'Test') : x.kopie(bewertung: 'io'),
      ]),
      geraet: g,
      kunde: 'Kunde',
      standort: 'Werk',
      raum: 'Büro',
    );
    // 1×1-PNG
    final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
    int bilder(Uint8List bytes) => RegExp(r'/Subtype\s*/Image').allMatches(latin1.decode(bytes)).length;

    test('nur wer geprüft hat, unterschreibt das Prüfblatt', () {
      expect(const PdfUnterschrift(name: ' kay ').unterschreibt(p), isTrue);
      expect(const PdfUnterschrift(name: 'Anna').unterschreibt(p), isFalse);
    });

    test('Einzelprotokoll trägt die Unterschrift', () async {
      Future<Uint8List> mit(String name) => einzelProtokollPdf(p, g,
          kopf: const ProtokollKopf(firma: 'F'),
          schriften: PdfSchriften.standard(),
          unterschrift: PdfUnterschrift(name: name, datumOrt: '08.11.2026, Hamburg', bild: png));
      expect(bilder(await mit('Kay')), greaterThan(0));
      expect(bilder(await mit('Anna')), 0, reason: 'fremde Prüfung: Linie bleibt leer');
      expect(
          bilder(await einzelProtokollPdf(p, g, kopf: const ProtokollKopf(), schriften: PdfSchriften.standard())), 0);
    });
  });
}

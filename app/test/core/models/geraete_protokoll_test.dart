import 'dart:convert';

import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/geraete_protokoll.dart';
import 'package:elektralog/core/models/geraete_pruefung.dart';
import 'package:elektralog/core/models/pruefmatrix.dart';
import 'package:elektralog/features/pdf/geraete_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

/// M6 Abnahme: Filtermatrix, Übersicht vor Einzelblättern, inaktive mit
/// Grund und null Prüfblättern, gemischte Prüftage, historische Fassung.
void main() {
  final heute = DateTime(2026, 11, 8);

  Geraet geraet(String id, {bool aktiv = true, String? letzte, String raum = 'r1', String sk = 'I'}) => Geraet(
        uuid: id,
        kundeUuid: 'k',
        standortUuid: 's',
        raumUuid: raum,
        bezeichnung: 'Gerät $id',
        schutzklasse: sk,
        aktiv: aktiv,
        inaktivGrund: aktiv ? null : 'in Reparatur',
        pruefintervallMonate: 12,
        letztePruefungDatum: letzte,
        letztePruefungErsatzwert: letzte == null,
        erstelltAm: DateTime.utc(2025, 1, 1),
      );

  GeraetePruefung pruefung(Geraet g, String datum, {bool bestanden = true}) {
    final e = neuerEntwurf(g, prueferName: 'Kay', heute: DateTime.parse(datum));
    final fertig = e.kopie(
      ergebnis: bestanden ? 'bestanden' : 'nicht_bestanden',
      maengel: bestanden ? null : 'Leitung beschädigt',
      intervallMonate: 12,
      punkte: [
        for (final x in e.punkte)
          x.istMessung ? x.kopie(bewertung: 'na', begruendung: 'Test') : x.kopie(bewertung: bestanden ? 'io' : 'nio', begruendung: 'Befund'),
      ],
    );
    return abschliessen(fertig, geraet: g, kunde: 'Kunde', standort: 'Werk', raum: 'Raum ${g.raumUuid}');
  }

  // A aktiv fristgerecht, B aktiv überfällig (nicht bestanden), C inaktiv fristgerecht,
  // D inaktiv überfällig, E aktiv ohne Prüfung (Ersatzwert → sofort fällig)
  final a = geraet('A', sk: 'I');
  final b = geraet('B', sk: 'II');
  final c = geraet('C', aktiv: false, letzte: '2026-06-01');
  final d = geraet('D', aktiv: false, letzte: '2024-01-01');
  final e = geraet('E');
  final alle = [a, b, c, d, e];
  final pruefungen = {
    'A': [pruefung(a, '2026-10-01')],
    'B': [pruefung(b, '2026-05-15', bestanden: false)],
  };
  final nachweise = pruefNachweise(pruefungen.values.expand((l) => l));

  List<String> filter(ProtokollFilter f, {Set<String> manuell = const {}}) => [
        for (final g in geraeteImFilter(alle, f, nachweise: nachweise, heute: heute, manuell: manuell)) g.uuid,
      ];

  GeraeteProtokollInhalt inhalt(ProtokollFilter f, {Set<String> manuell = const {}}) => protokollInhalt(
        titel: 'Test',
        filter: f,
        geraete: geraeteImFilter(alle, f, nachweise: nachweise, heute: heute, manuell: manuell),
        pruefungenJeGeraet: pruefungen,
        raumNamen: const {'r1': 'Büro', 'r2': 'Lager'},
        heute: heute,
      );

  test('Filtermatrix', () {
    expect(filter(ProtokollFilter.alle), ['A', 'B', 'C', 'D', 'E']);
    expect(filter(ProtokollFilter.aktive), ['A', 'B', 'E']);
    expect(filter(ProtokollFilter.nichtUeberschritten), ['A', 'C'], reason: 'unabhängig vom Aktiv-Status');
    expect(filter(ProtokollFilter.manuell, manuell: {'C', 'E'}), ['C', 'E']);
  });

  test('Übersicht enthält alle im Filter, Prüfblätter nur aktive und tatsächlich geprüfte', () {
    final alleInhalt = inhalt(ProtokollFilter.alle);
    expect(alleInhalt.zeilen.map((z) => z.geraet.uuid), ['B', 'A', 'C', 'D', 'E'], reason: 'durchgefallen zuerst');
    expect(alleInhalt.blaetter.map((x) => x.geraet.uuid), ['B', 'A']);
    final inaktiv = alleInhalt.zeilen.firstWhere((z) => z.geraet.uuid == 'D');
    expect((inaktiv.status, inaktiv.mitProtokoll), ('Inaktiv: in Reparatur', false));

    expect(inhalt(ProtokollFilter.aktive).zeilen.any((z) => !z.geraet.aktiv), isFalse,
        reason: '„nur aktive“ mischt keine inaktiven hinzu');
    expect(inhalt(ProtokollFilter.nichtUeberschritten).blaetter.map((x) => x.geraet.uuid), ['A']);
    expect(inhalt(ProtokollFilter.manuell, manuell: {'C', 'E'}).blaetter, isEmpty, reason: 'C inaktiv, E ungeprüft');
  });

  test('Sammelprotokoll mit verschiedenen echten Prüftagen und Schutzklassen', () {
    final blaetter = inhalt(ProtokollFilter.alle).blaetter;
    expect([for (final x in blaetter) x.pruefung.pruefungDatum], ['2026-05-15', '2026-10-01']);
    expect([for (final x in blaetter) x.pruefung.schutzklasse], ['II', 'I']);
    expect(blaetter.every((x) => x.pruefung.pruefartText.contains('DGUV Vorschrift 3')), isTrue);
  });

  test('Durchgefallene Geräte stehen abgesetzt am Anfang, inaktive nicht', () {
    final i = inhalt(ProtokollFilter.alle);
    expect([for (final z in i.durchgefallen) z.geraet.uuid], ['B']);
    expect([for (final z in i.uebrige) z.geraet.uuid], ['A', 'C', 'D', 'E'], reason: 'sonst Reihenfolge wie gewählt');
    // Inaktives Gerät mit nicht bestandener Prüfung gehört nicht in den Block.
    final raus = b.mitStatus(aktiv: false, grund: 'ausgesondert');
    final j = protokollInhalt(
      titel: 'T',
      filter: ProtokollFilter.alle,
      geraete: [a, raus],
      pruefungenJeGeraet: pruefungen,
      raumNamen: const {},
      heute: heute,
    );
    expect(j.durchgefallen, isEmpty);
  });

  test('Umzug nach der Prüfung ändert die historische Fassung nicht; Korrektur ersetzt', () {
    final umgezogen = a.umgehaengt(kundeUuid: 'k', standortUuid: 's', raumUuid: 'r2');
    final p = pruefungen['A']!.single;
    expect(p.ortSnapshot!['raum']['bezeichnung'], 'Raum r1');
    final neu = protokollInhalt(
      titel: 'T',
      filter: ProtokollFilter.alle,
      geraete: [umgezogen],
      pruefungenJeGeraet: pruefungen,
      raumNamen: const {'r1': 'Büro', 'r2': 'Lager'},
      heute: heute,
    );
    expect(neu.zeilen.single.raum, 'Lager', reason: 'Übersicht zeigt den aktuellen Ort');
    expect(neu.blaetter.single.pruefung.ortSnapshot!['raum']['bezeichnung'], 'Raum r1', reason: 'Prüfblatt den damaligen');

    final korrektur = abschliessen(
      korrekturVon(p).kopie(ergebnis: 'nicht_bestanden', maengel: 'nachgetragen'),
      geraet: a,
      kunde: 'Kunde',
      standort: 'Werk',
      raum: 'Raum r1',
    );
    expect(letzteGueltigePruefung([p, korrektur])!.uuid, korrektur.uuid);
  });

  test('PDF: Übersicht vor den Blättern, gleiche Daten ergeben dieselbe Ausgabe', () async {
    Future<List<int>> pdf() => geraeteProtokollPdf(
          inhalt(ProtokollFilter.alle),
          kopf: const ProtokollKopf(firma: 'Elektro Test', kunde: 'Kunde', standort: 'Werk'),
          schriften: PdfSchriften.standard(),
          erstellt: DateTime(2026, 11, 8),
        );
    final bytes = await pdf();
    final text = latin1.decode(bytes);
    expect(text.startsWith('%PDF'), isTrue);
    final seiten = RegExp(r'/Type\s*/Page[^s]').allMatches(text).length;
    expect(seiten, greaterThanOrEqualTo(3), reason: 'Übersicht + zwei Prüfblätter');
    final formate = [for (final m in RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)').allMatches(text)) double.parse(m[1]!) > double.parse(m[2]!)];
    expect(formate.first, isTrue, reason: 'Übersicht im Querformat');
    expect(formate.skip(1), everyElement(isFalse), reason: 'Prüfblätter im Hochformat');

    final einzel = await einzelProtokollPdf(
      pruefungen['A']!.single,
      a,
      kopf: const ProtokollKopf(firma: 'Elektro Test'),
      schriften: PdfSchriften.standard(),
    );
    expect(latin1.decode(einzel).startsWith('%PDF'), isTrue);
  });
}

import 'dart:convert';

import 'geraet.dart';
import 'geraete_faelligkeit.dart';
import 'geraete_pruefung.dart';

/// Prüfmatrix ortsveränderlicher Geräte (Roadmap Gate 2, Kay 2026-11-08:
/// „Vorschlag, Prüfer entscheidet“).
///
/// Die Grenzwerte sind **Vorschläge** nach DGUV Information 203-070
/// (Ausgabe 2026), Tabelle 1. Die Prüfperson kann sie je Messung ändern
/// (z. B. Leitungslänge, Heizgeräte, Messverfahren). Die App vergleicht
/// Messwert und Grenzwert und zeigt i. O./n. i. O. an; das Gesamtergebnis
/// setzt die Prüfperson, „bestanden“ ist bei einem n. i. O. gesperrt.
/// Keine Aussage zur Normkonformität — fachliche Freigabe der Matrix
/// durch die verantwortliche Elektrofachkraft steht aus (M8).
///
/// Jede Prüfung speichert [regelVersion], damit spätere Änderungen dieser
/// Datei alte Protokolle nicht umdeuten.
const regelVersion = 'ElektraLog-Prüfmatrix v1 (Vorschlag nach DGUV Information 203-070:2026, Tab. 1)';

const pruefarten = {
  'wiederholungspruefung': 'Wiederholungsprüfung',
  'erstpruefung': 'Erstprüfung',
  'nach_instandsetzung': 'Prüfung nach Instandsetzung/Änderung',
};

/// Sichtbare Prüfart auf jedem Protokoll (Praxisbeispiel E-Mail 23.10.2026).
String pruefartText(String pruefart) =>
    'Prüfung nach DGUV Vorschrift 3 für ortsveränderliche elektrische Betriebsmittel — '
    '${pruefarten[pruefart] ?? pruefart}';

const _besichtigen = [
  ('gehaeuse', 'Gehäuse und Schutzabdeckungen unbeschädigt'),
  ('leitung', 'Anschlussleitung und Stecker unbeschädigt'),
  ('zugentlastung', 'Knickschutz und Zugentlastung wirksam'),
  ('kennzeichnung', 'Aufschriften und Kennzeichnung (Schutzklasse) erkennbar'),
  ('gebrauch', 'Keine Anzeichen von Überlastung oder unsachgemäßem Gebrauch'),
];

const _ableitMethoden = ['Direktes Verfahren', 'Differenzstromverfahren', 'Ersatzableitstromverfahren'];

List<Pruefpunkt> _messungen(String? schutzklasse) => switch (schutzklasse) {
      'I' => const [
          Pruefpunkt(
            id: 'rpe',
            schritt: 'messen',
            bezeichnung: 'Schutzleiterwiderstand RPE',
            einheit: 'Ω',
            grenzwert: 0.3,
            vergleich: '<=',
            methoden: ['Messstrom ≥ 200 mA, Leitung bewegt'],
            hinweis: 'Bis 5 m Leitung; je weitere 7,5 m + 0,1 Ω, höchstens 1 Ω',
          ),
          Pruefpunkt(
            id: 'riso',
            schritt: 'messen',
            bezeichnung: 'Isolationswiderstand RISO',
            einheit: 'MΩ',
            grenzwert: 1.0,
            vergleich: '>=',
            methoden: ['500 V DC'],
            hinweis: 'Geräte mit Heizelementen: ≥ 0,3 MΩ',
          ),
          Pruefpunkt(
            id: 'ipe',
            schritt: 'messen',
            bezeichnung: 'Schutzleiterstrom IPE',
            einheit: 'mA',
            grenzwert: 3.5,
            vergleich: '<=',
            methoden: _ableitMethoden,
            hinweis: 'Heizgeräte ≥ 3,5 kW: 1 mA/kW, höchstens 10 mA',
          ),
          Pruefpunkt(
            id: 'ib',
            schritt: 'messen',
            bezeichnung: 'Berührungsstrom IB',
            einheit: 'mA',
            grenzwert: 0.5,
            vergleich: '<=',
            methoden: _ableitMethoden,
            hinweis: 'Nur bei berührbaren leitfähigen Teilen ohne Schutzleiterverbindung, sonst „n. a.“',
          ),
        ],
      'II' => const [
          Pruefpunkt(
            id: 'riso',
            schritt: 'messen',
            bezeichnung: 'Isolationswiderstand RISO',
            einheit: 'MΩ',
            grenzwert: 2.0,
            vergleich: '>=',
            methoden: ['500 V DC'],
          ),
          Pruefpunkt(
            id: 'ib',
            schritt: 'messen',
            bezeichnung: 'Berührungsstrom IB',
            einheit: 'mA',
            grenzwert: 0.5,
            vergleich: '<=',
            methoden: _ableitMethoden,
          ),
        ],
      // Schutzklasse III und „offen“: kein vorgegebener Messablauf —
      // Sonderfall erst nach fachlicher Freigabe (Roadmap M5).
      _ => const [],
    };

/// Vorlage für eine neue Prüfung je Schutzklasse.
List<Pruefpunkt> pruefpunkteVorlage(String? schutzklasse) => [
      for (final (id, text) in _besichtigen) Pruefpunkt(id: id, schritt: 'besichtigen', bezeichnung: text),
      ..._messungen(schutzklasse),
      const Pruefpunkt(id: 'funktion', schritt: 'erproben', bezeichnung: 'Funktionsprüfung / Erproben'),
    ];

/// Schutzklasse wechseln: Messpunkte neu, Besichtigen/Erproben behalten.
List<Pruefpunkt> mitSchutzklasse(List<Pruefpunkt> punkte, String? schutzklasse) => [
      for (final p in punkte)
        if (!p.istMessung) p,
    ]..insertAll(_besichtigen.length, _messungen(schutzklasse));

/// i. O./n. i. O. aus Messwert und Grenzwert, `null` ohne Wert.
String? messBewertung(double? messwert, double? grenzwert, String? vergleich) {
  if (messwert == null || grenzwert == null) return null;
  return switch (vergleich) {
    '<=' => messwert <= grenzwert ? 'io' : 'nio',
    '>=' => messwert >= grenzwert ? 'io' : 'nio',
    _ => null,
  };
}

/// Neuer Entwurf für [geraet].
GeraetePruefung neuerEntwurf(
  Geraet geraet, {
  String pruefart = 'wiederholungspruefung',
  String? prueferName,
  String? messgeraet,
  DateTime? heute,
}) =>
    GeraetePruefung(
      geraetUuid: geraet.uuid,
      pruefart: pruefart,
      pruefartText: pruefartText(pruefart),
      pruefungDatum: tagAlsText(heute ?? DateTime.now()),
      prueferName: prueferName,
      messgeraet: messgeraet,
      regelVersion: regelVersion,
      schutzklasse: geraet.schutzklasse,
      punkte: pruefpunkteVorlage(geraet.schutzklasse),
      intervallMonate: geraet.pruefintervallMonate,
    );

/// Korrektur einer abgeschlossenen Prüfung: neuer Entwurf mit denselben
/// Werten und Verweis auf die ersetzte Prüfung.
GeraetePruefung korrekturVon(GeraetePruefung alt) => GeraetePruefung(
      geraetUuid: alt.geraetUuid,
      pruefart: alt.pruefart,
      pruefartText: alt.pruefartText,
      anlass: 'Korrektur der Prüfung vom ${alt.pruefungDatum}',
      pruefungDatum: alt.pruefungDatum,
      prueferName: alt.prueferName,
      messgeraet: alt.messgeraet,
      regelVersion: alt.regelVersion,
      schutzklasse: alt.schutzklasse,
      punkte: alt.punkte,
      maengel: alt.maengel,
      bemerkung: alt.bemerkung,
      intervallMonate: alt.intervallMonate,
      ersetztUuid: alt.uuid,
    );

/// Was einem Abschluss noch im Weg steht. Leer = abschließbar.
List<String> abschlussFehler(GeraetePruefung p) => [
      if ((p.prueferName ?? '').trim().isEmpty) 'Prüfer fehlt',
      if (p.schutzklasse == null) 'Schutzklasse vor der Prüfung feststellen',
      for (final punkt in p.punkte)
        if (punkt.bewertung == null)
          'Offen: ${punkt.bezeichnung}'
        else if ((punkt.bewertung == 'na' || punkt.bewertung == 'nio') && (punkt.begruendung ?? '').trim().isEmpty)
          'Begründung fehlt: ${punkt.bezeichnung}'
        else if (punkt.istMessung && punkt.bewertung != 'na' && punkt.messwert == null)
          'Messwert fehlt: ${punkt.bezeichnung}',
      if (p.ergebnis == null) 'Gesamtergebnis wählen',
      if (p.ergebnis == 'bestanden' && p.punkte.any((x) => x.bewertung == 'nio'))
        'Bestanden ist nicht möglich: mindestens ein Punkt nicht in Ordnung',
      if (p.ergebnis == 'nicht_bestanden' && (p.maengel ?? '').trim().isEmpty) 'Mängel beschreiben',
      if (p.ergebnis == 'bestanden' && p.intervallMonate == null) 'Prüfintervall festlegen',
    ];

/// „Bestanden“ wählbar? (kein Punkt n. i. O.)
bool bestandenMoeglich(GeraetePruefung p) => !p.punkte.any((x) => x.bewertung == 'nio');

/// Abschluss: nächste Prüfung nur bei bestanden, Ort und Stammdaten als
/// Snapshot (späterer Umzug ändert das Protokoll nicht).
GeraetePruefung abschliessen(
  GeraetePruefung p, {
  required Geraet geraet,
  required String kunde,
  required String standort,
  required String raum,
  DateTime? jetzt,
}) {
  final fehler = abschlussFehler(p);
  if (fehler.isNotEmpty) throw StateError(fehler.join(', '));
  final stamm = geraet.toJson()..remove('statusHistorieJson');
  return p.kopie(
    status: 'abgeschlossen',
    naechstePruefung: p.bestanden ? tagAlsText(plusMonate(p.datum, p.intervallMonate!)) : null,
    ortSnapshotJson: jsonEncode({
      'kunde': {'uuid': geraet.kundeUuid, 'name': kunde},
      'standort': {'uuid': geraet.standortUuid, 'bezeichnung': standort},
      'raum': {'uuid': geraet.raumUuid, 'bezeichnung': raum},
      'geraet': stamm,
    }),
    abgeschlossenAm: (jetzt ?? DateTime.now()).toUtc(),
  );
}

/// Letzte gültige abgeschlossene Prüfung je Gerät (ersetzte zählen nicht).
Map<String, PruefNachweis> pruefNachweise(Iterable<GeraetePruefung> pruefungen) {
  final abgeschlossen = [for (final p in pruefungen) if (p.abgeschlossen) p];
  final ersetzt = {for (final p in abgeschlossen) if (p.ersetztUuid != null) p.ersetztUuid!};
  final letzte = <String, GeraetePruefung>{};
  for (final p in abgeschlossen) {
    if (ersetzt.contains(p.uuid)) continue;
    final bisher = letzte[p.geraetUuid];
    if (bisher == null ||
        p.datum.isAfter(bisher.datum) ||
        (p.datum == bisher.datum &&
            (p.abgeschlossenAm ?? p.erstelltAm).isAfter(bisher.abgeschlossenAm ?? bisher.erstelltAm))) {
      letzte[p.geraetUuid] = p;
    }
  }
  return {for (final e in letzte.entries) e.key: PruefNachweis(datum: e.value.datum, bestanden: e.value.bestanden)};
}

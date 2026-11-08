import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/geraete_pruefung.dart';
import 'package:elektralog/core/models/pruefmatrix.dart';
import 'package:flutter_test/flutter_test.dart';

/// M5: Prüfmatrix (Vorschlag) — klassenspezifische Messpunkte, Bewertung,
/// Abschlussregeln, Nachweis für die Fälligkeit.
void main() {
  final geraet = Geraet(uuid: 'g', kundeUuid: 'k', standortUuid: 's', raumUuid: 'r', bezeichnung: 'G', schutzklasse: 'I');

  List<String> ids(List<Pruefpunkt> p, String schritt) => [for (final x in p) if (x.schritt == schritt) x.id];

  test('Schutzklasse I und II haben fachlich unterschiedliche Messpunkte, III keinen Vorgabeablauf', () {
    expect(ids(pruefpunkteVorlage('I'), 'messen'), ['rpe', 'riso', 'ipe', 'ib']);
    expect(ids(pruefpunkteVorlage('II'), 'messen'), ['riso', 'ib'], reason: 'kein Schutzleiter bei II');
    expect(ids(pruefpunkteVorlage('III'), 'messen'), isEmpty);
    final riso1 = pruefpunkteVorlage('I').firstWhere((p) => p.id == 'riso');
    final riso2 = pruefpunkteVorlage('II').firstWhere((p) => p.id == 'riso');
    expect((riso1.grenzwert, riso2.grenzwert, riso1.einheit), (1.0, 2.0, 'MΩ'));
    for (final sk in ['I', 'II', 'III']) {
      expect(ids(pruefpunkteVorlage(sk), 'besichtigen'), hasLength(5));
      expect(ids(pruefpunkteVorlage(sk), 'erproben'), ['funktion']);
    }
  });

  test('Schutzklassenwechsel behält Besichtigen/Erproben, tauscht Messungen', () {
    final p = pruefpunkteVorlage('I').map((x) => x.istMessung ? x : x.kopie(bewertung: 'io')).toList();
    final neu = mitSchutzklasse(p, 'II');
    expect(ids(neu, 'messen'), ['riso', 'ib']);
    expect(neu.where((x) => !x.istMessung).every((x) => x.bewertung == 'io'), isTrue);
    expect(neu.indexWhere((x) => x.istMessung), 5, reason: 'Reihenfolge Besichtigen → Messen → Erproben');
  });

  test('Messbewertung: Höchst- und Mindestwerte inklusive Grenze', () {
    expect(messBewertung(0.3, 0.3, '<='), 'io');
    expect(messBewertung(0.31, 0.3, '<='), 'nio');
    expect(messBewertung(2.0, 2.0, '>='), 'io');
    expect(messBewertung(1.99, 2.0, '>='), 'nio');
    expect(messBewertung(null, 2.0, '>='), isNull);
  });

  GeraetePruefung vollstaendig({String ergebnis = 'bestanden', String ibBewertung = 'io'}) {
    final entwurf = neuerEntwurf(geraet, prueferName: 'Kay', heute: DateTime(2026, 11, 8));
    return entwurf.kopie(
      ergebnis: ergebnis,
      intervallMonate: 12,
      maengel: ergebnis == 'nicht_bestanden' ? 'IB zu hoch' : null,
      punkte: [
        for (final x in entwurf.punkte)
          x.istMessung
              ? x.id == 'ib'
                  ? x.kopie(bewertung: ibBewertung, begruendung: ibBewertung == 'na' ? 'keine berührbaren Teile' : 'zu hoch', messwert: ibBewertung == 'na' ? null : 0.6)
                  : x.kopie(messwert: x.vergleich == '<=' ? 0.1 : 50, bewertung: 'io')
              : x.kopie(bewertung: 'io'),
      ],
    );
  }

  test('Abschlussregeln: offene Punkte, fehlende Begründung/Messwerte, bestanden trotz n. i. O.', () {
    final entwurf = neuerEntwurf(geraet, prueferName: 'Kay');
    expect(abschlussFehler(entwurf), contains('Gesamtergebnis wählen'));
    expect(abschlussFehler(entwurf).where((f) => f.startsWith('Offen:')), hasLength(10));
    expect(abschlussFehler(vollstaendig(ibBewertung: 'na')), isEmpty);

    final nio = vollstaendig(ibBewertung: 'nio');
    expect(bestandenMoeglich(nio), isFalse);
    expect(abschlussFehler(nio), contains('Bestanden ist nicht möglich: mindestens ein Punkt nicht in Ordnung'));
    expect(abschlussFehler(vollstaendig(ergebnis: 'nicht_bestanden', ibBewertung: 'nio')), isEmpty);

    final ohneBegruendung = vollstaendig(ibBewertung: 'na');
    final kaputt = ohneBegruendung.kopie(punkte: [
      for (final x in ohneBegruendung.punkte) x.id == 'ib' ? x.kopie(begruendung: ' ') : x,
    ]);
    expect(abschlussFehler(kaputt), contains('Begründung fehlt: Berührungsstrom IB'));
    expect(abschlussFehler(vollstaendig().kopie(prueferName: ' ')), contains('Prüfer fehlt'));
  });

  test('Abschluss: nächste Prüfung nur bei bestanden, Ort-Snapshot, nicht bestanden ohne Verlängerung', () {
    final ok = abschliessen(vollstaendig(ibBewertung: 'na'), geraet: geraet, kunde: 'K', standort: 'S', raum: 'R');
    expect((ok.status, ok.naechstePruefung), ('abgeschlossen', '2027-11-08'));
    expect(ok.ortSnapshot!['raum'], {'uuid': 'r', 'bezeichnung': 'R'});
    final nein = abschliessen(vollstaendig(ergebnis: 'nicht_bestanden', ibBewertung: 'nio'), geraet: geraet, kunde: 'K', standort: 'S', raum: 'R');
    expect(nein.naechstePruefung, isNull);
    expect(() => abschliessen(neuerEntwurf(geraet), geraet: geraet, kunde: '', standort: '', raum: ''), throwsStateError);
    expect(GeraetePruefung.fromJson(ok.toJson()).toJson(), ok.toJson());
  });

  test('Nachweis: jüngste gültige Prüfung, ersetzte zählen nicht, Entwürfe nie', () {
    final alt = abschliessen(vollstaendig(ibBewertung: 'na'), geraet: geraet, kunde: 'K', standort: 'S', raum: 'R');
    final entwurf = neuerEntwurf(geraet, heute: DateTime(2027, 1, 1));
    expect(pruefNachweise([alt, entwurf])['g']!.bestanden, isTrue);

    final korrektur = korrekturVon(alt);
    expect((korrektur.ersetztUuid, korrektur.status, korrektur.pruefungDatum), (alt.uuid, 'entwurf', alt.pruefungDatum));
    final korrigiert = abschliessen(
      korrektur.kopie(ergebnis: 'nicht_bestanden', maengel: 'nachträglich Mangel festgestellt'),
      geraet: geraet,
      kunde: 'K',
      standort: 'S',
      raum: 'R',
    );
    final n = pruefNachweise([alt, korrigiert])['g']!;
    expect((n.bestanden, n.datum), (false, DateTime.utc(2026, 11, 8)));
    expect(pruefNachweise([entwurf]), isEmpty);
  });

  test('Prüfart ist auf jeder Prüfung sichtbar benannt, Regelversion gespeichert', () {
    final p = neuerEntwurf(geraet, pruefart: 'nach_instandsetzung');
    expect(p.pruefartText, contains('DGUV Vorschrift 3'));
    expect(p.pruefartText, contains('Instandsetzung'));
    expect(p.regelVersion, regelVersion);
  });
}

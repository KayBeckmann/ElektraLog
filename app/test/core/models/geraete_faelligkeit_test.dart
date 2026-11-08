import 'package:elektralog/core/models/geraet.dart';
import 'package:elektralog/core/models/geraete_faelligkeit.dart';
import 'package:flutter_test/flutter_test.dart';

/// M4: Fälligkeit der Geräteprüfung — Kalendermonate, Grenzwerte des
/// Intervalls, Ersatzdatum, Aktiv/Inaktiv, 90-Tage-Fenster.
void main() {
  DateTime d(int y, int m, int t) => DateTime.utc(y, m, t);

  group('Kalendermonate', () {
    final faelle = <(DateTime, int, DateTime)>[
      (d(2026, 1, 31), 1, d(2026, 2, 28)),
      (d(2028, 1, 31), 1, d(2028, 2, 29)), // Schaltjahr
      (d(2026, 8, 31), 6, d(2027, 2, 28)),
      (d(2027, 11, 30), 3, d(2028, 2, 29)),
      (d(2028, 2, 29), 12, d(2029, 2, 28)),
      (d(2028, 2, 29), 24, d(2030, 2, 28)),
      (d(2026, 3, 31), 6, d(2026, 9, 30)),
      (d(2026, 11, 8), 3, d(2027, 2, 8)),
      (d(2026, 12, 15), 12, d(2027, 12, 15)),
      (d(2026, 5, 31), 23, d(2028, 4, 30)),
    ];
    for (final (start, monate, erwartet) in faelle) {
      test('$start + $monate Monate = $erwartet', () => expect(plusMonate(start, monate), erwartet));
    }
  });

  test('Intervall: Vorauswahl genau 3/6/12/24, frei nur ganze Zahlen > 0 und < 24', () {
    expect(intervallVorauswahl, [3, 6, 12, 24]);
    for (final ok in ['1', '7', '23', ' 5 ']) {
      expect(pruefeFreiesIntervall(ok), isNull, reason: ok);
    }
    for (final nein in ['', '0', '-1', '24', '25', '1.5', '1,5', 'zwölf']) {
      expect(pruefeFreiesIntervall(nein), isNotNull, reason: nein);
    }
  });

  group('Fälligkeit', () {
    final heute = d(2026, 11, 8);
    Geraet g({int? intervall = 12, String? letzte, bool ersatz = false, bool aktiv = true}) => Geraet(
          kundeUuid: 'k',
          standortUuid: 's',
          raumUuid: 'r',
          bezeichnung: 'G',
          pruefintervallMonate: intervall,
          letztePruefungDatum: letzte,
          letztePruefungErsatzwert: ersatz,
          aktiv: aktiv,
          inaktivGrund: aktiv ? null : 'defekt',
          erstelltAm: DateTime.utc(2026, 10, 1, 9),
        );

    test('Ohne Nachweis (Ersatzwert): sofort fällig, als solcher erkennbar', () {
      final t = geraetTermin(g(letzte: '2026-10-01', ersatz: true), heute: heute);
      expect(t.status, GeraetTerminStatus.ueberfaellig);
      expect(t.faelligAm, d(2026, 10, 1));
      expect(t.ohneNachweis, isTrue);
      expect(t.hinweis, 'Noch keine nachgewiesene Prüfung');

      final heuteAngelegt = geraetTermin(g(letzte: '2026-11-08', ersatz: true), heute: heute);
      expect(heuteAngelegt.status, GeraetTerminStatus.faellig);
    });

    test('Angegebene Vorprüfung + Intervall', () {
      final t = geraetTermin(g(letzte: '2026-03-31', intervall: 12), heute: heute);
      expect((t.status, t.faelligAm, t.ohneNachweis), (GeraetTerminStatus.imPlan, d(2027, 3, 31), false));
    });

    test('Echte Prüfung schlägt ältere Angabe; nicht bestanden → sofort fällig', () {
      final geraet = g(letzte: '2025-01-01', intervall: 6);
      final bestanden = geraetTermin(geraet, letztePruefung: PruefNachweis(datum: d(2026, 9, 1), bestanden: true), heute: heute);
      expect(bestanden.faelligAm, d(2027, 3, 1));
      final nicht = geraetTermin(geraet, letztePruefung: PruefNachweis(datum: d(2026, 9, 1), bestanden: false), heute: heute);
      expect((nicht.status, nicht.faelligAm, nicht.hinweis), (GeraetTerminStatus.ueberfaellig, d(2026, 9, 1), 'Letzte Prüfung nicht bestanden'));
    });

    test('Ohne Intervall nach echter Prüfung: fällig mit Hinweis', () {
      final t = geraetTermin(g(intervall: null), letztePruefung: PruefNachweis(datum: d(2026, 11, 1), bestanden: true), heute: heute);
      expect((t.status, t.hinweis), (GeraetTerminStatus.ueberfaellig, 'Prüfintervall nicht festgelegt'));
    });

    test('Inaktiv: kein Termin; Reaktivierung mit überschrittenem Termin sofort überfällig', () {
      final alt = g(letzte: '2024-01-15', intervall: 12, aktiv: false);
      expect(geraetTermin(alt, heute: heute).status, GeraetTerminStatus.inaktiv);
      expect(geraetTermin(alt, heute: heute).inListe, isFalse);
      final wieder = alt.mitStatus(aktiv: true);
      final t = geraetTermin(wieder, heute: heute);
      expect((t.status, t.faelligAm), (GeraetTerminStatus.ueberfaellig, d(2025, 1, 15)));
    });

    test('90-Tage-Fenster: heute+90 enthalten, +91 nicht, gestern überfällig', () {
      // 2026-11-08 + 90 Tage = 2027-02-06
      expect(geraetTermin(g(letzte: '2026-02-06', intervall: 12), heute: heute).status, GeraetTerminStatus.faellig);
      expect(geraetTermin(g(letzte: '2026-02-07', intervall: 12), heute: heute).status, GeraetTerminStatus.imPlan);
      expect(geraetTermin(g(letzte: '2025-11-07', intervall: 12), heute: heute).status, GeraetTerminStatus.ueberfaellig);
      expect(geraetTermin(g(letzte: '2025-11-08', intervall: 12), heute: heute).status, GeraetTerminStatus.faellig);
    });

    test('Uhrzeit/Zeitzone des Stichtags spielt keine Rolle', () {
      final geraet = g(letzte: '2025-11-08', intervall: 12);
      for (final stichtag in [DateTime(2026, 11, 8, 0, 1), DateTime(2026, 11, 8, 23, 59), DateTime.utc(2026, 11, 8, 23, 59)]) {
        expect(geraetTermin(geraet, heute: stichtag).status, GeraetTerminStatus.faellig, reason: '$stichtag');
      }
    });

    test('Intervallwechsel wird mit Begründung im Verlauf festgehalten', () {
      final geraet = g(intervall: null).mitIntervall(6, begruendung: 'Baustelle', benutzer: 'Kay');
      expect(geraet.pruefintervallMonate, 6);
      final e = geraet.verlauf.single;
      expect((e.art, e.intervall, e.begruendung, e.benutzer), ('intervall', 6, 'Baustelle', 'Kay'));
      expect(identical(geraet.mitIntervall(6, begruendung: 'Baustelle'), geraet), isTrue, reason: 'ohne Änderung kein Eintrag');
      expect(geraet.mitIntervall(12, begruendung: 'Büro').verlauf, hasLength(2));
    });

    test('Verläufe zweier Fassungen werden ohne Verlust vereinigt', () {
      final basis = g();
      final a = basis.mitStatus(aktiv: false, grund: 'defekt', zeit: DateTime.utc(2026, 11, 1));
      final b = basis.mitIntervall(6, zeit: DateTime.utc(2026, 11, 2));
      final v = Geraet.fromJson({...a.toJson(), 'statusHistorieJson': verlaufVereinigen(a.statusHistorieJson, b.statusHistorieJson)});
      expect([for (final e in v.verlauf) e.art], ['status', 'intervall']);
      expect(verlaufVereinigen(a.statusHistorieJson, a.statusHistorieJson), a.statusHistorieJson);
    });
  });
}

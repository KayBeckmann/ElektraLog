import 'geraet.dart';

/// Fälligkeit der Geräteprüfung (Roadmap M4, Gate 3 — Kay 2026-11-08):
///
/// - Intervall in **ganzen Monaten**: Vorauswahl 3/6/12/24, frei 1–23.
/// - Nächste Prüfung = Basisdatum + n Kalendermonate; gibt es den Tag im
///   Zielmonat nicht, gilt der Monatsletzte (31.01. + 1 → 28./29.02.).
/// - Basis ist die letzte echte Prüfung (bestanden) oder ein angegebenes
///   Datum vor ElektraLog. Ohne Nachweis (nur Ersatzwert = Erstellungs-
///   datum) ist das Gerät **sofort** fällig.
/// - Nicht bestanden → sofort fällig, keine Verlängerung.
/// - Inaktive Geräte erscheinen in keiner Terminliste.
/// - Rechnung nur mit Kalendertagen (ohne Uhrzeit/Zeitzone), Stichtag
///   „heute“ wird übergeben → reproduzierbar.
const intervallVorauswahl = [3, 6, 12, 24];

/// Prüft die freie Intervall-Eingabe. `null` = gültig.
String? pruefeFreiesIntervall(String eingabe) {
  final s = eingabe.trim();
  if (s.isEmpty) return 'Intervall eingeben';
  final n = int.tryParse(s);
  if (n == null) return 'Nur ganze Monate';
  if (n <= 0) return 'Mindestens 1 Monat';
  if (n >= 24) return 'Frei nur unter 24 Monaten — 24 über die Vorauswahl';
  return null;
}

DateTime kalendertag(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// [tag] + [monate] Kalendermonate, am Monatsende gekappt.
DateTime plusMonate(DateTime tag, int monate) {
  final index = tag.month - 1 + monate;
  final jahr = tag.year + (index ~/ 12);
  final monat = index % 12 + 1;
  final letzter = DateTime.utc(jahr, monat + 1, 0).day;
  return DateTime.utc(jahr, monat, tag.day < letzter ? tag.day : letzter);
}

/// Letzte abgeschlossene Prüfung eines Geräts in ElektraLog.
class PruefNachweis {
  const PruefNachweis({required this.datum, required this.bestanden});
  final DateTime datum;
  final bool bestanden;
}

enum GeraetTerminStatus { inaktiv, ueberfaellig, faellig, imPlan }

class GeraetTermin {
  const GeraetTermin({required this.status, this.faelligAm, this.hinweis, this.ohneNachweis = false});

  final GeraetTerminStatus status;
  final DateTime? faelligAm;

  /// Warum sofort fällig (z. B. „Noch keine nachgewiesene Prüfung“).
  final String? hinweis;

  /// Es gibt keine belegte Prüfung — nur den Ersatzwert.
  final bool ohneNachweis;

  bool get inListe => status == GeraetTerminStatus.ueberfaellig || status == GeraetTerminStatus.faellig;
}

const terminFensterTage = 90;

GeraetTermin geraetTermin(Geraet g, {PruefNachweis? letztePruefung, required DateTime heute}) {
  final stichtag = kalendertag(heute);
  if (!g.aktiv) return const GeraetTermin(status: GeraetTerminStatus.inaktiv);

  DateTime faellig;
  String? hinweis;
  var ohneNachweis = false;

  final echte = letztePruefung;
  final angegeben =
      g.letztePruefungDatum != null && !g.letztePruefungErsatzwert ? textAlsTag(g.letztePruefungDatum!) : null;
  // Die jüngere belegte Angabe zählt.
  final basis = echte != null && (angegeben == null || !kalendertag(echte.datum).isBefore(angegeben))
      ? (datum: kalendertag(echte.datum), bestanden: echte.bestanden)
      : angegeben != null
          ? (datum: angegeben, bestanden: true)
          : null;

  if (basis == null) {
    faellig = g.letztePruefungDatum != null ? textAlsTag(g.letztePruefungDatum!) : kalendertag(g.erstelltAm.toLocal());
    hinweis = 'Noch keine nachgewiesene Prüfung';
    ohneNachweis = true;
  } else if (!basis.bestanden) {
    faellig = basis.datum;
    hinweis = 'Letzte Prüfung nicht bestanden';
  } else if (g.pruefintervallMonate == null) {
    faellig = basis.datum;
    hinweis = 'Prüfintervall nicht festgelegt';
  } else {
    faellig = plusMonate(basis.datum, g.pruefintervallMonate!);
  }

  final status = faellig.isBefore(stichtag)
      ? GeraetTerminStatus.ueberfaellig
      : !faellig.isAfter(stichtag.add(const Duration(days: terminFensterTage)))
          ? GeraetTerminStatus.faellig
          : GeraetTerminStatus.imPlan;
  return GeraetTermin(status: status, faelligAm: faellig, hinweis: hinweis, ohneNachweis: ohneNachweis);
}

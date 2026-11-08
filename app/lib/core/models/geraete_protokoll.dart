import 'geraet.dart';
import 'geraete_faelligkeit.dart';
import 'geraete_pruefung.dart';
import 'pruefmatrix.dart';

/// Geräteübersicht und Protokolle (Roadmap M6), getrennt in Auswahl
/// (Filter) und Inhalt — das PDF stellt nur noch dar, was hier entschieden
/// wird. Rein funktional, damit die Filtermatrix testbar ist.

enum ProtokollUmfang { geraet, raum, standort }

enum ProtokollFilter {
  alle('Alle Geräte'),
  aktive('Nur aktive Geräte'),
  nichtUeberschritten('Prüftermin noch nicht überschritten'),
  manuell('Manuelle Auswahl');

  const ProtokollFilter(this.bezeichnung);
  final String bezeichnung;
}

/// Fälligkeitsdatum unabhängig vom Nutzungsstatus — der Filter „Prüftermin
/// nicht überschritten“ gilt auch für inaktive Geräte.
DateTime? faelligAmOhneStatus(Geraet g, PruefNachweis? nachweis, DateTime heute) =>
    geraetTermin(Geraet.fromJson({...g.toJson(), 'aktiv': true, 'inaktivGrund': null}),
            letztePruefung: nachweis, heute: heute)
        .faelligAm;

/// Geräte im Umfang nach Filter. Bei [ProtokollFilter.manuell] genau die
/// [manuell] gewählten — inaktive werden nicht zusätzlich hineingemischt.
List<Geraet> geraeteImFilter(
  List<Geraet> imUmfang,
  ProtokollFilter filter, {
  required Map<String, PruefNachweis> nachweise,
  required DateTime heute,
  Set<String> manuell = const {},
}) {
  final stichtag = kalendertag(heute);
  return [
    for (final g in imUmfang)
      if (switch (filter) {
        ProtokollFilter.alle => true,
        ProtokollFilter.aktive => g.aktiv,
        ProtokollFilter.nichtUeberschritten =>
          !(faelligAmOhneStatus(g, nachweise[g.uuid], heute)?.isBefore(stichtag) ?? true),
        ProtokollFilter.manuell => manuell.contains(g.uuid),
      })
        g,
  ];
}

/// Eine Zeile der Geräteübersicht.
class UebersichtZeile {
  const UebersichtZeile({
    required this.geraet,
    required this.raum,
    required this.status,
    this.letztePruefung,
    this.naechstePruefung,
    required this.mitProtokoll,
  });

  final Geraet geraet;
  final String raum;

  /// „Aktiv“, „Inaktiv: <Grund>“
  final String status;
  final GeraetePruefung? letztePruefung;
  final DateTime? naechstePruefung;

  /// Bekommt ein eigenes Prüfblatt (aktiv + tatsächlich geprüft).
  final bool mitProtokoll;

  /// Aktives Gerät, dessen letzte gültige Prüfung nicht bestanden ist —
  /// steht in der Übersicht abgesetzt ganz oben.
  bool get durchgefallen => geraet.aktiv && letztePruefung != null && !letztePruefung!.bestanden;
}

class GeraeteProtokollInhalt {
  const GeraeteProtokollInhalt(
      {required this.titel, required this.filter, required this.zeilen, required this.blaetter});

  final String titel;
  final ProtokollFilter filter;

  /// Übersicht aller Geräte im Filter — immer zuerst; durchgefallene
  /// Geräte stehen am Anfang (Reihenfolge sonst wie gewählt).
  final List<UebersichtZeile> zeilen;

  List<UebersichtZeile> get durchgefallen => [for (final z in zeilen) if (z.durchgefallen) z];
  List<UebersichtZeile> get uebrige => [for (final z in zeilen) if (!z.durchgefallen) z];

  /// Prüfblätter: je aktivem, tatsächlich geprüftem Gerät dessen letzte
  /// gültige abgeschlossene Prüfung (echte Prüftage, kein gemeinsames Datum).
  final List<({Geraet geraet, GeraetePruefung pruefung})> blaetter;
}

GeraeteProtokollInhalt protokollInhalt({
  required String titel,
  required ProtokollFilter filter,
  required List<Geraet> geraete,
  required Map<String, List<GeraetePruefung>> pruefungenJeGeraet,
  required Map<String, String> raumNamen,
  required DateTime heute,
}) {
  final zeilen = <UebersichtZeile>[];
  final blaetter = <({Geraet geraet, GeraetePruefung pruefung})>[];
  for (final g in geraete) {
    final letzte = letzteGueltigePruefung(pruefungenJeGeraet[g.uuid] ?? const []);
    final mitProtokoll = g.aktiv && letzte != null;
    final nachweis = letzte == null ? null : PruefNachweis(datum: letzte.datum, bestanden: letzte.bestanden);
    zeilen.add(UebersichtZeile(
      geraet: g,
      raum: raumNamen[g.raumUuid] ?? '?',
      status: g.aktiv ? 'Aktiv' : 'Inaktiv: ${g.inaktivGrund ?? ''}',
      letztePruefung: letzte,
      naechstePruefung: g.aktiv ? geraetTermin(g, letztePruefung: nachweis, heute: heute).faelligAm : null,
      mitProtokoll: mitProtokoll,
    ));
  }
  // Durchgefallene zuerst — in der Übersicht und bei den Prüfblättern.
  final sortiert = [...zeilen.where((z) => z.durchgefallen), ...zeilen.where((z) => !z.durchgefallen)];
  for (final z in sortiert) {
    if (z.mitProtokoll) blaetter.add((geraet: z.geraet, pruefung: z.letztePruefung!));
  }
  return GeraeteProtokollInhalt(titel: titel, filter: filter, zeilen: sortiert, blaetter: blaetter);
}

/// Bewertung lesbar für Übersicht und Protokoll.
String bewertungText(String? b) => switch (b) {
      'io' => 'i. O.',
      'nio' => 'n. i. O.',
      'na' => 'n. a.',
      _ => 'offen',
    };

/// Prüfart-Kurzname für die Übersicht.
String pruefartKurz(GeraetePruefung p) => pruefarten[p.pruefart] ?? p.pruefart;

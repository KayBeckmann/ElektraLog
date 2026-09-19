import 'dart:convert';

import 'pruefprotokoll.dart';

/// Der Status, der in der Verteilerübersicht aus dem neuesten Prüfprotokoll
/// angezeigt wird.
enum VerteilerPruefstatus {
  unbekannt,
  bestanden,
  nichtBestanden,
  faellig,
}

/// Abgeleiteter, rein lokaler Anzeigestatus für einen Verteiler.
///
/// Die Quelle bleibt das unveränderliche [Pruefprotokoll]. Für Altprotokolle
/// ohne Snapshot wird kein Prüfergebnis erfunden.
class VerteilerPruefstatusInfo {
  const VerteilerPruefstatusInfo({
    required this.status,
    this.letztePruefung,
    this.naechstePruefung,
  });

  final VerteilerPruefstatus status;
  final DateTime? letztePruefung;
  final DateTime? naechstePruefung;

  static VerteilerPruefstatusInfo ausLetztemProtokoll(
    Pruefprotokoll? protokoll, {
    required int pruefintervallJahre,
    DateTime? jetzt,
  }) {
    if (protokoll == null) {
      return const VerteilerPruefstatusInfo(
        status: VerteilerPruefstatus.unbekannt,
      );
    }

    final letztePruefung = protokoll.protokollDatum;
    final naechstePruefung = DateTime(
      letztePruefung.year + pruefintervallJahre,
      letztePruefung.month,
      letztePruefung.day,
    );
    final heute = jetzt ?? DateTime.now();
    final faelligkeitsGrenze = heute.add(const Duration(days: 90));

    if (!naechstePruefung.isAfter(faelligkeitsGrenze)) {
      return VerteilerPruefstatusInfo(
        status: VerteilerPruefstatus.faellig,
        letztePruefung: letztePruefung,
        naechstePruefung: naechstePruefung,
      );
    }

    final ergebnis = _protokollErgebnis(protokoll.messdatenSnapshot);
    return VerteilerPruefstatusInfo(
      status: switch (ergebnis) {
        _ProtokollErgebnis.bestanden => VerteilerPruefstatus.bestanden,
        _ProtokollErgebnis.nichtBestanden =>
          VerteilerPruefstatus.nichtBestanden,
        null => VerteilerPruefstatus.unbekannt,
      },
      letztePruefung: letztePruefung,
      naechstePruefung: naechstePruefung,
    );
  }

  static _ProtokollErgebnis? _protokollErgebnis(String? snapshotJson) {
    if (snapshotJson == null || snapshotJson.isEmpty) return null;
    try {
      final snapshot = jsonDecode(snapshotJson) as Map<String, dynamic>;
      final ergebnisse = <String>[
        if (snapshot['sichtpruefung']
            case final Map<String, dynamic> sichtpruefung)
          if (sichtpruefung['ergebnis'] case final String ergebnis) ergebnis,
        for (final komponente
            in snapshot['komponenten'] as List<dynamic>? ?? const [])
          if (komponente is Map<String, dynamic>)
            for (final messung
                in komponente['messungen'] as List<dynamic>? ?? const [])
              if (messung is Map<String, dynamic>)
                if (messung['ergebnis'] case final String ergebnis) ergebnis,
      ];
      if (ergebnisse
          .any((e) => e == 'nicht_bestanden' || e == 'mit_maengeln')) {
        return _ProtokollErgebnis.nichtBestanden;
      }
      if (ergebnisse.any((e) => e == 'bestanden')) {
        return _ProtokollErgebnis.bestanden;
      }
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}

enum _ProtokollErgebnis { bestanden, nichtBestanden }

import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'geraet.dart';

/// Ein Prüfpunkt eines Prüfereignisses (Besichtigen, Messen, Erproben).
/// Rohwert, Einheit, Grenzwert, Vergleich, Methode, Bewertung und
/// Begründung bleiben getrennt — nichts wird in ein Textfeld gepresst.
class Pruefpunkt {
  const Pruefpunkt({
    required this.id,
    required this.schritt,
    required this.bezeichnung,
    this.bewertung,
    this.begruendung,
    this.messwert,
    this.einheit,
    this.grenzwert,
    this.vergleich,
    this.methode,
    this.methoden = const [],
    this.hinweis,
  });

  final String id;

  /// 'besichtigen' | 'messen' | 'erproben'
  final String schritt;
  final String bezeichnung;

  /// 'io' (in Ordnung) | 'nio' (nicht in Ordnung) | 'na' (nicht anwendbar) | null (offen)
  final String? bewertung;

  /// Pflicht bei 'na' und 'nio'.
  final String? begruendung;

  final double? messwert;
  final String? einheit;
  final double? grenzwert;

  /// '<=' (Höchstwert) oder '>=' (Mindestwert)
  final String? vergleich;
  final String? methode;
  final List<String> methoden;
  final String? hinweis;

  bool get istMessung => schritt == 'messen';

  Pruefpunkt kopie({
    String? bewertung,
    bool bewertungLeeren = false,
    String? begruendung,
    double? messwert,
    bool messwertLeeren = false,
    double? grenzwert,
    String? methode,
  }) =>
      Pruefpunkt(
        id: id,
        schritt: schritt,
        bezeichnung: bezeichnung,
        bewertung: bewertungLeeren ? null : (bewertung ?? this.bewertung),
        begruendung: begruendung ?? this.begruendung,
        messwert: messwertLeeren ? null : (messwert ?? this.messwert),
        einheit: einheit,
        grenzwert: grenzwert ?? this.grenzwert,
        vergleich: vergleich,
        methode: methode ?? this.methode,
        methoden: methoden,
        hinweis: hinweis,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'schritt': schritt,
        'bezeichnung': bezeichnung,
        'bewertung': bewertung,
        'begruendung': begruendung,
        'messwert': messwert,
        'einheit': einheit,
        'grenzwert': grenzwert,
        'vergleich': vergleich,
        'methode': methode,
        'methoden': methoden,
        'hinweis': hinweis,
      };

  factory Pruefpunkt.fromJson(Map<String, dynamic> j) => Pruefpunkt(
        id: j['id'] as String,
        schritt: j['schritt'] as String,
        bezeichnung: j['bezeichnung'] as String,
        bewertung: j['bewertung'] as String?,
        begruendung: j['begruendung'] as String?,
        messwert: (j['messwert'] as num?)?.toDouble(),
        einheit: j['einheit'] as String?,
        grenzwert: (j['grenzwert'] as num?)?.toDouble(),
        vergleich: j['vergleich'] as String?,
        methode: j['methode'] as String?,
        methoden: [for (final m in j['methoden'] as List? ?? const []) m as String],
        hinweis: j['hinweis'] as String?,
      );
}

/// Prüfereignis eines Geräts (Roadmap M5). Entwurf → abgeschlossen;
/// abgeschlossene Prüfungen sind unveränderlich, Korrekturen sind neue
/// Prüfungen mit [ersetztUuid].
class GeraetePruefung {
  GeraetePruefung({
    String? uuid,
    required this.geraetUuid,
    required this.pruefart,
    required this.pruefartText,
    this.anlass,
    required this.pruefungDatum,
    this.prueferName,
    this.messgeraet,
    required this.regelVersion,
    this.schutzklasse,
    this.status = 'entwurf',
    this.ergebnis,
    required this.punkte,
    this.maengel,
    this.bemerkung,
    this.ortSnapshotJson,
    this.intervallMonate,
    this.naechstePruefung,
    this.ersetztUuid,
    this.abgeschlossenAm,
    DateTime? erstelltAm,
    DateTime? aktualisiertAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now().toUtc(),
        aktualisiertAm = aktualisiertAm ?? DateTime.now().toUtc();

  final String uuid;
  final String geraetUuid;

  /// Schlüssel, z. B. 'wiederholungspruefung'.
  final String pruefart;

  /// Auf jedem Protokoll sichtbare, tatsächliche Prüfart.
  final String pruefartText;
  final String? anlass;

  /// Kalendertag `YYYY-MM-DD`.
  final String pruefungDatum;
  final String? prueferName;
  final String? messgeraet;
  final String regelVersion;
  final String? schutzklasse;

  /// 'entwurf' | 'abgeschlossen'
  final String status;

  /// 'bestanden' | 'nicht_bestanden' | null
  final String? ergebnis;
  final List<Pruefpunkt> punkte;
  final String? maengel;
  final String? bemerkung;
  final String? ortSnapshotJson;
  final int? intervallMonate;

  /// `YYYY-MM-DD`, nur bei bestanden.
  final String? naechstePruefung;
  final String? ersetztUuid;
  final DateTime? abgeschlossenAm;
  final DateTime erstelltAm;
  final DateTime aktualisiertAm;

  bool get abgeschlossen => status == 'abgeschlossen';
  bool get bestanden => ergebnis == 'bestanden';
  DateTime get datum => textAlsTag(pruefungDatum);

  Map<String, dynamic>? get ortSnapshot =>
      ortSnapshotJson == null ? null : (jsonDecode(ortSnapshotJson!) as Map).cast<String, dynamic>();

  GeraetePruefung kopie({
    String? pruefart,
    String? pruefartText,
    String? pruefungDatum,
    String? prueferName,
    String? messgeraet,
    String? schutzklasse,
    String? status,
    String? ergebnis,
    bool ergebnisLeeren = false,
    List<Pruefpunkt>? punkte,
    String? maengel,
    String? bemerkung,
    String? ortSnapshotJson,
    int? intervallMonate,
    bool intervallLeeren = false,
    String? naechstePruefung,
    DateTime? abgeschlossenAm,
  }) =>
      GeraetePruefung(
        uuid: uuid,
        geraetUuid: geraetUuid,
        pruefart: pruefart ?? this.pruefart,
        pruefartText: pruefartText ?? this.pruefartText,
        anlass: anlass,
        pruefungDatum: pruefungDatum ?? this.pruefungDatum,
        prueferName: prueferName ?? this.prueferName,
        messgeraet: messgeraet ?? this.messgeraet,
        regelVersion: regelVersion,
        schutzklasse: schutzklasse ?? this.schutzklasse,
        status: status ?? this.status,
        ergebnis: ergebnisLeeren ? null : (ergebnis ?? this.ergebnis),
        punkte: punkte ?? this.punkte,
        maengel: maengel ?? this.maengel,
        bemerkung: bemerkung ?? this.bemerkung,
        ortSnapshotJson: ortSnapshotJson ?? this.ortSnapshotJson,
        intervallMonate: intervallLeeren ? null : (intervallMonate ?? this.intervallMonate),
        naechstePruefung: naechstePruefung ?? this.naechstePruefung,
        ersetztUuid: ersetztUuid,
        abgeschlossenAm: abgeschlossenAm ?? this.abgeschlossenAm,
        erstelltAm: erstelltAm,
      );

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'geraetUuid': geraetUuid,
        'pruefart': pruefart,
        'pruefartText': pruefartText,
        'anlass': anlass,
        'pruefungDatum': pruefungDatum,
        'prueferName': prueferName,
        'messgeraet': messgeraet,
        'regelVersion': regelVersion,
        'schutzklasse': schutzklasse,
        'status': status,
        'ergebnis': ergebnis,
        'punkteJson': jsonEncode([for (final p in punkte) p.toJson()]),
        'maengel': maengel,
        'bemerkung': bemerkung,
        'ortSnapshotJson': ortSnapshotJson,
        'intervallMonate': intervallMonate,
        'naechstePruefung': naechstePruefung,
        'ersetztUuid': ersetztUuid,
        'abgeschlossenAm': abgeschlossenAm?.toUtc().toIso8601String(),
        'erstelltAm': erstelltAm.toUtc().toIso8601String(),
        'aktualisiertAm': aktualisiertAm.toUtc().toIso8601String(),
      };

  factory GeraetePruefung.fromJson(Map<String, dynamic> j) => GeraetePruefung(
        uuid: j['uuid'] as String,
        geraetUuid: j['geraetUuid'] as String,
        pruefart: j['pruefart'] as String,
        pruefartText: j['pruefartText'] as String,
        anlass: j['anlass'] as String?,
        pruefungDatum: (j['pruefungDatum'] as String).split('T').first,
        prueferName: j['prueferName'] as String?,
        messgeraet: j['messgeraet'] as String?,
        regelVersion: j['regelVersion'] as String,
        schutzklasse: j['schutzklasse'] as String?,
        status: j['status'] as String? ?? 'entwurf',
        ergebnis: j['ergebnis'] as String?,
        punkte: [
          for (final p in jsonDecode(j['punkteJson'] as String? ?? '[]') as List)
            Pruefpunkt.fromJson((p as Map).cast<String, dynamic>()),
        ],
        maengel: j['maengel'] as String?,
        bemerkung: j['bemerkung'] as String?,
        ortSnapshotJson: j['ortSnapshotJson'] as String?,
        intervallMonate: (j['intervallMonate'] as num?)?.toInt(),
        naechstePruefung: j['naechstePruefung'] as String?,
        ersetztUuid: j['ersetztUuid'] as String?,
        abgeschlossenAm: DateTime.tryParse(j['abgeschlossenAm'] as String? ?? ''),
        erstelltAm: DateTime.parse(j['erstelltAm'] as String),
        aktualisiertAm:
            DateTime.tryParse(j['aktualisiertAm'] as String? ?? '') ?? DateTime.parse(j['erstelltAm'] as String),
      );
}

import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Schutzklassen in römischer Schreibweise (UI und PDF).
const schutzklassen = ['I', 'II', 'III'];

/// Kalendertag als `YYYY-MM-DD`, ohne Uhrzeit/Zeitzone — so liefert ihn
/// auch der Server, damit lokale und Serverfassung identisch bleiben.
String tagAlsText(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime textAlsTag(String s) {
  final d = DateTime.parse(s.split('T').first);
  return DateTime.utc(d.year, d.month, d.day);
}

/// Ein Eintrag der Nutzungsstatus-Historie (aktiv ↔ inaktiv).
class StatusEreignis {
  const StatusEreignis({required this.aktiv, this.grund, required this.zeit, this.benutzer});

  final bool aktiv;
  final String? grund;
  final DateTime zeit;
  final String? benutzer;

  Map<String, dynamic> toJson() => {
        'aktiv': aktiv,
        if (grund != null) 'grund': grund,
        'zeit': zeit.toUtc().toIso8601String(),
        if (benutzer != null) 'benutzer': benutzer,
      };

  factory StatusEreignis.fromJson(Map<String, dynamic> j) => StatusEreignis(
        aktiv: j['aktiv'] as bool,
        grund: j['grund'] as String?,
        zeit: DateTime.parse(j['zeit'] as String),
        benutzer: j['benutzer'] as String?,
      );
}

/// Ortsveränderliches Gerät (Geräteprüfung M2). UUID wird automatisch
/// erzeugt und ist zugleich der Inhalt des Etiketts.
class Geraet {
  final String uuid;
  final String kundeUuid;
  final String standortUuid;
  final String raumUuid;
  final String bezeichnung;
  final String? hersteller;
  final String? typ;
  final String? seriennummer;
  final String? inventarnummer;
  final String? schutzart;

  /// 'I' | 'II' | 'III' | null (noch nicht festgestellt)
  final String? schutzklasse;

  /// Nutzungsstatus: aktiv = wird verwendet und ist zu prüfen.
  final bool aktiv;
  final String? inaktivGrund;

  /// Ganze Monate 1–24, vom Messtechniker festgelegt.
  final int? pruefintervallMonate;
  final String? intervallBegruendung;

  /// Letzte Prüfung vor ElektraLog als `YYYY-MM-DD`. Bei
  /// [letztePruefungErsatzwert] ist es das Erstellungsdatum —
  /// **kein** Prüfnachweis.
  final String? letztePruefungDatum;
  final bool letztePruefungErsatzwert;

  final String? statusHistorieJson;
  final String? bemerkung;
  final DateTime erstelltAm;
  final DateTime aktualisiertAm;

  Geraet({
    String? uuid,
    required this.kundeUuid,
    required this.standortUuid,
    required this.raumUuid,
    required this.bezeichnung,
    this.hersteller,
    this.typ,
    this.seriennummer,
    this.inventarnummer,
    this.schutzart,
    this.schutzklasse,
    this.aktiv = true,
    this.inaktivGrund,
    this.pruefintervallMonate,
    this.intervallBegruendung,
    this.letztePruefungDatum,
    this.letztePruefungErsatzwert = false,
    this.statusHistorieJson,
    this.bemerkung,
    DateTime? erstelltAm,
    DateTime? aktualisiertAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now().toUtc(),
        aktualisiertAm = aktualisiertAm ?? DateTime.now().toUtc();

  /// Neuanlage: ohne angegebene letzte Prüfung wird das Erstellungsdatum
  /// als systemseitiger Ersatzwert eingesetzt (Roadmap, Kay 2026-11-07).
  factory Geraet.neu({
    required String kundeUuid,
    required String standortUuid,
    required String raumUuid,
    required String bezeichnung,
    String? hersteller,
    String? typ,
    String? seriennummer,
    String? inventarnummer,
    String? schutzart,
    String? schutzklasse,
    int? pruefintervallMonate,
    String? intervallBegruendung,
    DateTime? letztePruefung,
    String? bemerkung,
    DateTime? jetzt,
  }) {
    final erstellt = (jetzt ?? DateTime.now()).toUtc();
    return Geraet(
      kundeUuid: kundeUuid,
      standortUuid: standortUuid,
      raumUuid: raumUuid,
      bezeichnung: bezeichnung,
      hersteller: hersteller,
      typ: typ,
      seriennummer: seriennummer,
      inventarnummer: inventarnummer,
      schutzart: schutzart,
      schutzklasse: schutzklasse,
      pruefintervallMonate: pruefintervallMonate,
      intervallBegruendung: intervallBegruendung,
      letztePruefungDatum: tagAlsText(letztePruefung ?? (jetzt ?? DateTime.now())),
      letztePruefungErsatzwert: letztePruefung == null,
      bemerkung: bemerkung,
      erstelltAm: erstellt,
      aktualisiertAm: erstellt,
    );
  }

  List<StatusEreignis> get statusHistorie {
    final raw = statusHistorieJson;
    if (raw == null || raw.isEmpty) return const [];
    return [
      for (final e in jsonDecode(raw) as List) StatusEreignis.fromJson((e as Map).cast<String, dynamic>()),
    ];
  }

  /// Pflicht- und Wertprüfung wie auf dem Server. Leere Liste = gültig.
  List<String> get fehler => [
        if (bezeichnung.trim().isEmpty) 'Bezeichnung fehlt',
        if (kundeUuid.isEmpty) 'Kunde fehlt',
        if (standortUuid.isEmpty) 'Standort fehlt',
        if (raumUuid.isEmpty) 'Raum fehlt',
        if (schutzklasse != null && !schutzklassen.contains(schutzklasse)) 'Schutzklasse muss I, II oder III sein',
        if (!aktiv && (inaktivGrund ?? '').trim().isEmpty) 'Inaktives Gerät braucht einen Grund',
        if (pruefintervallMonate != null && (pruefintervallMonate! < 1 || pruefintervallMonate! > 24))
          'Prüfintervall muss 1–24 Monate sein',
      ];

  /// Statuswechsel mit Historieneintrag. Prüftermin und Prüfhistorie
  /// bleiben unverändert — der Wechsel selbst ist keine Prüfung.
  Geraet mitStatus({required bool aktiv, String? grund, String? benutzer, DateTime? zeit}) {
    final eintrag = StatusEreignis(
      aktiv: aktiv,
      grund: aktiv ? null : grund,
      zeit: (zeit ?? DateTime.now()).toUtc(),
      benutzer: benutzer,
    );
    return _kopie(
      aktiv: aktiv,
      inaktivGrund: aktiv ? null : grund,
      setzeGrund: true,
      statusHistorieJson: jsonEncode([...statusHistorie, eintrag].map((e) => e.toJson()).toList()),
    );
  }

  /// Zuordnung ändern (nur nach bestätigtem Dialog aufrufen).
  Geraet umgehaengt({required String kundeUuid, required String standortUuid, required String raumUuid}) =>
      _kopie(kundeUuid: kundeUuid, standortUuid: standortUuid, raumUuid: raumUuid);

  bool gleicherOrt(Geraet other) =>
      other.kundeUuid == kundeUuid && other.standortUuid == standortUuid && other.raumUuid == raumUuid;

  Geraet mitStammdaten({
    required String bezeichnung,
    String? hersteller,
    String? typ,
    String? seriennummer,
    String? inventarnummer,
    String? schutzart,
    String? schutzklasse,
    int? pruefintervallMonate,
    String? intervallBegruendung,
    String? bemerkung,
  }) =>
      Geraet(
        uuid: uuid,
        kundeUuid: kundeUuid,
        standortUuid: standortUuid,
        raumUuid: raumUuid,
        bezeichnung: bezeichnung,
        hersteller: hersteller,
        typ: typ,
        seriennummer: seriennummer,
        inventarnummer: inventarnummer,
        schutzart: schutzart,
        schutzklasse: schutzklasse,
        aktiv: aktiv,
        inaktivGrund: inaktivGrund,
        pruefintervallMonate: pruefintervallMonate,
        intervallBegruendung: intervallBegruendung,
        letztePruefungDatum: letztePruefungDatum,
        letztePruefungErsatzwert: letztePruefungErsatzwert,
        statusHistorieJson: statusHistorieJson,
        bemerkung: bemerkung,
        erstelltAm: erstelltAm,
      );

  Geraet _kopie({
    String? kundeUuid,
    String? standortUuid,
    String? raumUuid,
    bool? aktiv,
    String? inaktivGrund,
    bool setzeGrund = false,
    String? statusHistorieJson,
  }) =>
      Geraet(
        uuid: uuid,
        kundeUuid: kundeUuid ?? this.kundeUuid,
        standortUuid: standortUuid ?? this.standortUuid,
        raumUuid: raumUuid ?? this.raumUuid,
        bezeichnung: bezeichnung,
        hersteller: hersteller,
        typ: typ,
        seriennummer: seriennummer,
        inventarnummer: inventarnummer,
        schutzart: schutzart,
        schutzklasse: schutzklasse,
        aktiv: aktiv ?? this.aktiv,
        inaktivGrund: setzeGrund ? inaktivGrund : this.inaktivGrund,
        pruefintervallMonate: pruefintervallMonate,
        intervallBegruendung: intervallBegruendung,
        letztePruefungDatum: letztePruefungDatum,
        letztePruefungErsatzwert: letztePruefungErsatzwert,
        statusHistorieJson: statusHistorieJson ?? this.statusHistorieJson,
        bemerkung: bemerkung,
        erstelltAm: erstelltAm,
      );

  /// Treffer für die Suche nach UUID, Bezeichnung, Serien- oder Inventarnummer.
  bool passtZu(String suche) {
    final s = suche.trim().toLowerCase();
    if (s.isEmpty) return true;
    return [uuid, bezeichnung, seriennummer, inventarnummer, hersteller, typ]
        .any((f) => f != null && f.toLowerCase().contains(s));
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'kundeUuid': kundeUuid,
        'standortUuid': standortUuid,
        'raumUuid': raumUuid,
        'bezeichnung': bezeichnung,
        'hersteller': hersteller,
        'typ': typ,
        'seriennummer': seriennummer,
        'inventarnummer': inventarnummer,
        'schutzart': schutzart,
        'schutzklasse': schutzklasse,
        'aktiv': aktiv,
        'inaktivGrund': inaktivGrund,
        'pruefintervallMonate': pruefintervallMonate,
        'intervallBegruendung': intervallBegruendung,
        'letztePruefungDatum': letztePruefungDatum,
        'letztePruefungErsatzwert': letztePruefungErsatzwert,
        'statusHistorieJson': statusHistorieJson,
        'bemerkung': bemerkung,
        'erstelltAm': erstelltAm.toUtc().toIso8601String(),
        'aktualisiertAm': aktualisiertAm.toUtc().toIso8601String(),
      };

  factory Geraet.fromJson(Map<String, dynamic> json) => Geraet(
        uuid: json['uuid'] as String,
        kundeUuid: json['kundeUuid'] as String,
        standortUuid: json['standortUuid'] as String,
        raumUuid: json['raumUuid'] as String,
        bezeichnung: json['bezeichnung'] as String,
        hersteller: json['hersteller'] as String?,
        typ: json['typ'] as String?,
        seriennummer: json['seriennummer'] as String?,
        inventarnummer: json['inventarnummer'] as String?,
        schutzart: json['schutzart'] as String?,
        schutzklasse: json['schutzklasse'] as String?,
        aktiv: json['aktiv'] as bool? ?? true,
        inaktivGrund: json['inaktivGrund'] as String?,
        pruefintervallMonate: (json['pruefintervallMonate'] as num?)?.toInt(),
        intervallBegruendung: json['intervallBegruendung'] as String?,
        letztePruefungDatum: json['letztePruefungDatum'] as String?,
        letztePruefungErsatzwert: json['letztePruefungErsatzwert'] as bool? ?? false,
        statusHistorieJson: json['statusHistorieJson'] as String?,
        bemerkung: json['bemerkung'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        aktualisiertAm:
            DateTime.tryParse(json['aktualisiertAm'] as String? ?? '') ?? DateTime.parse(json['erstelltAm'] as String),
      );
}

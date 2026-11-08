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

/// Eintrag im Geräteverlauf: Statuswechsel (aktiv ↔ inaktiv) oder
/// Intervallfestlegung durch den Messtechniker (auditierbar, M4).
class VerlaufEintrag {
  const VerlaufEintrag.status({required this.aktiv, this.grund, required this.zeit, this.benutzer})
      : art = 'status',
        intervall = null,
        begruendung = null;

  const VerlaufEintrag.intervall({required this.intervall, this.begruendung, required this.zeit, this.benutzer})
      : art = 'intervall',
        aktiv = null,
        grund = null;

  const VerlaufEintrag._(
      {required this.art, this.aktiv, this.grund, this.intervall, this.begruendung, required this.zeit, this.benutzer});

  final String art;
  final bool? aktiv;
  final String? grund;
  final int? intervall;
  final String? begruendung;
  final DateTime zeit;
  final String? benutzer;

  Map<String, dynamic> toJson() => {
        'art': art,
        if (aktiv != null) 'aktiv': aktiv,
        if (grund != null) 'grund': grund,
        if (art == 'intervall') 'intervall': intervall,
        if (begruendung != null) 'begruendung': begruendung,
        'zeit': zeit.toUtc().toIso8601String(),
        if (benutzer != null) 'benutzer': benutzer,
      };

  factory VerlaufEintrag.fromJson(Map<String, dynamic> j) => VerlaufEintrag._(
        art: j['art'] as String? ?? 'status',
        aktiv: j['aktiv'] as bool?,
        grund: j['grund'] as String?,
        intervall: (j['intervall'] as num?)?.toInt(),
        begruendung: j['begruendung'] as String?,
        zeit: DateTime.parse(j['zeit'] as String),
        benutzer: j['benutzer'] as String?,
      );

  String get _schluessel => '$art|${zeit.toUtc().toIso8601String()}|$benutzer';
}

/// Vereinigt zwei Verlaufsfassungen (z. B. beim Zusammenführen eines
/// Sync-Konflikts) — kein Eintrag geht verloren.
String? verlaufVereinigen(String? a, String? b) {
  List<VerlaufEintrag> lesen(String? raw) => raw == null || raw.isEmpty
      ? const []
      : [for (final e in jsonDecode(raw) as List) VerlaufEintrag.fromJson((e as Map).cast<String, dynamic>())];
  final alle = {
    for (final e in [...lesen(a), ...lesen(b)]) e._schluessel: e
  }.values.toList()
    ..sort((x, y) => x.zeit.compareTo(y.zeit));
  return alle.isEmpty ? null : jsonEncode([for (final e in alle) e.toJson()]);
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

  /// Gesamter Verlauf (Status und Intervall), älteste zuerst.
  List<VerlaufEintrag> get verlauf {
    final raw = statusHistorieJson;
    if (raw == null || raw.isEmpty) return const [];
    return [
      for (final e in jsonDecode(raw) as List) VerlaufEintrag.fromJson((e as Map).cast<String, dynamic>()),
    ];
  }

  List<VerlaufEintrag> get statusHistorie => [
        for (final e in verlauf)
          if (e.art == 'status') e
      ];

  /// Intervall festlegen/ändern mit Verlaufseintrag (wer, wann, warum).
  /// Ohne Änderung bleibt das Gerät unverändert.
  Geraet mitIntervall(int? monate, {String? begruendung, String? benutzer, DateTime? zeit}) {
    if (monate == pruefintervallMonate && begruendung == intervallBegruendung) return this;
    final eintrag = VerlaufEintrag.intervall(
      intervall: monate,
      begruendung: begruendung,
      zeit: (zeit ?? DateTime.now()).toUtc(),
      benutzer: benutzer,
    );
    return Geraet(
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
      pruefintervallMonate: monate,
      intervallBegruendung: begruendung,
      letztePruefungDatum: letztePruefungDatum,
      letztePruefungErsatzwert: letztePruefungErsatzwert,
      statusHistorieJson: jsonEncode([...verlauf, eintrag].map((e) => e.toJson()).toList()),
      bemerkung: bemerkung,
      erstelltAm: erstelltAm,
    );
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
    final eintrag = VerlaufEintrag.status(
      aktiv: aktiv,
      grund: aktiv ? null : grund,
      zeit: (zeit ?? DateTime.now()).toUtc(),
      benutzer: benutzer,
    );
    return _kopie(
      aktiv: aktiv,
      inaktivGrund: aktiv ? null : grund,
      setzeGrund: true,
      statusHistorieJson: jsonEncode([...verlauf, eintrag].map((e) => e.toJson()).toList()),
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

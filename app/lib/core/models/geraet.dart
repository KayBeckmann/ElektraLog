import 'package:uuid/uuid.dart';

class Geraet {
  final String uuid;
  final String standortUuid;
  final String bezeichnung;
  final String? seriennummer;
  final String? hersteller;
  final String? geraetetyp;

  /// Prüfintervall in Monaten — max. 24 Monate (DGUV V3 / VDE 0701-0702)
  final int pruefintervallMonate;

  final DateTime? letztePruefung;
  final DateTime erstelltAm;

  Geraet({
    String? uuid,
    required this.standortUuid,
    required this.bezeichnung,
    this.seriennummer,
    this.hersteller,
    this.geraetetyp,
    this.pruefintervallMonate = 24,
    this.letztePruefung,
    DateTime? erstelltAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now();

  DateTime? get naechstePruefung {
    if (letztePruefung == null) return null;
    // Monate addieren, Overflow wird von DateTime korrekt behandelt
    final m = letztePruefung!.month + pruefintervallMonate;
    return DateTime(
      letztePruefung!.year + (m - 1) ~/ 12,
      ((m - 1) % 12) + 1,
      letztePruefung!.day,
    );
  }

  bool get isUeberfaellig {
    final n = naechstePruefung;
    if (n == null) return false;
    return n.isBefore(DateTime.now());
  }

  /// Lesbare Anzeige des Intervalls (z.B. "12 Monate" oder "24 Monate")
  String get intervallLabel => '$pruefintervallMonate Monate';

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'standortUuid': standortUuid,
        'bezeichnung': bezeichnung,
        'seriennummer': seriennummer,
        'hersteller': hersteller,
        'geraetetyp': geraetetyp,
        'pruefintervallMonate': pruefintervallMonate,
        // Rückwärtskompatibilität: alten Jahreswert nicht mehr schreiben
        'letztePruefung': letztePruefung?.toIso8601String(),
        'erstelltAm': erstelltAm.toIso8601String(),
      };

  factory Geraet.fromJson(Map<String, dynamic> json) {
    // Rückwärtskompatibilität: altes pruefintervallJahre → Monate
    int monate;
    if (json['pruefintervallMonate'] != null) {
      monate = (json['pruefintervallMonate'] as num).toInt();
    } else if (json['pruefintervallJahre'] != null) {
      monate = ((json['pruefintervallJahre'] as num).toInt()) * 12;
    } else {
      monate = 24;
    }
    return Geraet(
      uuid: json['uuid'] as String,
      standortUuid: json['standortUuid'] as String,
      bezeichnung: json['bezeichnung'] as String,
      seriennummer: json['seriennummer'] as String?,
      hersteller: json['hersteller'] as String?,
      geraetetyp: json['geraetetyp'] as String?,
      pruefintervallMonate: monate.clamp(1, 24),
      letztePruefung: json['letztePruefung'] == null
          ? null
          : DateTime.parse(json['letztePruefung'] as String),
      erstelltAm: DateTime.parse(json['erstelltAm'] as String),
    );
  }

  Geraet copyWith({
    String? bezeichnung,
    String? seriennummer,
    String? hersteller,
    String? geraetetyp,
    int? pruefintervallMonate,
    DateTime? letztePruefung,
  }) =>
      Geraet(
        uuid: uuid,
        standortUuid: standortUuid,
        bezeichnung: bezeichnung ?? this.bezeichnung,
        seriennummer: seriennummer ?? this.seriennummer,
        hersteller: hersteller ?? this.hersteller,
        geraetetyp: geraetetyp ?? this.geraetetyp,
        pruefintervallMonate: pruefintervallMonate ?? this.pruefintervallMonate,
        letztePruefung: letztePruefung ?? this.letztePruefung,
        erstelltAm: erstelltAm,
      );
}

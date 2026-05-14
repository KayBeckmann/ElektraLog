import 'package:uuid/uuid.dart';

class Geraet {
  final String uuid;
  final String standortUuid;
  final String bezeichnung;
  final String? seriennummer;
  final String? hersteller;
  final String? geraetetyp; // z.B. "Bohrmaschine", "Verlängerungskabel"
  final int pruefintervallJahre; // max. 2 Jahre (DGUV V3)
  final DateTime? letztePruefung;
  final DateTime erstelltAm;

  Geraet({
    String? uuid,
    required this.standortUuid,
    required this.bezeichnung,
    this.seriennummer,
    this.hersteller,
    this.geraetetyp,
    this.pruefintervallJahre = 2,
    this.letztePruefung,
    DateTime? erstelltAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now();

  DateTime? get naechstePruefung => letztePruefung == null
      ? null
      : DateTime(
          letztePruefung!.year + pruefintervallJahre,
          letztePruefung!.month,
          letztePruefung!.day,
        );

  bool get isUeberfaellig {
    final naechste = naechstePruefung;
    if (naechste == null) return false;
    return naechste.isBefore(DateTime.now());
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'standortUuid': standortUuid,
        'bezeichnung': bezeichnung,
        'seriennummer': seriennummer,
        'hersteller': hersteller,
        'geraetetyp': geraetetyp,
        'pruefintervallJahre': pruefintervallJahre,
        'letztePruefung': letztePruefung?.toIso8601String(),
        'erstelltAm': erstelltAm.toIso8601String(),
      };

  factory Geraet.fromJson(Map<String, dynamic> json) => Geraet(
        uuid: json['uuid'] as String,
        standortUuid: json['standortUuid'] as String,
        bezeichnung: json['bezeichnung'] as String,
        seriennummer: json['seriennummer'] as String?,
        hersteller: json['hersteller'] as String?,
        geraetetyp: json['geraetetyp'] as String?,
        pruefintervallJahre: (json['pruefintervallJahre'] as num?)?.toInt() ?? 2,
        letztePruefung: json['letztePruefung'] == null
            ? null
            : DateTime.parse(json['letztePruefung'] as String),
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
      );

  Geraet copyWith({
    String? bezeichnung,
    String? seriennummer,
    String? hersteller,
    String? geraetetyp,
    int? pruefintervallJahre,
    DateTime? letztePruefung,
  }) =>
      Geraet(
        uuid: uuid,
        standortUuid: standortUuid,
        bezeichnung: bezeichnung ?? this.bezeichnung,
        seriennummer: seriennummer ?? this.seriennummer,
        hersteller: hersteller ?? this.hersteller,
        geraetetyp: geraetetyp ?? this.geraetetyp,
        pruefintervallJahre: pruefintervallJahre ?? this.pruefintervallJahre,
        letztePruefung: letztePruefung ?? this.letztePruefung,
        erstelltAm: erstelltAm,
      );
}

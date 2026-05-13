import 'package:uuid/uuid.dart';

class Standort {
  final String uuid;
  final String kundeUuid;
  final String bezeichnung;
  final String? strasse;
  final String? plz;
  final String? ort;
  final DateTime erstelltAm;

  Standort({
    String? uuid,
    required this.kundeUuid,
    required this.bezeichnung,
    this.strasse,
    this.plz,
    this.ort,
    DateTime? erstelltAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'kundeUuid': kundeUuid,
        'bezeichnung': bezeichnung,
        'strasse': strasse,
        'plz': plz,
        'ort': ort,
        'erstelltAm': erstelltAm.toIso8601String(),
      };

  factory Standort.fromJson(Map<String, dynamic> json) => Standort(
        uuid: json['uuid'] as String,
        kundeUuid: json['kundeUuid'] as String,
        bezeichnung: json['bezeichnung'] as String,
        strasse: json['strasse'] as String?,
        plz: json['plz'] as String?,
        ort: json['ort'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
      );

  Standort copyWith({
    String? bezeichnung,
    String? strasse,
    String? plz,
    String? ort,
  }) =>
      Standort(
        uuid: uuid,
        kundeUuid: kundeUuid,
        bezeichnung: bezeichnung ?? this.bezeichnung,
        strasse: strasse ?? this.strasse,
        plz: plz ?? this.plz,
        ort: ort ?? this.ort,
        erstelltAm: erstelltAm,
      );
}

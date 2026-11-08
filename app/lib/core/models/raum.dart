import 'package:uuid/uuid.dart';

/// Raum eines Standorts (Geräteprüfung). Jedes Gerät liegt in genau
/// einem Raum; der Verteilerbaum der Anlagenprüfung bleibt davon getrennt.
class Raum {
  final String uuid;
  final String standortUuid;
  final String bezeichnung;
  final String? bemerkung;
  final DateTime erstelltAm;
  final DateTime aktualisiertAm;

  Raum({
    String? uuid,
    required this.standortUuid,
    required this.bezeichnung,
    this.bemerkung,
    DateTime? erstelltAm,
    DateTime? aktualisiertAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now().toUtc(),
        aktualisiertAm = aktualisiertAm ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'standortUuid': standortUuid,
        'bezeichnung': bezeichnung,
        'bemerkung': bemerkung,
        'erstelltAm': erstelltAm.toUtc().toIso8601String(),
        'aktualisiertAm': aktualisiertAm.toUtc().toIso8601String(),
      };

  factory Raum.fromJson(Map<String, dynamic> json) => Raum(
        uuid: json['uuid'] as String,
        standortUuid: json['standortUuid'] as String,
        bezeichnung: json['bezeichnung'] as String,
        bemerkung: json['bemerkung'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        aktualisiertAm:
            DateTime.tryParse(json['aktualisiertAm'] as String? ?? '') ?? DateTime.parse(json['erstelltAm'] as String),
      );

  Raum copyWith({String? bezeichnung, String? bemerkung}) => Raum(
        uuid: uuid,
        standortUuid: standortUuid,
        bezeichnung: bezeichnung ?? this.bezeichnung,
        bemerkung: bemerkung ?? this.bemerkung,
        erstelltAm: erstelltAm,
      );
}

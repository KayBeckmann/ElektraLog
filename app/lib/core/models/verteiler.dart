import 'package:uuid/uuid.dart';

class Verteiler {
  final String uuid;
  final String standortUuid;
  final String bezeichnung;
  final String? bemerkung;

  /// Anlagendaten als JSON-String (dart:convert)
  final String? anlagendatenJson;

  final DateTime erstelltAm;

  Verteiler({
    String? uuid,
    required this.standortUuid,
    required this.bezeichnung,
    this.bemerkung,
    this.anlagendatenJson,
    DateTime? erstelltAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'standortUuid': standortUuid,
        'bezeichnung': bezeichnung,
        'bemerkung': bemerkung,
        'anlagendatenJson': anlagendatenJson,
        'erstelltAm': erstelltAm.toIso8601String(),
      };

  factory Verteiler.fromJson(Map<String, dynamic> json) => Verteiler(
        uuid: json['uuid'] as String,
        standortUuid: json['standortUuid'] as String,
        bezeichnung: json['bezeichnung'] as String,
        bemerkung: json['bemerkung'] as String?,
        anlagendatenJson: json['anlagendatenJson'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
      );

  Verteiler copyWith({
    String? bezeichnung,
    String? bemerkung,
    String? anlagendatenJson,
  }) =>
      Verteiler(
        uuid: uuid,
        standortUuid: standortUuid,
        bezeichnung: bezeichnung ?? this.bezeichnung,
        bemerkung: bemerkung ?? this.bemerkung,
        anlagendatenJson: anlagendatenJson ?? this.anlagendatenJson,
        erstelltAm: erstelltAm,
      );
}

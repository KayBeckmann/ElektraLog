import 'package:uuid/uuid.dart';

class Verteiler {
  final String uuid;
  final String standortUuid;
  final String bezeichnung;
  final String? bemerkung;

  /// Anlagendaten als JSON-String (dart:convert)
  final String? anlagendatenJson;

  /// Prüfintervall in Jahren — ortsfeste Anlagen max. 4 Jahre (VDE 0105)
  final int pruefintervallJahre;

  final DateTime erstelltAm;
  final DateTime aktualisiertAm;

  Verteiler({
    String? uuid,
    required this.standortUuid,
    required this.bezeichnung,
    this.bemerkung,
    this.anlagendatenJson,
    this.pruefintervallJahre = 4,
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
        'anlagendatenJson': anlagendatenJson,
        'pruefintervallJahre': pruefintervallJahre,
        'erstelltAm': erstelltAm.toUtc().toIso8601String(),
        'aktualisiertAm': aktualisiertAm.toUtc().toIso8601String(),
      };

  factory Verteiler.fromJson(Map<String, dynamic> json) => Verteiler(
        uuid: json['uuid'] as String,
        standortUuid: json['standortUuid'] as String,
        bezeichnung: json['bezeichnung'] as String,
        bemerkung: json['bemerkung'] as String?,
        anlagendatenJson: json['anlagendatenJson'] as String?,
        pruefintervallJahre:
            (json['pruefintervallJahre'] as num?)?.toInt() ?? 4,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        aktualisiertAm: DateTime.tryParse(
                json['aktualisiertAm'] as String? ?? '') ??
            DateTime.parse(json['erstelltAm'] as String),
      );

  Verteiler copyWith({
    String? bezeichnung,
    String? bemerkung,
    String? anlagendatenJson,
    int? pruefintervallJahre,
  }) =>
      Verteiler(
        uuid: uuid,
        standortUuid: standortUuid,
        bezeichnung: bezeichnung ?? this.bezeichnung,
        bemerkung: bemerkung ?? this.bemerkung,
        anlagendatenJson: anlagendatenJson ?? this.anlagendatenJson,
        pruefintervallJahre: pruefintervallJahre ?? this.pruefintervallJahre,
        erstelltAm: erstelltAm,
        aktualisiertAm: DateTime.now().toUtc(),
      );
}

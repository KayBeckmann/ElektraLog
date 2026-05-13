import 'package:uuid/uuid.dart';

class VerteilerKomponente {
  final String uuid;
  final String verteilerUuid;

  /// null = Wurzel-Element
  final String? parentUuid;

  /// 'hauptschalter'|'rcd'|'ls_schalter'|'fi_ls'|'vorsicherung'|
  /// 'nh_sicherung'|'ueberspannung'|'sammelschiene'|'sonstige'
  final String typ;

  final String bezeichnung;
  final int position;

  /// Typ-spezifische Eigenschaften als JSON-String
  final String? eigenschaftenJson;

  final DateTime erstelltAm;

  VerteilerKomponente({
    String? uuid,
    required this.verteilerUuid,
    this.parentUuid,
    required this.typ,
    required this.bezeichnung,
    this.position = 0,
    this.eigenschaftenJson,
    DateTime? erstelltAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'verteilerUuid': verteilerUuid,
        'parentUuid': parentUuid,
        'typ': typ,
        'bezeichnung': bezeichnung,
        'position': position,
        'eigenschaftenJson': eigenschaftenJson,
        'erstelltAm': erstelltAm.toIso8601String(),
      };

  factory VerteilerKomponente.fromJson(Map<String, dynamic> json) =>
      VerteilerKomponente(
        uuid: json['uuid'] as String,
        verteilerUuid: json['verteilerUuid'] as String,
        parentUuid: json['parentUuid'] as String?,
        typ: json['typ'] as String,
        bezeichnung: json['bezeichnung'] as String,
        position: (json['position'] as num?)?.toInt() ?? 0,
        eigenschaftenJson: json['eigenschaftenJson'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
      );

  VerteilerKomponente copyWith({
    String? typ,
    String? bezeichnung,
    int? position,
    String? eigenschaftenJson,
  }) =>
      VerteilerKomponente(
        uuid: uuid,
        verteilerUuid: verteilerUuid,
        parentUuid: parentUuid,
        typ: typ ?? this.typ,
        bezeichnung: bezeichnung ?? this.bezeichnung,
        position: position ?? this.position,
        eigenschaftenJson: eigenschaftenJson ?? this.eigenschaftenJson,
        erstelltAm: erstelltAm,
      );
}

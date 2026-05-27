import 'package:uuid/uuid.dart';

class Messung {
  final String uuid;
  final String? komponenteUuid;

  /// Immer 'vde_0100'
  final String norm;

  final DateTime pruefungDatum;
  final String? prueferName;

  /// Messwerte als JSON-String
  final String? messwertJson;

  /// 'bestanden'|'nicht_bestanden'|'nicht_geprueft'
  final String ergebnis;

  final String? bemerkung;
  final DateTime erstelltAm;
  final DateTime aktualisiertAm;

  Messung({
    String? uuid,
    this.komponenteUuid,
    required this.norm,
    required this.pruefungDatum,
    this.prueferName,
    this.messwertJson,
    required this.ergebnis,
    this.bemerkung,
    DateTime? erstelltAm,
    DateTime? aktualisiertAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now(),
        aktualisiertAm = aktualisiertAm ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'komponenteUuid': komponenteUuid,
        'norm': norm,
        'pruefungDatum': pruefungDatum.toIso8601String(),
        'prueferName': prueferName,
        'messwertJson': messwertJson,
        'ergebnis': ergebnis,
        'bemerkung': bemerkung,
        'erstelltAm': erstelltAm.toIso8601String(),
        'aktualisiertAm': aktualisiertAm.toIso8601String(),
      };

  factory Messung.fromJson(Map<String, dynamic> json) => Messung(
        uuid: json['uuid'] as String,
        komponenteUuid: json['komponenteUuid'] as String?,
        norm: json['norm'] as String? ?? 'vde_0100',
        pruefungDatum: DateTime.parse(json['pruefungDatum'] as String),
        prueferName: json['prueferName'] as String?,
        messwertJson: json['messwertJson'] as String?,
        ergebnis: json['ergebnis'] as String,
        bemerkung: json['bemerkung'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        aktualisiertAm: DateTime.tryParse(
                json['aktualisiertAm'] as String? ?? '') ??
            DateTime.parse(json['erstelltAm'] as String),
      );

  Messung copyWith({
    DateTime? pruefungDatum,
    String? prueferName,
    String? messwertJson,
    String? ergebnis,
    String? bemerkung,
  }) =>
      Messung(
        uuid: uuid,
        komponenteUuid: komponenteUuid,
        norm: norm,
        pruefungDatum: pruefungDatum ?? this.pruefungDatum,
        prueferName: prueferName ?? this.prueferName,
        messwertJson: messwertJson ?? this.messwertJson,
        ergebnis: ergebnis ?? this.ergebnis,
        bemerkung: bemerkung ?? this.bemerkung,
        erstelltAm: erstelltAm,
        aktualisiertAm: DateTime.now(),
      );
}

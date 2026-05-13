import 'package:uuid/uuid.dart';

class Sichtpruefung {
  final String uuid;
  final String verteilerUuid;
  final DateTime pruefungDatum;
  final String? prueferName;

  /// Checkliste als JSON-String
  final String? checklisteJson;

  final String? maengel;

  /// 'bestanden'|'mit_maengeln'|'nicht_bestanden'
  final String ergebnis;

  final DateTime erstelltAm;

  Sichtpruefung({
    String? uuid,
    required this.verteilerUuid,
    required this.pruefungDatum,
    this.prueferName,
    this.checklisteJson,
    this.maengel,
    required this.ergebnis,
    DateTime? erstelltAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'verteilerUuid': verteilerUuid,
        'pruefungDatum': pruefungDatum.toIso8601String(),
        'prueferName': prueferName,
        'checklisteJson': checklisteJson,
        'maengel': maengel,
        'ergebnis': ergebnis,
        'erstelltAm': erstelltAm.toIso8601String(),
      };

  factory Sichtpruefung.fromJson(Map<String, dynamic> json) => Sichtpruefung(
        uuid: json['uuid'] as String,
        verteilerUuid: json['verteilerUuid'] as String,
        pruefungDatum: DateTime.parse(json['pruefungDatum'] as String),
        prueferName: json['prueferName'] as String?,
        checklisteJson: json['checklisteJson'] as String?,
        maengel: json['maengel'] as String?,
        ergebnis: json['ergebnis'] as String,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
      );

  Sichtpruefung copyWith({
    DateTime? pruefungDatum,
    String? prueferName,
    String? checklisteJson,
    String? maengel,
    String? ergebnis,
  }) =>
      Sichtpruefung(
        uuid: uuid,
        verteilerUuid: verteilerUuid,
        pruefungDatum: pruefungDatum ?? this.pruefungDatum,
        prueferName: prueferName ?? this.prueferName,
        checklisteJson: checklisteJson ?? this.checklisteJson,
        maengel: maengel ?? this.maengel,
        ergebnis: ergebnis ?? this.ergebnis,
        erstelltAm: erstelltAm,
      );
}

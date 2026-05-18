import 'package:uuid/uuid.dart';

/// Wird automatisch erstellt wenn ein PDF-Protokoll generiert wird.
/// Dient als Prüfverlauf und Basis für den nächsten Prüftermin.
class Pruefprotokoll {
  final String uuid;
  final String verteilerUuid;
  final DateTime protokollDatum;
  final String? prueferName;
  final String? firma;
  final DateTime erstelltAm;

  Pruefprotokoll({
    String? uuid,
    required this.verteilerUuid,
    required this.protokollDatum,
    this.prueferName,
    this.firma,
    DateTime? erstelltAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'verteilerUuid': verteilerUuid,
        'protokollDatum': protokollDatum.toIso8601String(),
        'prueferName': prueferName,
        'firma': firma,
        'erstelltAm': erstelltAm.toIso8601String(),
      };

  factory Pruefprotokoll.fromJson(Map<String, dynamic> json) => Pruefprotokoll(
        uuid: json['uuid'] as String,
        verteilerUuid: json['verteilerUuid'] as String,
        protokollDatum: DateTime.parse(json['protokollDatum'] as String),
        prueferName: json['prueferName'] as String?,
        firma: json['firma'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
      );
}

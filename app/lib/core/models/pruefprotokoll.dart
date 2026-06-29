import 'package:uuid/uuid.dart';

/// Wird automatisch erstellt wenn ein PDF-Protokoll generiert wird.
/// Dient als unveränderlicher Prüfverlauf und Basis für den nächsten Prüftermin.
///
/// [messdatenSnapshot] ist ein JSON-Einfrierung aller Messwerte zum Zeitpunkt
/// der Protokollerstellung — unabhängig von späteren Änderungen an den Messungen.
class Pruefprotokoll {
  final String uuid;
  final String verteilerUuid;
  final DateTime protokollDatum;
  final String? prueferName;
  final String? firma;

  /// Optionale Bezeichnungen für Anzeige ohne DB-Joins
  final String? verteilerBezeichnung;
  final String? standortBezeichnung;
  final String? kundenBezeichnung;

  /// Einfrierung aller Messdaten zum Zeitpunkt des Exports als JSON.
  /// Struktur: { "komponenten": [...], "sichtpruefung": {...}, "geraete": [...] }
  final String? messdatenSnapshot;

  /// UUID des Protokolls im Backend (null = noch nicht synchronisiert)
  final String? backendUuid;

  final DateTime erstelltAm;

  Pruefprotokoll({
    String? uuid,
    required this.verteilerUuid,
    required this.protokollDatum,
    this.prueferName,
    this.firma,
    this.verteilerBezeichnung,
    this.standortBezeichnung,
    this.kundenBezeichnung,
    this.messdatenSnapshot,
    this.backendUuid,
    DateTime? erstelltAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'verteilerUuid': verteilerUuid,
        'protokollDatum': protokollDatum.toUtc().toIso8601String(),
        'prueferName': prueferName,
        'firma': firma,
        'verteilerBezeichnung': verteilerBezeichnung,
        'standortBezeichnung': standortBezeichnung,
        'kundenBezeichnung': kundenBezeichnung,
        'messdatenSnapshot': messdatenSnapshot,
        'backendUuid': backendUuid,
        'erstelltAm': erstelltAm.toUtc().toIso8601String(),
      };

  factory Pruefprotokoll.fromJson(Map<String, dynamic> json) => Pruefprotokoll(
        uuid: json['uuid'] as String,
        verteilerUuid: json['verteilerUuid'] as String,
        protokollDatum: DateTime.parse(json['protokollDatum'] as String),
        prueferName: json['prueferName'] as String?,
        firma: json['firma'] as String?,
        verteilerBezeichnung: json['verteilerBezeichnung'] as String?,
        standortBezeichnung: json['standortBezeichnung'] as String?,
        kundenBezeichnung: json['kundenBezeichnung'] as String?,
        messdatenSnapshot: json['messdatenSnapshot'] as String?,
        backendUuid: json['backendUuid'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
      );

  Pruefprotokoll mitBackendUuid(String id) => Pruefprotokoll(
        uuid: uuid,
        verteilerUuid: verteilerUuid,
        protokollDatum: protokollDatum,
        prueferName: prueferName,
        firma: firma,
        verteilerBezeichnung: verteilerBezeichnung,
        standortBezeichnung: standortBezeichnung,
        kundenBezeichnung: kundenBezeichnung,
        messdatenSnapshot: messdatenSnapshot,
        backendUuid: id,
        erstelltAm: erstelltAm,
      );
}

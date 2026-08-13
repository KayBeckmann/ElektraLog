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

  /// Base64-kodiertes Original-PDF, solange [backendUuid] noch null ist.
  /// Ermöglicht einen späteren Retry mit exakt demselben PDF, ohne es aus
  /// [messdatenSnapshot] neu erzeugen zu müssen (Monteure haben nicht immer
  /// direkt Empfang, siehe [SyncService.retryAusstehendeProtokolle]). Wird
  /// nach erfolgreichem Upload via [ohnePdf] wieder verworfen — die
  /// Dokumentenablage im Backend ist dann die alleinige Quelle für das PDF.
  final String? pdfBase64;

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
    this.pdfBase64,
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
        'pdfBase64': pdfBase64,
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
        pdfBase64: json['pdfBase64'] as String?,
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
        pdfBase64: pdfBase64,
        erstelltAm: erstelltAm,
      );

  /// Kopie ohne lokal gespeicherte PDF-Bytes — nach erfolgreichem Upload
  /// aufgerufen, damit nicht dauerhaft PDFs doppelt (lokal + Backend)
  /// vorgehalten werden.
  Pruefprotokoll ohnePdf() => Pruefprotokoll(
        uuid: uuid,
        verteilerUuid: verteilerUuid,
        protokollDatum: protokollDatum,
        prueferName: prueferName,
        firma: firma,
        verteilerBezeichnung: verteilerBezeichnung,
        standortBezeichnung: standortBezeichnung,
        kundenBezeichnung: kundenBezeichnung,
        messdatenSnapshot: messdatenSnapshot,
        backendUuid: backendUuid,
        pdfBase64: null,
        erstelltAm: erstelltAm,
      );
}

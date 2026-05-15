import 'package:uuid/uuid.dart';

class Messung {
  final String uuid;

  /// Gesetzt für Verteilerkomponenten (VDE 0100)
  final String? komponenteUuid;

  /// Gesetzt für portable Geräte (VDE 0701-0702 / DGUV V3)
  final String? geraetUuid;

  /// 'vde_0701_0702'|'dguv_v3'|'vde_0100'
  final String norm;

  final DateTime pruefungDatum;
  final String? prueferName;

  /// Messwerte als JSON-String
  final String? messwertJson;

  /// 'bestanden'|'nicht_bestanden'|'nicht_geprueft'
  final String ergebnis;

  final String? bemerkung;
  final DateTime erstelltAm;

  /// Nächstes Prüfungsdatum (z.B. aus DGUV-V3-Messung übernommen)
  final DateTime? naechstePruefungDatum;

  Messung({
    String? uuid,
    this.komponenteUuid,
    this.geraetUuid,
    required this.norm,
    required this.pruefungDatum,
    this.prueferName,
    this.messwertJson,
    required this.ergebnis,
    this.bemerkung,
    DateTime? erstelltAm,
    this.naechstePruefungDatum,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'komponenteUuid': komponenteUuid,
        'geraetUuid': geraetUuid,
        'norm': norm,
        'pruefungDatum': pruefungDatum.toIso8601String(),
        'prueferName': prueferName,
        'messwertJson': messwertJson,
        'ergebnis': ergebnis,
        'bemerkung': bemerkung,
        'erstelltAm': erstelltAm.toIso8601String(),
        'naechstePruefungDatum': naechstePruefungDatum?.toIso8601String(),
      };

  factory Messung.fromJson(Map<String, dynamic> json) => Messung(
        uuid: json['uuid'] as String,
        komponenteUuid: json['komponenteUuid'] as String?,
        geraetUuid: json['geraetUuid'] as String?,
        norm: json['norm'] as String,
        pruefungDatum: DateTime.parse(json['pruefungDatum'] as String),
        prueferName: json['prueferName'] as String?,
        messwertJson: json['messwertJson'] as String?,
        ergebnis: json['ergebnis'] as String,
        bemerkung: json['bemerkung'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        naechstePruefungDatum: json['naechstePruefungDatum'] != null
            ? DateTime.parse(json['naechstePruefungDatum'] as String)
            : null,
      );

  Messung copyWith({
    String? norm,
    DateTime? pruefungDatum,
    String? prueferName,
    String? messwertJson,
    String? ergebnis,
    String? bemerkung,
    DateTime? naechstePruefungDatum,
  }) =>
      Messung(
        uuid: uuid,
        komponenteUuid: komponenteUuid,
        geraetUuid: geraetUuid,
        norm: norm ?? this.norm,
        pruefungDatum: pruefungDatum ?? this.pruefungDatum,
        prueferName: prueferName ?? this.prueferName,
        messwertJson: messwertJson ?? this.messwertJson,
        ergebnis: ergebnis ?? this.ergebnis,
        bemerkung: bemerkung ?? this.bemerkung,
        erstelltAm: erstelltAm,
        naechstePruefungDatum:
            naechstePruefungDatum ?? this.naechstePruefungDatum,
      );
}

import 'package:uuid/uuid.dart';

class VerteilerKomponente {
  final String uuid;
  final String verteilerUuid;

  /// null = Wurzel-Element
  final String? parentUuid;

  /// 'hauptschalter'|'rcd'|'ls_schalter'|'fi_ls'|'vorsicherung'|
  /// 'nh_sicherung'|'ueberspannung'|'sammelschiene'|'sonstige'
  final String typ;

  /// Betriebsmittelkennzeichen nach DIN EN 81346, z.B. "-Q1", "-F1.1"
  final String betriebsmittelkennzeichen;

  /// Freitext-Beschriftung des Abgangs/Kreises, z.B. "Licht EG", "Steckdosen Bad"
  final String zielbezeichnung;

  final int position;

  /// Typ-spezifische Eigenschaften als JSON-String
  final String? eigenschaftenJson;

  final DateTime erstelltAm;
  final DateTime aktualisiertAm;

  VerteilerKomponente({
    String? uuid,
    required this.verteilerUuid,
    this.parentUuid,
    required this.typ,
    this.betriebsmittelkennzeichen = '',
    required this.zielbezeichnung,
    this.position = 0,
    this.eigenschaftenJson,
    DateTime? erstelltAm,
    DateTime? aktualisiertAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now().toUtc(),
        aktualisiertAm = aktualisiertAm ?? DateTime.now().toUtc();

  /// Anzeigename: BMK + Zielbezeichnung, oder nur eines von beiden.
  String get bezeichnung {
    if (betriebsmittelkennzeichen.isNotEmpty && zielbezeichnung.isNotEmpty) {
      return '$betriebsmittelkennzeichen — $zielbezeichnung';
    }
    if (betriebsmittelkennzeichen.isNotEmpty) return betriebsmittelkennzeichen;
    return zielbezeichnung;
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'verteilerUuid': verteilerUuid,
        'parentUuid': parentUuid,
        'typ': typ,
        'betriebsmittelkennzeichen': betriebsmittelkennzeichen,
        'zielbezeichnung': zielbezeichnung,
        'position': position,
        'eigenschaftenJson': eigenschaftenJson,
        'erstelltAm': erstelltAm.toUtc().toIso8601String(),
        'aktualisiertAm': aktualisiertAm.toUtc().toIso8601String(),
      };

  factory VerteilerKomponente.fromJson(Map<String, dynamic> json) =>
      VerteilerKomponente(
        uuid: json['uuid'] as String,
        verteilerUuid: json['verteilerUuid'] as String,
        parentUuid: json['parentUuid'] as String?,
        typ: json['typ'] as String,
        betriebsmittelkennzeichen:
            json['betriebsmittelkennzeichen'] as String? ?? '',
        // Datenmigration: bestehende 'bezeichnung' → 'zielbezeichnung'
        zielbezeichnung: json['zielbezeichnung'] as String? ??
            json['bezeichnung'] as String? ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
        eigenschaftenJson: json['eigenschaftenJson'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        aktualisiertAm: DateTime.tryParse(
                json['aktualisiertAm'] as String? ?? '') ??
            DateTime.parse(json['erstelltAm'] as String),
      );

  VerteilerKomponente copyWith({
    String? typ,
    String? betriebsmittelkennzeichen,
    String? zielbezeichnung,
    int? position,
    String? eigenschaftenJson,
  }) =>
      VerteilerKomponente(
        uuid: uuid,
        verteilerUuid: verteilerUuid,
        parentUuid: parentUuid,
        typ: typ ?? this.typ,
        betriebsmittelkennzeichen:
            betriebsmittelkennzeichen ?? this.betriebsmittelkennzeichen,
        zielbezeichnung: zielbezeichnung ?? this.zielbezeichnung,
        position: position ?? this.position,
        eigenschaftenJson: eigenschaftenJson ?? this.eigenschaftenJson,
        erstelltAm: erstelltAm,
        aktualisiertAm: DateTime.now().toUtc(),
      );
}

import 'package:uuid/uuid.dart';

class Standort {
  final String uuid;
  final String kundeUuid;
  final String bezeichnung;
  final String? strasse;
  final String? plz;
  final String? ort;

  /// Eigener Kontakt des Standorts (Roadmap 21.11.2026) — unabhängig vom
  /// Kunden; die E-Mail ist der Empfängervorschlag beim Protokollversand.
  final String? kontaktPerson;
  final String? kontaktEmail;
  final String? kontaktTelefon;
  final DateTime erstelltAm;
  final DateTime aktualisiertAm;

  Standort({
    String? uuid,
    required this.kundeUuid,
    required this.bezeichnung,
    this.strasse,
    this.plz,
    this.ort,
    this.kontaktPerson,
    this.kontaktEmail,
    this.kontaktTelefon,
    DateTime? erstelltAm,
    DateTime? aktualisiertAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now().toUtc(),
        aktualisiertAm = aktualisiertAm ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'kundeUuid': kundeUuid,
        'bezeichnung': bezeichnung,
        'strasse': strasse,
        'plz': plz,
        'ort': ort,
        'kontaktPerson': kontaktPerson,
        'kontaktEmail': kontaktEmail,
        'kontaktTelefon': kontaktTelefon,
        'erstelltAm': erstelltAm.toUtc().toIso8601String(),
        'aktualisiertAm': aktualisiertAm.toUtc().toIso8601String(),
      };

  factory Standort.fromJson(Map<String, dynamic> json) => Standort(
        uuid: json['uuid'] as String,
        kundeUuid: json['kundeUuid'] as String,
        bezeichnung: json['bezeichnung'] as String,
        strasse: json['strasse'] as String?,
        plz: json['plz'] as String?,
        ort: json['ort'] as String?,
        kontaktPerson: json['kontaktPerson'] as String?,
        kontaktEmail: json['kontaktEmail'] as String?,
        kontaktTelefon: json['kontaktTelefon'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        aktualisiertAm: DateTime.tryParse(
                json['aktualisiertAm'] as String? ?? '') ??
            DateTime.parse(json['erstelltAm'] as String),
      );

  Standort copyWith({
    String? bezeichnung,
    String? strasse,
    String? plz,
    String? ort,
    String? kontaktPerson,
    String? kontaktEmail,
    String? kontaktTelefon,
  }) =>
      Standort(
        uuid: uuid,
        kundeUuid: kundeUuid,
        bezeichnung: bezeichnung ?? this.bezeichnung,
        strasse: strasse ?? this.strasse,
        plz: plz ?? this.plz,
        ort: ort ?? this.ort,
        kontaktPerson: kontaktPerson ?? this.kontaktPerson,
        kontaktEmail: kontaktEmail ?? this.kontaktEmail,
        kontaktTelefon: kontaktTelefon ?? this.kontaktTelefon,
        erstelltAm: erstelltAm,
        aktualisiertAm: DateTime.now().toUtc(),
      );
}

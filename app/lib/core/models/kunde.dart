import 'package:uuid/uuid.dart';

class Kunde {
  final String uuid;
  final String name;
  final String? strasse;
  final String? plz;
  final String? ort;
  final String? kontaktEmail;
  final String? kontaktTelefon;

  /// Ein Ansprechpartner (Name) zu E-Mail/Telefon (Roadmap 20.11.2026).
  final String? ansprechpartner;
  final DateTime erstelltAm;
  final DateTime aktualisiertAm;

  Kunde({
    String? uuid,
    required this.name,
    this.strasse,
    this.plz,
    this.ort,
    this.kontaktEmail,
    this.kontaktTelefon,
    this.ansprechpartner,
    DateTime? erstelltAm,
    DateTime? aktualisiertAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now().toUtc(),
        aktualisiertAm = aktualisiertAm ?? DateTime.now().toUtc();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        'strasse': strasse,
        'plz': plz,
        'ort': ort,
        'kontaktEmail': kontaktEmail,
        'kontaktTelefon': kontaktTelefon,
        'ansprechpartner': ansprechpartner,
        'erstelltAm': erstelltAm.toUtc().toIso8601String(),
        'aktualisiertAm': aktualisiertAm.toUtc().toIso8601String(),
      };

  factory Kunde.fromJson(Map<String, dynamic> json) => Kunde(
        uuid: json['uuid'] as String,
        name: json['name'] as String,
        strasse: json['strasse'] as String?,
        plz: json['plz'] as String?,
        ort: json['ort'] as String?,
        kontaktEmail: json['kontaktEmail'] as String?,
        kontaktTelefon: json['kontaktTelefon'] as String?,
        ansprechpartner: json['ansprechpartner'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
        aktualisiertAm: DateTime.tryParse(
                json['aktualisiertAm'] as String? ?? '') ??
            DateTime.parse(json['erstelltAm'] as String),
      );

  Kunde copyWith({
    String? name,
    String? strasse,
    String? plz,
    String? ort,
    String? kontaktEmail,
    String? kontaktTelefon,
    String? ansprechpartner,
  }) =>
      Kunde(
        uuid: uuid,
        name: name ?? this.name,
        strasse: strasse ?? this.strasse,
        plz: plz ?? this.plz,
        ort: ort ?? this.ort,
        kontaktEmail: kontaktEmail ?? this.kontaktEmail,
        kontaktTelefon: kontaktTelefon ?? this.kontaktTelefon,
        ansprechpartner: ansprechpartner ?? this.ansprechpartner,
        erstelltAm: erstelltAm,
        aktualisiertAm: DateTime.now().toUtc(),
      );
}

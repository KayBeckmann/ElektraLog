import 'package:uuid/uuid.dart';

class Kunde {
  final String uuid;
  final String name;
  final String? strasse;
  final String? plz;
  final String? ort;
  final String? kontaktEmail;
  final String? kontaktTelefon;
  final DateTime erstelltAm;

  Kunde({
    String? uuid,
    required this.name,
    this.strasse,
    this.plz,
    this.ort,
    this.kontaktEmail,
    this.kontaktTelefon,
    DateTime? erstelltAm,
  })  : uuid = uuid ?? const Uuid().v4(),
        erstelltAm = erstelltAm ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        'strasse': strasse,
        'plz': plz,
        'ort': ort,
        'kontaktEmail': kontaktEmail,
        'kontaktTelefon': kontaktTelefon,
        'erstelltAm': erstelltAm.toIso8601String(),
      };

  factory Kunde.fromJson(Map<String, dynamic> json) => Kunde(
        uuid: json['uuid'] as String,
        name: json['name'] as String,
        strasse: json['strasse'] as String?,
        plz: json['plz'] as String?,
        ort: json['ort'] as String?,
        kontaktEmail: json['kontaktEmail'] as String?,
        kontaktTelefon: json['kontaktTelefon'] as String?,
        erstelltAm: DateTime.parse(json['erstelltAm'] as String),
      );

  Kunde copyWith({
    String? name,
    String? strasse,
    String? plz,
    String? ort,
    String? kontaktEmail,
    String? kontaktTelefon,
  }) =>
      Kunde(
        uuid: uuid,
        name: name ?? this.name,
        strasse: strasse ?? this.strasse,
        plz: plz ?? this.plz,
        ort: ort ?? this.ort,
        kontaktEmail: kontaktEmail ?? this.kontaktEmail,
        kontaktTelefon: kontaktTelefon ?? this.kontaktTelefon,
        erstelltAm: erstelltAm,
      );
}

import 'package:isar/isar.dart';

part 'kunde.g.dart';

@collection
class Kunde {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String name;

  String? strasse;
  String? plz;
  String? ort;
  String? kontaktEmail;
  String? kontaktTelefon;
  DateTime? erstelltAm;
}

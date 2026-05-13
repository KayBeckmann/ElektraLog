import 'package:isar/isar.dart';

part 'standort.g.dart';

@collection
class Standort {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String kundeUuid;

  late String bezeichnung;

  String? strasse;
  String? plz;
  String? ort;
  DateTime? erstelltAm;
}

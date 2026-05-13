import 'package:isar/isar.dart';

part 'verteiler.g.dart';

@collection
class Verteiler {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String standortUuid;

  late String bezeichnung;

  String? bemerkung;

  /// Anlagendaten als JSON-String (dart:convert)
  String? anlagendatenJson;

  DateTime? erstelltAm;
}

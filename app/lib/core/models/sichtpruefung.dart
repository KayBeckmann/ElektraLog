import 'package:isar/isar.dart';

part 'sichtpruefung.g.dart';

@collection
class Sichtpruefung {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String verteilerUuid;

  late DateTime pruefungDatum;

  String? prueferName;

  /// Checkliste als JSON-String
  String? checklisteJson;

  String? maengel;

  /// 'bestanden'|'mit_maengeln'|'nicht_bestanden'
  late String ergebnis;

  DateTime? erstelltAm;
}

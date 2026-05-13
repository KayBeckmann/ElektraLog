import 'package:isar/isar.dart';

part 'messung.g.dart';

@collection
class Messung {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String komponenteUuid;

  /// 'vde_0701_0702'|'dguv_v3'|'vde_0100'
  late String norm;

  late DateTime pruefungDatum;

  String? prueferName;

  /// Messwerte als JSON-String
  String? messwertJson;

  /// 'bestanden'|'nicht_bestanden'|'nicht_geprueft'
  late String ergebnis;

  String? bemerkung;
  DateTime? erstelltAm;
}

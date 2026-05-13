import 'package:isar/isar.dart';

part 'verteiler_komponente.g.dart';

@collection
class VerteilerKomponente {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String verteilerUuid;

  /// null = Wurzel-Element
  String? parentUuid;

  /// 'hauptschalter'|'rcd'|'ls_schalter'|'fi_ls'|'vorsicherung'|
  /// 'nh_sicherung'|'ueberspannung'|'sammelschiene'|'sonstige'
  late String typ;

  late String bezeichnung;

  int position = 0;

  /// Typ-spezifische Eigenschaften als JSON-String
  String? eigenschaftenJson;

  DateTime? erstelltAm;
}

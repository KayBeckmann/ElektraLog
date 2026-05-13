import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageService {
  StorageService._();
  static final StorageService I = StorageService._();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    if (kIsWeb) {
      return databaseFactoryWeb.openDatabase('elektralog.db');
    }
    final dir = await getApplicationDocumentsDirectory();
    return databaseFactoryIo.openDatabase(p.join(dir.path, 'elektralog.db'));
  }

  // Stores (one per collection)
  static final kundenStore = stringMapStoreFactory.store('kunden');
  static final standorteStore = stringMapStoreFactory.store('standorte');
  static final verteilerStore = stringMapStoreFactory.store('verteiler');
  static final komponentenStore = stringMapStoreFactory.store('komponenten');
  static final messungenStore = stringMapStoreFactory.store('messungen');
  static final sichtpruefungStore =
      stringMapStoreFactory.store('sichtpruefungen');
}

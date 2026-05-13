import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/kunde.dart';
import '../models/standort.dart';
import '../models/verteiler.dart';
import '../models/verteiler_komponente.dart';
import '../models/messung.dart';
import '../models/sichtpruefung.dart';

/// Singleton service for Isar database access.
class IsarService {
  IsarService._();

  static final IsarService _instance = IsarService._();
  static IsarService get I => _instance;

  Isar? _isar;

  /// Returns the open Isar instance, opening it first if necessary.
  Future<Isar> get instance async {
    if (_isar != null && _isar!.isOpen) return _isar!;
    _isar = await _open();
    return _isar!;
  }

  Future<Isar> _open() async {
    if (kIsWeb) {
      // Web: use a temporary directory path (in-memory, not persisted)
      return Isar.open(
        [
          KundeSchema,
          StandortSchema,
          VerteilerSchema,
          VerteilerKomponenteSchema,
          MessungSchema,
          SichtpruefungSchema,
        ],
        directory: '',
        name: 'elektralog_web',
        inspector: false,
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [
        KundeSchema,
        StandortSchema,
        VerteilerSchema,
        VerteilerKomponenteSchema,
        MessungSchema,
        SichtpruefungSchema,
      ],
      directory: dir.path,
    );
  }
}

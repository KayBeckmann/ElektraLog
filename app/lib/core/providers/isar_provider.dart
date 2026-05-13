import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

import '../database/isar_service.dart';

/// Provides a Future<Database> from the StorageService singleton.
final dbProvider = FutureProvider<Database>((ref) => StorageService.I.db);

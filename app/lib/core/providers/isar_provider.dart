import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../database/isar_service.dart';

/// Provides a Future<Isar> from the IsarService singleton.
final isarProvider = FutureProvider<Isar>((ref) async {
  return IsarService.I.instance;
});

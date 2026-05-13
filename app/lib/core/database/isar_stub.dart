// Web stub — Isar does not support web builds in version 3.x.
// This file provides no-op implementations for the web platform.
// Data is held in-memory only (not persisted across page reloads).
library isar_stub;

/// Placeholder — thrown when Isar is accessed on unsupported platform.
class IsarWebNotSupportedException implements Exception {
  @override
  String toString() => 'Isar is not available on the web platform in Phase 1. '
      'Web persistence will be added in Phase 2.';
}

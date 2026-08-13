/// Roadmap Phase 9, M9.1 — "Sync-Verhalten nach Server-Backup/Rücksetzung".
///
/// Reine Entscheidungslogik ohne Seiteneffekte (kein Netzwerk, keine
/// SharedPreferences), damit sie ohne Mocks testbar ist. [SyncService]
/// bindet sie an die eigentlichen Ein-/Ausgänge (zuletzt gespeicherte
/// Revision, Server-Antwort) an.
library;

/// Ergebnis eines Revisionsvergleichs zwischen der zuletzt bekannten und
/// der aktuell vom Server gemeldeten `syncRevision`.
enum RevisionCheck {
  /// Erster Kontakt mit diesem Server (kein lokaler Baseline-Wert
  /// gespeichert) — kein Rollback, einfach die neue Revision übernehmen.
  noBaseline,

  /// Server-Revision ist höher als zuletzt bekannt — normaler Fortschritt.
  advanced,

  /// Server-Revision unverändert — nichts Neues seit dem letzten Sync.
  unchanged,

  /// Server-Revision ist NIEDRIGER als zuletzt bekannt — starkes Indiz für
  /// ein Server-Restore auf ein älteres Backup. Ein blindes Pull-Merge
  /// würde in diesem Fall lokale, dem Server noch unbekannte Daten mit
  /// einem veralteten Serverstand überschreiben.
  rollbackDetected,
}

/// Vergleicht die zuletzt gespeicherte Revision ([lastKnown], `null` beim
/// allerersten Sync) gegen die aktuell vom Server gemeldete
/// [serverRevision] (siehe `syncRevision` im `/api/sync`-Response).
RevisionCheck evaluateSyncRevision({
  required int? lastKnown,
  required int serverRevision,
}) {
  if (lastKnown == null) return RevisionCheck.noBaseline;
  if (serverRevision < lastKnown) return RevisionCheck.rollbackDetected;
  if (serverRevision > lastKnown) return RevisionCheck.advanced;
  return RevisionCheck.unchanged;
}

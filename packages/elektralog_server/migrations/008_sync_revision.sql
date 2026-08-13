-- =============================================================================
-- ElektraLog — Migration 008: Sync-Revision (Server-Rollback-Erkennung)
--
-- Roadmap Phase 9, M9.1: "Sync-Verhalten nach Server-Backup/Rücksetzung".
--
-- Jede Firma bekommt einen monoton steigenden Zähler, der bei jeder
-- mutierenden Operation (Sync-Push, Löschungen, Protokoll-Upload) erhöht
-- wird. Wird der Server auf ein älteres Backup zurückgesetzt, springt
-- dieser Zähler zwangsläufig auf einen niedrigeren Wert zurück, weil er
-- selbst Teil der zurückgesicherten Daten ist — das ist das erkennbare
-- Signal für den Client, nicht ein fixer Zeitstempel/UUID, der beim
-- Restore ja ebenfalls einfach mitzurückgesetzt würde.
--
-- Der Client merkt sich die zuletzt gesehene Revision; sinkt die vom
-- Server gemeldete Revision unter den zuletzt bekannten Wert, wechselt
-- der Client in einen Schutzmodus statt blind zu pullen (siehe
-- app/lib/core/sync/sync_service.dart).
-- =============================================================================

ALTER TABLE firmen
  ADD COLUMN sync_revision BIGINT NOT NULL DEFAULT 0;

COMMENT ON COLUMN firmen.sync_revision IS
  'Monoton steigender Zähler, erhöht bei jeder mutierenden Sync-/Protokoll-Operation dieser Firma. Sinkt er gegenüber dem zuletzt vom Client gesehenen Wert, deutet das auf ein Server-Restore auf ein älteres Backup hin (Roadmap M9.1).';

-- =============================================================================
-- ElektraLog — Migration 003: Superadmin-Flag
-- Fügt ist_superadmin zu benutzer hinzu. Superadmins können Firmen sperren
-- und haben Zugriff auf alle Admin-Endpunkte unabhängig von ihrer firma_id.
-- =============================================================================

ALTER TABLE benutzer ADD COLUMN IF NOT EXISTS ist_superadmin BOOLEAN NOT NULL DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_benutzer_superadmin ON benutzer(ist_superadmin) WHERE ist_superadmin = true;

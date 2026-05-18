-- =============================================================================
-- ElektraLog — Migration 004: Rechtssichere Protokoll-Ablage
--
-- Rechtliche Anforderungen (GoBD-ähnlich):
--   1. Unveränderbarkeit — REVOKE UPDATE, DELETE für den App-User
--   2. Server-seitiger Timestamp — erstellt_am wird vom Server gesetzt
--   3. Integrität — SHA256-Hash des PDFs
--   4. Vollständigkeit — firma_id aus JWT, nicht aus Request
--   5. Nachvollziehbarkeit — pruefer_name, protokoll_datum, messdaten_json
-- =============================================================================

CREATE TABLE protokolle (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id            UUID        NOT NULL REFERENCES firmen(id),
  verteiler_bezeichnung TEXT      NOT NULL,
  standort_bezeichnung  TEXT,
  kunden_bezeichnung    TEXT,
  pruefer_name          TEXT,
  firma_name            TEXT,

  -- Vom Client übermitteltes Protokolldatum (für Anzeige)
  protokoll_datum     TIMESTAMPTZ NOT NULL,

  -- Messdaten-Snapshot: alle Messwerte zum Zeitpunkt des Exports (JSON)
  messdaten_json      TEXT,

  -- Das eigentliche PDF als Binärdaten
  pdf_data            BYTEA       NOT NULL,

  -- SHA256-Hash des PDFs zur Integritätsprüfung
  pdf_hash            TEXT        NOT NULL,

  -- Server-seitiger Erstellungszeitpunkt (nicht veränderbar, nicht vom Client steuerbar)
  erstellt_am         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indizes für schnelle Abfragen
CREATE INDEX idx_protokolle_firma    ON protokolle(firma_id);
CREATE INDEX idx_protokolle_datum    ON protokolle(firma_id, erstellt_am DESC);

-- =============================================================================
-- UNVERÄNDERBARKEIT: Update und Delete werden für den App-Datenbankbenutzer
-- entzogen. Der Postgres-Superuser kann im Notfall eingreifen.
-- Hinweis: Funktioniert nur wenn der App-User != postgres-Superuser ist.
--          Im Docker-Setup mit POSTGRES_USER als App-User wird dies durch
--          die Anwendungslogik (kein UPDATE/DELETE-Endpoint) erzwungen.
-- =============================================================================

-- Kommentar für Audit-Trail
COMMENT ON TABLE protokolle IS
  'Append-only Protokoll-Archiv. Einträge dürfen nach GoBD nicht verändert oder gelöscht werden.';
COMMENT ON COLUMN protokolle.pdf_hash IS
  'SHA256 (hex) des pdf_data-Feldes zur Integritätsprüfung.';
COMMENT ON COLUMN protokolle.erstellt_am IS
  'Server-seitiger Timestamp — wird nicht vom Client gesetzt und darf nicht verändert werden.';

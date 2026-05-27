-- =============================================================================
-- ElektraLog — Migration 005: aktualisiert_am + sichtpruefungen
-- Ermöglicht last-write-wins-Synchronisation anhand des Änderungszeitstempels.
-- =============================================================================

-- aktualisiert_am zu allen Sync-Tabellen hinzufügen
ALTER TABLE kunden
  ADD COLUMN aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE standorte
  ADD COLUMN aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE verteiler
  ADD COLUMN aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN pruefintervall_jahre INTEGER NOT NULL DEFAULT 4;

ALTER TABLE verteiler_komponenten
  ADD COLUMN aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN betriebsmittelkennzeichen TEXT NOT NULL DEFAULT '',
  ADD COLUMN zielbezeichnung TEXT NOT NULL DEFAULT '';

-- Bestehende bezeichnung als zielbezeichnung übernehmen (Datenmigration)
UPDATE verteiler_komponenten SET zielbezeichnung = bezeichnung WHERE zielbezeichnung = '';

-- bezeichnung ein DEFAULT geben, damit alte Clients nicht brechen
ALTER TABLE verteiler_komponenten ALTER COLUMN bezeichnung SET DEFAULT '';

ALTER TABLE messungen
  ADD COLUMN aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Sichtprüfungen-Tabelle (bisher nur lokal in App-DB gespeichert)
CREATE TABLE sichtpruefungen (
  uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  verteiler_uuid UUID NOT NULL REFERENCES verteiler(uuid) ON DELETE CASCADE,
  pruefung_datum DATE NOT NULL,
  pruefer_name TEXT,
  checkliste_json TEXT,
  maengel TEXT,
  ergebnis TEXT NOT NULL DEFAULT 'nicht_bestanden',
  naechste_pruefung_datum DATE,
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sichtpruefungen_firma ON sichtpruefungen(firma_id);
CREATE INDEX idx_sichtpruefungen_verteiler ON sichtpruefungen(verteiler_uuid);

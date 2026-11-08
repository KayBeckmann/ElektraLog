-- =============================================================================
-- ElektraLog — Migration 010: Räume und Geräte (Geräteprüfung M2)
--
-- Kunde → Standort → Raum → Gerät, unabhängig vom Verteilerbaum der
-- Anlagenprüfung. Kunde, Standort, Raum und Bezeichnung sind Pflicht; die
-- Konsistenz (Raum gehört zum Standort, Standort zum Kunden, alles zur
-- Firma) prüft zusätzlich der Server beim Sync.
-- =============================================================================

CREATE TABLE raeume (
  uuid UUID PRIMARY KEY,
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  standort_uuid UUID NOT NULL REFERENCES standorte(uuid) ON DELETE CASCADE,
  bezeichnung TEXT NOT NULL CHECK (btrim(bezeichnung) <> ''),
  bemerkung TEXT,
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE geraete (
  uuid UUID PRIMARY KEY,
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  kunde_uuid UUID NOT NULL REFERENCES kunden(uuid) ON DELETE CASCADE,
  standort_uuid UUID NOT NULL REFERENCES standorte(uuid) ON DELETE CASCADE,
  -- Kein CASCADE: ein Raum mit Geräten lässt sich nicht einzeln löschen.
  -- Beim Löschen des Standorts fallen Raum und Geräte gemeinsam weg.
  raum_uuid UUID NOT NULL REFERENCES raeume(uuid),
  bezeichnung TEXT NOT NULL CHECK (btrim(bezeichnung) <> ''),
  hersteller TEXT,
  typ TEXT,
  seriennummer TEXT,
  inventarnummer TEXT,
  schutzart TEXT,
  schutzklasse TEXT CHECK (schutzklasse IN ('I', 'II', 'III')),
  aktiv BOOLEAN NOT NULL DEFAULT true,
  inaktiv_grund TEXT,
  -- Ganze Monate (Kay, 2026-11-08): Vorauswahl 3/6/12/24, frei 1–23.
  pruefintervall_monate INTEGER CHECK (pruefintervall_monate BETWEEN 1 AND 24),
  intervall_begruendung TEXT,
  -- Letzte Prüfung vor ElektraLog. Ohne Angabe setzt die App das
  -- Erstellungsdatum als Ersatzwert ein (ersatzwert = true, kein Nachweis).
  letzte_pruefung_datum DATE,
  letzte_pruefung_ersatzwert BOOLEAN NOT NULL DEFAULT false,
  status_historie_json TEXT,
  bemerkung TEXT,
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (aktiv OR btrim(coalesce(inaktiv_grund, '')) <> '')
);

CREATE INDEX idx_raeume_firma ON raeume(firma_id);
CREATE INDEX idx_raeume_standort ON raeume(standort_uuid);
CREATE INDEX idx_geraete_firma ON geraete(firma_id);
CREATE INDEX idx_geraete_raum ON geraete(raum_uuid);
CREATE INDEX idx_geraete_standort ON geraete(standort_uuid);

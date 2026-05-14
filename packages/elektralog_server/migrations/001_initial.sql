-- =============================================================================
-- ElektraLog — Initial Schema
-- M2.2: RBAC tables, company data, measurements
-- =============================================================================

-- Firmen (Mandanten)
CREATE TABLE firmen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'aktiv', -- 'aktiv' | 'gesperrt'
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Benutzer
CREATE TABLE benutzer (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id UUID REFERENCES firmen(id) ON DELETE SET NULL,
  email TEXT NOT NULL UNIQUE,
  passwort_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'aktiv',
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RBAC: Berechtigungen (system-weit, unveränderlich)
CREATE TABLE berechtigungen (
  id TEXT PRIMARY KEY,  -- z.B. 'messungen:create'
  gruppe TEXT NOT NULL,
  bezeichnung TEXT NOT NULL
);

-- RBAC: Rollen (pro Firma)
CREATE TABLE rollen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  ist_vorlage BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (firma_id, name)
);

-- RBAC: Rollen <-> Berechtigungen
CREATE TABLE rollen_berechtigungen (
  rollen_id UUID NOT NULL REFERENCES rollen(id) ON DELETE CASCADE,
  berechtigung_id TEXT NOT NULL REFERENCES berechtigungen(id),
  PRIMARY KEY (rollen_id, berechtigung_id)
);

-- RBAC: Benutzer <-> Rollen
CREATE TABLE benutzer_rollen (
  benutzer_id UUID NOT NULL REFERENCES benutzer(id) ON DELETE CASCADE,
  rollen_id UUID NOT NULL REFERENCES rollen(id) ON DELETE CASCADE,
  firma_id UUID NOT NULL,
  PRIMARY KEY (benutzer_id, rollen_id)
);

-- Kunden, Standorte, Verteiler, Komponenten, Messungen (mit firma_id für RLS-Vorbereitung)
CREATE TABLE kunden (
  uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  strasse TEXT, plz TEXT, ort TEXT,
  kontakt_email TEXT, kontakt_telefon TEXT,
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE standorte (
  uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  kunde_uuid UUID NOT NULL REFERENCES kunden(uuid) ON DELETE CASCADE,
  bezeichnung TEXT NOT NULL,
  strasse TEXT, plz TEXT, ort TEXT,
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE verteiler (
  uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  standort_uuid UUID NOT NULL REFERENCES standorte(uuid) ON DELETE CASCADE,
  bezeichnung TEXT NOT NULL,
  bemerkung TEXT,
  anlagendaten_json TEXT,
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE verteiler_komponenten (
  uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  verteiler_uuid UUID NOT NULL REFERENCES verteiler(uuid) ON DELETE CASCADE,
  parent_uuid UUID REFERENCES verteiler_komponenten(uuid) ON DELETE CASCADE,
  typ TEXT NOT NULL,
  bezeichnung TEXT NOT NULL,
  position INTEGER NOT NULL DEFAULT 0,
  eigenschaften_json TEXT,
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE messungen (
  uuid UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  komponente_uuid UUID NOT NULL REFERENCES verteiler_komponenten(uuid) ON DELETE CASCADE,
  norm TEXT NOT NULL,
  pruefung_datum DATE NOT NULL,
  pruefer_name TEXT,
  messwert_json TEXT,
  ergebnis TEXT NOT NULL,
  bemerkung TEXT,
  sync_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indizes
CREATE INDEX idx_kunden_firma ON kunden(firma_id);
CREATE INDEX idx_standorte_firma ON standorte(firma_id);
CREATE INDEX idx_verteiler_firma ON verteiler(firma_id);
CREATE INDEX idx_komponenten_firma ON verteiler_komponenten(firma_id);
CREATE INDEX idx_messungen_firma ON messungen(firma_id);
CREATE INDEX idx_messungen_sync ON messungen(sync_uuid);

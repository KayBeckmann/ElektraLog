-- =============================================================================
-- ElektraLog — Migration 016: Kontakte, SMTP und Protokollversand
--
-- Roadmap-Nachtrag 20./21.11.2026 (Kay):
-- - Kunde: ein Ansprechpartner (Name) zu den vorhandenen Kontaktdaten.
-- - Standort: eigene Kontaktperson, E-Mail und Telefon — unabhängig vom
--   Kunden, damit Protokolle an den richtigen Standort gehen.
-- - Firma: ein SMTP-Zugang für den serverseitigen Protokollversand. Das
--   Passwort liegt nur verschlüsselt hier und wird nie ausgeliefert.
-- - Versandprotokoll je Protokoll mit Status/Fehler, getrennt vom
--   unveränderlichen PDF-Archiv. `anfrage_id` verhindert Doppelversand,
--   wenn der Client nach einem Timeout dieselbe Anfrage wiederholt.
--
-- Bestand: alle neuen Felder leer, keine Übernahme der Kundenadresse.
-- =============================================================================

ALTER TABLE kunden ADD COLUMN ansprechpartner TEXT;

ALTER TABLE standorte
  ADD COLUMN kontakt_person TEXT,
  ADD COLUMN kontakt_email TEXT,
  ADD COLUMN kontakt_telefon TEXT;

CREATE TABLE firmen_smtp (
  firma_id UUID PRIMARY KEY REFERENCES firmen(id) ON DELETE CASCADE,
  host TEXT NOT NULL CHECK (btrim(host) <> ''),
  port INTEGER NOT NULL CHECK (port BETWEEN 1 AND 65535),
  tls_modus TEXT NOT NULL CHECK (tls_modus IN ('ssl', 'starttls', 'keine')),
  absender_email TEXT NOT NULL CHECK (btrim(absender_email) <> ''),
  absender_name TEXT,
  benutzer TEXT,
  passwort_verschluesselt TEXT,
  aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE protokoll_versand (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  protokoll_id UUID NOT NULL REFERENCES protokolle(id) ON DELETE CASCADE,
  anfrage_id UUID NOT NULL,
  empfaenger TEXT NOT NULL,
  cc TEXT[] NOT NULL DEFAULT '{}',
  pdf_hash TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('laeuft', 'gesendet', 'fehler')),
  fehler TEXT,
  benutzer_id UUID REFERENCES benutzer(id) ON DELETE SET NULL,
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  abgeschlossen_am TIMESTAMPTZ,
  UNIQUE (firma_id, anfrage_id)
);
CREATE INDEX protokoll_versand_protokoll_idx ON protokoll_versand (firma_id, protokoll_id);

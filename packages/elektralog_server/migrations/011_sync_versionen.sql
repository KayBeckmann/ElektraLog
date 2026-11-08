-- =============================================================================
-- ElektraLog — Migration 011: Versionen pro Datensatz und Zuordnungs-Audit
--
-- Roadmap Geräteprüfung M3 (Kay, 2026-11-08: auch für den Anlagenbestand).
-- Jeder synchronisierte Datensatz bekommt eine Versionsnummer, die der
-- Server bei jeder übernommenen Änderung erhöht. Der Client schickt mit,
-- auf welcher Version seine Änderung beruht; weicht sie ab, meldet der
-- Server einen Konflikt statt still zu überschreiben.
--
-- Bestand: alle vorhandenen Zeilen starten bei Version 1.
-- =============================================================================

ALTER TABLE kunden ADD COLUMN version BIGINT NOT NULL DEFAULT 1;
ALTER TABLE standorte ADD COLUMN version BIGINT NOT NULL DEFAULT 1;
ALTER TABLE verteiler ADD COLUMN version BIGINT NOT NULL DEFAULT 1;
ALTER TABLE verteiler_komponenten ADD COLUMN version BIGINT NOT NULL DEFAULT 1;
ALTER TABLE messungen ADD COLUMN version BIGINT NOT NULL DEFAULT 1;
ALTER TABLE sichtpruefungen ADD COLUMN version BIGINT NOT NULL DEFAULT 1;
ALTER TABLE raeume ADD COLUMN version BIGINT NOT NULL DEFAULT 1;
ALTER TABLE geraete ADD COLUMN version BIGINT NOT NULL DEFAULT 1;

-- Jede bestätigte Änderung von Kunde/Standort/Raum eines Geräts.
-- Bewusst ohne Fremdschlüssel auf die Orte: der Verlauf bleibt lesbar,
-- auch wenn ein alter Raum später gelöscht wird.
CREATE TABLE zuordnung_audit (
  id BIGSERIAL PRIMARY KEY,
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  geraet_uuid UUID NOT NULL,
  alt_kunde_uuid UUID NOT NULL,
  alt_standort_uuid UUID NOT NULL,
  alt_raum_uuid UUID NOT NULL,
  neu_kunde_uuid UUID NOT NULL,
  neu_standort_uuid UUID NOT NULL,
  neu_raum_uuid UUID NOT NULL,
  benutzer_id UUID,
  bestaetigt_am TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_zuordnung_audit_geraet ON zuordnung_audit(firma_id, geraet_uuid);

-- =============================================================================
-- ElektraLog — Migration 009: Firmenmodule Anlagen-/Geräteprüfung
--
-- Roadmap Geräteprüfung M1. Pro Firma zwei unabhängige Schalter; ein
-- abgeschaltetes Modul wird in der App nur ausgeblendet, Daten bleiben
-- erhalten und synchronisieren weiter.
--
-- Migrationsregel (Kay, 2026-11-08): bestehende Firmen behalten nur die
-- Anlagenprüfung (Geräteprüfung aus), neue Firmen bekommen beide. Daher
-- zuerst mit DEFAULT false anlegen (füllt den Bestand) und danach den
-- Default für neue Zeilen auf true setzen.
-- =============================================================================

ALTER TABLE firmen
  ADD COLUMN modul_anlagenpruefung BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN modul_geraetepruefung BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE firmen ALTER COLUMN modul_geraetepruefung SET DEFAULT true;

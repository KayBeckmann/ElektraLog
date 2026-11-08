-- =============================================================================
-- ElektraLog — Migration 013: Prüfgerät je Messung
--
-- Kay, 2026-11-08: getrennte Prüfgeräte für Anlagen- und Geräteprüfung.
-- Jede Anlagen-Messung hält fest, mit welchem Prüfgerät sie entstanden ist;
-- das Protokoll übernimmt es von dort. Geräteprüfungen haben ihr Prüfgerät
-- bereits in geraetepruefungen.messgeraet (Migration 012).
--
-- Bestand: vorhandene Messungen bleiben ohne Angabe (NULL).
-- =============================================================================

ALTER TABLE messungen ADD COLUMN pruefgeraet TEXT;

-- =============================================================================
-- ElektraLog — Migration 014: Art des Protokolls in der Dokumentenablage
--
-- Kay, 2026-11-08: Geräteprüfungs-Protokolle (unterschrieben) landen wie die
-- Anlagenprotokolle in der Dokumentenablage. `art` unterscheidet beide;
-- verteiler_bezeichnung trägt bei Geräteprotokollen den Protokolltitel.
--
-- Bestand: alle vorhandenen Protokolle sind Anlagenprotokolle.
-- =============================================================================

ALTER TABLE protokolle
  ADD COLUMN art TEXT NOT NULL DEFAULT 'anlage'
  CHECK (art IN ('anlage', 'geraete'));

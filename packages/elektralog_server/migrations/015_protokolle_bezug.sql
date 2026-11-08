-- =============================================================================
-- ElektraLog — Migration 015: Bezug eines Protokolls
--
-- Kay, 2026-11-08: Die Web-App arbeitet online (keine lokale Kopie). Den
-- Prüfverlauf eines Verteilers bzw. Raums/Geräts liest sie deshalb aus der
-- Dokumentenablage — dafür braucht jedes Protokoll seinen Bezug (Verteiler,
-- bei Geräteprotokollen Standort, Raum oder Gerät).
--
-- Bestand: NULL (ältere Protokolle sind nur über die Liste auffindbar).
-- =============================================================================

ALTER TABLE protokolle ADD COLUMN bezug_uuid UUID;
CREATE INDEX protokolle_bezug_idx ON protokolle (firma_id, bezug_uuid);

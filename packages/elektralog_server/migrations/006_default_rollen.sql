-- =============================================================================
-- ElektraLog — Migration 006: Standardrollen für bestehende Firmen
-- Fügt Projektleiter und Monteur zu allen Firmen hinzu, die diese Rollen
-- noch nicht haben. Firmenadmin-Rolle war bereits in 001/mandanten_endpoint.
-- =============================================================================

DO $$
DECLARE
  f RECORD;
  pl_id UUID;
  mo_id UUID;
BEGIN
  FOR f IN SELECT id FROM firmen WHERE name != '_ElektraLog-System_' LOOP

    -- Projektleiter anlegen, falls noch nicht vorhanden
    IF NOT EXISTS (
      SELECT 1 FROM rollen WHERE firma_id = f.id AND name = 'Projektleiter'
    ) THEN
      pl_id := gen_random_uuid();
      INSERT INTO rollen (id, firma_id, name, ist_vorlage)
        VALUES (pl_id, f.id, 'Projektleiter', false);
      INSERT INTO rollen_berechtigungen (rollen_id, berechtigung_id)
        SELECT pl_id, id FROM berechtigungen
        WHERE id IN (
          'stammdaten:read', 'stammdaten:write',
          'messungen:create', 'messungen:read',
          'protokolle:export', 'firma:settings'
        );
    END IF;

    -- Monteur anlegen, falls noch nicht vorhanden
    IF NOT EXISTS (
      SELECT 1 FROM rollen WHERE firma_id = f.id AND name = 'Monteur'
    ) THEN
      mo_id := gen_random_uuid();
      INSERT INTO rollen (id, firma_id, name, ist_vorlage)
        VALUES (mo_id, f.id, 'Monteur', false);
      INSERT INTO rollen_berechtigungen (rollen_id, berechtigung_id)
        SELECT mo_id, id FROM berechtigungen
        WHERE id IN (
          'stammdaten:read', 'messungen:create', 'messungen:read'
        );
    END IF;

  END LOOP;
END $$;

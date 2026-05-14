-- =============================================================================
-- ElektraLog — Seed Permissions
-- M2.2: System-wide RBAC permissions
-- =============================================================================

-- Alle Berechtigungen anlegen
INSERT INTO berechtigungen (id, gruppe, bezeichnung) VALUES
  ('stammdaten:read',   'Stammdaten', 'Stammdaten lesen'),
  ('stammdaten:write',  'Stammdaten', 'Stammdaten schreiben'),
  ('messungen:create',  'Messungen',  'Messungen erfassen'),
  ('messungen:read',    'Messungen',  'Messungen lesen'),
  ('protokolle:export', 'Protokolle', 'Protokolle exportieren'),
  ('benutzer:manage',   'Benutzer',   'Benutzer verwalten'),
  ('rollen:manage',     'RBAC',       'Rollen verwalten'),
  ('firma:settings',    'Firma',      'Firmen-Einstellungen');

-- ElektraLog — Migration 007: Add company address fields
ALTER TABLE firmen ADD COLUMN IF NOT EXISTS strasse TEXT;
ALTER TABLE firmen ADD COLUMN IF NOT EXISTS plz TEXT;
ALTER TABLE firmen ADD COLUMN IF NOT EXISTS ort TEXT;

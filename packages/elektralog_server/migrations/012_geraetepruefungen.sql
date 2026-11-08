-- =============================================================================
-- ElektraLog — Migration 012: Prüfereignisse der Geräteprüfung (M5)
--
-- Ein Prüfereignis gehört zu genau einem Gerät. Entwürfe sind änderbar,
-- abgeschlossene Prüfungen nicht mehr (der Sync lehnt Änderungen ab);
-- Korrekturen entstehen als neue Prüfung mit Verweis (ersetzt_uuid).
--
-- Prüfpunkte (Besichtigen, Messen, Erproben) liegen als JSON vor: Rohwert,
-- Einheit, Grenzwert, Vergleich, Methode, Bewertung und Begründung bleiben
-- je Punkt getrennt. ort_snapshot_json hält Kunde/Standort/Raum und die
-- Gerätestammdaten zum Prüfzeitpunkt fest — ein späterer Umzug ändert
-- das Protokoll nicht.
-- =============================================================================

CREATE TABLE geraetepruefungen (
  uuid UUID PRIMARY KEY,
  firma_id UUID NOT NULL REFERENCES firmen(id) ON DELETE CASCADE,
  geraet_uuid UUID NOT NULL REFERENCES geraete(uuid) ON DELETE CASCADE,
  pruefart TEXT NOT NULL,
  pruefart_text TEXT NOT NULL,
  anlass TEXT,
  pruefung_datum DATE NOT NULL,
  pruefer_name TEXT,
  messgeraet TEXT,
  regel_version TEXT NOT NULL,
  schutzklasse TEXT CHECK (schutzklasse IN ('I', 'II', 'III')),
  status TEXT NOT NULL CHECK (status IN ('entwurf', 'abgeschlossen')),
  ergebnis TEXT CHECK (ergebnis IN ('bestanden', 'nicht_bestanden')),
  punkte_json TEXT NOT NULL,
  maengel TEXT,
  bemerkung TEXT,
  ort_snapshot_json TEXT,
  intervall_monate INTEGER CHECK (intervall_monate BETWEEN 1 AND 24),
  naechste_pruefung DATE,
  ersetzt_uuid UUID,
  abgeschlossen_am TIMESTAMPTZ,
  erstellt_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  aktualisiert_am TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  version BIGINT NOT NULL DEFAULT 1,
  CHECK (status = 'entwurf' OR (ergebnis IS NOT NULL AND pruefer_name IS NOT NULL))
);

CREATE INDEX idx_geraetepruefungen_firma ON geraetepruefungen(firma_id);
CREATE INDEX idx_geraetepruefungen_geraet ON geraetepruefungen(geraet_uuid);

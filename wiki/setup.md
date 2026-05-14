# Wiki.js Setup

> Diese Datei wird durch `README.md` ersetzt. Bitte die neue Startseite unter `wiki/README.md` verwenden.

## Wiki starten

```bash
docker-compose --profile company up -d
```

Anschließend unter **http://localhost:3000** erreichbar.

## Ersteinrichtung

1. Admin-Account erstellen
2. Sprache auf **Deutsch** setzen: Administration → Locale → de
3. Seiten aus den Markdown-Dateien dieses Verzeichnisses importieren

## Seitenstruktur (aktuell)

| Datei | Inhalt |
|---|---|
| `README.md` | Wiki-Übersicht und Ersteinrichtung |
| `erste-schritte.md` | Schnelleinstieg Solo-Modus |
| `benutzerhandbuch/monteur.md` | Bedienhandbuch Monteur |
| `installation/self-hosting.md` | Self-Hosting mit Docker |
| `technisch/architektur.md` | Architektur, Datenmodell, RBAC |

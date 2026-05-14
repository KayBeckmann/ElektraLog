# ElektraLog — Wiki

Dieses Wiki dokumentiert Installation, Bedienung und technische Architektur der ElektraLog-App.

## Wiki starten

Das Wiki läuft als Wiki.js-Instanz im Docker-Stack:

```bash
# Wiki zusammen mit Homepage und allen anderen Diensten starten
docker-compose --profile company up -d

# Nur Basisdienste (App + Backend + Postgres) ohne Wiki
docker-compose up -d
```

Nach dem Start ist das Wiki unter **http://localhost:3000** erreichbar.

## Ersteinrichtung Wiki.js

1. Browser öffnen: `http://localhost:3000`
2. Admin-Account anlegen (E-Mail + Passwort)
3. Sprache auf **Deutsch** setzen: Administration → Locale → de
4. Seiten aus den Markdown-Dateien in diesem Verzeichnis importieren oder manuell anlegen

## Seitenstruktur

| Datei | Inhalt |
|---|---|
| `erste-schritte.md` | Schnelleinstieg für Endanwender (Solo-Modus) |
| `benutzerhandbuch/monteur.md` | Bedienhandbuch für Monteure |
| `installation/self-hosting.md` | Self-Hosting mit Docker |
| `technisch/architektur.md` | Technische Architektur, Datenmodell, RBAC |

## Weiterführende Dokumente im Repo

- `README.md` — Projektübersicht und Quickstart
- `ROADMAP.md` — Entwicklungs-Roadmap und Phasen
- `docker-compose.yml` — Service-Definitionen

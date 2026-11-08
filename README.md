# ElektraLog

**Digitale Erfassung von VDE-Messungen und automatisierte Erstellung von Prüfprotokollen**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-informational)](https://flutter.dev)
[![Status](https://img.shields.io/badge/Status-Beta-orange)]()
[![Built with Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Backend: Serverpod](https://img.shields.io/badge/Backend-Serverpod-blueviolet)](https://serverpod.dev)

---

## Übersicht

ElektraLog ist eine Cross-Platform-App für Elektrotechniker und Prüfbetriebe zur digitalen Erfassung elektrischer Messungen nach **DIN VDE 0701-0702**, **DGUV V3** und **DIN VDE 0100**. Die App generiert **ZVEH-angelehnte Prüfprotokolle** als PDF und funktioniert vollständig offline — ohne Account und ohne Backend.

Sobald Sync, Mehrbenutzer und Firmenstruktur benötigt werden, schaltet die App in den **Company-Modus** mit Backend-Anbindung. Diesen gibt es als gehostete **Cloud-Variante** (20 €/Monat pauschal pro Firma) oder dank **MIT-Lizenz** vollständig **selbst gehostet** (kostenlos).

---

## Features

### Solo-Modus — kostenlos, kein Account

| Feature | Beschreibung |
|---------|-------------|
| Offline-First | Keine Internetverbindung erforderlich, alle Daten lokal |
| Stammdatenverwaltung | Kunden, Standorte, Verteiler, Betriebsmittel |
| Komponentenbaum | Freier rekursiver Baum je Verteiler (LS, RCD, FI/LS, NH-Sicherung …) |
| Anlagendaten | Netzform, Nennspannung, Frequenz, Schutzleiterart |
| Sichtprüfung | ZVEH-Checkliste als Pflichtschritt vor der Messerfassung |
| Messformulare | DIN VDE 0701-0702, DGUV V3, DIN VDE 0100 |
| Grenzwert-Bewertung | Automatische Auswertung Bestanden / Nicht bestanden |
| PDF-Export | ZVEH-angelehnte Prüfprotokolle direkt auf dem Gerät |
| Firmenmodule | Anlagenprüfung und Geräteprüfung unabhängig schaltbar (Firmenadmin, im Solo-Modus lokal) |
| Geräteprüfung | Kunde → Standort → Raum → Gerät, Prüfung nach DGUV V3 für ortsveränderliche Geräte mit Schutzklasse I/II, Intervall 3/6/12/24 oder 1–23 Monate |
| Gerätetermine | Eigene 90-Tage-Liste neben den Anlagenmessungen, Überfälliges gesondert |
| Geräteprotokolle | Übersicht (alle / aktive / fristgerecht / manuell) und Prüfblätter für Gerät, Raum oder Standort |
| Etiketten & Scan | QR-Etikett mit vollständiger UUID, Kamera- oder Handscanner öffnet das Gerät |

### Company-Modus — Cloud oder Self-Hosting

| Feature | Beschreibung |
|---------|-------------|
| Backend-Sync | Automatische Synchronisation über Serverpod-Backend |
| Multi-User | Monteure, Prüftechniker, Disponenten, Admins in einer Firma — unbegrenzt |
| RBAC | Vorgefertigte Rollen, editierbar — eigene Rollen möglich |
| Multi-Tenant | Firma-getrennte Datenhaltung via PostgreSQL Row-Level-Security |
| Multi-Device | Daten auf allen Geräten verfügbar |
| Upgrade-Flow | Lokale Solo-Daten optional ins Backend übertragen |
| Konfliktsicherer Sync | Version pro Datensatz; gleichzeitige Änderungen werden feldweise zusammengeführt statt überschrieben, Ortswechsel von Geräten nur mit Bestätigung (auditiert) |
| Selektiver Sync | Anlagen je Standort/Verteiler, Geräte je Standort oder Raum — lokal pro Arbeitsgerät |

### Preisstruktur

| Variante | Nutzer | Preis | Betrieb |
|----------|--------|-------|---------|
| Solo | 1, kein Account | **kostenlos** | lokal auf dem Gerät |
| Cloud | unbegrenzt | **20 €/Monat** pauschal pro Firma | von uns gehostet & gewartet |
| Self-Hosting | unbegrenzt | **kostenlos** (MIT-Lizenz) | auf eigener Infrastruktur |

Die Cloud- und die Self-Hosting-Variante bieten denselben Funktionsumfang. Der
Cloud-Preis deckt Hosting, Wartung, Updates und Backups ab — Self-Hosting ist dank
MIT-Lizenz kostenlos, erfordert aber eigenen Betrieb (siehe [Self-Hosting-Guide](https://wiki.elektralog.de/installation/self-hosting)).

---

## Benutzerrollen (Company-Modus)

| Rolle | Stammdaten lesen | Stammdaten schreiben | Messungen erfassen | Protokoll exportieren | Benutzerverwaltung |
|-------|:---:|:---:|:---:|:---:|:---:|
| Monteur | ✓ | — | ✓ | — | — |
| Prüftechniker | ✓ | — | ✓ | ✓ | — |
| Disponent | ✓ | ✓ | — | ✓ | — |
| Firmenadmin | ✓ | ✓ | ✓ | ✓ | ✓ |

Rollen sind vorgefertigte Vorlagen — Berechtigungen können pro Firma angepasst und eigene Rollen erstellt werden.

---

## Technologie-Stack

| Schicht | Technologie |
|---------|-------------|
| App | Flutter — Android, Windows, Linux, Web |
| Backend | Serverpod (Dart, Code-Gen, WebSockets, ORM) |
| Datenbank | PostgreSQL 16 + Row-Level-Security |
| Lokale DB | Sembast (NoSQL, `sembast` / `sembast_web`) — primär im Solo-Modus, Offline-Cache im Company-Modus |
| Sync | Operation-Queue-Pattern, idempotent via UUID |
| Auth | Serverpod Auth, JWT |
| PDF-Export | dart_pdf / printing |
| Homepage | Nginx + statisches HTML/CSS |
| Docs / Wiki | Wiki.js |

---

## Infrastruktur (Docker)

Jeder Dienst läuft in einem eigenen Docker-Container:

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   postgres  │  │  serverpod  │  │     app     │
│  (Port 5432)│  │  (API-Backend│  │ Flutter Web │
└─────────────┘  └─────────────┘  └─────────────┘
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  homepage   │  │    wiki     │  │    proxy    │
│  Landingpage│  │   Wiki.js   │  │   Traefik   │
└─────────────┘  └─────────────┘  └─────────────┘
```

PostgreSQL bedient zwei Datenbanken in einem Container: `elektralog` (App) und `wikijs` (Wiki.js).

---

## Schnellstart (Docker)

> Setzt Docker und Docker Compose voraus.

```bash
git clone https://github.com/kay-beckmann/elektralog.git
cd elektralog
cp .env.example .env
# .env anpassen (DB-Passwörter, Domain, etc.)
docker compose up -d
```

Erreichbar unter:
- App: `https://app.deinedomain.de`
- Homepage: `https://elektralog.de`
- Wiki: `https://wiki.elektralog.de`

---

## Entwicklungs-Setup

### Voraussetzungen

- Flutter SDK ≥ 3.x
- Dart SDK ≥ 3.x
- Docker + Docker Compose
- PostgreSQL (lokal oder via Docker)

### App starten

```bash
# Abhängigkeiten installieren
flutter pub get

# Android
flutter run -d android

# Web
flutter run -d chrome

# Desktop (Linux)
flutter run -d linux
```

### Backend starten

```bash
cd packages/server
docker compose -f docker-compose-dev.yml up -d  # PostgreSQL für Entwicklung
dart bin/main.dart
```

### Server-Tests

API-Tests laufen gegen den echten Handler (`lib/src/app.dart`) und ein
Wegwerf-Postgres. Die Test-Datenbank wird bei jedem Test **komplett
geleert** und mit `migrations/*.sql` neu aufgebaut — nie auf eine
produktive Datenbank zeigen lassen.

```bash
docker run -d --rm --name elektralog-test-pg -e POSTGRES_PASSWORD=test \
  -e POSTGRES_USER=test -e POSTGRES_DB=test -p 127.0.0.1:55434:5432 postgres:16-alpine
cd packages/elektralog_server
ELEKTRALOG_TEST_DB=localhost:55434:test:test:test dart test
```

Ohne `ELEKTRALOG_TEST_DB` werden die Server-Tests übersprungen.

### Web-App: online statt Kopie

Die Web-App (Büro, immer online) hält keine Daten im Browser. Angemeldet
liest sie je Ansicht über `GET /api/daten/<typ>?<filter>=…` (z. B. die
Geräte eines Raums) und schreibt versioniert über `POST /api/sync` —
dieselben Konfliktregeln wie beim Sync der Endgeräte. Ansichten laden nach
eigenen Änderungen sofort, sonst im Minutentakt neu. Umsetzung:
`app/lib/core/online/` (Repositories mit lokaler und Online-Umsetzung).
Endgeräte arbeiten unverändert lokal mit Sync und Download-Auswahl.

Der Server nutzt einen Verbindungspool: Eine einzelne Postgres-Verbindung
nimmt während einer Transaktion keine weiteren Anfragen an.

### End-to-End-Test (zwei Arbeitsgeräte gegen echten Server)

`app/test/e2e/` treibt zwei App-Instanzen (eigene lokale Datenbanken,
echte `SyncEngine`) sowie zwei Web-Sitzungen (Online-Datenschicht) gegen
einen laufenden Server: Anlage, Raumauswahl,
gleichzeitige Änderung mit Zusammenführung, bestätigter Raumwechsel,
abgeschlossene Prüfung (danach unveränderlich), Mandantengrenze,
Modul aus/an. Legt eigene fiktive Testfirmen an — **nie gegen eine
produktive Instanz laufen lassen.**

```bash
docker exec elektralog-test-pg psql -U test -d test -c "CREATE DATABASE e2e;"
cd packages/elektralog_server
POSTGRES_HOST=localhost POSTGRES_PORT=55434 POSTGRES_DB=e2e POSTGRES_USER=test \
  POSTGRES_PASSWORD=test SERVERPOD_PORT=18080 JWT_SECRET=<min. 32 Zeichen> \
  SUPERADMIN_EMAIL=e2e-admin@e2e.invalid SUPERADMIN_PASSWORD=<passwort> dart run bin/main.dart &
cd ../../app
ELEKTRALOG_E2E_URL=http://localhost:18080 \
  ELEKTRALOG_E2E_ADMIN=e2e-admin@e2e.invalid:<passwort> flutter test test/e2e/
```

Ohne die beiden Variablen wird der Test übersprungen.

### Restore-Probe

Nach dem E2E-Test liegen synthetische Daten in `e2e`. Probe:

```bash
docker exec elektralog-test-pg pg_dump -U test -d e2e --no-owner | gzip > e2e_backup.sql.gz
docker exec elektralog-test-pg psql -U test -d test -c "CREATE DATABASE e2e_restore;"
gunzip -c e2e_backup.sql.gz | docker exec -i elektralog-test-pg psql -q -U test -d e2e_restore -v ON_ERROR_STOP=1
# Tabellenbestände beider Datenbanken vergleichen, dann den Server mit
# POSTGRES_DB=e2e_restore starten: erwartet „Datenbankschema aktuell“.
```

### Datenbank-Migrationen

Der Server spielt `packages/elektralog_server/migrations/*.sql` **beim
Start selbst** ein (`lib/src/migrations.dart`) und merkt sich in der
Tabelle `schema_migrations`, was angewendet ist — auf neuen **und**
bestehenden Datenbanken. Postgres' `docker-entrypoint-initdb.d` legt nur
noch die Wiki-Datenbank an.

- Neue Schemaänderung = **neue Datei** mit der nächsten Nummer
  (`013_….sql`). Angewendete Dateien nie ändern: Der Server erkennt das
  an der Prüfsumme und startet dann nicht.
- Jede Datei läuft in einer eigenen Transaktion. Schlägt sie fehl, bleibt
  die Datenbank auf dem alten Stand und der Server startet nicht.
- Datenbanken aus der Zeit vor dem Läufer werden beim ersten Start anhand
  des vorhandenen Schemas übernommen; die idempotente `006` läuft dabei
  einmal erneut (legt fehlende Standardrollen nach).
- **Rückweg ist das Backup**, es gibt keine Down-Skripte. Vor jedem
  Server-Update mit neuer Migration:

```bash
docker compose exec -T postgres sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' \
  | gzip > "backup_vor_update_$(date +%Y%m%d_%H%M%S).sql.gz"
docker compose up -d --build serverpod
docker compose logs serverpod | grep -i migration
```

`JWT_SECRET` ist Pflicht — ohne startet der Server nicht.

---

## Dokumentation

Vollständige technische Dokumentation und Benutzerhandbuch: **[Wiki](https://wiki.elektralog.de)**

- [Benutzerhandbuch — Monteur](https://wiki.elektralog.de/handbuch/monteur)
- [Benutzerhandbuch — Firmenadmin](https://wiki.elektralog.de/handbuch/admin)
- [Self-Hosting-Guide](https://wiki.elektralog.de/installation/self-hosting)
- [API-Referenz](https://wiki.elektralog.de/api)

---

## Roadmap

Eine detaillierte, phasenbasierte Roadmap: **[ROADMAP.md](ROADMAP.md)**

Aktueller Stand: **Phasen 0–3 abgeschlossen** (Solo-Modus, Company-Modus mit Auth/RBAC/Sync, Infrastruktur, Homepage & Wiki). In Arbeit: **Phase 4 — Erweiterte Features** (Foto-Anhänge, Fälligkeitsverwaltung, digitale Unterschrift, individuelle Templates).

---

## Design

Das Design-System *Industrial Precision System* ist auf den Einsatz unter Feldbedingungen optimiert:

- **Inter** für Interface-Elemente, **JetBrains Mono** für Messwerte und technische IDs
- Hoher Kontrast, semantische Farben (Grün = bestanden, Rot = nicht bestanden, Amber = Warnung)
- Touch-Targets ≥ 44×44 px für Tablet- und Handynutzung auf Baustellen
- Kompakte Datentabellen auf Desktop, fluid 4-Column-Grid auf Mobile

---

## Contributing

Beiträge sind willkommen. Bitte öffne zunächst ein Issue, um die geplante Änderung zu diskutieren.

```bash
# Fork + Branch
git checkout -b feature/mein-feature

# Änderungen + Tests
flutter test

# Pull Request öffnen
```

Code-Stil: `flutter format .` + `flutter analyze` müssen fehlerfrei durchlaufen.

---

## Lizenz

[MIT License](LICENSE) — Copyright © 2026 Kay Beckmann

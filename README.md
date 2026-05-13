# ElektraLog

**Digitale Erfassung von VDE-Messungen und automatisierte Erstellung von Prüfprotokollen**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-informational)](https://flutter.dev)
[![Status](https://img.shields.io/badge/Status-In%20Development-yellow)]()
[![Built with Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![Backend: Serverpod](https://img.shields.io/badge/Backend-Serverpod-blueviolet)](https://serverpod.dev)

---

## Übersicht

ElektraLog ist eine Cross-Platform-App für Elektrotechniker und Prüfbetriebe zur digitalen Erfassung elektrischer Messungen nach **DIN VDE 0701-0702**, **DGUV V3** und **DIN VDE 0100**. Die App generiert **ZVEH-angelehnte Prüfprotokolle** als PDF und funktioniert vollständig offline — ohne Account und ohne Backend.

Sobald Sync, Mehrbenutzer und Firmenstruktur benötigt werden, schaltet die App in den kostenpflichtigen **Company-Modus** mit Backend-Anbindung.

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

### Company-Modus — gestaffelte Tiers

| Feature | Beschreibung |
|---------|-------------|
| Backend-Sync | Automatische Synchronisation über Serverpod-Backend |
| Multi-User | Monteure, Prüftechniker, Disponenten, Admins in einer Firma |
| RBAC | Vorgefertigte Rollen, editierbar — eigene Rollen möglich |
| Multi-Tenant | Firma-getrennte Datenhaltung via PostgreSQL Row-Level-Security |
| Multi-Device | Daten auf allen Geräten verfügbar |
| Upgrade-Flow | Lokale Solo-Daten optional ins Backend übertragen |

### Preisstruktur

| Tier | Nutzer | Preis |
|------|--------|-------|
| Solo | 1, kein Account | kostenlos |
| Team | bis 5 | auf Anfrage |
| Business | bis 20 | auf Anfrage |
| Enterprise | unbegrenzt | auf Anfrage |

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
| Lokale DB | Isar — primär im Solo-Modus, Offline-Cache im Company-Modus |
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

Aktuelle Phase: **Phase 0 — Konzept & Setup**

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

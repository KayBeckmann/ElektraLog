# Technische Architektur

## Service-Übersicht

| Service | Image / Technologie | Interner Port | Externer Port (Standard) | Profil |
|---|---|---|---|---|
| `postgres` | PostgreSQL 16 | 5432 | — (intern) | default |
| `elektralog_server` | Dart / Shelf | 8080 | — (intern) | default |
| `app` | Flutter Web + nginx | 80 | 8888 (`APP_PORT`) | default |
| `homepage` | Gethomepage | — | 8090 (`HOMEPAGE_PORT`) | company |
| `wiki` | Wiki.js | — | 3000 (`WIKI_PORT`) | company |

## Datenhierarchie

```
Firma
└── Kunde
    └── Standort
        ├── Verteiler
        │   └── Komponente (rekursiver Baum)
        │       ├── Messungen
        │       └── Sichtprüfungen
        └── Geräte
```

Kernpunkte:

- **Komponente** ist selbstreferenziell — eine Komponente kann beliebig viele Unterkomponenten haben (z. B. Sammelschiene → LS-Schalter → FI/LS).
- **Messungen** sind immer einer Komponente zugeordnet, nicht dem Verteiler direkt.
- **Geräte** sind dem Standort zugeordnet und haben eigene Prüffristen/-intervalle.
- Komponenteneigenschaften (Polzahl, I∆n, Charakteristik, Nennstrom usw.) werden als **JSONB**-Spalte in PostgreSQL gespeichert, damit verschiedene Typen ohne Schema-Änderung erweiterbar sind.

## Offline-First-Architektur

| Schicht | Technologie | Aufgabe |
|---|---|---|
| Lokale Datenbank | Sembast | Persistenz auf dem Gerät, kein SQL-Setup nötig |
| Operationswarteschlange | Sembast + Riverpod | Mutationen werden lokal gepuffert |
| Sync-Mechanismus | HTTP (Dart/Shelf REST) | Warteschlange bei Verbindungsaufbau abarbeiten |
| Idempotenz | UUID pro Datensatz | Doppelte Übertragung idempotent, keine Duplikate |

Schreibvorgänge (Messungen, Sichtprüfungen) werden zuerst lokal in Sembast gespeichert und erst dann zum Server übertragen. Die App bleibt ohne Netzwerkverbindung voll bedienbar.

## RBAC — Rollen und Berechtigungen

### Berechtigungen

| Berechtigung | Beschreibung |
|---|---|
| `messungen:create` | Messungen und Sichtprüfungen erfassen |
| `stammdaten:read` | Kunden, Standorte, Verteiler, Komponenten lesen |
| `stammdaten:write` | Stammdaten anlegen und bearbeiten |
| `protokolle:export` | PDF-Protokolle generieren und exportieren |
| `benutzer:manage` | Benutzer und Rollen verwalten |

### Vordefinierte Rollen

| Rolle | Berechtigungen |
|---|---|
| Monteur | `messungen:create`, `stammdaten:read` |
| Prüftechniker | `messungen:create`, `stammdaten:read`, `protokolle:export` |
| Disponent | `messungen:create`, `stammdaten:read`, `stammdaten:write`, `protokolle:export` |
| Firmenadmin | Alle Berechtigungen inkl. `benutzer:manage` |

## Messtypen

| Messtyp | Einsatzbereich | Besonderheiten |
|---|---|---|
| VDE 0100 | Niederspannungsanlagen (Neubau/Änderung) | Pro-Phase-Felder bei mehrpoligen Komponenten, Drehfeld bei 3-polig |
| VDE 0701-0702 | Prüfung nach Reparatur/Änderung von Elektrogeräten | Gerätebezogen |
| DGUV V3 | Prüfung elektrischer Betriebsmittel | Gerätebezogen, Prüffristen-relevant |

### VDE-0100-Felder im Detail

Bei **mehrpoligen** Komponenten (2- oder 3-polig) werden Felder für jede Phase separat erfasst:

- **L1, L2** bei 2-polig
- **L1, L2, L3** bei 3-polig
- **Drehfeld** (Rechtsfeld / Linksfeld) nur bei 3-poligen Komponenten

RCD-Felder:

- Auslösestrom: 50 % bis 100 % I∆n
- Auslösezeit: ≤ 300 ms

## Tech Stack

| Bereich | Technologie |
|---|---|
| Frontend | Flutter 3.x (Android, Web, Linux, Windows) |
| State Management | Riverpod |
| Routing | GoRouter |
| Lokale DB | Sembast |
| Backend | Dart / Shelf (HTTP-Server) |
| Datenbank | PostgreSQL 16 |
| Authentifizierung | JWT + bcrypt |
| PDF-Erzeugung | dart_pdf + printing |

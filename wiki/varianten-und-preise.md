# Varianten & Preise

ElektraLog gibt es in drei Varianten. Der Funktionsumfang der App bleibt gleich —
der Unterschied liegt in Datenhaltung, Mehrbenutzerbetrieb und Betrieb.

## Überblick

| Variante | Preis | Nutzer | Datenhaltung | Betrieb |
|----------|-------|--------|--------------|---------|
| **Solo** | kostenlos, für immer | 1, ohne Account | lokal auf dem Gerät | keiner nötig |
| **Cloud** | 20 €/Monat pauschal pro Firma | unbegrenzt | Backend (von uns gehostet) | von uns |
| **Self-Hosting** | kostenlos (MIT-Lizenz) | unbegrenzt | Backend (eigene Server) | selbst |

## Solo — kostenlos

Für Einzelanwender, die ohne Server arbeiten. Alle Daten liegen lokal auf dem
Gerät, es ist keine Registrierung nötig und die App funktioniert vollständig
offline. Enthält Stammdatenverwaltung, Komponentenbaum, Sichtprüfung, alle
Messformulare (VDE, DGUV V3) und den PDF-Export.

→ Einstieg: [Erste Schritte — Solo-Modus](erste-schritte.md)

## Cloud — 20 €/Monat pro Firma

Der **Company-Modus** als gehosteter Dienst. Ein Pauschalpreis von **20 € pro
Monat für die gesamte Firma** — unabhängig von der Anzahl der Nutzer. Enthält:

- Backend-Sync über alle Geräte
- Unbegrenzte Nutzer mit Rollen (Monteur, Prüftechniker, Disponent, Firmenadmin)
- RBAC — vorgefertigte, editierbare Rollen sowie eigene Rollen
- Mandantengetrennte Datenhaltung (PostgreSQL Row-Level-Security)
- Hosting, Wartung, automatische Updates und tägliche Backups inklusive

Der Preis deckt den kompletten Betrieb ab — es fällt kein zusätzlicher Aufwand
auf eurer Seite an.

## Self-Hosting — kostenlos (MIT-Lizenz)

Derselbe Company-Funktionsumfang wie in der Cloud-Variante, aber auf **eigener
Infrastruktur** betrieben. Dank **MIT-Lizenz** ist das kostenlos und ohne
Einschränkung möglich — volle Datenhoheit, unbegrenzte Nutzer. Betrieb, Updates
und Backups liegen in eurer Verantwortung.

→ Anleitung: [Self-Hosting mit Docker](installation/self-hosting.md)

## Welche Variante passt?

- **Einzelperson, keine Cloud nötig** → Solo
- **Firma, die sich nicht um Server kümmern will** → Cloud
- **Firma mit eigener IT / hohen Datenschutzanforderungen** → Self-Hosting

Ein Wechsel von Solo zu Cloud oder Self-Hosting ist jederzeit möglich — lokale
Daten lassen sich beim ersten Login ins Backend übertragen (siehe Upgrade-Flow).

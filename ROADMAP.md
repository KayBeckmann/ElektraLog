# Roadmap — ElektraLog

Phasenbasierte Entwicklungsplanung. Jede Phase baut auf der vorherigen auf.

## Status-Legende

| Symbol | Bedeutung |
|--------|-----------|
| ✅ | Abgeschlossen |
| 🔄 | In Arbeit |
| ✅ | Geplant |
| 💡 | Idee / Backlog |

---

## Phase 0 — Konzept & Setup

> Ziel: Lauffähige Entwicklungsumgebung, vollständiges DB-Schema, Docker-Grundgerüst.

### M0.1 — Repository & Projektstruktur

- ✅ Flutter-Projekt initialisieren (Android, Web, Windows, Linux)
- ✅ Serverpod-Projekt erstellen und mit Flutter-Client verbinden
- ✅ Monorepo-Struktur festlegen (`packages/app`, `packages/server`, `packages/shared`)
- ✅ `.gitignore`, `.editorconfig`, `analysis_options.yaml` anlegen
- ✅ Lint-Regeln und `flutter format` als Pre-Commit-Hook einrichten
- ✅ Lizenz-Header-Konvention festlegen

### M0.2 — Docker-Grundgerüst

- ✅ `docker-compose.yml` mit allen 6 Containern anlegen (`postgres`, `serverpod`, `app`, `homepage`, `wiki`, `proxy`)
- ✅ `docker-compose.dev.yml` für lokale Entwicklung (nur `postgres` + `serverpod`)
- ✅ PostgreSQL-Container: Init-Script mit zwei Datenbanken (`elektralog`, `wikijs`)
- ✅ Serverpod-Container: Dockerfile (Dart-Builder + Laufzeit-Image)
- ✅ Flutter-Web-Container: Dockerfile (Builder + Nginx)
- ✅ Traefik-Container: SSL via Let's Encrypt, Routing-Regeln
- ✅ Wiki.js-Container konfigurieren (`requarks/wiki:2`)
- ✅ Homepage-Container: Nginx + statischer Build
- ✅ `.env.example` mit allen benötigten Variablen anlegen
- ✅ Healthchecks für alle Container definieren
- ✅ Volume-Definitionen für persistente Daten (PostgreSQL, Wiki.js-Uploads)

### M0.3 — Datenbankschema (Migrationen)

- ✅ Serverpod-Migrations-Tooling einrichten
- ✅ Migration 001: `firma`, `benutzer`
- ✅ Migration 002: `kunden`, `standorte`, `verteiler` (mit `anlagendaten` JSONB)
- ✅ Migration 003: `verteiler_komponenten` (rekursiver Baum, `parent_id`, `eigenschaften` JSONB)
- ✅ Migration 004: `messungen` (mit `sync_uuid`, `messwerte` JSONB)
- ✅ Migration 005: `sichtpruefungen` (mit `checkliste` JSONB)
- ✅ Migration 006: RBAC — `berechtigungen`, `rollen`, `rollen_berechtigungen`, `benutzer_rollen`
- ✅ Row-Level-Security-Policies für alle Mandanten-Tabellen
- ✅ Performance-Indizes (`firma_id`, `parent_id`, `verteiler_id`, `sync_uuid`)
- ✅ Seed-Script: Permissions anlegen (alle Permission-Strings)
- ✅ Seed-Script: Vorgaberollen anlegen (Monteur, Prüftechniker, Disponent, Firmenadmin)

### M0.4 — Konzept-Abschluss

- ✅ ZVEH-Referenzformular beschaffen — alle Felder vollständig auflisten
- ✅ Sichtprüfungs-Checkliste finalisieren (ZVEH-Katalog)
- ✅ Konkurrenzanalyse: existierende Lösungen am Markt prüfen

---

## Phase 1 — Solo-Modus (Free Tier)

> Ziel: Vollständig funktionsfähige App ohne Backend. Messerfassung, Sichtprüfung und PDF-Export laufen komplett offline.

### M1.1 — Flutter-Grundgerüst

- ✅ App-Architektur: Riverpod (State) + GoRouter (Navigation)
- ✅ Sembast-Datenbankschema: lokale Modelle für alle Entitäten
- ✅ App-Modus-Erkennung: Solo vs. Company via `SharedPreferences`
- ✅ Navigation-Shell: Bottom Navigation Bar (Mobile) / Navigation Rail (Tablet) / Drawer (Desktop)
- ✅ Theme-System: Industrial Precision System (Inter + JetBrains Mono, Slate-Palette)
- ✅ Basis-Widgets: `StatusBadge`, `DataCard`, `SectionHeader`, `ConfirmDialog`
- ✅ Lokalisierung: Deutsch als Standardsprache, i18n-Struktur vorbereiten

### M1.2 — Kundenverwaltung

- ✅ Kundenliste (Suchbar, sortierbar)
- ✅ Kunden-Detailansicht (Stammdaten + Standortliste)
- ✅ Kunde anlegen (Formular: Name, Anschrift, Kontakt)
- ✅ Kunde bearbeiten
- ✅ Kunde löschen (mit Bestätigung, kaskadierend)
- ✅ Eingabe-Validierung (Pflichtfelder, Format)

### M1.3 — Standort & Verteiler

- ✅ Standortliste pro Kunde
- ✅ Standort-Detailansicht (Adresse + Verteilerübersicht)
- ✅ Standort anlegen / bearbeiten / löschen
- ✅ Verteilerliste pro Standort
- ✅ Verteiler-Detailansicht
- ✅ Verteiler anlegen / bearbeiten / löschen
- ✅ Anlagendaten-Formular am Verteiler
  - ✅ Nennspannung (230 V / 400 V)
  - ✅ Frequenz (50 Hz)
  - ✅ Netzform (TN-C / TN-S / TN-CS / TT / IT)
  - ✅ Anzahl Außenleiter (1 / 3)
  - ✅ Schutzleiterart (PE / PEN)
  - ✅ Max. Kurzschlussstrom (optional)
  - ✅ Bemerkung

### M1.4 — Komponentenbaum

- ✅ Rekursive Baumdarstellung (TreeView-Widget mit Einrückung und Verbindungslinien)
- ✅ Komponente hinzufügen: Typ auswählen (Hauptschalter, NH-Sicherung, Vorsicherung, RCD, LS-Schalter, FI/LS, NeoZed-Sicherung, DiaZed-Sicherung, Überspannungsableiter, Sammelschiene, Sonstige)
- ✅ Typ-spezifische Eigenschaften erfassen (Nennstrom, Pole, Charakteristik, RCD-Typ, Auslösestrom)
- ✅ NeoZed-Größen (D01 / D02 / D03) und DiaZed-Größen (DII / DIII / DIV / DV) auswählbar
- ✅ Bezeichnung und Position festlegen
- ✅ Komponente bearbeiten
- ✅ Komponente löschen (kaskadierend mit Kindern + Messungen, Bestätigung)
- ✅ Reihenfolge ändern (Position-Feld, Up/Down-Buttons)
- ✅ Baum kollabieren / expandieren (alle / einzeln)
- ✅ Typ-Icons je Komponente (Legende im UI)

### M1.5 — Sichtprüfung (ZVEH)

- ✅ Sichtprüfungs-Startbildschirm pro Verteiler
- ✅ ZVEH-Checkliste: je Punkt **drei Zustände** (Bestanden / Durchgefallen / Nicht zutreffend) per Tap-Toggle
  - ✅ Kennzeichnung vorhanden
  - ✅ Schutzleiter angeschlossen und korrekt
  - ✅ Leitungen ordnungsgemäß verlegt
  - ✅ Schutzeinrichtungen vorhanden und korrekt
  - ✅ Brandschutzabdichtungen
  - ✅ Beschriftung der Abgänge
  - ✅ Zustand des Gehäuses / Schranks
  - ✅ Verteiler abschließbar / abgeschlossen
- ✅ Inline-Status-Badge je Punkt (grün / rot / grau)
- ✅ Mängeltext-Eingabe (Freitext je Punkt oder global)
- ✅ Ergebnis-Berechnung: bestanden / mit Mängeln — „Nicht zutreffend" zählt als bestanden
- ✅ Pflicht-Sperre: Messerfassung erst nach abgeschlossener Sichtprüfung freigeschalten
- ✅ Sichtprüfungs-Verlauf pro Verteiler (Datum, Prüfer, Ergebnis)
- ✅ Sichtprüfung nachträglich bearbeiten (Bearbeiten-Button im Verlauf, Formular vorausgefüllt)
- ✅ Rückwärtskompatibilität: alte `ok`/`mangel`-Schlüssel werden migriert

### M1.6 — Geräteverwaltung (DGUV V3)

- ✅ Geräteliste pro Standort (in Standort-Detailansicht)
- ✅ Gerät anlegen: Bezeichnung, Gerätetyp, Hersteller, Seriennummer / Inventar-Nr.
- ✅ Prüfintervall in **Monaten** (max. 24 Monate, DGUV V3 / VDE 0701-0702)
  - ✅ Schnellauswahl-Chips: 6 / 12 / 18 / 24 Monate
  - ✅ Freitexteingabe (1–24) mit Validierung
- ✅ Nächste Prüfung automatisch berechnet (letztePruefung + Intervall)
- ✅ Überfälligkeits-Anzeige (`isUeberfaellig`)
- ✅ Gerät bearbeiten / löschen
- ✅ Rückwärtskompatibilität: altes `pruefintervallJahre` × 12 → Monate

### M1.7 — Messformulare

#### DIN VDE 0701-0702 (ortsveränderliche Geräte)

- ✅ Schutzleiterprüfung: Messwert-Eingabe (Ω), Grenzwert ≤ 0,3 Ω
- ✅ Isolationsmessung: Messwert (MΩ) **oder** Checkbox „Messbereichsendwert erreicht", min. 1 MΩ
- ✅ Ableitstrom: Messwert (mA), Grenzwert je Schutzklasse (SK I: 0,5 mA, SK II: 1 mA)
- ✅ Berührungsstrom: optional
- ✅ Funktionsprüfung: Checkbox
- ✅ Sicherungs-Charakteristik und Nennstrom eingeben
- ✅ Automatische Gesamtbewertung (alle Einzelwerte bestanden?)

#### DGUV V3 (Wiederholungsprüfung)

- ✅ Schutzleiterwiderstand (Ω)
- ✅ Isolationswiderstand (MΩ)
- ✅ Ableitstrom (mA)
- ✅ Funktionsprüfung (Checkbox)
- ✅ Nächstes Prüfungsdatum (Datepicker, Prüfintervall wählbar)
- ✅ Automatische Gesamtbewertung

#### DIN VDE 0100 (ortsfeste Anlagen)

- ✅ Schleifenimpedanz Zs (Ω) — polzahlabhängig (je Phase L1/L2/L3)
- ✅ Isolationswiderstand (MΩ) — polzahlabhängig
- ✅ Kurzschlussstrom Ik (A) pro Phase (min. B=5×, C=10×, D=20× Nennstrom)
- ✅ RCD-Auslösestrom: gemessen (mA) vs. Nennauslösestrom; gültig 50 %–100 % I∆n
- ✅ RCD-Auslösezeit (ms), Grenzwert ≤ 300 ms
- ✅ Nenn-I∆n aus Komponenteneigenschaften vorausgefüllt
- ✅ Drehfeldrichtung: **nur bei Mehrpoligen** (≥ 3-polig); bei Einpolschaltern ausgeblendet
- ✅ Erdungswiderstand (optional)
- ✅ Automatische Gesamtbewertung (alle Phasen + RCD-Grenzwerte)
- ✅ Kurzschlussstrom getrennt nach **L-PE** (Schutznachweis) und **L-N** (optional) je Phase
- ✅ Bei 3-phasig: **L-L-Messungen** (L1-L2, L2-L3, L1-L3) als optionale Felder
- ✅ Bewertung basiert auf L-PE-Messung (normgerecht)

#### Allgemein

- ✅ Messung bearbeiten / löschen
- ✅ Messungs-Verlauf pro Komponente (mit Datum)
- ✅ Bemerkungsfeld pro Messung

### M1.8 — PDF-Export (ZVEH-angelehnt)

- ✅ Deckblatt: Prüfer, Firma (Solo: Freitext), Datum, Auftrags-/Prüfnummer
- ✅ Abschnitt 1: Anlagendaten (Netzform, Spannung, Frequenz, Nennstrom etc.)
- ✅ Abschnitt 2: Sichtprüfung (Checkliste mit Ergebnissen, Mängeltext)
- ✅ Abschnitt 3: Komponentenbaum mit Messwerten
  - ✅ Eingerückte Baumdarstellung (Typ-Symbole, Bezeichnungen)
  - ✅ Messwerte je Komponente (tabellarisch)
  - ✅ Ergebnis-Kennzeichnung: ✓ bestanden / ✗ nicht bestanden
- ✅ Abschnitt 4: Gesamtbewertung
- ✅ Unterschriftsfeld: Prüfer + Auftraggeber (leer für Druck)
- ✅ **Protokoll pro Verteiler** (Icon-Button in Verteiler-Detailansicht)
- ✅ **Protokoll pro Standort** (Icon-Button → Verteiler-Picker → je Verteiler ein Protokoll)
- ✅ Dialog: Prüfer-Name + Datum/Ort vor Generierung abfragbar
- ✅ Printing.layoutPdf — Browser-Print-Dialog (Web) / System-Druck (Android)
- ✅ PDF teilen (System-Share-Dialog)
- ✅ **Prüfverlauf**: Nach PDF-Export wird ein `Pruefprotokoll`-Eintrag gespeichert (Datum, Prüfer, Firma)
- ✅ **Nächste Prüfung**: Termin wird aus letztem Protokolldatum + Prüfintervall berechnet und in der Verteiler-Detailansicht angezeigt (grün / orange / rot)

---

## Phase 2 — Company-Modus (Cloud & Self-Hosting)

> Ziel: Backend, Authentifizierung, RBAC und Offline-Sync. Solo-Nutzer können auf Company upgraden.

### M2.1 — Auth & Firmen-Onboarding

- ✅ Registrierung: Firmenname, E-Mail, Passwort
- ✅ E-Mail-Bestätigung (Bestätigungs-Link)
- ✅ Login / Logout
- ✅ JWT-Refresh (automatisch im Hintergrund)
- ✅ Passwort zurücksetzen (E-Mail-Link)
- ✅ Firma beim ersten Login zuordnen (neue Firma anlegen oder Einladungslink)
- ✅ Profil-Screen: Name, E-Mail, Passwort ändern

### M2.2 — Superadmin-Portal

- ✅ Superadmin-Flag (`ist_superadmin`) in `benutzer`-Tabelle (Migration 003)
- ✅ Superadmin-Login: JWT enthält `istSuperadmin`-Claim; Login gesperrter Firmen wird für Nicht-Superadmins geblockt
- ✅ Mandanten-Übersicht: `GET /api/admin/firmen` — alle Firmen, Status (aktiv / gesperrt)
- ✅ Mandant anlegen: `POST /api/admin/firmen`
- ✅ Mandant sperren / entsperren: `PATCH /api/admin/firmen/:id/status`
- ✅ Firma-Sperrung sofort wirksam via `firmaSperreMiddleware` (DB-Check pro Request)
- 📋 Mandant-Details: Benutzeranzahl, Abo-Status (Cloud aktiv / Self-Hosting) (noch offen)

### M2.3 — Serverpod API-Endpoints

- ✅ RLS-Middleware: `app.firma_id` aus JWT in PostgreSQL-Session setzen
- ✅ Kunden: CRUD-Endpoints
- ✅ Standorte: CRUD-Endpoints
- ✅ Verteiler: CRUD-Endpoints (inkl. Anlagendaten)
- ✅ Verteiler-Komponenten: CRUD-Endpoints
- ✅ Sichtprüfungen: Create/Read-Endpoints
- ✅ Messungen: Create/Read/Delete-Endpoints
- ✅ Permission-Check-Middleware (RBAC-Prüfung je Endpoint)

### M2.4 — RBAC-System

- ✅ Permission-Check-Middleware in Serverpod
- ✅ Rollen-Verwaltungs-Screen (Firmenadmin)
  - ✅ Vorgaberollen anzeigen (nicht löschbar, aber editierbar)
  - ✅ Berechtigungen einer Rolle bearbeiten (Checkbox-Liste)
  - ✅ Custom-Rolle erstellen
  - ✅ Custom-Rolle löschen (nur wenn kein Benutzer zugewiesen)
- ✅ Benutzer-Verwaltungs-Screen (Firmenadmin)
  - ✅ Benutzerübersicht: Name, E-Mail, Rolle, Status
  - ✅ Benutzer einladen (E-Mail-Link mit Einladungs-Token)
  - ✅ Rolle zuweisen / ändern
  - ✅ Benutzer deaktivieren / reaktivieren
- ✅ UI: Menüpunkte und Aktionen dynamisch nach eigenen Permissions einblenden/ausblenden

### M2.5 — Offline-Sync

- ✅ Operation-Queue in Sembast (lokales Log aller Änderungen: Create/Delete + Typ + Payload)
- ✅ Sync-Trigger: automatisch bei Netzwerkverfügbarkeit (connectivity_plus)
- ✅ Idempotente Verarbeitung auf dem Server (`sync_uuid` als Idempotenz-Key)
- ✅ Sync-Status je Datensatz: ausstehend / synchronisiert / Fehler
- ✅ Sync-Status-Anzeige (Icon in AppBar, Badge auf Einstellungen)
- ✅ Fehler-Queue: fehlgeschlagene Ops anzeigen, manuell erneut versuchen
- ✅ Stammdaten-Pull: Verteiler/Komponenten initial vom Backend laden (Read-Only für Monteure)

### M2.6 — Upgrade-Flow Solo → Company

- ✅ „Mit Konto verbinden"-Button im Solo-Modus
- ✅ Login / Registrierungs-Bildschirm erreichbar ohne Datenverlust
- ✅ Migrations-Dialog: „Möchtest du deine lokalen Daten ins Backend übertragen?" (Ja / Nein / Später)
- ✅ Migrations-Routine: lokale Sembast-Datensätze per API ins Backend schreiben (UUID erhalten)
- ✅ Migrations-Fortschrittsanzeige (Batch-Upload)
- ✅ Rollback bei Fehler (lokale Daten bleiben erhalten)

---

## Phase 3 — Infrastruktur & Außendarstellung

> Ziel: Alle Docker-Services produktionsreif, Projekt-Homepage live, Wiki befüllt, CI/CD automatisiert.

### M3.1 — Docker-Compose Produktion

- ✅ Production-Compose: Restart-Policies (`unless-stopped`), Named Volumes
- ✅ Traefik: SSL via Let's Encrypt (ACME HTTP-Challenge)
- ✅ Traefik: Routen für alle Dienste (`app.`, `wiki.`, Homepage-Root)
- ✅ PostgreSQL: Backup-Script (täglicher Dump, Rotation nach 7 Tagen)
- ✅ Monitoring-Grundlage: Container-Logs nach stdout (Traefik-Access-Log)
- ✅ `.env`-Dokumentation: alle Variablen kommentiert
- ✅ Self-Hosting-Guide im Wiki

### M3.2 — Projekt-Homepage

- ✅ Seitenstruktur: Hero / Features / Preise / FAQ / Footer
- ✅ Inhalt: Hero (Tagline, Screenshot-Mockup, Download-CTA)
- ✅ Inhalt: Feature-Kacheln (Solo vs. Company)
- ✅ Inhalt: Preis-Tabelle (Solo / Cloud / Self-Hosting)
- ✅ Inhalt: FAQ (häufige Fragen)
- ✅ Inhalt: Footer (Impressum-Link, Datenschutz-Link, GitHub-Link)
- ✅ Responsiv: Mobile-First, Breakpoints für Tablet und Desktop
- ✅ Design: konsistent mit Industrial Precision System (Slate-Palette, Inter)
- ✅ Impressum und Datenschutzerklärung (separate Seiten)

### M3.3 — Wiki (Wiki.js)

- ✅ Grundstruktur anlegen
- ✅ **Technische Dokumentation**
  - ✅ Architektur-Übersicht (Dienste, Datenfluss)
  - ✅ Datenbankschema (ER-Diagramm)
  - ✅ API-Referenz (Serverpod-Endpoints)
  - ✅ RBAC-Permissions-Tabelle
  - ✅ Sync-Protokoll (Operation-Queue-Beschreibung)
- ✅ **Benutzerhandbuch**
  - ✅ Erste Schritte (Solo-Modus)
  - ✅ Handbuch: Monteur
  - ✅ Handbuch: Prüftechniker
  - ✅ Handbuch: Disponent
  - ✅ Handbuch: Firmenadmin (Benutzerverwaltung, Rollen)
  - ✅ PDF-Protokoll exportieren
  - ✅ Upgrade Solo → Company
- ✅ **Installation & Betrieb**
  - ✅ Self-Hosting mit Docker Compose
  - ✅ Erste Einrichtung (Superadmin anlegen)
  - ✅ Backup & Restore
  - ✅ Updates einspielen

### M3.4 — CI/CD

- ✅ GitHub Actions: `flutter analyze` + `flutter test` bei jedem Push
- ✅ GitHub Actions: Dart-Tests (Serverpod) bei jedem Push
- ✅ GitHub Actions: Flutter-Web-Build + Docker-Image-Build bei Tag
- ✅ GitHub Actions: Serverpod-Docker-Image-Build bei Tag
- ✅ Release-Workflow: APK-Build (Android) + Artefakt-Upload
- ✅ Docker Hub / Gitea Registry: automatischer Push bei Release-Tag

---

## Phase 4 — Erweiterte Features

> Ziel: Funktionsumfang für den professionellen Dauerbetrieb.

### M4.1 — Foto-Anhänge

- ✅ Kamera-Integration (Flutter `image_picker`)
- ✅ Fotos zu Messungen anhängen (max. 5 Fotos je Messung)
- ✅ Fotos zu Komponenten anhängen (Ist-Zustand dokumentieren)
- ✅ Bildgalerie in der Detailansicht
- ✅ Fotos optional im PDF einbetten (verkleinert)
- ✅ Company-Modus: Fotos in Backend-Speicher hochladen (Sync)
- ✅ Speicher-Limit für Cloud-Backend definieren

### M4.2 — Fälligkeitsverwaltung

- ✅ Fälligkeitsdatum je Gerät/Komponente (aus DGUV-V3-Messung übernehmen)
- ✅ Dashboard-Widget „Fällig in X Tagen"
- ✅ Übersicht: alle Geräte nach Fälligkeit sortiert
- ✅ Filter: fällig diese Woche / diesen Monat / nächste 90 Tage / überfällig
- ✅ Push-Benachrichtigungen (optional, X Tage vor Fälligkeit)

### M4.3 — Digitale Unterschrift

- ✅ Unterschriften-Pad (Flutter `signature`-Widget, Touch/Stylus)
- ✅ Unterschrift von Prüfer und optional Auftraggeber erfassen
- ✅ Unterschriften als PNG im PDF einbetten
- ✅ Unterschrift verwerfen / erneut zeichnen

### M4.4 — Individuelle Protokoll-Templates (Company)

- ⏳ Template-Verwaltung pro Firma
- ⏳ Firmen-Logo hochladen und im Protokoll-Header anzeigen
- ⏳ Felder ein-/ausblenden (z.B. Berührungsstrom weglassen)
- ⏳ Fußzeile anpassen (Firmendaten, Kontakt)
- ⏳ Template-Vorschau

---

## Phase 5 — Enterprise & Integrationen

> Ziel: Skalierbarkeit, Importmöglichkeiten, Statistiken.

### M5.0 — PDF-Export (echte Implementierung)

- ✅ ZVEH-angelehtes Prüfprotokoll mit dart_pdf + printing
- ✅ Abschnitte: Prüfinformationen, Anlagendaten, Sichtprüfung, Messwerte, Unterschrift
- ✅ Google Fonts (Inter + JetBrains Mono) direkt aus Package
- ✅ Printing.layoutPdf — Browser-Print-Dialog (Web) / System-Druck (Android)
- ✅ QR-Etiketten-PDF (2×4 Grid auf A4, BarcodeWidget aus pdf-Package)

### M5.1 — Import

- ✅ Geräte-Import: CSV-Template bereitstellen (Dialog)
- ✅ Geräte-Import: CSV einlesen, Vorschau (erste 5 Zeilen), Bestätigung
- ✅ Kunden-Import: CSV mit Spalten name, strasse, plz, ort, kontakt_email, kontakt_telefon
- ✅ Fehlerbehandlung: invalide Zeilen rot hervorheben
- ✅ Fortschrittsanzeige (LinearProgressIndicator)
- ✅ Erreichbar über CSV-Import-Link im Drawer

### M5.2 — Prüfhistorie & Statistiken

- ✅ Dashboard: Prüfquote (% bestanden)
- ✅ Dashboard: Fehlerrate (% nicht bestanden)
- ✅ Dashboard: Überfällige Prüftermine
- ✅ Dashboard: Kunden-Anzahl
- ✅ Horizontale StatCard-Reihe mit Schwellwert-Farbgebung
- ⏳ Export: Auswertung als Excel-Tabelle

### M5.3 — QR-Code / Barcode-Etiketten

- ✅ QR-Code pro Komponente generieren (UUID-basiert, qr_flutter)
- ✅ QR-Code-Screen mit UUID-Anzeige und Druck-Button
- ✅ QR-Icon-Button direkt im KomponentenBaum
- ✅ Etiketten-Sheet als PDF drucken (2×4 = 8 Etiketten je A4-Seite)
- ⏳ Gerät per QR-Code-Scan direkt öffnen (Flutter `mobile_scanner`)

### M5.4 — Monetarisierung aktivieren

> Preismodell (Stand Juli 2026): **Solo** kostenlos · **Cloud** 20 €/Monat pauschal
> pro Firma (unbegrenzte Nutzer) · **Self-Hosting** kostenlos via MIT-Lizenz.
> Keine gestaffelten Tiers, keine Nutzerlimits.

- ⏳ Stripe-Integration: eine Subscription (Cloud, 20 €/Monat pro Firma)
- ⏳ Billing-Portal für Firmenadmins (Abo starten / kündigen / Rechnungen)
- ⏳ Cloud-Abo-Status im Backend prüfen (aktiv / gekündigt → Zugriff steuern)
- ✅ Self-Hosting ohne Lizenzschlüssel (MIT-Lizenz, frei nutzbar)
- ✅ Preise in Homepage & Wiki eingepflegt (2026-07-06)

---

## Phase 6 — UX-Verbesserungen (Backlog)

> Ziel: Alle rein technischen UX-Verbesserungen ohne externe Abhängigkeiten.

### M6.1 — Bemerkungsfelder

- ✅ Bemerkungsfeld auf Protokoll-Deckblatt (Textarea im PdfOptionsSheet → Seite 1 PDF)
- ✅ Bemerkung in Verteiler-Detailansicht (_BemerkungsKarte, wenn Feld befüllt)
- ✅ Bemerkung nachträglich an Messung ergänzen (edit_note-Icon → _BemerkungEditSheet)

### M6.2 — Eingabemaske-UX

- ✅ Sektions-Header in Messformularen (_SektionsHeader: Icon + Label + Divider)
- ✅ Sektions-Trennlinie im Komponenten-Formular (Allgemein / Typ-Eigenschaften)

### M6.3 — Workflow-Verbesserungen

- ✅ Prüfungen editierbar solange kein Protokoll erstellt (open_in_new + ConfirmDialog)
- ✅ Reihenfolge per Up/Down-Buttons im Komponenten-PopupMenu (Position-Tausch)

---

## Phase 7 — Obsidian Inbox Anforderungen (Juni 2026)

> Ziel: Behebung offener Fehler und Implementierung neuer Anforderungen aus der Obsidian-Inbox.

### M7.1 — Synchronisation & Datenintegrität
- 📋 Synchronisation: Neuster Eintrag gewinnt
- ✅ Alte Messungen nicht in neues Protokoll
- ✅ Messwerte, die in einem Protokoll sind, dürfen nicht mehr verändert werden
- ✅ Neue Messungen darf der User noch bearbeiten
- ✅ Im Protokoll wird immer nur der neuste Messwert pro BMK angezeigt.

### M7.2 — Dashboard- & UI-Optimierungen
- ✅ Dashboard dynamisieren:
  - ✅ Anstehende Termine -> Die nächsten 90 Tage
  - ✅ Aktiv -> Messungen ohne Prüfprotokoll
- ✅ Im Fenster "Prüfung erfassen" soll das BMK mit angezeigt werden
- ✅ Messwerte-Anzeige: Schleifenmessung + Isomessung in einer Tabelle anzeigen

### M7.3 — Einstellungen & API-Fixes
- 📋 Download der Archivierten Prüfprotokolle wirft einen Fehler: `{"error":"Nicht authentifiziert"}`
- ✅ In den Einstellungen die Firma inklusive Adresse vom Server übernehmen, wenn man angemeldet ist.

---

## Phase 8 — Inbox-Anforderungen Juli 2026

> Ziel: Verbesserungen aus der Obsidian-Inbox umsetzen.

### M8.1 — PDF-Verbesserungen & Download-Fix

- ✅ **Messdatum in Kopfzeile pro BMK**: Messdatum erscheint jetzt rechtsbündig im dunklen Komponenten-Header-Balken (Kopfzeile) jeder BMK-Sektion im Protokoll — auf einen Blick sichtbar, ohne Messwertdetail lesen zu müssen
- ✅ **Neueste Messung pro BMK immer abdrucken**: `filterMessungenForProtokoll()` filtert bereits korrekt (neueste pro Komponente, archivierte raus) — gilt jetzt konsequent auch im Standort-Screen; gleichzeitig `Printing.layoutPdf`-Bug im Standort-Screen behoben (war noch nicht auf `sharePdf` umgestellt)
- ✅ **PDF-Download Web + Android**: `Printing.layoutPdf` → `Printing.sharePdf` in Protokoll-Übersicht **und** Standort-Screen — kein leerer Print-Screen auf Android mehr, echter Datei-Download auf Web

### M8.2 — PDF-Archiv: Korruption durch ungetypten postgres-Parameter

- ✅ **Root Cause**: postgres 3.x `_defaultTextEncoder` kodiert `Uint8List` als PostgreSQL-Array-Literal `{37,80,...}` weil `Uint8List is List<int>` — ohne explizite Typangabe landet ASCII-Text statt Binärdaten in der BYTEA-Spalte
- ✅ **Backend-Fix**: `'pdf': TypedValue(Type.byteArray, pdfBytes)` im INSERT-Parameter des `create`-Endpoints — postgres-Bibliothek nutzt jetzt `PostgresBinaryEncoder` für korrekte Binär-Kodierung
- ✅ **Download-Endpoint**: `getPdf` expliziter `Uint8List`-Cast + `Stream<List<int>>.value(pdfBytes)` als Shelf-Body — keine Shelf-Ambiguität mehr bei `List<int>` vs. `Uint8List`
- ✅ **Deployment-Fix**: `image: elektralog-serverpod:latest` in `docker-compose.yml` explizit gesetzt — verhindert, dass `--force-recreate` das falsche (lokal gebaute) Image nimmt statt das extern importierte
- ⚠️ **Altdaten**: Alle vor dem Fix gespeicherten Protokolle in der DB enthalten korrumpierte PDFs (`{37,80,...}` als Text statt Binärdaten) — müssen neu generiert und hochgeladen werden

---

## Phase 9 — Synchronisations-Robustheit & PDF-Ablage

> Quelle: Inbox-Datei `ElektraLog.md`, übernommen am 2026-08-06 als Besprechungsnotiz. Ziel: ElektraLog muss klar definieren, wie sich Sync nach Server-Backup/Rücksetzung verhält, partielle Synchronisation erlauben und PDFs nicht direkt in der Datenbank speichern.

### M9.1 — Sync-Verhalten nach Server-Backup/Rücksetzung

**Status: erledigt 2026-08-13.** Migration 008 führt `firmen.sync_revision` ein (monoton, erhöht bei jedem Sync-Push/Delete/Protokoll-Upload). `GET /api/sync` liefert `syncRevision` mit; der Client (`SyncService`/`evaluateSyncRevision`) merkt sich den zuletzt bekannten Wert und überspringt den destruktiven Pull-Merge, sobald die Server-Revision zurückspringt — stattdessen wird erneut idempotent gepusht (Push läuft bewusst vor dem Pull) und eine deutsche Warnung angezeigt. Bleibt aktiv, bis der Server den alten Stand wieder erreicht/überholt. End-to-End gegen einen echten Docker-Compose-Stack verifiziert (Push/Pull/Delete-Revisionsverhalten + simulierter Server-Restore).

- ✅ Szenario explizit behandeln: Server wurde auf ein älteres Backup zurückgesetzt, lokale Geräte haben aber bereits neuere Daten von heute.
- ✅ Lokale neuere Daten dürfen nicht durch den älteren Serverstand gelöscht oder überschrieben werden.
- ✅ Sync muss Server-Rollback erkennen oder zumindest sicher darauf reagieren:
  - Server-Sync-Revision / Backup-Generation / Sync-Epoch einführen;
  - Client speichert zuletzt bekannte Server-Revision;
  - bei Rücksprung Warnung und Schutzmodus statt blindem Abgleich.
- ✅ Append-only-Operationen erneut idempotent hochladen, wenn sie lokal vorhanden, auf dem Server aber nach Restore fehlen.
- ⚠️ Konfliktfälle dokumentiert (siehe oben), aber nicht als granulare Einzelfall-UI ausdifferenziert — die Lösung ist bewusst grob (ganze Firma in Schutzmodus statt Konflikt je Datensatz), reicht aber für das beschriebene Szenario.
- ✅ Benutzerfeedback in Deutsch: klar anzeigen, dass ein Server-Restore erkannt wurde und lokale Daten geschützt/erneut synchronisiert werden.
- ✅ Testfälle mit simuliertem Server-Restore ergänzt (`app/test/core/sync/sync_revision_test.dart` + manuelle Docker-Compose-Verifikation).

### M9.2 — Asymmetrische Synchronisation: Upload immer vollständig, Download nach Nutzer-Auswahl

- ✅ Präzisierung 2026-08-06: Die partielle Synchronisation betrifft **nur den Download-/Synchalten-Umfang vom Server zum Endgerät**.
- 📋 Upload-Regel: Das Endgerät gleicht **immer alles lokal Vorhandene** gegen den Server ab und lädt **alles hoch, was dem Server noch nicht bekannt ist**.
  - Keine lokale Messung/Strukturänderung darf nur deshalb ungepusht bleiben, weil der Nutzer aktuell nur einen Teilbereich synchron hält.
  - Der Server muss Uploads idempotent per UUID/Revision annehmen bzw. als bereits bekannt erkennen.
  - Upload ist damit Schutz gegen Server-Backup/Rollback: lokal vorhandene, serverseitig fehlende Daten werden erneut hochgeladen.
- 📋 Download-/Synchalten-Regel: Vom Server wird nur das auf das Endgerät geladen bzw. aktuell gehalten, was der Nutzer aktiviert hat.
- 📋 Auswahl-/Filterebenen für den Download:
  - Kunde;
  - Standort;
  - Verteiler.
- 📋 Die UI muss eine klare hierarchische Auswahl anbieten:
  - zuerst Kunde wählen;
  - danach optional Standort einschränken;
  - danach optional einzelnen Verteiler einschränken.
- 📋 Leere Struktur auf dem Endgerät immer anlegen:
  - Kunde;
  - Standort;
  - Verteiler.
- 📋 Aufbau im Verteiler, also Komponentenbaum/Betriebsmittel/Prüfpunkte, wird nur heruntergeladen, wenn die Synchronisation für diesen Verteiler aktiviert ist.
- 📋 Alte Messdaten werden nur heruntergeladen, wenn dies ebenfalls aktiviert ist.
- 📋 Auswahlzustand muss sichtbar bleiben: Nutzer sieht jederzeit, ob gerade „alles", ein Kunde, ein Standort oder ein Verteiler synchron gehalten wird und ob alte Messdaten mitgeladen werden.
- 📋 Für Monteure/Prüftechniker darf die Auswahl nur Daten zeigen, auf die sie rollen-/mandantenbedingt Zugriff haben.
- 📋 Backend/API muss Filterparameter für `kundeId`, `standortId`, `verteilerId`, `includeVerteilerAufbau` und `includeAlteMessdaten` unterstützen und nur berechtigte Mandantendaten liefern.
- 📋 Offline-First-Regel bewahren: lokal vorhandene Daten bleiben nutzbar, auch wenn sie nicht im aktuellen Download-Teil-Sync enthalten sind.
- 📋 Lösch-/Archivlogik sauber trennen: „nicht im Download-Filter enthalten" bedeutet nicht „löschen".

### M9.3 — Alte Messdaten / Sync-Zeitraum als separate Download-Option

- 📋 Synchronisationsumfang für alte Messdaten auswählbar machen; diese Option betrifft den **Download vom Server**, nicht den vollständigen Upload lokaler Daten.
- 📋 Vorgesehene Optionen aus der Inbox:
  - alte Messdaten nicht laden;
  - alle Messungen;
  - die letzten 2 Messungen;
  - die letzten 4 Messungen.
- 📋 Präzisieren, ob „letzte 2/4 Messungen" pro Komponente, Verteiler oder Standort gilt; bevorzugt pro Komponente/BMK, weil das zur Protokolllogik passt.
- 📋 Zusätzlich prüfen, ob ein Datumsfenster sinnvoller ist:
  - heute;
  - letzte 7 Tage;
  - letzter Prüfzyklus;
  - benutzerdefinierter Zeitraum.
- 📋 Sync-Optionen müssen PDF-/Protokoll-Erzeugung berücksichtigen: Wenn nur wenige Messungen heruntergeladen/synchron gehalten sind, darf das Protokoll nicht so tun, als seien ältere Messungen geprüft/verfügbar.

### M9.4 — PDF-Ablage nicht direkt in der Datenbank

- 📋 Strategiewechsel für Prüfprotokoll-PDFs: PDF-Dateien nicht mehr direkt als BYTEA in PostgreSQL speichern.
- 📋 Datenbank speichert nur Metadaten und Pfad/Objekt-Key:
  - Protokoll-ID / UUID;
  - Firma/Kunde/Standort/Verteiler;
  - Erstellungsdatum;
  - Prüfer;
  - Dateipfad / Storage-Key;
  - Hash/Größe/MIME-Type;
  - optional Signatur-/Freigabestatus.
- 📋 Dateisystem-/Object-Storage-Struktur nach Inbox-Vorgabe:
  - Kunde;
  - Standort;
  - Verteiler.
- 📋 Konkretes Pfadschema definieren, z. B. `pdf_archive/<firma>/<kunde>/<standort>/<verteiler>/<yyyy>/<protokoll_uuid>.pdf`.
- 📋 Download-Endpoint liest PDF aus Storage und streamt sie authentifiziert aus.
- 📋 Zugriffsschutz muss weiterhin mandanten- und rollenbasiert über Backend laufen; keine direkten ungeschützten Dateilinks.
- 📋 Migration für vorhandene DB-PDFs planen:
  - gültige PDFs aus DB exportieren;
  - Dateien ins neue Storage schreiben;
  - DB auf Pfad/Metadaten aktualisieren;
  - beschädigte Alt-PDFs neu generieren.

### M9.5 — Tests und Abnahme für Sync/PDF-Slice

- ✅ Test: Server-Restore simulieren, lokale heutige Daten bleiben erhalten und werden erneut hochgeladen. *(nur M9.1-Teil; PDF-Storage-Tests folgen mit M9.4)*
- 📋 Test: Partielle Synchronisation Kunde/Standort lädt nur gewünschten Bereich.
- 📋 Test: Auswahl „alle / letzte 2 / letzte 4 Messungen" wirkt deterministisch.
- 📋 Test: Teil-Sync löscht keine lokalen Daten außerhalb des Filters.
- 📋 Test: PDF-Erzeugung schreibt Datei ins Storage und Metadaten in DB.
- 📋 Test: PDF-Download funktioniert über Backend mit Auth/RBAC.
- 📋 Test: DB enthält keine neuen PDF-BLOBs mehr.

---

## Nicht geplant (bewusst ausgeschlossen)

- Native iOS-App (kein Apple-Entwicklerkonto im Scope)
- Echtzeit-Kollaboration (mehrere Nutzer gleichzeitig am selben Verteiler)
- KI-gestützte Auswertung
- Integration mit Messgeräten via Bluetooth/USB (Phase 5+ falls Bedarf)

---

## Aktueller Status

**Stand: Mai 2026**

Implementierte Phasen: 0–5 vollständig, Phase 6 (UX-Backlog) in Planung

| Feature | Status |
|---------|--------|
| Solo-Modus (offline, lokale DB) | ✅ Produktiv |
| PDF-Export pro Verteiler + Standort | ✅ Produktiv |
| Komponentenbaum (inkl. NeoZed/DiaZed) | ✅ Produktiv |
| Sichtprüfung 3-Zustände (ZVEH) | ✅ Produktiv |
| Mehrphasige Messungen (VDE 0100) | ✅ Produktiv |
| RCD-Validierung (50 %–100 % I∆n, ≤ 300 ms) | ✅ Produktiv |
| Geräteverwaltung + Prüfintervall (Monate) | ✅ Produktiv |
| Fälligkeitsverwaltung | ✅ Produktiv |
| CSV-Import | ✅ Produktiv |
| Statistik-Dashboard | ✅ Produktiv |
| QR-Code-Etiketten | ✅ Produktiv |
| Digitale Unterschrift | ✅ Produktiv |
| Company-Modus (Auth + Backend) | ✅ Produktiv |
| RBAC-Rollensystem | ✅ Produktiv |
| Offline-Sync | ✅ Produktiv |
| Projekt-Homepage | ✅ Produktiv |
| Wiki.js Dokumentation | ✅ Konfiguriert |
| CI/CD (GitHub Actions) | ✅ Aktiv |
| Einstellungen (Prüfer/Firma/Gerät persistent) | ✅ Produktiv |
| Sichtprüfung jederzeit öffenbar | ✅ Produktiv |
| Bemerkungsfelder & Workflow-UX | ✅ Produktiv |
| Individuelle Templates | ⏳ braucht Designentscheidung |
| Stripe-Monetarisierung | ⏳ braucht Stripe-Account |

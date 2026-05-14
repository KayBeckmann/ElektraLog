# Benutzerhandbuch — Monteur

## Rolle und Berechtigungen

Der Monteur darf:

- Stammdaten **lesen** (Kunden, Standorte, Verteiler, Komponenten)
- Messungen **erfassen und bearbeiten**
- Sichtprüfungen **durchführen**

Der Monteur darf **nicht**:

- Stammdaten anlegen oder ändern
- PDF-Protokolle exportieren (`protokolle:export` fehlt)
- Benutzer verwalten

## Navigation

Die App folgt der Datenhierarchie:

```
Kunden → Standorte → Verteiler → Komponentenbaum
```

Über die Zurück-Schaltfläche oder die Breadcrumb-Leiste kann jederzeit zur übergeordneten Ebene navigiert werden.

## Geräteverwaltung

### Geräte an einem Standort finden

Navigation: **Standort auswählen → Geräte**

Die Liste zeigt alle Geräte, die dem Standort zugeordnet sind.

### Prüffristen verstehen

| Spalte | Bedeutung |
|---|---|
| Letzte Prüfung | Datum der letzten abgeschlossenen Messung |
| Prüfintervall | Konfiguriertes Wiederholungsintervall (z. B. 12 Monate) |
| Nächste Prüfung | Errechnetes Fälligkeitsdatum |
| Status | Grün = fällig in der Zukunft, Gelb = bald fällig, Rot = überfällig |

## Messung erfassen (VDE 0100)

### Voraussetzung: Sichtprüfung abgeschlossen

Die Sichtprüfung (3-Zustands-Checkliste) muss vollständig bewertet sein, bevor eine Messung gestartet werden kann.

### Messfelder nach Komponententyp

#### Einpolige Komponenten (1-polig)

Nur ein Satz Felder für Phase **L** (Leiterschleifen-Widerstand, Isolationswiderstand, etc.).

#### Mehrpolige Komponenten (2- oder 3-polig)

Felder erscheinen **pro Phase**:

| Phase | Felder |
|---|---|
| L1 | Messwerte für Phase 1 |
| L2 | Messwerte für Phase 2 |
| L3 | Messwerte für Phase 3 (nur bei 3-polig) |

#### RCD-spezifische Felder

| Feld | Anforderung |
|---|---|
| Auslösestrom | 50 % bis 100 % des Nennfehlerstroms I∆n |
| Auslösezeit | ≤ 300 ms |
| Prüfstrom-Richtung | Positiv / Negativ |

#### Drehfeld

Das Drehfeld-Feld erscheint **nur** bei 3-poligen Komponenten. Mögliche Werte: Rechtsfeld / Linksfeld.

### Ablauf einer Messung

1. Komponente in der Navigation auswählen
2. **Messung → „+" (Neu)** tippen
3. Messtyp auswählen (VDE 0100, VDE 0701-0702, DGUV V3)
4. Alle relevanten Felder ausfüllen
5. **Speichern** — die Messung wird sofort lokal gespeichert

Bei aktiver Verbindung zum Server wird die Messung automatisch synchronisiert. Im Offline-Betrieb landet sie in der Warteschlange und wird beim nächsten Verbindungsaufbau übertragen.

## Sichtprüfung — Workflow

1. Komponente auswählen → **Sichtprüfung**
2. Jeden Prüfpunkt auf einen der drei Zustände setzen:
   - **Bestanden** — kein Mangel
   - **Durchgefallen** — Mangel vorhanden (Bemerkungsfeld erscheint)
   - **Nicht zutreffend** — Punkt irrelevant für diese Komponente
3. Bei „Durchgefallen": kurze Beschreibung des Mangels eintragen
4. **Abschließen** — Status der Sichtprüfung wird auf „Abgeschlossen" gesetzt

## Komponententypen — Übersicht

| Typ | Kürzel | Typische Felder |
|---|---|---|
| Hauptschalter | HS | Polzahl, Nennstrom |
| NH-Sicherung | NH | Nennstrom, Charakteristik |
| Vorsicherung | VS | Nennstrom, Charakteristik |
| RCD | RCD | I∆n, Auslösestrom, Auslösezeit |
| LS-Schalter | LS | Polzahl, Nennstrom, Charakteristik |
| FI/LS-Kombination | FI/LS | Polzahl, I∆n, Nennstrom |
| NeoZed D01 | D01 | Nennstrom |
| NeoZed D02 | D02 | Nennstrom |
| NeoZed D03 | D03 | Nennstrom |
| DiaZed DII | DII | Nennstrom |
| DiaZed DIII | DIII | Nennstrom |
| DiaZed DIV | DIV | Nennstrom |
| DiaZed DV | DV | Nennstrom |
| Überspannungsableiter | UA | Schutzpegel |
| Sammelschiene | SB | Querschnitt |
| Sonstige | — | Freitext-Beschreibung |

Komponenteneigenschaften (Polzahl, I∆n, Charakteristik usw.) werden vom Disponenten oder Firmenadmin beim Anlegen der Stammdaten hinterlegt.

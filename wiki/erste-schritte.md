# Erste Schritte — Solo-Modus

Diese Anleitung richtet sich an Einzelanwender, die ElektraLog ohne eigenen Server nutzen (Solo-Modus, lokale Datenbank).

## App öffnen

- **Web:** Browser öffnen und die App-URL aufrufen (z. B. `http://localhost:8888` bei Self-Hosting)
- **Android:** App aus dem Store installieren und starten
- **Desktop (Linux/Windows):** Executable starten

Beim ersten Start wird automatisch eine lokale Sembast-Datenbank angelegt. Keine Registrierung erforderlich.

## Stammdaten anlegen

Die Daten sind hierarchisch organisiert. Die Reihenfolge beim ersten Einrichten:

### 1. Kunde anlegen

Navigation: **Kunden → „+" (Neu)**

Pflichtfelder: Name, optional Adresse und Kontaktdaten.

### 2. Standort anlegen

Navigation: **Kunde auswählen → Standorte → „+" (Neu)**

Ein Standort ist eine physische Adresse oder ein Gebäude beim Kunden.

### 3. Verteiler anlegen

Navigation: **Standort auswählen → Verteiler → „+" (Neu)**

Ein Verteiler entspricht einem Schaltschrank oder Sicherungskasten. Pro Standort sind mehrere Verteiler möglich.

### 4. Komponenten anlegen

Navigation: **Verteiler auswählen → Komponenten → „+" (Neu)**

Komponenten bilden den Komponentenbaum innerhalb des Verteilers. Verfügbare Typen:

- Hauptschalter, NH-Sicherung, Vorsicherung
- RCD, LS-Schalter, FI/LS
- NeoZed (D01/D02/D03), DiaZed (DII/DIII/DIV/DV)
- Überspannungsableiter, Sammelschiene, Sonstige

Relevante Eigenschaften (je nach Typ): Polzahl, Charakteristik, Nennstrom, I∆n.

## Sichtprüfung durchführen

Die Sichtprüfung muss vor der Messung abgeschlossen sein.

Navigation: **Komponente auswählen → Sichtprüfung**

Jeder Prüfpunkt hat drei Zustände:

| Symbol | Bedeutung |
|---|---|
| Bestanden | Prüfpunkt erfüllt |
| Durchgefallen | Mangel festgestellt |
| Nicht zutreffend | Prüfpunkt nicht anwendbar |

Alle Punkte müssen bewertet werden, bevor die Messung gestartet werden kann.

## Messung erfassen

Navigation: **Komponente auswählen → Messung → „+" (Neu)**

Je nach Komponententyp erscheinen unterschiedliche Felder (siehe [Monteur-Handbuch](benutzerhandbuch/monteur.md) für Details zu VDE-0100-Feldern).

Nach dem Speichern wird die Messung der Komponente zugeordnet und ist offline verfügbar.

## PDF-Protokoll erstellen

### Protokoll für einen Verteiler

Navigation: **Verteiler auswählen → Protokoll → PDF erstellen**

Das Protokoll enthält alle Komponenten und Messungen des Verteilers.

### Protokoll für einen Standort

Navigation: **Standort auswählen → Protokoll → PDF erstellen**

Ein Picker erscheint: Auswahl, welche Verteiler in das Protokoll aufgenommen werden sollen.

### Digitale Unterschrift

Nach der PDF-Vorschau kann eine Unterschrift direkt auf dem Gerät gezeichnet werden (Touchscreen oder Maus). Die Unterschrift wird in das finale PDF eingebettet.

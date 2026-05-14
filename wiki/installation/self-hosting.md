# Self-Hosting mit Docker

## Voraussetzungen

- **Docker** (aktuelle stabile Version)
- **docker-compose v1** (`docker-compose`, nicht `docker compose`)
- **Git**
- Empfohlener RAM: mindestens 1 GB, Postgres benötigt ca. 256 MB

## Installation

### 1. Repository klonen

```bash
git clone https://github.com/your-org/elektralog.git
cd elektralog
```

### 2. Umgebungsvariablen konfigurieren

```bash
cp .env.example .env
```

Datei `.env` mit einem Editor öffnen und die Pflichtfelder befüllen (siehe Abschnitt [Wichtige .env-Variablen](#wichtige-env-variablen)).

### 3. Dienste starten

```bash
# Basisdienste: App + Backend + PostgreSQL
docker-compose up -d

# Alle Dienste inkl. Homepage und Wiki
docker-compose --profile company up -d
```

Die App ist danach unter `http://localhost:8888` erreichbar.

## Wichtige .env-Variablen

| Variable | Standard | Beschreibung |
|---|---|---|
| `APP_PORT` | `8888` | Externer Port der Flutter-Web-App (nginx) |
| `POSTGRES_USER` | — | Datenbankbenutzer (Pflicht) |
| `POSTGRES_PASSWORD` | — | Datenbankpasswort (Pflicht, sicheres Passwort wählen) |
| `POSTGRES_DB` | — | Datenbankname (Pflicht) |
| `JWT_SECRET` | — | Geheimnis für JWT-Signierung — **mindestens 32 Zeichen** |
| `WIKI_PORT` | `3000` | Port für Wiki.js |
| `HOMEPAGE_PORT` | `8090` | Port für die Homepage |

Alle weiteren Variablen sind in `.env.example` dokumentiert.

## Reverse Proxy (nginx / Caddy)

Der Docker-Stack enthält **keinen** Reverse Proxy. Für den Produktionsbetrieb mit HTTPS muss ein eigener Proxy vorgelagert werden.

Beispiel-nginx-Konfiguration (Ausschnitt):

```nginx
server {
    listen 443 ssl;
    server_name elektralog.example.com;

    location / {
        proxy_pass http://127.0.0.1:8888;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Für Caddy genügt ein Eintrag in der `Caddyfile`:

```
elektralog.example.com {
    reverse_proxy localhost:8888
}
```

## PostgreSQL-Backup

Das Backup-Skript liegt unter `docker/postgres/backup.sh`.

### Manuell ausführen

```bash
bash docker/postgres/backup.sh
```

Das Skript erstellt einen `pg_dump` im Verzeichnis `docker/postgres/backups/` mit Zeitstempel.

### Automatisch per Cron

```
# Täglich um 02:00 Uhr sichern
0 2 * * * /bin/bash /pfad/zu/elektralog/docker/postgres/backup.sh >> /var/log/elektralog-backup.log 2>&1
```

## Updates einspielen

```bash
# Neuesten Stand holen
git pull

# Images neu bauen
docker-compose build

# Dienste neu starten (Downtime < 30 s)
docker-compose up -d
```

Bei Datenbankmigrationen werden diese automatisch beim Start des Backend-Containers ausgeführt.

## Dienste und Ports

| Dienst | Interner Port | Standard externer Port |
|---|---|---|
| PostgreSQL | 5432 | — (nur intern) |
| Backend (Dart/Shelf) | 8080 | — (nur intern) |
| App (nginx) | 80 | 8888 |
| Homepage | — | 8090 |
| Wiki.js | — | 3000 |

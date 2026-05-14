#!/bin/bash
# ElektraLog PostgreSQL Backup
# Usage: ./backup.sh (läuft im postgres-Container)
set -e
BACKUP_DIR="${BACKUP_DIR:-/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"
pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | gzip > "$BACKUP_DIR/elektralog_$TIMESTAMP.sql.gz"
# Behalte nur die letzten 7 Backups
ls -t "$BACKUP_DIR"/elektralog_*.sql.gz | tail -n +8 | xargs -r rm
echo "Backup erstellt: elektralog_$TIMESTAMP.sql.gz"

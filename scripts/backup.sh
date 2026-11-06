#!/bin/bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$ROOT_DIR/backups/offsite-simulation"
AGE_KEY="$HOME/.config/study-now/age-key.txt"

AGE_RECIPIENT="age13e47hl8zgf5txwe0mhq9mk7waayhk0u0wlk34xqc8w0rjje07elqu5ydx2"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

if [[ ! -f "$AGE_KEY" ]]; then
  echo "ERROR: age private key not found"
  exit 1
fi

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_FILE="$BACKUP_DIR/study_now-$TIMESTAMP.archive.gz.age"

echo "Starting MongoDB backup..."

docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T mongo \
  sh -c 'mongodump \
    --host 127.0.0.1 \
    --port 27017 \
    --username "$MONGO_INITDB_ROOT_USERNAME" \
    --password "$MONGO_INITDB_ROOT_PASSWORD" \
    --authenticationDatabase admin \
    --db study_now \
    --archive \
    --gzip' \
  | age -r "$AGE_RECIPIENT" -o "$BACKUP_FILE"

chmod 600 "$BACKUP_FILE"

if [[ ! -s "$BACKUP_FILE" ]]; then
  echo "ERROR: backup file is empty"
  exit 1
fi

echo "Removing encrypted backups older than 7 days..."
find "$BACKUP_DIR" -type f -name '*.archive.gz.age' -mmin +10080 -print -delete

echo "Backup completed successfully."
echo "File: $BACKUP_FILE"
ls -lh "$BACKUP_FILE"

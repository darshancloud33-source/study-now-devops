#!/bin/bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="$ROOT_DIR/backups/offsite-simulation"
AGE_KEY="$HOME/.config/study-now/age-key.txt"

BACKUP_FILE="${1:-$(find "$BACKUP_DIR" -type f -name '*.age' | sort | tail -n 1)}"

if [[ -z "$BACKUP_FILE" || ! -f "$BACKUP_FILE" ]]; then
  echo "ERROR: Backup file not found"
  exit 1
fi

if [[ ! -f "$AGE_KEY" ]]; then
  echo "ERROR: age private key not found"
  exit 1
fi

if [[ "${RESTORE_CONFIRM:-}" != "YES" ]]; then
  echo "ERROR: Restore replaces collections included in the backup."
  echo "Review the backup, then run with RESTORE_CONFIRM=YES."
  exit 1
fi

TEMP_DIR="$(mktemp -d)"
CONTAINER_ARCHIVE="/tmp/study-now-restore.archive.gz"

cleanup() {
  docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T mongo \
    sh -c 'rm -f /tmp/study-now-restore.archive.gz' \
    >/dev/null 2>&1 || true
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "Decrypting backup..."
age -d \
  -i "$AGE_KEY" \
  -o "$TEMP_DIR/restore.archive.gz" \
  "$BACKUP_FILE"

echo "Copying archive into MongoDB container..."
CONTAINER_ID="$(docker compose -f "$ROOT_DIR/docker-compose.yml" ps -q mongo)"

if [[ -z "$CONTAINER_ID" ]]; then
  echo "ERROR: MongoDB container is not running"
  exit 1
fi

docker cp "$TEMP_DIR/restore.archive.gz" \
  "$CONTAINER_ID:$CONTAINER_ARCHIVE"

echo "Restoring MongoDB collections..."
docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T mongo sh -c '
  mongorestore \
    --drop \
    --gzip \
    --archive=/tmp/study-now-restore.archive.gz \
    --username "$MONGO_INITDB_ROOT_USERNAME" \
    --password "$MONGO_INITDB_ROOT_PASSWORD" \
    --authenticationDatabase admin \
    --nsInclude="study_now.*"
'

echo "Restore completed successfully."

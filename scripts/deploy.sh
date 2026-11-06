#!/bin/bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

UPSTREAM_FILE="$ROOT_DIR/docker/nginx/upstream.conf"
BACKUP_FILE="$(mktemp)"
SWITCHED=false

cleanup() {
  rm -f "$BACKUP_FILE"
}
trap cleanup EXIT

if [[ ! -f "$UPSTREAM_FILE" ]]; then
  echo "ERROR: Nginx upstream configuration not found"
  exit 1
fi

cp "$UPSTREAM_FILE" "$BACKUP_FILE"

if grep -q 'server app-blue:3000;' "$UPSTREAM_FILE"; then
  ACTIVE_SERVICE="app-blue"
  TARGET_SERVICE="app-green"
elif grep -q 'server app-green:3000;' "$UPSTREAM_FILE"; then
  ACTIVE_SERVICE="app-green"
  TARGET_SERVICE="app-blue"
else
  echo "ERROR: Could not identify the active application"
  exit 1
fi

rollback() {
  echo "Restoring traffic to $ACTIVE_SERVICE..."
  cp "$BACKUP_FILE" "$UPSTREAM_FILE"
  docker compose exec -T nginx nginx -t
  docker compose exec -T nginx nginx -s reload
}

echo "Active: $ACTIVE_SERVICE"
echo "Deployment target: $TARGET_SERVICE"

echo "Building inactive application..."
docker compose build "$TARGET_SERVICE"

echo "Starting updated application..."
docker compose up -d --no-deps --force-recreate "$TARGET_SERVICE"

CONTAINER_ID="$(docker compose ps -q "$TARGET_SERVICE")"

if [[ -z "$CONTAINER_ID" ]]; then
  echo "ERROR: Target container was not created"
  exit 1
fi

echo "Waiting for readiness health check..."

HEALTH="starting"

for attempt in $(seq 1 30); do
  HEALTH="$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER_ID")"

  if [[ "$HEALTH" == "healthy" ]]; then
    break
  fi

  if [[ "$HEALTH" == "unhealthy" ]]; then
    echo "ERROR: Target application is unhealthy"
    exit 1
  fi

  sleep 2
done

if [[ "$HEALTH" != "healthy" ]]; then
  echo "ERROR: Health check timed out"
  exit 1
fi

echo "Target application is healthy."

cat > "$UPSTREAM_FILE" <<NGINX
upstream study_now_app {
    server $TARGET_SERVICE:3000;
    keepalive 16;
}
NGINX

if ! docker compose exec -T nginx nginx -t; then
  echo "ERROR: Invalid Nginx configuration"
  cp "$BACKUP_FILE" "$UPSTREAM_FILE"
  exit 1
fi

if ! docker compose exec -T nginx nginx -s reload; then
  echo "ERROR: Nginx reload failed"
  rollback
  exit 1
fi

SWITCHED=true

echo "Nginx configuration validated and reloaded."
echo "Deployment successful."
echo "Traffic switched from $ACTIVE_SERVICE to $TARGET_SERVICE."

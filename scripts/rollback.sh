#!/bin/bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

UPSTREAM_FILE="$ROOT_DIR/docker/nginx/upstream.conf"

if grep -q 'server app-green:3000;' "$UPSTREAM_FILE"; then
    TARGET_SERVICE="app-blue"
elif grep -q 'server app-blue:3000;' "$UPSTREAM_FILE"; then
    TARGET_SERVICE="app-green"
else
    echo "ERROR: Cannot identify active application"
    exit 1
fi

CONTAINER_ID="$(docker compose ps -q "$TARGET_SERVICE")"

if [[ -z "$CONTAINER_ID" ]]; then
    echo "ERROR: Rollback target is not running"
    exit 1
fi

HEALTH="$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER_ID")"

if [[ "$HEALTH" != "healthy" ]]; then
    echo "ERROR: Rollback target is not healthy"
    exit 1
fi

echo "Switching traffic to $TARGET_SERVICE..."

TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT

cat > "$TEMP_FILE" <<NGINX
upstream study_now_app {
    server $TARGET_SERVICE:3000;
    keepalive 16;
}
NGINX

cp "$TEMP_FILE" "$UPSTREAM_FILE"

docker compose exec -T nginx nginx -t
docker compose exec -T nginx nginx -s reload

echo "Rollback successful."
echo "Traffic now routes to $TARGET_SERVICE."

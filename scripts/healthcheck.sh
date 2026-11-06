#!/bin/bash
set -Eeuo pipefail

HEALTH_URL="${HEALTH_URL:-http://localhost:8081/health}"
WEBHOOK_FILE="$HOME/.config/study-now/discord-webhook-url"

if curl --fail --silent --show-error --max-time 10 "$HEALTH_URL" >/dev/null; then
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') HEALTHY: Application health check passed."
    exit 0
fi

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') ALERT: Application health check failed."

if [[ ! -s "$WEBHOOK_FILE" ]]; then
    echo "ERROR: Discord webhook is not configured; alert was not sent."
    exit 1
fi

WEBHOOK_URL="$(cat "$WEBHOOK_FILE")"

curl --fail --silent --show-error --max-time 10 \
    -H "Content-Type: application/json" \
    -d '{"content":"ALERT: Study Now application health check failed. Please investigate the application and Docker containers."}' \
    "$WEBHOOK_URL"

echo "Discord alert sent."

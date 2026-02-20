#!/bin/bash
set -e

COMPOSE_FILE="docker-compose.lightsail.yml"
APP_DIR="/home/ubuntu/nihongo_ecom"

cd "$APP_DIR"

echo "=== Deploying nihongo_ecom ==="

# 1. Pull latest code
echo "→ Pulling latest code..."
git pull origin main

# 2. Build new images
echo "→ Building images..."
docker compose -f $COMPOSE_FILE build web

# 3. Run migrations
echo "→ Running migrations..."
docker compose -f $COMPOSE_FILE run --rm web bin/rails db:migrate

# 4. Restart app + sidekiq (nginx/db/redis giữ nguyên)
echo "→ Restarting app..."
docker compose -f $COMPOSE_FILE up -d web sidekiq

# 5. Wait and health check
echo "→ Waiting for app to start..."
sleep 10

HEALTH=$(curl -sf http://localhost/health || echo "FAIL")
if [ "$HEALTH" = "FAIL" ]; then
  echo "✗ Health check failed! Check logs:"
  echo "  docker compose -f $COMPOSE_FILE logs web --tail 30"
  exit 1
fi

echo "✓ Health check passed"

# 6. Cleanup old images
echo "→ Cleaning up old images..."
docker image prune -f

echo "=== Deploy complete ==="

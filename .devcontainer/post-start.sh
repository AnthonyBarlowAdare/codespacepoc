#!/bin/bash
# Runs every time the Codespace starts (including restarts)

# --------------------------------------------------
# 1. Ensure Docker daemon is running
# --------------------------------------------------
if ! docker info &>/dev/null 2>&1; then
    echo "🐳 Waiting for Docker daemon..."
    sleep 3
fi

# --------------------------------------------------
# 2. Start database + LocalStack if compose file exists
# --------------------------------------------------
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ] || [ -f "compose.yaml" ]; then
    echo "🗄️  Starting services (db, localstack)..."
    docker compose up -d db localstack 2>/dev/null || true
fi

# --------------------------------------------------
# 3. Quick health check
# --------------------------------------------------
echo ""
echo "🚀 Codespace ready!"
echo ""

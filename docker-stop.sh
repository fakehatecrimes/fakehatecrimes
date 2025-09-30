#!/bin/bash
set -e

echo "🛑 Stopping containers (but keeping volumes and data)..."
docker-compose stop

echo "✅ Containers stopped. To start again, run ./docker-start.sh"


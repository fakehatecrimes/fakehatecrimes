#!/bin/bash
set -e
echo "🐚 Opening MySQL shell inside the db container..."
docker-compose exec db mysql -u root

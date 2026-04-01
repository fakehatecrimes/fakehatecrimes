#!/bin/bash
set -e  # Exit immediately if a command fails

echo "Run 'mysql -h 127.0.0.1 -u root -p'"

docker-compose down
docker-compose up -d
docker-compose exec db bash


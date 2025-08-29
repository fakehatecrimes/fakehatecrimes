#!/bin/bash
set -e
echo "In one of the bash shells with the prompt root@AHEXNUMBER:/app# enter rails server -b 0.0.0.0 -p 3000"

echo "🚀 Starting containers..."
docker-compose up -d

echo "🐚 Attaching to web container shell..."
docker-compose exec web bash


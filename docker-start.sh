#!/bin/bash
set -e
echo "In one of the bash shells with the prompt root@AHEXNUMBER:/app# enter "
echo "rails server -b 0.0.0.0 -p 3003 "
echo "or run script docker-rails-3003.sh"

echo "🚀 Starting containers..."
docker-compose up -d

echo "🐚 Attaching to web container shell..."
docker-compose exec web bash


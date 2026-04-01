#!/bin/bash
set -e  # Exit immediately if a command fails

echo "🛠 Cleaning up old containers and volumes..."
docker-compose down --volumes

# Ensure Gemfile.lock exists
rm -f Gemfile.lock
touch Gemfile.lock

echo "📦 Building images from scratch..."
docker-compose build --no-cache

# Ensure Gemfile.lock inside container
docker-compose run --rm web bash -c "touch Gemfile.lock"

echo "💎 Installing gems with Bundler 1.17.3..."
docker-compose run --rm web bundle _1.17.3_ install

echo "🗄 Creating database..."
docker-compose run --rm web rake db:create

echo "✅ Setup complete. Run ./docker-start.sh to launch your app."



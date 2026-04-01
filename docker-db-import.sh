#!/bin/bash
set -e

echo "📥 Creating databases if they don't exist..."
docker exec -i fakehatecrimes-db-1 mysql -u root -e "CREATE DATABASE IF NOT EXISTS fakehatecrimesdevelopment;"
docker exec -i fakehatecrimes-db-1 mysql -u root -e "CREATE DATABASE IF NOT EXISTS fakehatecrimestest;"

echo "📥 Importing schema/data into databases..."
docker exec -i fakehatecrimes-db-1 mysql -u root fakehatecrimesdevelopment < db/database.sql.txt
docker exec -i fakehatecrimes-db-1 mysql -u root fakehatecrimestest < db/database.sql.txt
echo "✅ Import complete."

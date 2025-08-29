#!/bin/bash
set -e

docker exec -i new_docker_built_rails_app-db-1 mysql -u root fakehatecrimesdevelopment < db/database.sql.txt
docker exec -i new_docker_built_rails_app-db-1 mysql -u root fakehatecrimestest < db/database.sql.txt
echo "Running Docker shell from which you can run mysql..."
docker-compose exec db bash


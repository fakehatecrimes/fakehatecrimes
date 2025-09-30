#!/bin/bash
set -e
docker exec -i fakehatecrimes-db-1 mysqldump -u root fakehatecrimesdevelopment > db/database.sql.txt
echo "✅ Export complete."


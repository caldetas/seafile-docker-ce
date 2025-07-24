#!/usr/bin/env bash

SCRIPT_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
cd "$SCRIPT_DIR"

set -a; source .env; set +a

echo "Starting restore process..."

# Restore database dumps
echo "Restoring MySQL databases..."
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" ccnet_db < backup/db/ccnet.sql
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" seafile_db < backup/db/seafile.sql
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" seahub_db < backup/db/seahub.sql

echo "Database restore complete."

# Restore seafile data
echo "Restoring seafile-data directory..."
rsync -aHvr backup/seafile-data/ data/seafile/seafile-data/

echo "Data restore complete."

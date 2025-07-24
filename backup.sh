#!/bin/bash

SCRIPT_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
cd $SCRIPT_DIR

set -a; source .env; set +a

mkdir -p backup/db
mkdir -p backup/seafile-data

echo "Performing backup..."

docker compose exec db mysqldump -u root --password=$DB_ROOT_PASSWD --single-transaction --routines ccnet_db > backup/db/ccnet.sql
docker compose exec db mysqldump -u root --password=$DB_ROOT_PASSWD --single-transaction --routines seafile_db > backup/db/seafile.sql
docker compose exec db mysqldump -u root --password=$DB_ROOT_PASSWD --single-transaction --routines seahub_db > backup/db/seahub.sql

echo "DB backup finished - check output"

rsync -vr data/seafile/seafile-data/ backup/seafile-data

echo "Data backup finished - check output"

  #!/usr/bin/env bash
  set -euo pipefail

  SCRIPT_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
  RESTORE_DIR="/mnt/hetzner-box/backup/nixcz/restore"
  DATA_DIR="$SCRIPT_DIR/data/seafile"
  SEAFILE_DATA_BLOCKS_DIR="/mnt/nas/seafile-data" #if actual data is stored on external mount
  cd "$SCRIPT_DIR"

  set -a; source  /run/secrets/seafile/.env; set +a

  echo "Starting restore process..."

  echo $RESTORE_DIR$SCRIPT_DIR
  echo $RESTORE_DIR$DATA_DIR
  echo $SEAFILE_DATA_BLOCKS_DIR


  mkdir -p $RESTORE_DIR
  rm -fr $RESTORE_DIR/* || true
  borgmatic extract --archive latest --destination $RESTORE_DIR


# Restore database dumps
echo "Restoring MySQL databases..."
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" ccnet_db < $RESTORE_DIR$SCRIPT_DIR/backup/db/ccnet.sql
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" seafile_db < $RESTORE_DIR$SCRIPT_DIR/backup/db/seafile.sql
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" seahub_db < $RESTORE_DIR$SCRIPT_DIR/backup/db/seahub.sql

echo "Database restore complete."

# Restore seafile data
echo "Restoring seafile data directories..."
rsync -aHr $RESTORE_DIR$DATA_DIR/ $DATA_DIR/
echo "Restoring seafile data blocks directories..."

mkdir -p $SEAFILE_DATA_BLOCKS_DIR
rsync -aHr $RESTORE_DIR$SEAFILE_DATA_BLOCKS_DIR/ $SEAFILE_DATA_BLOCKS_DIR #$DATA_DIR/seafile-data/ for local install
chown -R root:root $SEAFILE_DATA_BLOCKS_DIR #only necessary with external block storage

chown -R root:root $DATA_DIR
rm -fr $RESTORE_DIR/* || true

echo "Data restore complete. Restarting Docker Compose.."

systemctl stop seafile-docker-compose.service
systemctl start seafile-docker-compose.service

echo "Restoration complete. Exiting.."

  #!/usr/bin/env bash

  SCRIPT_DIR="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
  RESTORE_DIR="/mnt/hetzner-box/backup/nixcz/restore"
  DATA_DIR="$SCRIPT_DIR/data/seafile"
  cd "$SCRIPT_DIR"

  set -a; source  /run/secrets/seafile/.env; set +a

  echo "Starting restore process..."


  mkdir -p $RESTORE_DIR
  rm -fr $RESTORE_DIR/* || true
  borgmatic extract --archive latest --destination $RESTORE_DIR

  echo $RESTORE_DIR$SCRIPT_DIR
  echo $RESTORE_DIR$DATA_DIR

# Restore database dumps
echo "Restoring MySQL databases..."
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" ccnet_db < $RESTORE_DIR$SCRIPT_DIR/backup/db/ccnet.sql
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" seafile_db < $RESTORE_DIR$SCRIPT_DIR/backup/db/seafile.sql
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" seahub_db < $RESTORE_DIR$SCRIPT_DIR/backup/db/seahub.sql

echo "Database restore complete."

# Restore seafile data
echo "Restoring seafile-data directory..."
rsync -aHvr $RESTORE_DIR$DATA_DIR/ $DATA_DIR/
chown -R root:root $DATA_DIR #necessary?
rm -fr $RESTORE_DIR/* || true

echo "Data restore complete. Restarting Docker Compose.."

systemctl stop seafile-docker-compose.service
systemctl start seafile-docker-compose.service

echo "Restoration complete. Exiting.."

  #!/usr/bin/env bash
  set -euo pipefail

  #the restore directory ($RESTORE_DIR) should contain these two folders from the backup:
  #    - seafile-data # external storage blocks folder
  #    - seafile-docker-ce # git conf folder with dbs

  # first reinstall seafile fresh (delete git folder and rebuild)
  # second uncomment the external storage line in docker-compose
  # third run sudo ./setup.sh

  SCRIPT_DIR="/home/caldetas/git/seafile-docker-ce"
  RESTORE_DIR="/tmp/restore"
  cd "$SCRIPT_DIR"

  set -a; source  /run/secrets/seafile/.env; set +a

  echo "Starting restore process..."

  echo $SCRIPT_DIR
  echo $RESTORE_DIR

# Restore database dumps
echo "Restoring MySQL databases..."
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" ccnet_db < $RESTORE_DIR/seafile-docker-ce/backup/db/ccnet.sql
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" seafile_db < $RESTORE_DIR/seafile-docker-ce/backup/db/seafile.sql
docker compose exec -T db mysql -u root --password="$DB_ROOT_PASSWD" seahub_db < $RESTORE_DIR/seafile-docker-ce/backup/db/seahub.sql
echo "Database restore complete."


systemctl stop seafile-docker-compose.service


# Restore seafile data
echo "Restoring seafile data directories..."
rsync -aHr $RESTORE_DIR/seafile-docker-ce/data/seafile/ $SCRIPT_DIR/data/seafile/ #settings and structure folder (eg. library permissions)
rsync -aHr $RESTORE_DIR/seafile-data/ $SCRIPT_DIR/data/seafile/seafile-data # data blocks
echo "Finished restoring seafile data blocks directories..."

#needs root as owner
sudo chown -R root:root $SCRIPT_DIR/data

# external storage needs root as owner
#rsync -aHr $RESTORE_DIR$SEAFILE_DATA_BLOCKS_DIR/ $DATA_DIR/
#chown -R root:root $SEAFILE_DATA_BLOCKS_DIR #only necessary with external block storage
#chown -R root:root $DATA_DIR

echo "Data restore complete. Restarting Docker Compose.."

systemctl start seafile-docker-compose.service

echo "Restoration complete. Exiting.."

# todo: local restore should be downloadable and uploadable via web interface
#       right now fastest way to restore files is to connect seafile client to local instance (http://127.0.0.1:8000)
#       tried so far and only working with seafile client:
# .env:
#       SEAFILE_SERVER_HOSTNAME=127.0.0.1
#       SEAFILE_SERVER_PROTOCOL=http
#
# seafile-docker-ce/data/seafile/conf/seahub_settings.py:
# append the following lines
#       FILE_SERVER_ROOT = 'http://127.0.0.1:8000/seafhttp'
#       CSRF_TRUSTED_ORIGINS = ['http://127.0.0.1:8000', 'http://localhost:8000']
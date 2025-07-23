docker exec -it seafile sed -i 's/bind = "127.0.0.1:8000"/bind = "0.0.0.0:8000"/' /opt/seafile/conf/gunicorn.conf.py
echo "CSRF_TRUSTED_ORIGINS = ['https://seafile.caldetas.com']" | sudo tee -a data/seafile/conf/seahub_settings.py > /dev/null
docker exec -it seafile /opt/seafile/seafile-server-latest/seahub.sh restart





# Import SQL dumps into their respective databases
docker exec -i seafile-mysql mysql -uroot -p$ROOT_PASSWD seafile_db < ./seafile_db
docker exec -i seafile-mysql mysql -uroot -p$ROOT_PASSWD ccnet_db < ./ccnet_db
docker exec -i seafile-mysql mysql -uroot -p$ROOT_PASSWD seahub_db < ./seahub_db
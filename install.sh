#!/bin/bash

for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d= | awk '{ print substr( $0, 3 ) }')
   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+3}"
   export "$KEY"="$VALUE"
done

service_name="${installer__service_name:-sh_runner_app.service}"

sudo chmod 777 /etc/systemd/system/
poetry install --no-interaction --no-ansi --only main --no-root
poetry run python installer.py "$@"
sudo chmod 755 /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl start "$service_name"
sudo systemctl enable  "$service_name"
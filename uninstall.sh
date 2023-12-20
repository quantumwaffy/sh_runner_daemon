#!/bin/bash

for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d= | awk '{ print substr( $0, 3 ) }')
   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+3}"
   export "$KEY"="$VALUE"
done

service_name="${installer__service_name:-sh_runner_app.service}"

sudo systemctl stop "$service_name"
sudo systemctl disable "$service_name"
sudo rm /etc/systemd/system/"$service_name"
sudo systemctl daemon-reload
sudo systemctl reset-failed

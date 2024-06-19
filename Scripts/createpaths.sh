#!/bin/sh

echo "INFO: create paths"
IMMICH_PATH=/opt/services/immich
BASEDIR="$(dirname "$0")"

mkdir -p $IMMICH_PATH
chown -R immich:immich $IMMICH_PATH
mkdir -p /var/log/immich
chown -R immich:immich /var/log/immich

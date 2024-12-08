#!/bin/sh

echo "INFO: create paths"

. ./config.sh || exit 1

if [ -z "$TAG" ]; then
  echo "DEBUG: config not working"
  exit 1
fi

# IMMICH_PATH=/opt/services/immich
# BASEDIR="$(dirname "$0")"

mkdir -p $IMMICH_PATH
chown -R immich:immich $IMMICH_PATH
mkdir -p /var/log/immich
chown -R immich:immich /var/log/immich

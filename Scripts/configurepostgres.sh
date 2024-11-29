#!/bin/sh

set -eux

echo "INFO: configure postgresql"

# shellcheck disable=SC1091
. ./config.sh

if [ -z "$TAG" ]; then
  echo "DEBUG: config not working"
  exit 1
fi

ME="$(whoami)"

if [ "$USER" != "$ME" ]; then
  sudo -u "$USER" "$0" "$@"
else
  PASSWD="$1"

  psql-17 postgres << EOF
create database immich;
create user immich with encrypted password '$PASSWD';
grant all privileges on database immich to immich;
ALTER USER immich WITH SUPERUSER;
EOF

fi
exit 0

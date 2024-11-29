#!/bin/sh

set -eux

IMMICH_PATH="/opt/services/immich"
REALUSER="$(whoami)"

deleteUser() {
  echo "INFO: deleting user"
  dscl . -delete "/Users/immich" && \
  dscl . -delete "/Groups/immich"
}

uninstallDaemons() {
  echo "INFO: uninstalling daemons"
  launchctl bootout system /Library/LaunchDaemons/com.immich.machine.learning.plist
  launchctl bootout system /Library/LaunchDaemons/com.immich.plist
  rm -f /Library/LaunchDaemons/com.immich*plist
}

deletePostgresDB() {
  echo "INFO: deleting PostgreSQL immich user and database"
  sudo -u "$REALUSER" psql-17 postgres << EOF
drop database immich;
drop user immich;
EOF
}


uninstallDaemons
deleteUser
deletePostgresDB
echo "INFO: deleting $IMMICH_PATH"
rm -rf "$IMMICH_PATH"

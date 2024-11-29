#!/bin/sh

export TAG="v1.121.0"
export IMMICH_PATH="/opt/services/immich"
export APP="$IMMICH_PATH/app"
BASEDIR="$(dirname "$0")"
export BASEDIR
export PATH="/usr/local/bin:$PATH"

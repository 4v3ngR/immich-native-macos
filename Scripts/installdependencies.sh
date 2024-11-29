#!/bin/sh

set -eux

ME=$(whoami)

if [ "$USER" != "$ME" ]; then
  su -l "$USER" -c "$0" "$@"
else
  echo "INFO:  install dependencies"

  export PATH="/usr/local/bin:$PATH"

  [ -z "$(which brew)" ] && echo "Brew is not installed" && exit 1

  cd /tmp/
  brew install \
    ffmpeg \
    node \
    npm \
    pgvector \
    postgresql@17 \
    python@3.11 \
    redis \
    vips \
    wget
  brew services restart postgresql@17
  brew services restart redis
  cd -
fi

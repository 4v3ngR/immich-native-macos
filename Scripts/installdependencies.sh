#!/bin/sh

ME=$(whoami)

if [ "$USER" != "$ME" ]; then
  su -l $USER -c "$0" $* || exit 1
else
  echo "INFO:  install dependencies"

  export PATH=/usr/local/bin:/opt/homebrew/bin:$PATH

  [ -z "$(which brew)" ] && echo "Brew is not installed" && exit 1

  cd /tmp/
  DEPS="cmake postgresql node pgvector redis ffmpeg vips wget npm python@3.11"
  brew install $DEPS
  brew services restart postgresql
  brew services restart redis
  cd -
fi

#!/bin/sh

set -eux

echo "INFO: create user"

# shellcheck disable=SC1091
. ./config.sh
if [ -z "$TAG" ]; then
  echo "DEBUG: config not working"
  exit 1
fi

sudo -u immich echo 2> /dev/null || (
dscl . -create "/Groups/immich" && \
  dscl . -create "/Groups/immich" RealName immich && \
  dscl . -create "/Groups/immich" passwd "*" && \
  dscl . -create "/Groups/immich" gid 9999 && \
  dscl . -create "/Users/immich" && \
  dscl . -create "/Users/immich" UserShell /sbin/nologin && \
  dscl . -create "/Users/immich" RealName immich && \
  dscl . -create "/Users/immich" UniqueID 9999 && \
  dscl . -create "/Users/immich" PrimaryGroupID 9999 && \
  dscl . -create "/Users/immich" NFSHomeDirectory "$HOME" && \
  dscl . -create "/Users/immich" passwd "*" && \
  dscl . -create "/Groups/immich" GroupMembership immich
)

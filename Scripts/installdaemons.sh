#!/bin/sh

set -eux

echo "INFO:  install daemons"

launchctl bootstrap system /Library/LaunchDaemons/com.immich.plist
launchctl bootstrap system /Library/LaunchDaemons/com.immich.machine.learning.plist

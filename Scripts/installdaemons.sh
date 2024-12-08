#!/bin/sh

echo "INFO:  install daemons"

# blindly try to unload
launchctl unload -w /Library/LaunchDaemons/com.immich.plist > /dev/null 2>&1
launchctl unload -w /Library/LaunchDaemons/com.immich.machine.learning.plist > /dev/null 2>&1

launchctl load -w /Library/LaunchDaemons/com.immich.plist && \
launchctl load -w /Library/LaunchDaemons/com.immich.machine.learning.plist

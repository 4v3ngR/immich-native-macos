#!/bin/sh

set -eux

install_logfile="$1"
rm -f "$install_logfile"
touch "$install_logfile"
chmod 666 "$install_logfile"
open "$install_logfile"

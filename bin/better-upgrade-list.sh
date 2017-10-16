#!/bin/sh

set -e
cd -- "$(dirname -- "$0")/.."

. ./lib/better-upgrade-list.lib.sh
if [ "$1" = "-" ]; then
	better_apt_upgrade_list
else
	apt-get upgrade -s | better_apt_upgrade_list
fi

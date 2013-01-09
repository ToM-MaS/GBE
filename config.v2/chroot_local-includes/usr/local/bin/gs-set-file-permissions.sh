#!/bin/bash
#
# Gemeinschaft 5
# Enforce file permissions
#
# Copyright (c) 2012, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

# General settings
[ -f /etc/gemeinschaft/system.conf ] && source /etc/gemeinschaft/system.conf || echo "FATAL ERROR: Local configuration file in /etc/gemeinschaft/system.conf missing"

# check each command return codes for errors
#
set -e

chown -R "${GS_USER}"."${GS_GROUP}" "${GS_DIR}" /var/log/gemeinschaft

# Allow members of the GS system group to modify+upgrade files
chmod -R g+w "${GS_DIR}"

# Restrict access to configuration and logfiles
chmod 0770 /var/log/gemeinschaft

# add GS system user to freeswitch group
usermod -a -G freeswitch ${GS_USER} 

# Set permissions for FreeSwitch configurations
chown -R ${GS_USER}.freeswitch "${GS_DIR_LOCAL}/freeswitch/scripts/ini"
find "${GS_DIR_LOCAL}/freeswitch/scripts/ini" -type d -exec chmod 0750 {} \;
find "${GS_DIR_LOCAL}/freeswitch/scripts/ini" -type f -exec chmod 0640 {} \;

if [ -f /var/lib/freeswitch/.odbc.ini ]; then
	chmod 440 /var/lib/freeswitch/.odbc.ini
	chown freeswitch.freeswitch /var/lib/freeswitch/.odbc.ini
fi

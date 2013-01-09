#!/bin/bash
#
# Gemeinschaft 5
# Enforce file permissions and security settings
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

# General settings
[ -f /etc/gemeinschaft/system.conf ] && source /etc/gemeinschaft/system.conf || echo "FATAL ERROR: Local configuration file in /etc/gemeinschaft/system.conf missing"

# check each command return codes for errors
#
set -e

# Group memberships for GS_USER
if id -u ${GS_USER} >/dev/null 2>&1; then
	usermod -g ${GS_GROUP} ${GS_USER} 2>&1 >/dev/null
	usermod -a -G freeswitch ${GS_USER} 2>&1 >/dev/null
fi

# Group memberships for user gsmaster
if id -u gsmaster >/dev/null 2>&1; then
	usermod -g ${GS_GROUP} gsmaster 2>&1 >/dev/null
	usermod -a -G freeswitch gsmaster 2>&1 >/dev/null
fi

# GS program files
chown -vR "${GS_USER}"."${GS_GROUP}" "${GS_DIR}"

# FreeSwitch configurations
chown -vR ${GS_USER}.freeswitch "${GS_DIR_LOCAL}/freeswitch/scripts/ini" "${GS_DIR_LOCAL}/freeswitch/conf"
find "${GS_DIR_LOCAL}/freeswitch/scripts/ini" "${GS_DIR_LOCAL}/freeswitch/conf" -type d -exec chmod -v 0750 {} \;
find "${GS_DIR_LOCAL}/freeswitch/scripts/ini" "${GS_DIR_LOCAL}/freeswitch/conf" -type f -exec chmod -v 0640 {} \;
if [ -f /var/lib/freeswitch/.odbc.ini ]; then
	chown -v freeswitch.freeswitch /var/lib/freeswitch/.odbc.ini
	chmod -v 0440 /var/lib/freeswitch/.odbc.ini
fi

# FreeSwitch variable files
chown -vR freeswitch.freeswitch "${GS_DIR_LOCAL}/freeswitch/db" "${GS_DIR_LOCAL}/freeswitch/recordings" "${GS_DIR_LOCAL}/freeswitch/storage"
find "${GS_DIR_LOCAL}/freeswitch/db" "${GS_DIR_LOCAL}/freeswitch/recordings" "${GS_DIR_LOCAL}/freeswitch/storage" -type d -exec chmod -v 0770 {} \;
find "${GS_DIR_LOCAL}/freeswitch/db" "${GS_DIR_LOCAL}/freeswitch/recordings" "${GS_DIR_LOCAL}/freeswitch/storage" -type f -exec chmod -v 0660 {} \;

# FreeSwitch files
chown -v ${GS_USER}.root /usr/share/freeswitch/sounds
find /usr/share/freeswitch/sounds -type d -exec chmod -vR 0755 {} \;
find /usr/share/freeswitch/sounds -type f -exec chmod -vR 0644 {} \;

# GS_USER homedir
chown -vR ${GS_USER}.${GS_GROUP} /var/lib/${GS_USER}
chmod -vR 0770 /var/lib/${GS_USER}
chmod -v 0440 "${GS_MYSQL_PASSWORD_FILE}"

# Logfiles
chown -vR "${GS_USER}"."${GS_GROUP}" /var/log/gemeinschaft
chmod -v 0770 /var/log/gemeinschaft

# Spooling directories
chown -vR freeswitch.root /var/spool/freeswitch

# Allow GS service account some system commands via sudo
echo "Cmnd_Alias SHUTDOWN = /sbin/shutdown -h now" >> /etc/sudoers.d/gemeinschaft
echo "Cmnd_Alias REBOOT = /sbin/shutdown -r now" >> /etc/sudoers.d/gemeinschaft
echo "${GS_USER} ALL = (ALL) NOPASSWD: SHUTDOWN, REBOOT" >> /etc/sudoers.d/gemeinschaft

# System configurations
chown -v root.root /etc/sudoers.d/*
chmod -v 0440 /etc/sudoers.d/*

#!/bin/bash
#
# Gemeinschaft 5
# Change between production and development state
#
# Copyright (c) 2012, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

# General settings
[ -f /etc/gemeinschaft/system.conf ] && source /etc/gemeinschaft/system.conf || echo "FATAL ERROR: Local configuration file in /etc/gemeinschaft/system.conf missing"

# check each command return codes for errors
#
set -e

if [[ ${EUID} -ne 0 ]]; then
	echo "$0 needs to be run as root."
	exit 1
fi

case "$1" in

	# Lower debug levels for productive installations
	production)
		echo "** Updating FreeSwitch debugging to production level"
		sed -i "s/<map name=\"all\" value=\"debug,info,notice,warning,err,crit,alert\"\/>/<map name=\"all\" value=\"info,notice,warning,err,crit,alert\"\/>/" "${GS_DIR_NORMALIZED_LOCAL}/freeswitch/conf/freeswitch.xml"

		echo "** Updating Apache Passenger environment to production level"
		sed -i "s/RailsEnv development/RailsEnv production/" "/etc/apache2/sites-available/gemeinschaft"
		sed -i "s/#RackEnv development/#RackEnv production/" "/etc/apache2/sites-available/gemeinschaft"

		echo "** Updating Gemeinschaft debugging to production level"
		sed -i "s/# config.log_level = :debug/config.log_level = :warn/" "${GS_DIR_NORMALIZED}config/environments/production.rb"

		echo "** Updating monAMI debugging to production level"
		sed -i "s/ARGS=\"--log-file=\/var\/log\/gemeinschaft\/mon_ami.log\"/ARGS=\"--log-file=\/var\/log\/gemeinschaft\/mon_ami.log --log-level=2\"/" "/etc/init.d/mon_ami"

		echo "** Updating Cron logging to production level"
		sed -i "s/# EXTRA_OPTS=\"-L 2\"/EXTRA_OPTS=\"-L 0\"/" /etc/syslog-ng/syslog-ng.conf

		;;

	# Higher debug levels for development installations
	development)
		echo "** Updating FreeSwitch debugging to development level"
		sed -i "s/<map name=\"all\" value=\"info,notice,warning,err,crit,alert\"\/>/<map name=\"all\" value=\"debug,info,notice,warning,err,crit,alert\"\/>/" "${GS_DIR_NORMALIZED_LOCAL}/freeswitch/conf/freeswitch.xml"

		echo "** Updating Apache Passenger environment to development level"
		sed -i "s/RailsEnv production/RailsEnv development/" "/etc/apache2/sites-available/gemeinschaft"
		sed -i "s/#RackEnv production/#RackEnv development/" "/etc/apache2/sites-available/gemeinschaft"

		echo "** Updating Gemeinschaft debugging to development level"
		sed -i "s/config.log_level = :warn/# config.log_level = :debug/" "${GS_DIR_NORMALIZED}/config/environments/production.rb"

		echo "** Updating monAMI debugging to development level"
		sed -i "s/ARGS=\"--log-file=\/var\/log\/gemeinschaft\/mon_ami.log --log-level=2\"/ARGS=\"--log-file=\/var\/log\/gemeinschaft\/mon_ami.log\"/" "/etc/init.d/mon_ami"

		echo "** Updating Cron logging to development level"
		sed -i "s/EXTRA_OPTS=\"-L 0\"/# EXTRA_OPTS=\"-L 2\"/" /etc/syslog-ng/syslog-ng.conf

		;;
	*)
		echo "Usage: $0 [production | development]"
		exit 3
		;;
esac

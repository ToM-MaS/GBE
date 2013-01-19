#!/bin/bash
#
# Gemeinschaft 5
# System add-on installer
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

# General settings
[ -f /etc/gemeinschaft/system.conf ] && source /etc/gemeinschaft/system.conf || echo "FATAL ERROR: Local configuration file in /etc/gemeinschaft/system.conf missing"
[[ x"${GS_DIR}" == x"" ]] && exit 1
GS_SYSADDON_DIR="/usr/local/lib/gs-addons"

# Enforce root rights
#
if [[ ${EUID} -ne 0 ]];
	then
	echo "ERROR: $0 needs to be run as root. Aborting ..."
	exit 1
fi

# For Debian
if [ -f /etc/debian_version ]; then
	OS_DISTRIBUTION="`cat /etc/debian_version`"
	OS_VERSION=${OS_DISTRIBUTION%%.*}

	if [ x"${OS_VERSION}" == x"6" ]; then
		OS_CODENAME="squeeze"
	elif [ x"${OS_VERSION}" == x"7" ]; then
		OS_CODENAME="wheezy"
	else
		echo "ERROR: Debian version ${OS_DISTRIBUTION} is not supported. Aborting ..."
		exit 1
	fi
# Unsupported Distribution
else
	echo "ERROR: This Linux distribution is not supported. Aborting ..."
	exit 1
fi


# Run switcher
#
echo -e "\nGEMEINSCHAFT SYSTEM ADD-ON MANAGEMENT\n"

case "$1" in
	install|remove)
		if [ x"$2" ==  x"" ]; then
			echo -e "\n\nPlease specify a package name.\n"
			exit 1
		fi
		if [ -d "${GS_SYSADDON_DIR}" ]; then
			[ -d "${GS_SYSADDON_DIR}/${OS_CODENAME}" ] && GS_SYSADDON_SCRIPT="`find "${GS_SYSADDON_DIR}/${OS_CODENAME}" -maxdepth 1 -type f -name "$2"`" || GS_SYSADDON_SCRIPT=""
			[ "${GS_SYSADDON_SCRIPT}" == "" ] && GS_SYSADDON_SCRIPT="`find "${GS_SYSADDON_DIR}" -maxdepth 1 -type f -name "$2"`"
			if [ -f "${GS_SYSADDON_SCRIPT}" ]; then
				bash ${GS_SYSADDON_SCRIPT} $1
				if [ $? != 0 ]; then
					echo -e "\n\nERROR: Installation of add-on '$2' FAILED!\n"
					exit 1
				else
					echo -e "\n\nInstallation of add-on '$2' was SUCCESSFUL!\n"
					exit 0
				fi
			else
				echo -e "\n\nThe specified system add-on '$2' does not exist or is not available for your system.\n"
				exit 1
			fi
		else
			echo -e "\n\nFATAL ERROR: ${GS_SYSADDON_DIR} not found.\n"
			exit 1
		fi
		;;

	list)
		echo "Available system add-ons:"
		echo -e "\nPACKAGES FOR ${OS_CODENAME^^} :"
		[ -d "${GS_SYSADDON_DIR}/${OS_CODENAME}" ] && find "${GS_SYSADDON_DIR}/${OS_CODENAME}" -maxdepth 1 -type f ! -iname ".*" -exec bash {} info \;
		echo -e "\nGENERAL PACKAGES :"
		[ -d "${GS_SYSADDON_DIR}" ] && find "${GS_SYSADDON_DIR}" -maxdepth 1 -type f ! -iname ".*" -exec bash {} info \;
		echo -e "\nUse '`basename "$0"` install <PACKAGE NAME>' to install.\n"
		exit 0
		;;
	
	help|-h|--help|*)
		echo "Usage: $0 [ install | remove | list ] package"
		exit 1
		;;
esac

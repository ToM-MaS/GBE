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
[[ x"${GS_SYSADDON_DIR}" == x"" ]] && exit 1

# Enforce root rights
#
if [[ ${EUID} -ne 0 ]];
	then
	echo "ERROR: $0 needs to be run as root. Aborting ..."
	exit 1
fi

# For Debian
if [ -f /etc/debian_version ]; then
	OS_DISTRIBUTION="Debian"
	OS_VERSION="`cat /etc/debian_version`"
	OS_VERSION_MAJOR=${OS_VERSION%%.*}

	if [ x"${OS_VERSION_MAJOR}" == x"6" ]; then
		OS_CODENAME="squeeze"
	elif [ x"${OS_VERSION_MAJOR}" == x"7" ]; then
		OS_CODENAME="wheezy"
	else
		echo "ERROR: ${OS_DISTRIBUTION} version ${OS_VERSION} is not supported. Aborting ..."
		exit 1
	fi
# Unsupported Distribution
else
	echo "ERROR: This Linux distribution is not supported. Aborting ..."
	exit 1
fi


# Run switcher
#
echo -e "\n GEMEINSCHAFT SYSTEM ADD-ON MANAGEMENT"
echo -e "---------------------------------------"

GS_SYSADDON_ACTION="$1"
GS_SYSADDON_NAME="$2"

case "${GS_SYSADDON_ACTION}" in
	install|remove)
		if [ x"${GS_SYSADDON_NAME}" ==  x"" ]; then
			echo -e "\n\nPlease specify an add-on name.\n"
			exit 1
		fi
		if [ -d "${GS_SYSADDON_DIR}" ]; then
			
			# Try to find the specified add-on script
			[ -d "${GS_SYSADDON_DIR}/${OS_CODENAME}" ] && GS_SYSADDON_SCRIPT="`find "${GS_SYSADDON_DIR}/${OS_CODENAME}" -maxdepth 1 -type f -name "${GS_SYSADDON_NAME}" ! -iname ".*"`" || GS_SYSADDON_SCRIPT=""
			[ "${GS_SYSADDON_SCRIPT}" == "" ] && GS_SYSADDON_SCRIPT="`find "${GS_SYSADDON_DIR}" -maxdepth 1 -type f -name "${GS_SYSADDON_NAME}" ! -iname ".*"`"

			if [ -f "${GS_SYSADDON_SCRIPT}" ]; then

				[ -f "${GS_SYSADDON_DIR}/.status" ] && GS_SYSADDON_STATUS="`sed -n "/^${GS_SYSADDON_NAME} .*$/p" "${GS_SYSADDON_DIR}/.status"`" || GS_SYSADDON_STATUS=""

				# Process installation
				if [ "${GS_SYSADDON_ACTION}" == "install" ]; then
					if [ x"${GS_SYSADDON_STATUS}" == x"" ]; then
						echo -e "\nStarting installation of add-on '${GS_SYSADDON_NAME}' ...\n"
						bash ${GS_SYSADDON_SCRIPT} install
						if [ $? != 0 ]; then
							echo -e "\n\nERROR: Installation of add-on '${GS_SYSADDON_NAME}' FAILED!\n"
							exit 1
						else
							echo -e "\n\nAdd-on '${GS_SYSADDON_NAME}' was INSTALLED SUCCESSFULLY!\n"
							echo "${GS_SYSADDON_NAME} `date +'%Y-%m-%d_%T'`" >> "${GS_SYSADDON_DIR}/.status"
						fi
					else
						echo -e "\nAdd-on '${GS_SYSADDON_NAME}' was already installed on ${GS_SYSADDON_STATUS#* }\n"
					fi

				# Process removal
				elif [ "${GS_SYSADDON_ACTION}" == "remove" ]; then
					if [ x"${GS_SYSADDON_STATUS}" != x"" ]; then
						echo -e "\nRemoving add-on '${GS_SYSADDON_NAME}' ...\n"
						bash ${GS_SYSADDON_SCRIPT} remove
						if [ $? != 0 ]; then
							echo -e "\n\nERROR: Removal of add-on '${GS_SYSADDON_NAME}' FAILED!\n"
							exit 1
						else
							echo -e "\n\nAdd-on '${GS_SYSADDON_NAME}' was REMOVED SUCCESSFULLY!\n"
							sed -i "/^${GS_SYSADDON_NAME} .*$/d" "${GS_SYSADDON_DIR}/.status"
						fi
					else
						echo -e "\nAdd-on '${GS_SYSADDON_NAME}' is currently not installed.\n"
					fi

				# This should actually not happen
				else
					echo "FATAL ERROR: Logic error."
					exit 3
				fi

			# In case we could not find a declared script for the specified add-on
			else
				echo -e "\n\nThe specified system add-on '${GS_SYSADDON_NAME}' does not exist or is not available for your system.\n"
				exit 1
			fi
		else
			echo -e "\n\nFATAL ERROR: ${GS_SYSADDON_DIR} not found.\n"
			exit 3
		fi
		;;

	status)
		if [ x"${GS_SYSADDON_NAME}" == x"" ]; then
			[ -f "${GS_SYSADDON_DIR}/.status" ] && LIST="`cat "${GS_SYSADDON_DIR}/.status"`" || LIST=""
			[ x"${LIST}" != x"" ] && echo -e "\nThe following add-ons are currently installed:\n${LIST}\n" || echo -e "\nCurrently there are no add-ons installed.\n"
		else
			[ -f "${GS_SYSADDON_DIR}/.status" ] && GS_SYSADDON_STATUS="`sed -n "/^${GS_SYSADDON_NAME} .*$/p" "${GS_SYSADDON_DIR}/.status"`" || GS_SYSADDON_STATUS=""
			[ x"${GS_SYSADDON_STATUS}" != x"" ] && echo -e "\nThe system add-on '${GS_SYSADDON_NAME}' was installed on ${GS_SYSADDON_STATUS#* }.\n" || echo -e "\nThe system add-on '${GS_SYSADDON_NAME}' is currently not installed.\n"
		fi
		;;

	list)
		[ -d "${GS_SYSADDON_DIR}/${OS_CODENAME}" ] && LIST="`find "${GS_SYSADDON_DIR}/${OS_CODENAME}" -maxdepth 1 -type f ! -iname ".*"`"
		if [ x"${LIST}" != x"" ]; then
			echo -e "\nADD-ONS FOR ${OS_DISTRIBUTION^^} ${OS_CODENAME^^}"
			
			for GS_SYSADDON_SCRIPT in ${LIST}; do
				GS_SYSADDON_SCRIPT_BASE="`basename "${GS_SYSADDON_SCRIPT}"`"
				[ -f "${GS_SYSADDON_DIR}/.status" ] && GS_SYSADDON_STATUS="`sed -n "/^${GS_SYSADDON_SCRIPT_BASE} .*$/p" "${GS_SYSADDON_DIR}/.status"`" || GS_SYSADDON_STATUS=""
				[ x"${GS_SYSADDON_STATUS}" == x"" ] && echo -n "  " || echo -n "* "
				bash "${GS_SYSADDON_SCRIPT}" info
			done
		fi

		[ -d "${GS_SYSADDON_DIR}" ] && LIST="`find "${GS_SYSADDON_DIR}" -maxdepth 1 -type f ! -iname ".*"`"
		if [ x"${LIST}" != x"" ]; then
			echo -e "\nGENERAL ADD-ONS"

			for GS_SYSADDON_SCRIPT in ${LIST}; do
				GS_SYSADDON_SCRIPT_BASE="`basename "${GS_SYSADDON_SCRIPT}"`"
				[ -f "${GS_SYSADDON_DIR}/.status" ] && GS_SYSADDON_STATUS="`sed -n "/^${GS_SYSADDON_SCRIPT_BASE} .*$/p" "${GS_SYSADDON_DIR}/.status"`" || GS_SYSADDON_STATUS=""
				[ x"${GS_SYSADDON_STATUS}" == x"" ] && echo -n "  " || echo -n "* "
				bash "${GS_SYSADDON_SCRIPT}" info
			done
		fi

		echo -e "\nUse '`basename "$0"` install <ADD-ON NAME>' to install.\nUse '`basename "$0"` remove <ADD-ON NAME>' to uninstall.\n"
		;;
	
	help|-h|--help|*)
		echo -e "\nUsage: $0 [ install | remove | list | status ] <ADD-ON NAME>\n"
		exit 1
		;;
esac

exit 0

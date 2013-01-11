#!/bin/bash
#
# Gemeinschaft 5
# Update script
#
# Copyright (c) 2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

# General settings
[ -f /etc/gemeinschaft/system.conf ] && source /etc/gemeinschaft/system.conf || echo "FATAL ERROR: Local configuration file in /etc/gemeinschaft/system.conf missing"
[ -f "${GS_MYSQL_PASSWORD_FILE}" ] && GS_MYSQL_PASSWD="`cat "${GS_MYSQL_PASSWORD_FILE}"`" || echo "FATAL ERROR: GS lost it's database password in ${GS_MYSQL_PASSWORD_FILE}"
[[ x"${GS_DIR}" == x"" || x"${GS_MYSQL_PASSWD}" == x"" ]] && exit 1
GS_UPDATE_DIR="${GS_DIR}.update"

# check each command return codes for errors
#
set -e

# Enforce root rights
#
if [[ ${EUID} -ne 0 ]];
	then
	echo "ERROR: $0 needs to be run as root. Aborting ..."
	exit 1
fi

# Run switcher
#
case "$1" in
	--help|-h|help)
	echo "Usage: $0 [--cancel]"
	exit 0
	;;

	--cancel)
	MODE="cancel"
	if [[ -d "${GS_UPDATE_DIR}" ]]
		rm -rf ${GS_UPDATE_DIR}
		echo "Planned update task was canceled."
		exit 0
	else
		echo "No planned update task found."
		exit 1
	fi
	;;

	--force-init)
	MODE="init"
	;;

	--force-update)
	MODE="update"
	;;
	
	*)
	MODE="update-init"

	clear
	echo "
***    ------------------------------------------------------------------
***     GEMEINSCHAFT UPDATE
***     Current version: ${GS_VERSION}
***     Branch: ${GS_BRANCH}
***    ------------------------------------------------------------------
***
***     ATTENTION! Please read the following information CAREFULLY!
***     ===========================================================
***
***     This script will prepare your system to upgrade to the latest GS5
***     source code.
***     Updating the system via this script is NOT supported, we
***     recommend to use the backup/restore function via the web
***     interface instead. This will also ensure the latest system
***     environment is used.
***
***     ! ALWAYS DO A BACKUP OF YOUR CONFIGURATION FIRST !
***
***     The system environment is not fully upgradeable which might lead
***     to a non-functional system after the update. If that is the case
***     you need to do a clean installation and restore from your backup.
***
"

	while true; do
	    read -p "If you understand the risk, please confirm by entering \"OK\" : " yn
	    case $yn in
	        OK|ok ) echo -e "\nRisk accepted.\n\n"; break;;
	        * ) echo "Aborting ..."; exit;;
	    esac
	done

	;;
esac

# Prepare for system update
#
if [[ "${MODE}" == "update-init" ]]; then

	# Clone the git repository
	#
	[[ -d "${GS_UPDATE_DIR}" ]] && rm -rf "${GS_UPDATE_DIR}"
	[[ -d "${GS_UPDATE_DIR}.tmp" ]] && rm -rf "${GS_UPDATE_DIR}.tmp"

	# use master branch if no explicit branch was given and GBE branch is master
	[[ x"${GS_BRANCH}" == x"" && x"${GDFDL_BRANCH}" == x"develop" ]] && GS_BRANCH="develop"
	[[ x"${GS_BRANCH}" == x"" && x"${GDFDL_BRANCH}" != x"develop" ]] && GS_BRANCH="master"

	echo -e "Preparing update of Gemeinschaft ...\n"

	# Setup Github user credentials for login
	#
	if [ ! -z "${GS_GIT_USER}" -a ! -z "${GS_GIT_PASSWORD}" ]
		then
		echo "Github credentials found!"
echo "machine Github.com
login ${GS_GIT_USER}
password ${GS_GIT_PASSWORD}
" >  ~/.netrc
	fi

	set +e
	c=1
	while [[ $c -le 5 ]]
	do
		git clone -b "${GS_BRANCH}" "${GS_GIT_URL}" "${GS_UPDATE_DIR}.tmp" 2>&1
		if [ "$?" -eq "0" ]
			then
			mv "${GS_UPDATE_DIR}.tmp" "${GS_UPDATE_DIR}"
			break;
		else
			[[ $c -eq 5 ]] && exit 1
			(( c++ ))
			rm -rf "${GS_UPDATE_DIR}.tmp"
			echo "$c. try in 3 seconds ..."
			sleep 3
		fi
	done
	set -e

	if [ -f "${GS_DIR}/config/application.rb" ];
		then
		rm -rf ~/.netrc
		echo -e "\n\nUpdate preparation SUCCESSFUL. Please reboot the system to start the update process.\n\n"
	else
		echo -e "\n\nCould not download current version from repository, ABORTING ...\n\n"
		rm -rf "${GS_UPDATE_DIR}*"
		exit 1
	fi
fi

# Initialize update
#
if [[ "${MODE}" == "update" ]]; then
	if [[ -d "${GS_UPDATE_DIR}" ]]
		# make sure only mysql is running
		service mom_ami stop
		service freeswitch stop
		service apache2 stop
		service mysql start
		
		echo "** Rename and backup old files in \"${GS_DIR}\""
		mv ${GS_DIR} ${GS_DIR}.bak
		mv ${GS_UPDATE_DIR} ${GS_DIR}
	else
		echo "ERROR: No new version found in \"${GS_UPDATE_DIR}\" - aborting ..."
		exit 1
	fi	
fi

# Run essential init and update commands
#
if [[ "${MODE}" == "init" || "${MODE}" == "update" ]]; then
	# Remove Git remote reference
	#
	echo "** Remove Git remote reference"
	GS_GIT_REMOTE="`git --git-dir="${GS_DIR_NORMALIZED}/.git" remote`"
	for _REMOTE in ${GS_GIT_REMOTE}; do
		su - ${GS_USER} -c "cd \"${GS_DIR_NORMALIZED}\"; git remote rm ${_REMOTE}"
	done

	echo "** Setup logging directory"
	rm -rf "${GS_DIR}/log"
	ln -sf /var/log/gemeinschaft "${GS_DIR}/log"

	echo "** Copy FreeSwitch static configuration files"
	cp -an ${GS_DIR}/misc/freeswitch/conf ${GS_DIR_LOCAL}/freeswitch

	# make local copy of Lua dialplan script configurations
	echo "** Copy Lua dialplan static ini files"
	cp -an ${GS_DIR}/misc/freeswitch/scripts/ini ${GS_DIR_LOCAL}/freeswitch/scripts
	rm -rf ${GS_DIR}/misc/freeswitch/scripts/ini
	ln -s ${GS_DIR_NORMALIZED_LOCAL}/freeswitch/scripts/ini ${GS_DIR}/misc/freeswitch/scripts/ini

	echo "** Updating Gemeinschaft with database password"
	sed -i "s/password:.*/password: ${GS_MYSQL_PASSWD}/" "${GS_DIR}/config/database.yml"

	echo "** Updating FreeSwitch with database password"
	sed -i "s/<param name=\"core-db-dsn\".*/<param name=\"core-db-dsn\" value=\"${GS_MYSQL_DB}:${GS_MYSQL_USER}:${GS_MYSQL_PASSWD}\"\/>/" "${GS_DIR_NORMALIZED_LOCAL}/freeswitch/conf/freeswitch.xml"

	# Lower debug levels for productive installations
	#
	if [[ `expr length ${GS_BUILDNAME}` == 10 ]]; then
		/usr/local/bin/gs-change-state.sh production

	# Enforce higher debug levels for development installations
	#
	else
		/usr/local/bin/gs-change-state.sh development
	fi

	# Special tasks for update only
	#
	if [[ "${MODE}" == "update" ]]; then
		echo "** Enforcing file permissions and security settings ..."
		/usr/local/bin/gs-enforce-security.sh | grep -Ev retained | grep -Ev "no changes" | grep -Ev "nor referent has been changed"

		echo "** Install Gems"
		su - ${GS_USER} -c "cd \"${GS_DIR_NORMALIZED}\"; RAILS_ENV=production bundle install"
	fi

	# Load database structure into DB
	#
	echo "** Initializing database"
	su - ${GS_USER} -c "cd \"${GS_DIR_NORMALIZED}\"; RAILS_ENV=production bundle exec rake db:migrate --trace"

	# Generate assets (like CSS)
	#
	echo "** Precompile GS assets"
	su - ${GS_USER} -c "cd \"${GS_DIR_NORMALIZED}\"; RAILS_ENV=production bundle exec rake assets:precompile --trace"

	# Special tasks for update only
	#
	if [[ "${MODE}" == "update" ]]; then
		# start/stop system services accordingly
		service apache2 start
		service freeswitch start
		service mon_ami start
	fi
fi

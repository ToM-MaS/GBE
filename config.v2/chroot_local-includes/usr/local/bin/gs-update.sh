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

# check each command return codes for errors
#
set -e


# Remove Git remote reference
#
echo "** Remove Git remote reference"
GS_GIT_REMOTE="`git --git-dir="${GS_DIR_NORMALIZED}/.git" remote`"
for _REMOTE in ${GS_GIT_REMOTE}; do
	su - ${GS_USER} -c "cd \"${GS_DIR_NORMALIZED}\"; git remote rm ${_REMOTE}"
done

# Update database password in Gemeinschaft config
#
echo "** Updating Gemeinschaft with database password"
sed -i "s/password:.*/password: ${MYSQL_PASSWD_GS}/" "${GS_DIR}/config/database.yml"

# Update database password in FreeSwitch config
#
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

# Load database structure into DB
#
echo "** Initializing database"
su - ${GS_USER} -c "cd \"${GS_DIR_NORMALIZED}\"; RAILS_ENV=production bundle exec rake db:migrate --trace"

# Generate assets (like CSS)
#
echo "** Precompile GS assets"
su - ${GS_USER} -c "cd \"${GS_DIR_NORMALIZED}\"; RAILS_ENV=production bundle exec rake assets:precompile --trace"

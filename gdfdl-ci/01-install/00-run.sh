#!/bin/bash
#
# GDFDL - A Development Framework for Debian live-build
# Local Installer script
#
# Copyright (c) 2012, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GDFDL file for details.
#

###
# Don't change this file directly.
# If you create additional scripts following the series 01-,02-,03- etc
# we will hand over the stick to the next one in this same directory.
###

set -e

SELF="`readlink -f $0`"
GDFDL_INSTALLER_BASEDIR_CI_01="`dirname ${SELF}`"
GDFDL_INSTALLER_BASEDIR_CI="`dirname ${GDFDL_INSTALLER_BASEDIR_CI_01}`"
GDFDL_INSTALLER_BASEDIR="`dirname ${GDFDL_INSTALLER_BASEDIR_CI}`"
GDFDL_BRANCH="`cd "${GDFDL_INSTALLER_BASEDIR}"; git branch | cut -d " " -f 2`"
[ x"$1" == x"" ] && GDFDL_INSTALLER_DESTINATION="${GDFDL_INSTALLER_BASEDIR}/.ci" || GDFDL_INSTALLER_DESTINATION="$1"

[ ! -d "${GDFDL_INSTALLER_DESTINATION}" ] && mkdir "${GDFDL_INSTALLER_DESTINATION}"
cd "${GDFDL_INSTALLER_DESTINATION}"

# start the actual installer
bash "${GDFDL_INSTALLER_BASEDIR}/gdfdl-scripts/gdfdl-installer" "${GDFDL_BRANCH}" "${GDFDL_INSTALLER_BASEDIR}" "${GDFDL_INSTALLER_BASEDIR}" ci

cd - 2>&1 >/dev/null

# if we find another script in the series, go on and run that
#
GDFDL_CI_NEXT="`find "${GDFDL_BASEDIR_CI_01}" -maxdepth 1 -name 01-*.sh`"
if [ -f "${GDFDL_CI_NEXT}" ]
	then
	echo "NOTE: Next script '${GDFDL_CI_NEXT}' found, handing over now ..."
	"${GDFDL_CI_NEXT}" "${@}"
	exit 0
fi

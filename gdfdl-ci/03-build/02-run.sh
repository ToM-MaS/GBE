#!/bin/bash
#
# Gemeinschaft 5
# GBE post-build script for CI
#
# Copyright (c) 2012-2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

set -e

SELF="`readlink -f $0`"
GDFDL_BASEDIR_CI_STEP="`dirname ${SELF}`"
GDFDL_BASEDIR_CI="`dirname ${GDFDL_BASEDIR_CI_STEP}`"
GDFDL_BASEDIR="`dirname ${GDFDL_BASEDIR_CI}`"
source "${GDFDL_BASEDIR}/gdfdl.conf"
[ -f "${GDFDL_BASEDIR}/gdfdl-custom.conf" ] && source "${GDFDL_BASEDIR}/gdfdl-custom.conf"
GDFDL_ENTRYWRAPPER="`find "${GDFDL_BASEDIR}/.ci" -maxdepth 1 -name '*.sh'`"

# finalize build
#
if [ -f "${GDFDL_ENTRYWRAPPER}" ];
	then
	INSTALLBASEDIR="`"${GDFDL_ENTRYWRAPPER}" chroot --printdir`"

	if [ -d "${GDFDL_BASEDIR}/.ci/GS5" ]
		then
		echo -n "Extracting GS5 tag information from SCM ... "
		"${GDFDL_ENTRYWRAPPER}" chroot rm -rf "/iso/SCM-TAG.GS5"
		"${GDFDL_ENTRYWRAPPER}" chroot chmod -f 777 "/iso"
		TAGGED_COMMIT="`git --exec-path="${GDFDL_BASEDIR}/.ci/GS5" --git-dir="${GDFDL_BASEDIR}/.ci/GS5/.git" rev-list --tags --max-count=1`"
		git --exec-path="${GDFDL_BASEDIR}/.ci/GS5" --git-dir="${GDFDL_BASEDIR}/.ci/GS5/.git" describe --tags "${TAGGED_COMMIT}" > "${INSTALLBASEDIR}/iso/SCM-TAG.GS5"
	fi

	echo "done"

else
	echo "ERROR: No existing build environment installation found. Run installer first."
	exit 1
fi

# run original build script
#
echo "GBE: Handing back to original run script now ..."
"${GDFDL_BASEDIR_CI_STEP}/00-run.sh" --force "${@}"

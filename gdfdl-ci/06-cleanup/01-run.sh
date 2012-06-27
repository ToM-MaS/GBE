#!/bin/bash
#
# Gemeinschaft 5
# GBE pre-cleanup for CI
#
# Copyright (c) 2012, Julian Pawlowski <jp@jps-networks.eu>
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

# prepage cleanup
#
if [ -f "${GDFDL_ENTRYWRAPPER}" ];
	then
	INSTALLBASEDIR="`"${GDFDL_ENTRYWRAPPER}" chroot --printdir`"
	SRC_CACHE_BIN="${GDFDL_BASEDIR}/.ci/src-cache-bin"

	# save pre-compiled archives into cache directory
	set +e
	if [ -d "${INSTALLBASEDIR}/src-cache-bin" ]
		then
		echo "GBE: Saving pre-compiled archives into cache directory ..."
		[[ ! -d "${SRC_CACHE_BIN}" ]] && mkdir -p "${SRC_CACHE_BIN}"
		find "${INSTALLBASEDIR}/src-cache-bin" -name 'BIN_' -exec cp -rf '{}' "${SRC_CACHE_BIN}" \;
	fi
	set -e

else
	echo "ERROR: No existing build environment installation found. Run installer first."
	exit 1
fi

# run original build script
#
echo "GBE: Handing back to original run script now ..."
"${GDFDL_BASEDIR_CI_STEP}/00-run.sh" --force "${@}"

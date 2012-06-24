#!/bin/bash
#
# Gemeinschaft 5
# GBE installer for CI
#
# Copyright (c) 2012, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

set -e

SELF="`readlink -f $0`"
GDFDL_BASEDIR_CI_STEP="`dirname ${SELF}`"
GDFDL_BASEDIR_CI="`dirname ${GDFDL_BASEDIR_CI_STEP}`"
GDFDL_BASEDIR="`dirname ${GDFDL_BASEDIR_CI}`"
GDFDL_ENTRYWRAPPER="`find "${GDFDL_BASEDIR}/.ci" -maxdepth 1 -name *.sh`"

# prepare build
#
if [ -f "${GDFDL_ENTRYWRAPPER}" ];
	then
	echo "GBE: Copying latest upstream project repositories into their places ..."
	"${GDFDL_ENTRYWRAPPER}" chroot rm -rf /be/config/chroot_local-includes/usr/local/src
	"${GDFDL_ENTRYWRAPPER}" chroot mkdir -p /be/config/chroot_local-includes/usr/local/src
	"${GDFDL_ENTRYWRAPPER}" chroot chmod 777 /be/config/chroot_local-includes/usr/local/src
	[ -d "${GDFDL_BASEDIR}/.ci/freeswitch" ] && echo "Upstream Freeswitch sources found!"
	[ -d "${GDFDL_BASEDIR}/.ci/GS5" ] && echo "Upstream GS5 sources found!"
else
	echo "ERROR: No existing build environment installation found. Run installer first."
	exit 1
fi

# run original build script
#
echo "GBE: Handing back to original run script now ..."
"${GDFDL_BASEDIR_CI_STEP}/00-run.sh --force"

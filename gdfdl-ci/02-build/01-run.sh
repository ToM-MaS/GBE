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
GDFDL_BASEDIR_CI_02="`dirname ${SELF}`"
GDFDL_BASEDIR_CI="`dirname ${GDFDL_BASEDIR_CI_02}`"
GDFDL_BASEDIR="`dirname ${GDFDL_BASEDIR_CI}`"
GDFDL_ENTRYWRAPPER="`find "${GDFDL_BASEDIR}/.ci" -maxdepth 1 -name *.sh`"

# prepare build
#
if [[ -f "${GDFDL_ENTRYWRAPPER}" ]];
	then

else
	echo "ERROR: No existing build environment installation found. Run installer first."
	exit 1
fi

# run original build script
#
"${GDFDL_BASEDIR_CI_02}/00-run.sh --force"

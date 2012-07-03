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
source "${GDFDL_BASEDIR}/gdfdl.conf"
[ -f "${GDFDL_BASEDIR}/gdfdl-custom.conf" ] && source "${GDFDL_BASEDIR}/gdfdl-custom.conf"
GDFDL_ENTRYWRAPPER="`find "${GDFDL_BASEDIR}/.ci" -maxdepth 1 -name '*.sh'`"

# prepare build
#
if [ -f "${GDFDL_ENTRYWRAPPER}" ];
	then
	INSTALLBASEDIR="`"${GDFDL_ENTRYWRAPPER}" chroot --printdir`"
	SRC_CACHE="${GDFDL_BASEDIR}/.ci/src-cache"
	SRC_CACHE_BIN="${GDFDL_BASEDIR}/.ci/src-cache-bin"

	[ -d "${INSTALLBASEDIR}${GDFDL_DIR}/config/chroot_local-includes/usr/local/src" ] && "${GDFDL_ENTRYWRAPPER}" chroot rm -rf "${GDFDL_DIR}/config/chroot_local-includes/usr/local/src"
	[ -d "${INSTALLBASEDIR}${GDFDL_DIR}/config/chroot_local-includes/opt" ] && "${GDFDL_ENTRYWRAPPER}" chroot rm -rf "${GDFDL_DIR}/config/chroot_local-includes/opt"
	"${GDFDL_ENTRYWRAPPER}" chroot mkdir -p -m 777 "${GDFDL_DIR}/config/chroot_local-includes/usr/local/src"
	"${GDFDL_ENTRYWRAPPER}" chroot mkdir -p -m 777 "${GDFDL_DIR}/config/chroot_local-includes/opt"

	# echo "GBE: Caching 3rd party dependencies ..."
	# [ ! -d "${SRC_CACHE}" ] && mkdir -p "${SRC_CACHE}"
	# # Download 3rd party modules if not cached already
	# #
	# # FS: loading autotalent for mod_ladspa
	# [ ! -f "${SRC_CACHE}/autotalent-${FS3RD_ladspa_autotalent}.tar.gz" ] && wget -P "${SRC_CACHE}" -c -t 5 --waitretry=3 "http://web.mit.edu/tbaran/www/autotalent-${FS3RD_ladspa_autotalent}.tar.gz"
	# # FS: loading Sangoma wanpipe driver for mod_freetdm
	# [ ! -f "${SRC_CACHE}/wanpipe-${FS3RD_freetdm_sangoma_wanpipe}.tgz" ] && wget -P "${SRC_CACHE}" -c -t 5 --waitretry=3 "ftp://ftp.sangoma.com/linux/current_wanpipe/wanpipe-${FS3RD_freetdm_sangoma_wanpipe}.tgz"
	# # FS: loading Sangoma ISDN driver for mod_freetdm
	# [ ! -f "${SRC_CACHE}/libsng_isdn-${FS3RD_freetdm_sangoma_isdn}.i686.tgz" ] && wget -P "${SRC_CACHE}" -c -t 5 --waitretry=3 "ftp://ftp.sangoma.com/linux/libsng_isdn/libsng_isdn-${FS3RD_freetdm_sangoma_isdn}.i686.tgz"
	# # FS: loading Sangoma SS7 driver for mod_freetdm
	# [ ! -f "${SRC_CACHE}/libsng_ss7-4-${FS3RD_freetdm_sangoma_ss7}.i686.tgz" ] && wget -P "${SRC_CACHE}" -c -t 5 --waitretry=3 "ftp://ftp.sangoma.com/linux/libsng_ss7/libsng_ss7-4-${FS3RD_freetdm_sangoma_ss7}.i686.tgz"
	# # FS: loading libpri driver for mod_freetdm
	# [ ! -f "${SRC_CACHE}/libpri-${FS3RD_freetdm_libpri}.tar.gz" ] && wget -P "${SRC_CACHE}" -c -t 5 --waitretry=3 "http://downloads.asterisk.org/pub/telephony/libpri/releases/libpri-${FS3RD_freetdm_libpri}.tar.gz"
	# # loading opal for mod_opal
	# set +e
	# if [ ! -d "${SRC_CACHE}/ptlib-${FS3RD_opal_ptlib}" ]
	# 	then
	#   	c=1
	# 	while [[ $c -le 5 ]]
	# 	do
	# 		svn --non-interactive co "https://opalvoip.svn.sourceforge.net/svnroot/opalvoip/ptlib/${FS3RD_opal_ptlib}" "${SRC_CACHE}/ptlib-${FS3RD_opal_ptlib}"
	# 		if [ "$?" -eq "0" ]; then
	# 			break;
	# 		else
	# 			[[ $c -eq 5 ]] && exit 1
	# 			(( c++ ))
	# 			rm -rf "${SRC_CACHE}/ptlib-${FS3RD_opal_ptlib}"
	# 			echo "$c. try in 3 seconds ..."
	# 			sleep 3
	# 		fi
	# 	done
	# fi
	# 
	# if [ ! -d "${SRC_CACHE}/opal-${FS3RD_opal}" ]
	# 	then
	# 	c=1
	# 	while [[ $c -le 5 ]]
	# 	do
	# 		svn --non-interactive co "https://opalvoip.svn.sourceforge.net/svnroot/opalvoip/opal/${FS3RD_opal}" "${SRC_CACHE}/opal-${FS3RD_opal}"
	# 		if [ "$?" -eq "0" ]; then
	# 			break;
	# 		else
	# 			[[ $c -eq 5 ]] && exit 1
	# 			(( c++ ))
	# 			rm -rf "${SRC_CACHE}/opal-${FS3RD_opal}"
	# 			echo "$c. try in 3 seconds ..."
	# 			sleep 3
	# 		fi
	# 	done
	# fi
	# 
	# # loading OpenR2 driver for mod_freetdm
	# if [ ! -d "${SRC_CACHE}/openr2-${FS3RD_freetdm_openr2}" ]
	# 	then
	# 	c=1
	# 	while [[ $c -le 5 ]]
	# 	do
	# 		svn --non-interactive co "http://openr2.googlecode.com/svn/${FS3RD_freetdm_openr2}/" "${SRC_CACHE}/openr2-${FS3RD_freetdm_openr2}"
	# 		if [ "$?" -eq "0" ]; then
	# 			break;
	# 		else
	# 			[[ $c -eq 5 ]] && exit 1
	# 			(( c++ ))
	# 			rm -rf "${SRC_CACHE}/openr2-${FS3RD_freetdm_openr2}"
	# 			echo "$c. try in 3 seconds ..."
	# 			sleep 3
	# 		fi
	# 	done
	# fi
	# 
	# # loading DAHDI driver for mod_freetdm
	# if [ ! -d "${SRC_CACHE}/dahdi-hfcs" ]
	# 	then
	# 	c=1
	# 	while [[ $c -le 5 ]]
	# 	do
	# 		git clone --depth=0 "git://dahdi-hfcs.git.sourceforge.net/gitroot/dahdi-hfcs/dahdi-hfcs" "${SRC_CACHE}/dahdi-hfcs"
	# 		if [ "$?" -eq "0" ]; then
	# 			break;
	# 		else
	# 			[[ $c -eq 5 ]] && exit 1
	# 			(( c++ ))
	# 			rm -rf "${SRC_CACHE}/dahdi-hfcs"
	# 			echo "$c. try in 3 seconds ..."
	# 			sleep 3
	# 		fi
	# 	done
	# fi
	# set -e


	if [[ -d "${SRC_CACHE}" ]]
		then
		echo "GBE: Copying 3rd party source depdendencies into their places ..."
		cp -rpf "${SRC_CACHE}/"* "${INSTALLBASEDIR}${GDFDL_DIR}/config/chroot_local-includes/usr/local/src/"
	fi

	if [[ -d "${SRC_CACHE_BIN}" ]]
		then
		echo "GBE: Copying 3rd party pre-compiled depdendencies into their places ..."
		cp -rpf "${SRC_CACHE_BIN}/"* "${INSTALLBASEDIR}${GDFDL_DIR}/config/chroot_local-includes/usr/local/src/"
	fi

	echo -n "GBE: Copying latest upstream project repositories into their places ... "
	if [ -d "${GDFDL_BASEDIR}/.ci/freeswitch" ]
		then
		echo -n "FreeSWITCH "
		cp -rpf "${GDFDL_BASEDIR}/.ci/freeswitch" "${INSTALLBASEDIR}${GDFDL_DIR}/config/chroot_local-includes/usr/local/src/"
	fi

	if [ -d "${GDFDL_BASEDIR}/.ci/GS5" ]
		then
		echo -n "GS5 "
		cp -rpf "${GDFDL_BASEDIR}/.ci/GS5" "${INSTALLBASEDIR}${GDFDL_DIR}/config/chroot_local-includes/opt/"
	fi

	echo "... done"
else
	echo "ERROR: No existing build environment installation found. Run installer first."
	exit 1
fi

# run original build script
#
echo "GBE: Handing back to original run script now ..."
"${GDFDL_BASEDIR_CI_STEP}/00-run.sh" --force "${@}"

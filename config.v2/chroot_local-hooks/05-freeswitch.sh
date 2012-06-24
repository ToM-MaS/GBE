#!/bin/bash
#
# Gemeinschaft 5
# Install FreeSWITCH for Gemeinschaft 5
#
# Copyright (c) 2012, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

# check each command return codes for errors
#
set -e

# General settings
source /gdfdl.conf
[ -f /gdfdl-custom.conf ] && source /gdfdl-custom.conf
SRC_DIR="/usr/local/src"

echo -e "\n###########################################################
## GBE: FreeSwitch installation\n\n"

echo -e "GBE: Downloading FreeSwitch and 3rd party components ...\n"
cd ${SRC_DIR}

if [ ! -d ./freeswitch ]
	then
	set +e
	c=1
	while [[ $c -le 5 ]]
	do
		git clone http://git.freeswitch.org/freeswitch.git freeswitch
		if [ "$?" -eq "0" ]; then
			break;
		else
			[[ $c -eq 5 ]] && exit 1
			(( c++ ))
			rm -rf freeswitch
			echo "$c. try in 3 seconds ..."
			sleep 3
		fi
	done
	set -e
fi

# FreeSwitch version handling
#
if [ x${FREESWITCH_VERSION} != x"HEAD" && x${FREESWITCH_VERSION} =! x"" ];
then
	git checkout ${FREESWITCH_VERSION}
fi

# loading autotalent for mod_ladspa
wget -P ${SRC_DIR} -c -t 5 --waitretry=3 http://web.mit.edu/tbaran/www/autotalent-${FS3RD_ladspa_autotalent}.tar.gz 2>&1
# loading opal for mod_opal
set +e
c=1
while [[ $c -le 5 ]]
do
	svn --non-interactive co https://opalvoip.svn.sourceforge.net/svnroot/opalvoip/ptlib/${FS3RD_opal_ptlib} ptlib 2>&1
	if [ "$?" -eq "0" ]; then
		break;
	else
		[[ $c -eq 5 ]] && exit 1
		(( c++ ))
		rm -rf ptlib
		echo "$c. try in 3 seconds ..."
		sleep 3
	fi
done

c=1
while [[ $c -le 5 ]]
do
	svn --non-interactive co https://opalvoip.svn.sourceforge.net/svnroot/opalvoip/opal/${FS3RD_opal} opal 2>&1
	if [ "$?" -eq "0" ]; then
		break;
	else
		[[ $c -eq 5 ]] && exit 1
		(( c++ ))
		rm -rf opal
		echo "$c. try in 3 seconds ..."
		sleep 3
	fi
done
set -e
# loading Sangoma wanpipe driver for mod_freetdm
wget -P ${SRC_DIR} -c -t 5 --waitretry=3 ftp://ftp.sangoma.com/linux/current_wanpipe/wanpipe-${FS3RD_freetdm_sangoma_wanpipe}.tgz 2>&1
# loading Sangoma ISDN driver for mod_freetdm
wget -P ${SRC_DIR} -c -t 5 --waitretry=3 ftp://ftp.sangoma.com/linux/libsng_isdn/libsng_isdn-${FS3RD_freetdm_sangoma_isdn}.i686.tgz 2>&1
# loading Sangoma SS7 driver for mod_freetdm
wget -P ${SRC_DIR} -c -t 5 --waitretry=3 ftp://ftp.sangoma.com/linux/libsng_ss7/libsng_ss7-4-${FS3RD_freetdm_sangoma_ss7}.i686.tgz 2>&1
# loading libpri driver for mod_freetdm
wget -P ${SRC_DIR} -c -t 5 --waitretry=3 http://downloads.asterisk.org/pub/telephony/libpri/releases/libpri-${FS3RD_freetdm_libpri}.tar.gz 2>&1
# loading OpenR2 driver for mod_freetdm
set +e
c=1
while [[ $c -le 5 ]]
do
	svn --non-interactive co http://openr2.googlecode.com/svn/${FS3RD_freetdm_openr2}/ openr2 2>&1
	if [ "$?" -eq "0" ]; then
		break;
	else
		[[ $c -eq 5 ]] && exit 1
		(( c++ ))
		rm -rf openr2
		echo "$c. try in 3 seconds ..."
		sleep 3
	fi
done
# loading DAHDI driver for mod_freetdm
c=1
while [[ $c -le 5 ]]
do
	git clone --depth=0 git://dahdi-hfcs.git.sourceforge.net/gitroot/dahdi-hfcs/dahdi-hfcs dahdi-hfcs 2>&1
	if [ "$?" -eq "0" ]; then
		break;
	else
		[[ $c -eq 5 ]] && exit 1
		(( c++ ))
		rm -rf dahdi-hfcs
		echo "$c. try in 3 seconds ..."
		sleep 3
	fi
done
set -e

echo -e "GBE: Installing FreeSwitch 3rd party components ...\n"
# installing autotalent for mod_ladspa
cd ${SRC_DIR}; tar xfz autotalent-${FS3RD_ladspa_autotalent}.tar.gz && cd autotalent-* && make install 2>&1
# installing opal for mod_opal
cd ${SRC_DIR}/ptlib; ./configure --prefix=/usr 2>&1 && make 2>&1 && make install 2>&1
cd ${SRC_DIR}/opal; PKG_CONFIG_PATH=/usr/lib/pkgconfig ./configure --prefix=/usr 2>&1 && make 2>&1 && make install 2>&1
# installing Sandoma wanpipe driver for mod_freetdm - only loadable when explicitly booting with 686 kernel or from local installation
cd ${SRC_DIR}; tar xfz wanpipe-${FS3RD_freetdm_sangoma_wanpipe}.tgz && cd wanpipe-* && KVER=`find /lib/modules -name 2.6*-686 -type d | cut -d"/" -f4` make freetdm 2>&1 && make install 2>&1
# installing Sandoma ISDN driver for mod_freetdm
cd ${SRC_DIR}; tar xfz libsng_isdn-${FS3RD_freetdm_sangoma_isdn}.i686.tgz 2>&1 && cd libsng_isdn-* 2>&1 && make install
# installing Sandoma SS7 driver for mod_freetdm
cd ${SRC_DIR}; tar xfz libsng_ss7-4-${FS3RD_freetdm_sangoma_ss7}.i686.tgz 2>&1 && cd libsng_ss7-* 2>&1 && make install
# installing libpri driver for mod_freetdm
cd ${SRC_DIR}; tar xfz libpri-${FS3RD_freetdm_libpri}.tar.gz 2>&1 && cd libpri-* 2>&1 && make 2>&1 && make install 2>&1
# installing OpenR2 for mod_freetdm
mkdir ${SRC_DIR}/openr2/mybuild; cd ${SRC_DIR}/openr2/mybuild; cmake -DCMAKE_INSTALL_PREFIX=/usr 2>&1 && make 2>&1 && make install 2>&1
# installing DAHDI for mod_freetdm
cd ${SRC_DIR}/dahdi-hfcs; make 2>&1 && make install 2>&1

echo -e "GBE: Preparing FreeSwitch for compilation ...\n"
cd ${SRC_DIR}/freeswitch
./bootstrap.sh -j 2>&1
# assure basic FreeSwitch modules are loaded as Gemeinschaft relies on them
sed -i 's/#applications\/mod_cluechoo/applications\/mod_cluechoo/' modules.conf
sed -i 's/#applications\/mod_cluechoo/applications\/mod_cluechoo/' modules.conf
sed -i 's/#applications\/mod_conference/applications\/mod_conference/' modules.conf
sed -i 's/#applications\/mod_db/applications\/mod_db/' modules.conf
sed -i 's/#applications\/mod_dptools/applications\/mod_dptools/' modules.conf
sed -i 's/#applications\/mod_enum/applications\/mod_enum/' modules.conf
sed -i 's/#applications\/mod_esf/applications\/mod_esf/' modules.conf
sed -i 's/#applications\/mod_expr/applications\/mod_expr/' modules.conf
sed -i 's/#applications\/mod_fifo/applications\/mod_fifo/' modules.conf
sed -i 's/#applications\/mod_fsv/applications\/mod_fsv/' modules.conf
sed -i 's/#applications\/mod_hash/applications\/mod_hash/' modules.conf
sed -i 's/#applications\/mod_httapi/applications\/mod_httapi/' modules.conf
sed -i 's/#applications\/mod_sms/applications\/mod_sms/' modules.conf
sed -i 's/#applications\/mod_spandsp/applications\/mod_spandsp/' modules.conf
sed -i 's/#applications\/mod_valet_parking/applications\/mod_valet_parking/' modules.conf
sed -i 's/#applications\/mod_voicemail/applications\/mod_voicemail/' modules.conf
sed -i 's/#codecs\/mod_amr/codecs\/mod_amr/' modules.conf
sed -i 's/#codecs\/mod_bv/codecs\/mod_bv/' modules.conf
sed -i 's/#codecs\/mod_g723_1/codecs\/mod_g723_1/' modules.conf
sed -i 's/#codecs\/mod_g729/codecs\/mod_g729/' modules.conf
sed -i 's/#codecs\/mod_h26x/codecs\/mod_h26x/' modules.conf
sed -i 's/#codecs\/mod_speex/codecs\/mod_speex/' modules.conf
sed -i 's/#dialplans\/mod_dialplan_asterisk/dialplans\/mod_dialplan_asterisk/' modules.conf
sed -i 's/#dialplans\/mod_dialplan_xml/dialplans\/mod_dialplan_xml/' modules.conf
sed -i 's/#endpoints\/mod_loopback/endpoints\/mod_loopback/' modules.conf
sed -i 's/#endpoints\/mod_sofia/endpoints\/mod_sofia/' modules.conf
sed -i 's/#event_handlers\/mod_cdr_csv/event_handlers\/mod_cdr_csv/' modules.conf
sed -i 's/#event_handlers\/mod_cdr_sqlite/event_handlers\/mod_cdr_sqlite/' modules.conf
sed -i 's/#event_handlers\/mod_event_socket/event_handlers\/mod_event_socket/' modules.conf
sed -i 's/#formats\/mod_local_stream/formats\/mod_local_stream/' modules.conf
sed -i 's/#formats\/mod_native_file/formats\/mod_native_file/' modules.conf
sed -i 's/#formats\/mod_sndfile/formats\/mod_sndfile/' modules.conf
sed -i 's/#formats\/mod_tone_stream/formats\/mod_tone_stream/' modules.conf
sed -i 's/#languages\/mod_lua/languages\/mod_lua/' modules.conf
sed -i 's/#languages\/mod_spidermonkey/languages\/mod_spidermonkey/' modules.conf
sed -i 's/#loggers\/mod_console/loggers\/mod_console/' modules.conf
sed -i 's/#loggers\/mod_logfile/loggers\/mod_logfile/' modules.conf
sed -i 's/#loggers\/mod_syslog/loggers\/mod_syslog/' modules.conf
sed -i 's/#say\/mod_say_en/say\/mod_say_en/' modules.conf
sed -i 's/#xml_int\/mod_xml_cdr/xml_int\/mod_xml_cdr/' modules.conf
sed -i 's/#xml_int\/mod_xml_rpc/xml_int\/mod_xml_rpc/' modules.conf
sed -i 's/#xml_int\/mod_xml_scgi/xml_int\/mod_xml_scgi/' modules.conf

# enable additional FreeSwitch modules
sed -i 's/#applications\/mod_avmd/applications\/mod_avmd/' modules.conf
sed -i 's/#applications\/mod_blacklist/applications\/mod_blacklist/' modules.conf
sed -i 's/#applications\/mod_callcenter/applications\/mod_callcenter/' modules.conf
sed -i 's/#applications\/mod_cidlookup/applications\/mod_cidlookup/' modules.conf
sed -i 's/#applications\/mod_directory/applications\/mod_directory/' modules.conf
sed -i 's/#applications\/mod_distributor/applications\/mod_distributor/' modules.conf
sed -i 's/#applications\/mod_easyroute/applications\/mod_easyroute/' modules.conf
sed -i 's/#applications\/mod_esl/applications\/mod_esl/' modules.conf
sed -i 's/#applications\/mod_fsk/applications\/mod_fsk/' modules.conf
sed -i 's/#applications\/mod_http_cache/applications\/mod_http_cache/' modules.conf
sed -i 's/#applications\/mod_ladspa/applications\/mod_ladspa/' modules.conf
sed -i 's/#applications\/mod_lcr/applications\/mod_lcr/' modules.conf
sed -i 's/#applications\/mod_memcache/applications\/mod_memcache/' modules.conf
sed -i 's/#applications\/mod_nibblebill/applications\/mod_nibblebill/' modules.conf
#sed -i 's/#applications\/mod_osp/applications\/mod_osp/' modules.conf ## does not build in Squeeze, see http://jira.freeswitch.org/browse/FS-4211
sed -i 's/#applications\/mod_rss/applications\/mod_rss/' modules.conf
sed -i 's/#applications\/mod_snapshot/applications\/mod_snapshot/' modules.conf
sed -i 's/#applications\/mod_snom/applications\/mod_snom/' modules.conf
sed -i 's/#applications\/mod_soundtouch/applications\/mod_soundtouch/' modules.conf
sed -i 's/#applications\/mod_spy/applications\/mod_spy/' modules.conf
sed -i 's/#applications\/mod_voicemail_ivr/applications\/mod_voicemail_ivr/' modules.conf
sed -i 's/#applications\/mod_random/applications\/mod_random/' modules.conf
sed -i 's/#asr_tts\/mod_flite/asr_tts\/mod_flite/' modules.conf
sed -i 's/#asr_tts\/mod_pocketsphinx/asr_tts\/mod_pocketsphinx/' modules.conf
sed -i 's/#asr_tts\/mod_tts_commandline/asr_tts\/mod_tts_commandline/' modules.conf
sed -i 's/#asr_tts\/mod_unimrcp/asr_tts\/mod_unimrcp/' modules.conf
sed -i 's/#codecs\/mod_dahdi_codec/codecs\/mod_dahdi_codec/' modules.conf
sed -i 's/#dialplans\/mod_dialplan_directory/dialplans\/mod_dialplan_directory/' modules.conf
sed -i 's/#directories\/mod_ldap/directories\/mod_ldap/' modules.conf
sed -i 's/#endpoints\/mod_dingaling/endpoints\/mod_dingaling/' modules.conf
sed -i 's/#endpoints\/mod_opal/endpoints\/mod_opal/' modules.conf
sed -i 's/#endpoints\/mod_skinny/endpoints\/mod_skinny/' modules.conf
#sed -i 's/#endpoints\/mod_skypopen/endpoints\/mod_skypopen/' modules.conf #TODO check advanced installation needs from wiki
sed -i 's/#event_handlers\/mod_snmp/event_handlers\/mod_snmp/' modules.conf
sed -i 's/#formats\/mod_shout/formats\/mod_shout/' modules.conf
#sed -i 's/#formats\/mod_vlc/formats\/mod_vlc/' modules.conf #TODO needs libvlc >=2.0 which has very complex dependencies for compilation
sed -i 's/#languages\/mod_yaml/languages\/mod_yaml/' modules.conf
sed -i 's/#say\/mod_say_de/say\/mod_say_de/' modules.conf
sed -i 's/#xml_init\/mod_xml_curl/xml_init\/mod_xml_curl/' modules.conf
sed -i 's/#..\/..\/libs\/freetdm\/mod_freetdm/..\/..\/libs\/freetdm\/mod_freetdm/' modules.conf

echo -e "GBE: Building FreeSwitch ...\n"
./configure --prefix=/opt/freeswitch 2>&1
make 2>&1

echo -e "GBE: Installing FreeSwitch ...\n"
make all install 2>&1
echo "FREESWITCH_ENABLED=\"true\"
FREESWITCH_PARAMS=\"-nc\"
" > /etc/default/freeswitch

echo -e "GBE: Installing FreeSwitch sounds ...\n"
make hd-sounds-install \
	hd-moh-install \
	sounds-install \
	moh-install 2>&1

echo -e "GBE: Activating SNMP monitoring for FreeSwitch ...\n"
echo "
#  Listen on default named socket /var/agentx/master
#  agentXPerms  SOCKPERMS [DIRPERMS [USER|UID [GROUP|GID]]]
agentXPerms     0755 0755 freeswitch daemon
" >> /etc/snmp/snmpd.conf

echo -e "GBE: Setting up permissions ...\n"
adduser --system --quiet --disabled-password --disabled-login --ingroup daemon --home /opt/freeswitch freeswitch
adduser --quiet freeswitch ${GS_GROUP}

# Create FreeSWITCH log directory
#
mkdir /var/log/freeswitch/
chown -R freeswitch.adm /var/log/freeswitch
chown -R freeswitch.root /opt/freeswitch

echo -e "GBE: Cleaning up FreeSwitch sources ...\n"
rm -rf ${SRC_DIR}/*

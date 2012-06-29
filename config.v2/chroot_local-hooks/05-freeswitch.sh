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

echo -e "GBE: Enabling FreeSwitch ...\n"
echo "FREESWITCH_ENABLED=\"true\"
FREESWITCH_PARAMS=\"-nc\"
" > /etc/default/freeswitch

echo -e "GBE: Activating SNMP monitoring for FreeSwitch ...\n"
echo "
#  Listen on default named socket /var/agentx/master
#  agentXPerms  SOCKPERMS [DIRPERMS [USER|UID [GROUP|GID]]]
agentXPerms     0755 0755 freeswitch daemon
" >> /etc/snmp/snmpd.conf

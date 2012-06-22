#!/bin/bash
#
# Gemeinschaft 5
# Standard Linux Settings for Gemeinschaft 5
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

echo -e "\n###########################################################
## GBE: Gemeinschaft specific system configuration\n\n"

echo -e "GBE: Enable SNMP monitoring ...\n"
sed -i 's/# rocommunity public  localhost/rocommunity public default/' /etc/snmp/snmpd.conf

echo -e "GBE: Create local user ${GS_USER} and set default password ...\n"
useradd ${GS_USER} -U -m -s /bin/bash
echo "${GS_USER}:${GS_PASSWORD}" | chpasswd

echo -e "GBE: Correcting file permissions ...\n"
chmod 0440 /etc/sudoers.d/*

echo - "GBE: Enable bootlog ...\n"
sed -i 's/BOOTLOGD_ENABLE=No/BOOTLOGD_ENABLE=yes/' /etc/default/bootlogd

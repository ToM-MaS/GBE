#!/bin/bash
#
# Gemeinschaft 5
# Enable system services
#
# Copyright (c) 2012-2013, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

# check each command return codes for errors
#
set -e

# General settings
source /gdfdl.conf
[ -f /gdfdl-custom.conf ] && source /gdfdl-custom.conf

echo -e "\n###########################################################
## GBE: System bootup configuration\n\n"

echo -e "GBE: Enabling system services ...\n"
update-rc.d gemeinschaft-runtime-init defaults 2>&1
update-rc.d gemeinschaft-runtime-helper defaults 2>&1
update-rc.d gemeinschaft-runtime-init-post defaults 2>&1
update-rc.d mon_ami defaults 2>&1
[ -f /etc/default/shorewall ] && sed -i "s/^startup=.*\$/startup=1/" /etc/default/shorewall
[ -f /etc/default/shorewall6 ] && sed -i "s/^startup=.*\$/startup=1/" /etc/default/shorewall6

echo -e "GBE: Set initial file permissions and security settings ...\n"
/usr/local/bin/gs-enforce-security.sh | grep -Ev retained | grep -Ev "no changes" | grep -Ev "nor referent has been changed"

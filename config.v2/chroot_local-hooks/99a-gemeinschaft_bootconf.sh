#!/bin/bash
#
# Gemeinschaft 5
# Enable system services for Gemeinschaft 5
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
## GBE: Gemeinschaft specific system bootup configuration\n\n"

echo -e "GBE: Enabling Gemeinschaft specific system services ...\n"
update-rc.d freeswitch defaults 2>&1

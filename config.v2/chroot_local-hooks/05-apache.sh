#!/bin/bash
#
# Gemeinschaft 5
# Install Apache2 Passenger module for Gemeinschaft 5
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
## GBE: Webserver configuration\n\n"

echo -e "GBE: Installing Passenger version ${PASSENGER_VERSION} @Apache2 ...\n"
su - ${GS_USER} -c "gem install passenger --version ${PASSENGER_VERSION} 2>&1"
su - ${GS_USER} -c "passenger-install-apache2-module --auto 2>&1"

ln -snf \
  "`su - ${GS_USER} -c "passenger-config --root"`/ext/apache2/mod_passenger.so" \
  "/usr/lib/apache2/modules/mod_passenger.so"

cd "`su - ${GS_USER} -c "passenger-config --root"`/.."
[ ! -e "passenger" ] || rm -rf "passenger"

ln -snf \
  "`su - ${GS_USER} -c "passenger-config --root"`" \
  "`su - ${GS_USER} -c "passenger-config --root"`/../passenger"

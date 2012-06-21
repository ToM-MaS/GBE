#!/bin/bash
#
# Gemeinschaft 5
# Install Gemeinschaft 5
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
## GBE: Gemeinschaft installation\n\n"

echo -e "GBE: Downloading GS5 ...\n"

# Setup Github user credentials for login
#
if [ ! -z "${GS_GIT_USER}" -a ! -z "${GS_GIT_PASSWORD}" ]
then
	echo "Github credentials found!"
echo "machine Github.com
  login ${GS_GIT_USER}
  password ${GS_GIT_PASSWORD}
" >  ~/.netrc
fi

# use latest revision if no explicit revision was given
if [ x"${GS_BRANCH}" == x"" ]
then
	GS_BRANCH="master"
else
	echo "${GS_BRANCH}" > /etc/gemeinschaft_revision
fi

# Clone the git repository
#
set +e
c=1
while [[ $c -le 5 ]]
do
	git clone -b "${GS_BRANCH}" "${GS_GIT_URL}" "${GS_DIR}" 2>&1
	if [ "$?" -eq "0" ]; then
		break;
	else
		[[ $c -eq 5 ]] && exit 1
		(( c++ ))
		rm -rf "${GS_DIR}"
		echo "$c. try in 3 seconds ..."
		sleep 3
	fi
done
set -e

if [ -f "${GS_DIR}/config/application.rb" ]
then
  rm -rf ~/.netrc
else
  rm -rf ~/.netrc
  exit 1
fi

# Install delayed worker job
#
echo "W1:2345:respawn:/bin/su - gs5 -l -c \"cd ${GS_DIR}; RAILS_ENV=production rake jobs:work >> /var/log/gemeinschaft/worker.log 2>&1\"" >> /etc/inittab

# Create log dir
#
mkdir /var/log/gemeinschaft

# Set ownership
#
chown -R "${GS_USER}".root "${GS_DIR}" /var/log/gemeinschaft

echo -e "GBE: Installing GS5 gems ...\n"
su - ${GS_USER} -c "cd ${GS_DIR}; bundle install 2>&1"

echo -e "GBE: Creating FreeSWITCH configuration ...\n"
mv /opt/freeswitch/conf /opt/freeswitch/conf.default
mv /opt/freeswitch/scripts /opt/freeswitch/scripts.default
ln -s "${GS_DIR}/misc/freeswitch/conf" /opt/freeswitch/conf
ln -s "${GS_DIR}/misc/freeswitch/scripts" /opt/freeswitch/scripts

PASSENGER_ROOT="`su - ${GS_USER} -c "passenger-config --root"`"

echo -e "GBE: Adjusting Apache2 configuration ...\n"
echo "LoadModule passenger_module ${PASSENGER_ROOT}/ext/apache2/mod_passenger.so" > /etc/apache2/mods-available/passenger.load
echo "PassengerRoot ${PASSENGER_ROOT}
PassengerRuby /home/${GS_USER}/.rvm/wrappers/default/ruby

PassengerMaxPoolSize 4
PassengerMaxInstancesPerApp 3
# http://stackoverflow.com/questions/821820/how-does-phusion-passenger-reuse-threads-and-processes
# Both virtual hosts (PassengerAppRoot /opt/gemeinschaft) are actually
# the same application!

PassengerPoolIdleTime 200
PassengerMaxRequests 10000
PassengerLogLevel 0
RailsFrameworkSpawnerIdleTime 0
RailsAppSpawnerIdleTime 0
PassengerUserSwitching on
PassengerDefaultUser nobody
PassengerFriendlyErrorPages off
PassengerSpawnMethod smart-lv2" > /etc/apache2/mods-available/passenger.conf

# enable modules
a2enmod rewrite 2>&1
a2enmod ssl 2>&1
a2enmod passenger 2>&1
# enable virtual webserver
a2dissite default 2>&1
a2ensite gemeinschaft 2>&1

echo -e "GBE: Setting up permissions ...\n"
# Allow GS user to modify essential system configuration files
chgrp ${GS_GROUP} /etc/resolv.conf
chmod g+rw /etc/resolv.conf

#FIXME: really necessary to grant rw access to all group members, resp. all daemons?
#chmod -R g+w "${GS_DIR}"

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
GDFDL_BUILDNAME="`cat /etc/gdfdl_build`"
[[ ${GDFDL_BUILDNAME} =~ "-" ]] && GDFDL_BRANCH=`echo ${GDFDL_BUILDNAME} | cut -d - -f2` || GDFDL_BRANCH="master"

echo -e "\n###########################################################
## GBE: Gemeinschaft installation\n\n"

# Clone the git repository
#
if [[ ! -d "${GS_DIR}" ]];
	then

	# use master branch if no explicit branch was given and GBE branch is master
	[[ x"${GS_BRANCH}" == x"" && x"${GDFDL_BRANCH}" == x"develop" ]] && GS_BRANCH="develop"
	[[ x"${GS_BRANCH}" == x"" && x"${GDFDL_BRANCH}" != x"develop" ]] && GS_BRANCH="master"
	[[ ! -f /etc/gemeinschaft_branch ]] && echo "${GS_BRANCH}" > /etc/gemeinschaft_branch

	echo -e "GBE: Downloading GS from ${GS_GIT_URL} (branch: ${GS_BRANCH}) ...\n"

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
	
	set +e
	c=1
	while [[ $c -le 5 ]]
	do
		git clone -b "${GS_BRANCH}" "${GS_GIT_URL}" "${GS_DIR}" 2>&1
		if [ "$?" -eq "0" ]
			then
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

	[ -f "${GS_DIR}/config/application.rb" ] && rm -rf ~/.netrc
fi

#  Create alias for GS5 backwards compatibility
#
GS_DIR_SHORT=`dirname "${GS_DIR}"`/GS5
ln -s `basename "${GS_DIR}"` "${GS_DIR_SHORT}"

# Install GS related Gems
#
echo -e "GBE: Install GS gems ...\n"
su - ${GS_USER} -c "cd ${GS_DIR}; bundle install 2>&1"

# Install delayed worker job
#
echo -e "GBE: Install delayed worker job ...\n"
echo "W1:2345:respawn:/bin/su - ${GS_USER} -l -c \"cd ${GS_DIR}; RAILS_ENV=production bundle exec rake jobs:work 2>&1 >/dev/null\"" >> /etc/inittab

# Install cronjobs
#
echo -e "GBE: Install cronjobs ...\n"
[ ! -d /etc/cron.d ] && mkdir -p /etc/cron.d
echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin
SHELL=/var/lib/${GS_USER}/.rvm/bin/rvm-shell
RAILS_ENV=production
23 1 * * * ${GS_USER} ${GS_DIR}/script/logout_phones
* * * * * ${GS_USER} ( cd ${GS_DIR}; bundle exec rake send_voicemail_notifications )
* * * * * ${GS_USER} ( sleep 30; cd ${GS_DIR}; bundle exec rake send_fax_notifications )" > /etc/cron.d/gemeinschaft_rvm

# Create log dir
#
echo -e "GBE: Create logfile directory ...\n"
[ ! -d /var/log/gemeinschaft ] && mkdir -p /var/log/gemeinschaft

# Create local configuration dir
#
GS_DIR_LOCAL="${GS_DIR}-local"
mkdir -p ${GS_DIR_LOCAL}/config
mkdir -p ${GS_DIR_LOCAL}/freeswitch/conf
mkdir -p ${GS_DIR_LOCAL}/freeswitch/scripts/ini

# Make initial copy of local configuration files
#
cp -r ${GS_DIR}/config ${GS_DIR_LOCAL}
cp -r ${GS_DIR}/misc/freeswitch/conf ${GS_DIR_LOCAL}/freeswitch
cp -r ${GS_DIR}/misc/freeswitch/scripts/ini ${GS_DIR_LOCAL}/freeswitch/scripts

# Link FS configs
echo -e "GBE: Link FreeSWITCH configuration ...\n"
[ ! -d /etc/freeswitch ] && mkdir -p /etc/freeswitch
[ -d /usr/share/freeswitch/scripts ] && rm -rf /usr/share/freeswitch/scripts
ln -s "${GS_DIR_LOCAL}/freeswitch/conf/freeswitch.xml" /etc/freeswitch/freeswitch.xml
ln -s "${GS_DIR}/misc/freeswitch/scripts" /usr/share/freeswitch/scripts

# Move Freeswitch storage files
mv /var/lib/freeswitch/db ${GS_DIR_LOCAL}/freeswitch/db
mv /var/lib/freeswitch/storage ${GS_DIR_LOCAL}/freeswitch/storage
mv /var/lib/freeswitch/recordings ${GS_DIR_LOCAL}/freeswitch/recordings
ln -s ${GS_DIR_LOCAL}/freeswitch/db /var/lib/freeswitch/db
ln -s ${GS_DIR_LOCAL}/freeswitch/storage /var/lib/freeswitch/storage
ln -s ${GS_DIR_LOCAL}/freeswitch/recordings /var/lib/freeswitch/recordings

#FIXME this should be avoided in the future, /var/log/gemeinschaft should be used directly
echo -e "GBE: Setup loggin directory ...\n"
rm -rf "${GS_DIR}/log"
ln -sf /var/log/gemeinschaft "${GS_DIR}/log"

# compatibility with manual installation and GS default directories
ln -s /etc/freeswitch /opt/freeswitch/conf
ln -s /usr/share/freeswitch/scripts /opt/freeswitch/scripts

#FIXME this is definitely a hack! correct path in GS Lua scripts would be a better idea...
ln -s /usr/share/freeswitch/scripts /usr/scripts
ln -s /var/lib/freeswitch/db /usr/db
ln -s /var/lib/freeswitch/recordings /usr/recordings
ln -s /var/lib/freeswitch/storage /usr/storage
ln -s /usr/lib/lua /usr/local/lib/lua

#FIXME another hack for ruby/rails environment as GS scripts explicitly uses this path for sourcing
#      (although excplicit sourcing is deprecated from GBE perspective)
mkdir -p /usr/local/rvm/scripts
ln -s /var/lib/${GS_USER}/.rvm/scripts/rvm /usr/local/rvm/scripts/rvm

PASSENGER_ROOT="`su - ${GS_USER} -c "passenger-config --root"`"

echo -e "GBE: Adjust Apache2 configuration ...\n"
echo "LoadModule passenger_module ${PASSENGER_ROOT}/ext/apache2/mod_passenger.so" > /etc/apache2/mods-available/passenger.load
echo "PassengerRoot ${PASSENGER_ROOT}
PassengerRuby /var/lib/${GS_USER}/.rvm/wrappers/default/ruby

PassengerMaxPoolSize 4
PassengerMaxInstancesPerApp 3
# http://stackoverflow.com/questions/821820/how-does-phusion-passenger-reuse-threads-and-processes
# Both virtual hosts (PassengerAppRoot ${GS_DIR}) are actually
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

echo "<IfModule mpm_prefork_module>
    StartServers          2
    MinSpareServers       1
    MaxSpareServers       4
    MaxClients           50
    MaxRequestsPerChild   0
</IfModule>


HostnameLookups Off
KeepAlive On
MaxKeepAliveRequests 40
KeepAliveTimeout 60
Timeout 100

<VirtualHost *:80>
	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined
	LogLevel error

	DocumentRoot ${GS_DIR}/public

	PassengerEnabled on
	PassengerAppRoot ${GS_DIR}
	PassengerMinInstances 1
	PassengerPreStart http://127.0.0.1:80/
	PassengerStatThrottleRate 10
	PassengerSpawnMethod smart-lv2
	PassengerUseGlobalQueue on
	PassengerUser  ${GS_USER}
	PassengerGroup ${GS_GROUP}

	# http://blog.phusion.nl/2010/01/08/phusion-passenger-2-2-9-released/
	# http://blog.phusion.nl/2010/07/29/the-road-to-passenger-3-technology-preview-4-adding-new-features-and-removing-old-limitations/
	RailsBaseURI /
	#RackBaseURI  /
	RailsEnv development
	#RackEnv  development

	<Directory ${GS_DIR}/public>
		AllowOverride all
		Options -MultiViews
		Options FollowSymLinks
	</Directory>
</VirtualHost>


<VirtualHost *:443>
	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined
	LogLevel error

	DocumentRoot ${GS_DIR}/public

	PassengerEnabled on
	PassengerAppRoot ${GS_DIR}
	PassengerMinInstances 1
	PassengerPreStart https://127.0.0.1:443/
	PassengerStatThrottleRate 10
	PassengerSpawnMethod smart-lv2
	PassengerUseGlobalQueue on
	PassengerUser  ${GS_USER}
	PassengerGroup ${GS_GROUP}

	# http://blog.phusion.nl/2010/01/08/phusion-passenger-2-2-9-released/
	# http://blog.phusion.nl/2010/07/29/the-road-to-passenger-3-technology-preview-4-adding-new-features-and-removing-old-limitations/
	RailsBaseURI /
	#RackBaseURI  /
	RailsEnv development
	#RackEnv  development

	<Directory ${GS_DIR}/public>
		AllowOverride all
		Options -MultiViews
		Options FollowSymLinks
	</Directory>
        
	SSLEngine on
	SSLCertificateFile    /etc/ssl/gemeinschaft.crt
	SSLCertificateKeyFile /etc/ssl/gemeinschaft.key
</VirtualHost>" > /etc/apache2/sites-available/gemeinschaft

# enable modules
a2enmod rewrite 2>&1
a2enmod ssl 2>&1
a2enmod passenger 2>&1
# enable virtual webserver
a2dissite default 2>&1
a2ensite gemeinschaft 2>&1

echo -e "GBE: Setup runtime user for MonAMI ...\n"
sed -i "s/^USER=.*/USER=\"${GS_USER}\"/" /etc/init.d/mon_ami

echo -e "GBE: Set permissions ...\n"
chown -R "${GS_USER}"."${GS_GROUP}" "${GS_DIR}" "${GS_DIR_LOCAL}/config" /var/log/gemeinschaft
# Allow members of the GS system group to modify+upgrade files
chmod -R g+w "${GS_DIR}" "${GS_DIR_LOCAL}/config"
# Restrict access to configuration and logfiles
chmod 0770 "${GS_DIR_LOCAL}/config" /var/log/gemeinschaft
# add GS system user to freeswitch group
usermod -a -G freeswitch ${GS_USER} 
# Set permissions for FreeSwitch configurations
chmod 0640 "${GS_DIR_LOCAL}/freeswitch/scripts/ini/database.ini" "${GS_DIR_LOCAL}/freeswitch/scripts/ini/sofia.ini" "${GS_DIR_LOCAL}/freeswitch/conf/freeswitch.xml"
chown .freeswitch "${GS_DIR_LOCAL}/freeswitch/scripts/ini/database.ini" "${GS_DIR_LOCAL}/freeswitch/scripts/ini/sofia.ini" "${GS_DIR_LOCAL}/freeswitch/conf/freeswitch.xml"

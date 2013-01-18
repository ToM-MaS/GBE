#!/bin/bash
#
# Gemeinschaft 5
# Install Gemeinschaft 5
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
else
	[ -f /etc/gemeinschaft_branch ] && GS_BRANCH="`cat /etc/gemeinschaft_branch`"

	#FIXME lazy workaround for Jenkins who loses our branch names ...
	cd "${GS_DIR}"
	git checkout -b "${GS_BRANCH}"
	cd -
fi

# Make sure we checkout the latest tagged version in case we are in the master branch
if [ "${GS_BRANCH}" == "master" ]; then
	cd "${GS_DIR}"
	git checkout `git tag -l | tail -n1`
	cd -
fi

#  Create alias for GS5 backwards compatibility
#
GS_DIR_NORMALIZED=`dirname "${GS_DIR}"`/gemeinschaft
ln -s `basename "${GS_DIR}"` "${GS_DIR_NORMALIZED}"

# Install GS related Gems
#
echo -e "GBE: Install GS gems ...\n"
su - ${GS_USER} -c "cd ${GS_DIR}; bundle install 2>&1"

# Install delayed worker job
#
echo -e "GBE: Install delayed worker job ...\n"
echo "W1:2345:respawn:/bin/su - ${GS_USER} -l -c \"cd ${GS_DIR_NORMALIZED}; RAILS_ENV=production bundle exec rake jobs:work 2>&1 >/dev/null\"" >> /etc/inittab

# Install cronjobs
#
echo -e "GBE: Install cronjobs ...\n"
[ ! -d /etc/cron.d ] && mkdir -p /etc/cron.d
echo "PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
SHELL=/var/lib/gemeinschaft/.rvm/bin/rvm-shell
RAILS_ENV=production
23 1 * * * ${GS_USER} ${GS_DIR_NORMALIZED}/script/logout_phones
* * * * * ${GS_USER} ( cd ${GS_DIR_NORMALIZED}; bundle exec rake send_voicemail_notifications )
* * * * * ${GS_USER} ( sleep 30; cd ${GS_DIR_NORMALIZED}; bundle exec rake send_fax_notifications )" > /etc/cron.d/gemeinschaft_rvm

# Create log dir
#
echo -e "GBE: Create logfile directory ...\n"
[ ! -d /var/log/gemeinschaft ] && mkdir -p /var/log/gemeinschaft
[ ! -d /var/log/mon_ami ] && mkdir -p /var/log/mon_ami

# Create local configuration dir
#
GS_DIR_LOCAL="/var/opt/`basename "${GS_DIR}"`"
GS_DIR_NORMALIZED_LOCAL="`dirname "${GS_DIR_LOCAL}"`/`basename "${GS_DIR_NORMALIZED}"`"
mkdir -p ${GS_DIR_LOCAL}/freeswitch/conf
ln -s `basename "${GS_DIR_LOCAL}"` "${GS_DIR_NORMALIZED_LOCAL}"

# Link FS configs
echo -e "GBE: Link FreeSWITCH configuration ...\n"
[ -d /etc/freeswitch ] && rm -rf /etc/freeswitch
ln -s "${GS_DIR_NORMALIZED_LOCAL}/freeswitch/conf" /etc/freeswitch
[ -d /usr/conf ] && rm -rf /usr/conf
ln -s /etc/freeswitch /usr/conf
[ -d /usr/share/freeswitch/scripts ] && rm -rf /usr/share/freeswitch/scripts
ln -s "${GS_DIR_NORMALIZED}/misc/freeswitch/scripts" /usr/share/freeswitch/scripts

# Move Freeswitch storage files
mv /var/lib/freeswitch/db ${GS_DIR_LOCAL}/freeswitch/db
mv /var/lib/freeswitch/storage ${GS_DIR_LOCAL}/freeswitch/storage
mv /var/lib/freeswitch/recordings ${GS_DIR_LOCAL}/freeswitch/recordings
ln -s ${GS_DIR_NORMALIZED_LOCAL}/freeswitch/db /var/lib/freeswitch/db
ln -s ${GS_DIR_NORMALIZED_LOCAL}/freeswitch/storage /var/lib/freeswitch/storage
ln -s ${GS_DIR_NORMALIZED_LOCAL}/freeswitch/recordings /var/lib/freeswitch/recordings

#FIXME this is definitely a hack! correct path in GS Lua scripts would be a better idea...
ln -s /usr/share/freeswitch/scripts /usr/scripts
ln -s /var/lib/freeswitch/db /usr/db
ln -s /var/lib/freeswitch/recordings /usr/recordings
ln -s /var/lib/freeswitch/storage /usr/storage
ln -s /usr/lib/lua /usr/local/lib/lua

#FIXME another hack for ruby/rails environment as GS scripts explicitly uses this path for sourcing
#      (although excplicit sourcing is deprecated from GBE perspective)
mkdir -p /usr/local/rvm/scripts
ln -s /var/lib/gemeinschaft/.rvm/scripts/rvm /usr/local/rvm/scripts/rvm

PASSENGER_ROOT="`su - ${GS_USER} -c "passenger-config --root"`"

echo -e "GBE: Adjust Apache2 configuration ...\n"
echo "LoadModule passenger_module ${PASSENGER_ROOT}/ext/apache2/mod_passenger.so" > /etc/apache2/mods-available/passenger.load
echo "PassengerRoot ${PASSENGER_ROOT}
PassengerRuby /var/lib/gemeinschaft/.rvm/wrappers/default/ruby

PassengerMaxPoolSize 4
PassengerMaxInstancesPerApp 3
# http://stackoverflow.com/questions/821820/how-does-phusion-passenger-reuse-threads-and-processes
# Both virtual hosts (PassengerAppRoot ${GS_DIR_NORMALIZED}) are actually
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

	DocumentRoot ${GS_DIR_NORMALIZED}/public

	PassengerEnabled on
	PassengerAppRoot ${GS_DIR_NORMALIZED}
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

	<Directory ${GS_DIR_NORMALIZED}/public>
		AllowOverride all
		Options -MultiViews
		Options FollowSymLinks
	</Directory>
</VirtualHost>


<VirtualHost *:443>
	ErrorLog \${APACHE_LOG_DIR}/error.log
	CustomLog \${APACHE_LOG_DIR}/access.log combined
	LogLevel error

	DocumentRoot ${GS_DIR_NORMALIZED}/public

	PassengerEnabled on
	PassengerAppRoot ${GS_DIR_NORMALIZED}
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

	<Directory ${GS_DIR_NORMALIZED}/public>
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

# Check if we have a production or development state build
# (production = master-branch was used from GS5 and GBE repo)
#
GS_BUILDNAME="`cat /etc/gdfdl_build`"
if [[ `expr length ${GS_BUILDNAME}` == 10 && x${GS_BRANCH} = x"master" ]]
	then
	GS_ENV="production"
else
	GS_ENV="development"
fi

echo -e "GBE: Write local settings file ..."
mkdir -p /etc/gemeinschaft
echo "GS_DIR=\"${GS_DIR}\"" >> /etc/gemeinschaft/system.conf
echo "GS_DIR_LOCAL=\"${GS_DIR_LOCAL}\"" >> /etc/gemeinschaft/system.conf
echo "GS_DIR_NORMALIZED=\"${GS_DIR_NORMALIZED}\"" >> /etc/gemeinschaft/system.conf
echo "GS_DIR_NORMALIZED_LOCAL=\"${GS_DIR_NORMALIZED_LOCAL}\"" >> /etc/gemeinschaft/system.conf
echo "GS_USER=\"${GS_USER}\"" >> /etc/gemeinschaft/system.conf
echo "GS_GROUP=\"${GS_GROUP}\"" >> /etc/gemeinschaft/system.conf
echo "GS_BRANCH=\"${GS_BRANCH}\""  >> /etc/gemeinschaft/system.conf
echo "GS_BUILDNAME=\"${GS_BUILDNAME}\""  >> /etc/gemeinschaft/system.conf
echo "GS_MYSQL_USER=\"gemeinschaft\""  >> /etc/gemeinschaft/system.conf
echo "GS_MYSQL_DB=\"\${GS_MYSQL_USER}\""  >> /etc/gemeinschaft/system.conf
echo "GS_MYSQL_PASSWORD_FILE=\"/var/lib/gemeinschaft/.gs_mysql_password\""  >> /etc/gemeinschaft/system.conf
echo "GS_GIT_URL=\"${GS_GIT_URL}\"" >> /etc/gemeinschaft/system.conf
echo "GS_ENFORCE_SECURITY_ON_BOOTUP=true" >> /etc/gemeinschaft/system.conf
echo "GS_ENV=\"${GS_ENV}\"" >> /etc/gemeinschaft/system.conf
echo "RAILS_ENV=$GS_ENV" >> /etc/gemeinschaft/system.conf
rm -f /etc/gemeinschaft_branch /etc/gdfdl_build

# set GS variables as global ENV variables
[ -f /etc/environment ] && rm /etc/environment
ln -s /etc/gemeinschaft/system.conf /etc/environment

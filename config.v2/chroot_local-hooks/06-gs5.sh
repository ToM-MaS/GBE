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

# use master branch if no explicit branch was given
[ x"${GS_BRANCH}" == x"" ] && GS_BRANCH="master"
echo "${GS_BRANCH}" > /etc/gemeinschaft_branch

# Clone the git repository
#
if [[ ! -d "${GS_DIR}" ]];
	then

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

#  Create alias
GS_DIR_NORMALIZED=`dirname "${GS_DIR}"`/gemeinschaft
ln -s `filename("${GS_DIR}")` "${GS_DIR_NORMALIZED}"

# Install delayed worker job
#
echo -e "GBE: Install delayed worker job ...\n"
echo "W1:2345:respawn:/bin/su - ${GS_USER} -l -c \"cd ${GS_DIR_NORMALIZED}; RAILS_ENV=production bundle exec rake jobs:work >> /var/log/gemeinschaft/worker.log 2>&1\"" >> /etc/inittab

# Install cronjobs
#
echo -e "GBE: Install cronjobs ...\n"
[ ! -d /etc/cron.d ] && mkdir -p /etc/cron.d
echo "23 1 * * * ${GS_USER} ${GS_DIR_NORMALIZED}/script/logout_phones.sh" > /etc/cron.d/gemeinschaft

# Create log dir
#
echo -e "GBE: Create logfile directory ...\n"
[ ! -d /var/log/gemeinschaft ] && mkdir -p /var/log/gemeinschaft

echo -e "GBE: Installing GS gems ...\n"
su - ${GS_USER} -c "cd ${GS_DIR}; bundle install 2>&1"

echo -e "GBE: Linking FreeSWITCH configuration ...\n"
[ ! -d /etc/freeswitch ] && mkdir -p /etc/freeswitch
[ -d /usr/share/freeswitch/scripts ] && rm -rf /usr/share/freeswitch/scripts
ln -s "${GS_DIR_NORMALIZED}/misc/freeswitch/conf/freeswitch.xml" /etc/freeswitch/freeswitch.xml
ln -s "${GS_DIR_NORMALIZED}/misc/freeswitch/scripts" /usr/share/freeswitch/scripts

echo -e "GBE: Setup loggin directory ...\n"
rm -rf "${GS_DIR}/log"
ln -sf /var/log/gemeinschaft "${GS_DIR}/log"

#FIXME compatibility with manual installation and GS default directories
ln -s "${GS_DIR_NORMALIZED}/misc/freeswitch/conf" /opt/freeswitch/conf
ln -s "${GS_DIR_NORMALIZED}/misc/freeswitch/scripts" /opt/freeswitch/scripts

#FIXME this is definitely a hack! correct path in GS Lua scripts would be a better idea...
ln -s /usr/share/freeswitch/scripts /usr/scripts
ln -s /var/lib/freeswitch/db /usr/db
ln -s /var/lib/freeswitch/recordings /usr/recordings
ln -s /var/lib/freeswitch/storage /usr/storage
ln -s /usr/lib/lua /usr/local/lib/lua

PASSENGER_ROOT="`su - ${GS_USER} -c "passenger-config --root"`"

echo -e "GBE: Adjusting Apache2 configuration ...\n"
echo "LoadModule passenger_module ${PASSENGER_ROOT}/ext/apache2/mod_passenger.so" > /etc/apache2/mods-available/passenger.load
echo "PassengerRoot ${PASSENGER_ROOT}
PassengerRuby /var/lib/${GS_USER}/.rvm/wrappers/default/ruby

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
	ErrorLog  \"|/usr/bin/logger -t apache -i -p local6.info\" 
	CustomLog \"|/usr/bin/logger -t apache -i -p local6.info\" combined

	RewriteEngine on

	# Workaround for Apache2 exploit
	# http://mail-archives.apache.org/mod_mbox/httpd-announce/201108.mbox/%3C20110826103531.998348F82@minotaur.apache.org%3E
	RewriteCond %{REQUEST_METHOD} ^(HEAD|GET) [NC]
	RewriteCond %{HTTP:Range} ([0-9]*-[0-9]*)(\s*,\s*[0-9]*-[0-9]*)+
	RewriteRule .* - [F]

	RewriteCond %{HTTP_HOST} 127.0.0.1|localhost
	RewriteRule ^.* - [L]
	RewriteCond %{REQUEST_URI} ^/(settings)
	RewriteRule ^.* - [L]

	RewriteRule ^/(.*) https://%{HTTP_HOST}/$1 [R,L]

	SetEnvIf Request_URI \"^/freeswitch-call-processing/actions\" downgrade-1.0 no-gzip no-cache
	BrowserMatch \"^freeswitch-spidermonkey-curl/1\\.\" downgrade-1.0 no-gzip no-cache
	BrowserMatch \"^freeswitch-xml/1\\.\" downgrade-1.0 no-gzip no-cache

	DocumentRoot ${GS_DIR_NORMALIZED}/public

	PassengerEnabled on
	PassengerAppRoot ${GS_DIR_NORMALIZED}
	PassengerMinInstances 1
	PassengerPreStart http://127.0.0.1:80/
	PassengerStatThrottleRate 10
	PassengerSpawnMethod smart-lv2
	PassengerUseGlobalQueue on
	PassengerUser  ${GS_USER}
	#PassengerGroup www-data

	# http://blog.phusion.nl/2010/01/08/phusion-passenger-2-2-9-released/
	# http://blog.phusion.nl/2010/07/29/the-road-to-passenger-3-technology-preview-4-adding-new-features-and-removing-old-limitations/
	RailsBaseURI /
	#RackBaseURI  /
	RailsEnv production
	#RackEnv  production

	<Directory ${GS_DIR_NORMALIZED}/public>
		AllowOverride all
		Options -MultiViews
		Options FollowSymLinks
	</Directory>
</VirtualHost>


<VirtualHost *:443>
	ErrorLog  \"|/usr/bin/logger -t apache -i -p local6.info\"
	CustomLog \"|/usr/bin/logger -t apache -i -p local6.info\" combined

	RewriteEngine on

	# Workaround for Apache2 exploit
	# http://mail-archives.apache.org/mod_mbox/httpd-announce/201108.mbox/%3C20110826103531.998348F82@minotaur.apache.org%3E
	RewriteCond %{REQUEST_METHOD} ^(HEAD|GET) [NC]
	RewriteCond %{HTTP:Range} ([0-9]*-[0-9]*)(\s*,\s*[0-9]*-[0-9]*)+
	RewriteRule .* - [F]

	SetEnvIf Request_URI \"^/freeswitch-call-processing/actions\" downgrade-1.0 no-gzip no-cache
	BrowserMatch \"^freeswitch-spidermonkey-curl/1\\.\" downgrade-1.0 no-gzip no-cache
	BrowserMatch \"^freeswitch-xml/1\\.\" downgrade-1.0 no-gzip no-cache

	DocumentRoot ${GS_DIR_NORMALIZED}/public

	PassengerEnabled on
	PassengerAppRoot ${GS_DIR_NORMALIZED}
	PassengerMinInstances 1
	PassengerPreStart https://127.0.0.1:443/
	PassengerStatThrottleRate 10
	PassengerSpawnMethod smart-lv2
	PassengerUseGlobalQueue on
	PassengerUser  ${GS_USER}
	#PassengerGroup www-data

	# http://blog.phusion.nl/2010/01/08/phusion-passenger-2-2-9-released/
	# http://blog.phusion.nl/2010/07/29/the-road-to-passenger-3-technology-preview-4-adding-new-features-and-removing-old-limitations/
	RailsBaseURI /
	#RackBaseURI  /
	RailsEnv production
	#RackEnv  production

	<Directory ${GS_DIR_NORMALIZED}/public>
		AllowOverride all
		Options -MultiViews
		Options FollowSymLinks
	</Directory>
        
        SSLVerifyClient none

       <Files ~ \"settings-.*\">
          SSLVerifyClient require
          SSLVerifyDepth 1
        </Files>	
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

echo -e "GBE: Setting up permissions ...\n"
chown -R "${GS_USER}"."${GS_GROUP}" "${GS_DIR}" /var/log/gemeinschaft
# Allow members of the GS system group to modify+upgrade files
chmod -R g+w "${GS_DIR}"
# Restrict access to configuration and logfiles
chmod 0770 "${GS_DIR}/config" /var/log/gemeinschaft

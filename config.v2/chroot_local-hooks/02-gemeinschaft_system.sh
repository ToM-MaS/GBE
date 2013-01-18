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

# Upgrade kernel to 3.2
echo -e "GBE: Kernel upgrade ...\n"
apt-get -y --force-yes -t squeeze-backports install linux-image-3.2.0-0.bpo.4-686-pae firmware-linux-free

echo -e "GBE: Create service group '${GS_GROUP}' ...\n"
groupadd -r -f ${GS_GROUP}

echo -e "GBE: Create service account ${GS_USER} ...\n"
# hint: This should be a system service account (-s) or at least UID needs to be != 1000
# otherwise live-config user setup will not work correctly.
useradd ${GS_USER} -N -m -r -d /var/lib/${GS_USER} -s /bin/bash -c "Gemeinschaft Service Account" -g ${GS_GROUP}
ln -s ${GS_USER} /var/lib/gemeinschaft

echo -e "GBE: Create service account mon_ami ...\n"
# hint: This should be a system service account (-s) or at least UID needs to be != 1000
# otherwise live-config user setup will not work correctly.
useradd mon_ami -m -r -d /var/lib/mon_ami -s /bin/bash -c "MonAMI Service Account"

echo -e "GBE: Configuring Postfix ...\n"
# Disable TLS for INCOMING mails to avoid certificate issues
# when Gemeinschaft wants to send mails
sed -i 's/smtpd_use_tls=yes/smtpd_use_tls=no/' /etc/postfix/main.cf
# Enable TLS for OUTGOING mails so that emails to users can be encrypted
echo "smtp_use_tls = yes" >> /etc/postfix/main.cf
echo "smtp_tls_security_level = may" >> /etc/postfix/main.cf
echo "smtpd_tls_CApath = /etc/ssl/certs" >> /etc/postfix/main.cf
echo "smtpd_tls_cert_file=/etc/ssl/gemeinschaft.crt" >> /etc/postfix/main.cf
echo "smtpd_tls_key_file=/etc/ssl/gemeinschaft.key" >> /etc/postfix/main.cf
echo "${GS_USER}: root" >> /etc/aliases
echo "gsmaster: root" >> /etc/aliases
newaliases

echo - "GBE: Configuring NTP server ...\n"
sed -i "s/^server.*\$//" /etc/ntp.conf
echo "server 0.de.pool.ntp.org" >> /etc/ntp.conf
echo "server 1.de.pool.ntp.org" >> /etc/ntp.conf
echo "server 2.de.pool.ntp.org" >> /etc/ntp.conf
echo "server 3.de.pool.ntp.org" >> /etc/ntp.conf

echo -e "GBE: Setup name resolution ...\n"
rm -rf /etc/resolv.conf
ln -s /etc/resolvconf/run/resolv.conf /etc/resolv.conf
echo "REPORT_ABSENT_SYMLINK=no" > /etc/default/resolvconf

echo -e "GBE: Adjust syslog facilities ...\n"
sed -i "s/filter f_syslog3 { not facility(auth, authpriv, mail) and not filter(f_debug); };/filter f_syslog3 { not facility(auth, authpriv, mail, cron) and not filter(f_debug); };/" /etc/syslog-ng/syslog-ng.conf

#FIXME temporal workaround for timezone issues between GS5 call logs and actual local time
echo -e "GBE: Setup MySQL default time zone ...\n"
echo "[mysqld]" > /etc/mysql/conf.d/gemeinschaft.cnf
echo "default-time-zone='+00:00'" >> /etc/mysql/conf.d/gemeinschaft.cnf

echo -e "GBE: Enable bootlog ...\n"
sed -i 's/BOOTLOGD_ENABLE=No/BOOTLOGD_ENABLE=yes/' /etc/default/bootlogd

echo -e "GBE: Installing nodejs ...\n"
cd /usr/local/src
wget -c -t 5 --waitretry=3 http://nodejs.org/dist/node-${NODEJS_VERSION}.tar.gz
tar xzvf node-*.tar.gz && cd `ls -rd node-v*` && ./configure && make install
cd ..
rm -rf node-*

echo -e "GBE: Add Debian APT sources ...\n"
echo "deb http://cdn.debian.net/debian/ squeeze main contrib" >> /etc/apt/sources.list

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

echo -e "GBE: Create service group '${GS_GROUP}' ...\n"
groupadd -r -f ${GS_GROUP}

echo -e "GBE: Create service account ${GS_USER} ...\n"
# hint: This should be a system service account (-s) or at least UID needs to be != 1000
# otherwise live-config user setup will not work correctly.
useradd ${GS_USER} -N -m -r -d /var/lib/${GS_USER} -s /bin/bash -c "Gemeinschaft Service Account" -g ${GS_GROUP}

# Allow service account some system commands via sudo
echo "Cmnd_Alias BACKUP = /usr/bin/nohup /usr/local/bin/backup_system.sh *" > /etc/sudoers.d/gemeinschaft
echo "Cmnd_Alias SHUTDOWN = /sbin/shutdown -h now" >> /etc/sudoers.d/gemeinschaft
echo "Cmnd_Alias REBOOT = /sbin/shutdown -r now" >> /etc/sudoers.d/gemeinschaft
echo "${GS_USER} ALL = (ALL) NOPASSWD: SHUTDOWN, REBOOT, BACKUP" >> /etc/sudoers.d/gemeinschaft

echo -e "GBE: Correcting file permissions ...\n"
chmod -R g+w /var/lib/${GS_USER}
chmod 0770 /var/lib/${GS_USER}
chmod 0440 /etc/sudoers.d/*

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

echo - "GBE: Enable bootlog ...\n"
sed -i 's/BOOTLOGD_ENABLE=No/BOOTLOGD_ENABLE=yes/' /etc/default/bootlogd

echo - "GBE: Enable local firewall ...\n"

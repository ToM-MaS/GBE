#!/bin/bash
#
# Gemeinschaft 5
# Build Xsession settings for Gemeinschaft 5
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
## GBE: Xsession configuration\n\n"

echo -e "GBE: Setup Xsession for user ${GS_USER} ...\n"
cat > /home/${GS_USER}/.xinitrc << EOF
#!/bin/bash
# give a nice white background for when Firefox reloads
xsetroot -solid white &
# optionally, the above can be commented out and the one below
# can be uncommented to use an image for the background (only 
# if xli is installed)
#xli - onroot -quiet /home/${GS_USER}/ad-or-logo.png &

# Start browser
iceweasel http://localhost/

# reboot after browser has been closed
shutdown -r now
EOF

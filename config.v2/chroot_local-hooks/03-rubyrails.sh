#!/bin/bash
#
# Gemeinschaft 5
# Build Ruby/Rails environment for Gemeinschaft 5
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
## GBE: Ruby/Rails installation\n\n"

echo -e "GBE: Install RVM version ${RVM_VERSION} ...\n"
su - ${GS_USER} -c "curl --retry 5 --fail --silent -L get.rvm.io | bash -s ${RVM_VERSION} 2>&1"

echo -e "GBE: Modify Shell enviroment for RVM usage ...\n"
echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"' >> /var/lib/${GS_USER}/.bashrc

echo -e "GBE: Disable ri and rdoc generation ...\n"
echo "gem: --no-ri --no-rdoc" > /var/lib/${GS_USER}/.gemrc
chown ${GS_USER}.${GS_GROUP} /var/lib/${GS_USER}/.gemrc

echo -e "GBE: Install Ruby version ${RUBY_VERSION} ...\n"
su - ${GS_USER} -c "rvm install ${RUBY_VERSION} 2>&1"

echo -e "GBE: Set Ruby default version ...\n"
su - ${GS_USER} -c "rvm use ${RUBY_VERSION} --default 2>&1"

echo -e "GBE: Update Ruby Gems version ${RUBY_GEMS_VERSION} ...\n"
su - ${GS_USER} -c "rvm rubygems ${RUBY_GEMS_VERSION} 2>&1"

echo -e "GBE: Install Rails ${RAILS_VERSION} ...\n"
su - ${GS_USER} -c "gem install rails --version '~> ${RAILS_VERSION}' 2>&1"

#!/bin/sh
#
# Gemeinschaft 5
# live-helper hook to update syslinux boot menu
#
# Copyright (c) 2012, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

LB_BOOTAPPEND_LIVE_DE="timezone=Europe/Berlin locales=de_DE.UTF-8 keyboard-layouts=de"
LB_BOOTAPPEND_LIVE_CH="timezone=Europe/Zurich locales=de_CH.UTF-8 keyboard-layouts=ch"
LB_BOOTAPPEND_LIVE_EN="timezone=Europe/London locales=en_US.UTF-8 keyboard-layouts=us"
SELF="`pwd`"

# Copy default files
echo "Copy files from ${SELF}/config/binary_syslinux/ to ${SELF}/binary/isolinux/ ..."
cp -pf ${SELF}/config/binary_syslinux/splash.png ${SELF}/binary/isolinux/
cp -pf ${SELF}/config/binary_syslinux/stdmenu.cfg ${SELF}/binary/isolinux/
cp -pf ${SELF}/config/binary_syslinux/menu.cfg ${SELF}/binary/isolinux/

# Live boot menu
echo "Generating ${SELF}/binary/isolinux/live.cfg based on ${SELF}/config/binary_syslinux/live.cfg.in ..."
sed -e "s|@KERNEL@|/live/vmlinuz|g" \
    -e "s|@INITRD@|/live/initrd.gz|g" \
    -e "s|@LB_BOOTAPPEND_LIVE_DE@|${LB_BOOTAPPEND_LIVE} ${LB_BOOTAPPEND_LIVE_DE}|g" \
    -e "s|@LB_BOOTAPPEND_LIVE_CH@|${LB_BOOTAPPEND_LIVE} ${LB_BOOTAPPEND_LIVE_CH}|g" \
    -e "s|@LB_BOOTAPPEND_LIVE_EN@|${LB_BOOTAPPEND_LIVE} ${LB_BOOTAPPEND_LIVE_EN}|g" \
    ${SELF}/config/binary_syslinux/live.cfg.in > ${SELF}/binary/isolinux/live.cfg

# Install menu
echo "Generating ${SELF}/binary/isolinux/install.cfg based on ${SELF}/config/binary_syslinux/install.cfg.in ..."
sed -e "s|@KERNEL@|/install/gtk/vmlinuz|g" \
    -e "s|@INITRD@|/install/gtk/initrd.gz|g" \
    -e "s|@LB_BOOTAPPEND_INSTALL@|video=vesa:ywrap,mtrr vga=788 quiet ${LB_BOOTAPPEND_INSTALL}|g" \
    ${SELF}/config/binary_syslinux/install.cfg.in > ${SELF}/binary/isolinux/install.cfg

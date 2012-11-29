#!/bin/sh
#
# Gemeinschaft 5
# live-helper hook to update syslinux boot menu
#
# Copyright (c) 2012, Julian Pawlowski <jp@jps-networks.eu>
# See LICENSE.GBE file for details.
#

LB_BOOTAPPEND_LIVE_DE="noautologin quickreboot noprompt timezone=Europe/Berlin keyboard-layouts=de"
LB_BOOTAPPEND_LIVE_CH="noautologin quickreboot noprompt timezone=Europe/Zurich keyboard-layouts=ch"
LB_BOOTAPPEND_LIVE_EN="noautologin quickreboot noprompt timezone=Europe/London keyboard-layouts=us"
SELF="`pwd`"

# Copy default files
echo "Copy files from ${SELF}/config/binary_syslinux/ to ${SELF}/binary/isolinux/ ..."
cp -pf ${SELF}/config/binary_syslinux/splash.png ${SELF}/binary/isolinux/
cp -pf ${SELF}/config/binary_syslinux/stdmenu.cfg ${SELF}/binary/isolinux/
cp -pf ${SELF}/config/binary_syslinux/menu.cfg ${SELF}/binary/isolinux/

# Live boot menu
echo "Generating ${SELF}/binary/isolinux/live.cfg based on ${SELF}/config/binary_syslinux/live.cfg.in ..."
sed -e "s|@KERNEL@|/live/vmlinuz|g" \
    -e "s|@INITRD@|/live/initrd.img|g" \
    -e "s|@LB_BOOTAPPEND_LIVE_DE@|${LB_BOOTAPPEND_LIVE} ${LB_BOOTAPPEND_LIVE_DE}|g" \
    -e "s|@LB_BOOTAPPEND_LIVE_CH@|${LB_BOOTAPPEND_LIVE} ${LB_BOOTAPPEND_LIVE_CH}|g" \
    -e "s|@LB_BOOTAPPEND_LIVE_EN@|${LB_BOOTAPPEND_LIVE} ${LB_BOOTAPPEND_LIVE_EN}|g" \
    ${SELF}/config/binary_syslinux/live.cfg.in > ${SELF}/binary/isolinux/live.cfg

# Install menu
echo "Generating ${SELF}/binary/isolinux/install.cfg based on ${SELF}/config/binary_syslinux/install.cfg.in ..."
sed -e "s|@KERNEL@|/install/vmlinuz|g" \
	-e "s|@KERNEL_GUI@|/install/gtk/vmlinuz|g" \
    -e "s|@INITRD@|/install/initrd.gz|g" \
    -e "s|@INITRD_GUI@|/install/gtk/initrd.gz|g" \
    -e "s|@LB_BOOTAPPEND_INSTALL@|vga=normal quiet file=/cdrom/install/preseed.cfg ${LB_BOOTAPPEND_INSTALL}|g" \
    -e "s|@LB_BOOTAPPEND_INSTALL_GUI@|video=vesa:ywrap,mtrr vga=788 file=/cdrom/install/preseed.cfg ${LB_BOOTAPPEND_INSTALL}|g" \
    ${SELF}/config/binary_syslinux/install.cfg.in > ${SELF}/binary/isolinux/install.cfg

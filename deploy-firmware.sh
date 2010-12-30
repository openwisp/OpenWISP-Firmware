#!/bin/bash
#
# OpenWISP Firmware
# Copyright (C) 2010 CASPUR (Davide Guerri d.guerri@caspur.it)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#     our ROOTFS will be $BUILDROOT/build_dir/arch/root-*/
#     arch will be one of i386, mips, ....


TOOLS='.'

if [ -z "$1" ]; then
  echo "Usage: $0 <openwrt sources path> <platform>"
  echo "Read the README file for more instruction "
  exit 1
fi

REPO=http://downloads.openwrt.org/kamikaze/8.09.2/$PLATFORM/packages/

PLATFORM=$2
BUILDROOT=$1

if [ -z "$BUILDROOT" ] || [ ! -f "$BUILDROOT/scripts/getver.sh" ] ; then
  echo "Invalid openwrt sources path"
  exit 1
fi

if [ ! -x $BUILDROOT/build_dir/root-* ]; then 
  echo "You don't have an already compiled system, I'll build a minimal one for you "
  REPLAY="y"
else
  echo "Do you want to build a minimal OpenWRT system?[y/n]"
  read REPLAY
fi

if [ $REPLAY == 'y' ] || [ $REPLAY == 'Y' ]; then
  # Configure and compile a minimal owrt system
  echo "Building images..."
  cp configwrt.minimal $BUILDROOT/.config
  #echo $1
  pushd $1
  make package/symlinks
  make oldconfig
  make
  popd
else 
  echo "Assuming No"
fi

# Assume that the script will be launched in the same dir  

if [ -z "$TOOLS" ] || [ ! -x "$TOOLS" ]; then
	echo "You must run this script in the openwisp manager tools directory"
  exit 1
fi

# By default the buildroot is a bit difficult to find :)

ROOTFS=$(find $BUILDROOT/build_dir -name root-*)

if [ -z "$ROOTFS" ] || [ ! -x "$ROOTFS" ]; then
  echo "Invalid openwrt rootfs path"
  exit 1
fi

#Copy custom file to target os 

echo $ROOTFS 
echo "Copying file..."
mkdir $ROOTFS/etc/owispmanager 2>/dev/null
cp -R $TOOLS/common.sh $TOOLS/owispmanager.sh $TOOLS/web $ROOTFS/etc/owispmanager 2>/dev/null
find $ROOTFS/etc/owispmanager -iname "*.svn" -exec rm -Rf {} \; 2>/dev/null
chmod +x $ROOTFS/etc/owispmanager/owispmanager.sh 
if [ "$?" -ne "0" ]; then
 echo "Failed to copy files..."
 exit 2
fi

echo "Installing boot script"
cat << EOF > $ROOTFS/etc/inittab
::sysinit:/etc/init.d/rcS S boot
::shutdown:/etc/init.d/rcS K stop
tts/0::askfirst:/bin/ash --login
ttyS0::askfirst:/bin/ash --login
tty1::askfirst:/bin/ash --login
::respawn:/etc/owispmanager/owispmanager.sh
EOF
if [ "$?" -ne "0" ]; then
 echo "Failed to install inittab"
 exit 2
fi

echo "Configuring openwrt default firmware:"
echo "* Disabling unneeded services"
rm $ROOTFS/etc/rc.d/S45firewall $ROOTFS/etc/rc.d/S50httpd $ROOTFS/etc/rc.d/S60dnsmasq 2>/dev/null 

echo "* Enabling needed services"
pushd $ROOTFS
ln -sf /etc/init.d/ntpdate /etc/rc.d/S60ntpdate
popd 

#You can put here your configuration if needed

echo "* Deploying initial wireless configuration"
cat << EOF > $ROOTFS/etc/config/wireless
config wifi-device  wifi0
       option type     atheros
       option channel  auto
       option disabled 1

config wifi-device  wifi1
       option type     atheros
       option channel  auto
       option disabled 1
EOF

echo "* Configuring password timezone and hostname"
sed -i 's/option\ hostname\ OpenWrt/option\ hostname\ Unconfigured/' $ROOTFS/etc/config/system
if [ "$?" -ne "0" ]; then
 echo "Failed to set default hostname"
 exit 2
fi

sed -i 's/option\ timezone\ UTC/option\ timezone\ \"CET-1CEST-2,M3\.5\.0\/02:00:00,M10\.5\.0\/03:00:00\"/' $ROOTFS/etc/config/system
if [ "$?" -ne "0" ]; then
 echo "Failed to set timezone"
 exit 2
fi

sed -i 's/root:\!:0:0:root:\/root:\/bin\/ash/root:\$1\$1.OBJgX7\$4VwOsIlaEDcmq9CUrYCHF\/:0:0:root:\/root:\/bin\/ash/' $ROOTFS/etc/passwd
if [ "$?" -ne "0" ]; then
 echo "Failed to set root password"
 exit 2
fi

echo "* Installing repository"
cat << EOF > $ROOTFS/etc/opkg.conf
src/gz snapshots $REPO
dest root /
dest ram /tmp
lists_dir ext /var/opkg-lists
option overlay_root /jffs
EOF
if [ "$?" -ne "0" ]; then
 echo "Failed to set opkg repository"
 exit 2
fi

echo "Rebuilding images..."
echo $BUILDROOT
pushd $BUILDROOT
make target/install
make package/index
popd

echo "Done."


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

if [ -z "$1" ]; then
  echo "Usage: $0 <openwrt sources path> <owispmanager firmware tools directory> <openwrt root fs path> <opkg packages repository url>"
  exit 1
fi

BUILDROOT=$1
if [ -z "$BUILDROOT" ] || [ ! -f "$BUILDROOT/scripts/getver.sh" ] ; then
  echo "Invalid openwrt build root"
  exit 1
fi

TOOLS=$2
if [ -z "$TOOLS" ] || [ ! -x "$TOOLS" ]; then
	echo "Invalid owispmanager path!"
	exit 1
fi

ROOTFS=$3
if [ -z "$ROOTFS" ] || [ ! -x "$ROOTFS" ]; then
  echo "Invalid openwrt rootfs path"
  exit 1
fi

REPO=$4
if [ -z "$REPO" ]; then
  echo "Invalid repo url"
  exit 1
fi

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
pushd $BUILDROOT
make target/install
make package/index
popd

echo "Done."


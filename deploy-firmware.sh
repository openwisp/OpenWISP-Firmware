#!/bin/bash
#
# OpenWISP Firmware
# Copyright (C) 2010 CASPUR
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

#Prints Usage
usage() {
cat << EOU
  usage: $0 -s /path/to/sources -r owrtRelease -p platform -o remote_vpn_server_ip 
  Read the README.txt file for more instructions
  Options:
    -s: OpenWrt sources path
    -r: OpenWrt release
    -p: Platform
    -o: OpenVpn remote server
EOU
}

#Define variables to be set with getopt 
PLATFORM="atheros"
VPN_REMOTE=""
BUILDROOT=""
RELEASE=""
TOOLS="."
DISABLE_IPTABLES="yes"

while getopts "hs:r:p:o:" OPTION
do
  case $OPTION in
    h) 
      usage
      exit 1
      ;;
    s)
      BUILDROOT=$OPTARG
      ;;
    r)
      RELEASE=$OPTARG
      ;;
    p)
      PLATFORM=$OPTARG
      ;;
    o)
      VPN_REMOTE=$OPTARG
      ;;
    ?)
      usage
      exit 1 
      ;;
  esac
done

if [ -z "$BUILDROOT" ]||[ -z "$RELEASE" ]; then
  usage
  exit 1 
fi

if [ -f "$TOOLS/openvpn/ca.crt" ] && [ -z "$VPN_REMOTE" ]; then
  echo ""
  echo " ** HINT **"
  echo " ** You must specify the OpenVPN remote server with -o option"
  echo " ** If you put your certs on the openvpn folder server configuration page will be hidden"
  echo ""
  usage
  exit 1 
fi

if [ ! -f "$BUILDROOT/scripts/getver.sh" ] ; then
  echo "Invalid openwrt sources path"
  exit 1
fi


if [ ! -x $BUILDROOT/build_dir/linux-* ]; then 
  echo "You don't have an already compiled system, I'll build a minimal one for you "
  REPLAY="y"
else
  echo "Do you want to build a minimal OpenWRT system?[y/n]"
  read REPLAY
fi

if [ $REPLAY == 'y' ] || [ $REPLAY == 'Y' ]; then
  # Configure and compile a minimal owrt system and also sets the repository
  echo "Building images..."
  cp configwrt.minimal $BUILDROOT/.config
  pushd $BUILDROOT
  if [ "$RELEASE" = "kamikaze" ]; then
    make package/symlinks
    REPO=http://downloads.openwrt.org/$RELEASE/8.09.2/$PLATFORM/packages/
  elif [ $RELEASE = "backfire" ]; then
    ./scripts/feeds update -a 
    ./scripts/feeds install -a
    REPO=http://downloads.openwrt.org/$RELEASE/10.03/$PLATFORM/packages/
  else 
    echo "Invalid Release. Please choose from kamikaze or backfire"
    usage
    exit 1
  fi
  make oldconfig
  make
  popd
else 
  echo "Assuming No"
fi

#Sets ROOTFS smartly
ROOTFS=$(find $BUILDROOT/build_dir -name root-$PLATFORM)
  
if [ -z "$ROOTFS" ] || [ ! -x "$ROOTFS" ]; then
  echo "Invalid openwrt rootfs path"
  exit 1
fi

#Copy custom file to target os
echo "Copying file..."
mkdir $ROOTFS/etc/owispmanager 2>/dev/null
cp -R $TOOLS/common.sh $TOOLS/owispmanager.sh $TOOLS/web $ROOTFS/etc/owispmanager 2>/dev/null
mkdir $ROOTFS/etc/openvpn 2>/dev/null
cp -R $TOOLS/openvpn/* $ROOTFS/etc/openvpn/ 2>/dev/null
find $ROOTFS/etc/owispmanager -iname "*.svn" -exec rm -Rf {} \; 2>/dev/null
chmod +x $ROOTFS/etc/owispmanager/owispmanager.sh
cp $TOOLS/htpdate/htpdate.init $ROOTFS/etc/init.d/htpdate
cp $TOOLS/htpdate/htpdate.default $ROOTFS/etc/default/htpdate
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
if [ "$DISABLE_IPTABLES" == "yes" ]; then
  echo "* Disabling iptables"
  rm $ROOTFS/etc/rc.d/S45firewall 2>/dev/null 
  mkdir $ROOTFS/etc/modules.d/disabled 2>/dev/null
  mv $ROOTFS/etc/modules.d/*-ipt-* $ROOTFS/etc/modules.d/disabled/ 2>/dev/null
fi

rm $ROOTFS/etc/rc.d/S49htpdate $ROOTFS/etc/rc.d/S50httpd $ROOTFS/etc/rc.d/S50uhttpd $ROOTFS/etc/rc.d/S60dnsmasq 2>/dev/null 

echo "* Enabling needed services"
pushd $ROOTFS
echo "0 */1 * * * (/usr/sbin/ntpdate -s -b -u -t 5 ntp.ien.it || (htpdate -s -t www.google.it & sleep 5; kill $!)) >/dev/null 2>&1" >>  ./etc/crontabs/root
popd

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

echo "* Configuring owispmanager settings"
if [ -z "$VPN_REMOTE" ] || [ ! -f "$TOOLS/openvpn/client.crt" ]; then 
  STATUS="unconfigured"
  HIDE_SERVER_PAGE="0"
else
  STATUS="configured"
  HIDE_SERVER_PAGE="1"
fi
cat << EOF > $ROOTFS/etc/config/owispmanager
config 'server' 'home'
  option 'address' '$VPN_REMOTE'
  option 'status' '$STATUS'
  option 'inner_server' ''
  option 'inner_server_port' ''

config 'server' 'local'
  option 'hide_server_page' '$HIDE_SERVER_PAGE'
  option 'setup_wpa_psk' ''
  option 'setup_wifi_dev' ''
  option 'setup_httpd_port' ''
  option 'setup_ssid' ''
  option 'setup_ip' ''
  option 'setup_netmask' ''
  option 'setup_range_ip_start' ''
  option 'setup_range_ip_end' ''
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

sed -i 's/root:.*:0:0:root:\/root:\/bin\/ash/root:\$1\$1.OBJgX7\$4VwOsIlaEDcmq9CUrYCHF\/:0:0:root:\/root:\/bin\/ash/' $ROOTFS/etc/passwd
if [ "$?" -ne "0" ]; then
 echo "Failed to set root password"
 exit 2
else
 echo "Root password set"
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

echo "Moving Compiled Images into \"builds\" directory"
if [ "$RELEASE" = "backfire" ]; then 
  cp $BUILDROOT/bin/$PLATFORM/openwrt-atheros-root.squashfs $BUILDROOT/bin/$PLATFORM/openwrt-atheros-ubnt2-squashfs.bin $BUILDROOT/bin/$PLATFORM/openwrt-atheros-vmlinux.lzma $BUILDROOT/bin/$PLATFORM/openwrt-atheros-ubnt2-pico2-squashfs.bin ./builds/
else
  cp $BUILDROOT/bin/openwrt-atheros-root.squashfs $BUILDROOT/bin/openwrt-atheros-ubnt2-squashfs.bin $BUILDROOT/bin/openwrt-atheros-vmlinux.lzma $BUILDROOT/bin/openwrt-atheros-ubnt2-pico2-squashfs.bin ./builds/
fi
echo "Your system is ready." 

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

# Adds some colored output

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
WHITE="\033[1;37m"

#Prints Usage
usage() {
cat << EOU

  OpenWisp Firmware deployer V 1.2, OpenWisp suite (c) caspur http://spider.caspur.it

  usage: $0 -s /path/to/sources -a arch [OPTION]  
  
  Read the README.txt file for more instructions

  Options:
  -h: Print this help and exit
  -s: OpenWrt sources path
  -a: Architecture (e.g. atheros)
  -v: Vpn server
  -w: Default wpa-psk
  -e: Configuration essid
  -i: Inner server 
  -p: Inner server port
  -P: Root password
EOU
}

#check if INNER_SERVER is a valid ip 
#TODO: pass inner server variable. 

is_valid_ip() {

  echo "$INNER_SERVER" | awk -F '[.]' 'function ok(n) {return (n ~ /^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/)}{exit (ok($1) && ok($2) && ok($3) && ok($4))}'
  echo $?

}

#Define variables to be set with getopt 
PLATFORM="atheros"
VPN_REMOTE=""
BUILDROOT=""
TOOLS="."
DISABLE_IPTABLES="yes"
WPA_PSK=""
WPA_SSID=""
DEFAULT_IP=""
INNER_SERVER=""
INNER_SERVER_PORT=""
PASSWORD=""

while getopts "hs:a:v:w:e:i:p:P:" OPTION
do
  case $OPTION in
    h) 
      usage
      exit 1
      ;;
    s)
      BUILDROOT=$OPTARG
      ;;
    a)
      PLATFORM=$OPTARG
      ;;
    v)
      VPN_REMOTE=$OPTARG
      ;;
    w)
      WPA_PSK=$OPTARG
      ;;
    e)
      WPA_SSID=$OPTARG
      ;;
    i)
      INNER_SERVER_PORT=$OPTARG
      ;;
    p)
      INNER_SERVER=$OPTARG
      ;;
    P)
      PASSWORD=$OPTARG
      ;;
    ?)
      echo -e "$RED Invalid argument"
      usage
      exit 1 
      ;;
  esac
done

if [ -z "$BUILDROOT" ]; then
  usage
  exit 1 
fi

if [ -n "$PASSWORD" ]; then 
  ENC_PWD=`perl $TOOLS/utils/pw.pl $PASSWORD`
fi

if [ -f "$TOOLS/openvpn/ca.crt" ] && [ -z "$VPN_REMOTE" ]; then
  echo ""
  echo -e "$RED ** $BLUE HINT $RED **"
  echo -e "$RED ** $BLUE You must specify the OpenVPN remote server with -o option"
  echo -e "$RED ** $BLUE If you put your certs on the openvpn folder server configuration page will be hidden"
  echo ""
  usage
  exit 1 
fi

if [ -n "$WPA_PSK" ] && [ ${#WPA_PSK} -lt 14  ]; then
  echo -e "$RED WPA-PSK problem:"
  echo -e "$RED ** $BLUE HINT $RED**"
  echo -e "$BLUE WPA-PSK key must be 14 character lenght"
  usage
  exit 1
elif [ -z "$WPA_PSK" ]; then
  echo -e "$YELLOW WPA-PSK will be owm-Ohz6ohngei"
fi

if [ -n "$INNER_SERVER_PORT" ] && [ ! $(echo "$INNER_SERVER_PORT" | grep -E "^[0-9]+$") ]; then
  echo ""
  echo -e "$RED ** $BLUE HINT $RED **"
  echo -e "$BLUE Inner server port must be an integer"
  usage
  exit 1
fi

if [ -n "$INNER_SERVER" ] && [ `is_valid_ip` == 1 ]; then
  echo -e "$YELLOW Default OpenVPN INNER SERVER will be $INNER_SERVER"
elif [ -z "$INNER_SERVER" ]; then 
  echo -e "$GREEN OpenVPN Inner Sever not changed"
else
  echo -e "$RED Inner server error"
  echo -e "$RED ${INNER_SERVER} is not a valid IP address!"
  usage
  exit 1
fi

if [ ! -x "$BUILDROOT/scripts/getver.sh" ] ; then
  echo -e "$RED Invalid openwrt sources path"
  exit 1
fi

#Sets ROOTFS smartly

ROOTFS=$(find $BUILDROOT/build_dir -name root-$PLATFORM)
if [ -z "$ROOTFS" ] || [ ! -x "$ROOTFS" ]; then
  echo -e "$RED Invalid openwrt rootfs path"
  exit 1
fi

#All version-dependent variables will be setted here
if [ `cat $ROOTFS/etc/openwrt_version` == "8.09" ]; then
  CODENAME="kamikaze"
  RELEASE="8.09"
  PKG_CMD="make package/symlinks"
  BINARIES="$BUILDROOT/bin/openwrt-atheros-root.squashfs $BUILDROOT/bin/openwrt-atheros-ubnt2-squashfs.bin $BUILDROOT/bin/openwrt-atheros-vmlinux.lzma $BUILDROOT/bin/openwrt-atheros-ubnt2-pico2-squashfs.bin $BUILDROOT/bin/openwrt-x86-squashfs.image"
elif [ `cat $ROOTFS/etc/openwrt_version` == "10.03" ]; then
  CODENAME="backfire"
  RELEASE="10.03"
  BINARIES="$BUILDROOT/bin/$PLATFORM/openwrt-atheros-root.squashfs $BUILDROOT/bin/$PLATFORM/openwrt-atheros-ubnt2-squashfs.bin $BUILDROOT/bin/$PLATFORM/openwrt-atheros-vmlinux.lzma $BUILDROOT/bin/$PLATFORM/openwrt-atheros-ubnt2-pico2-squashfs.bin $BUILDROOT/bin/$PLATFORM/openwrt-x86-generic-combined-squashfs.img"
  PKG_CMD="./scripts/feeds update -a && ./scripts/feeds install -a"
else 
  echo -e "$RED Invalid Release. OWF support Backfire (10.03) or Kamikaze (9.02) "
  exit 1
fi

echo "$GREEN OpenWRT $RELEASE a.k.a. $CODENAME detected"
REPO=http://downloads.openwrt.org/$CODENAME/$RELEASE/$PLATFORM/packages/

# Check for an existing pre-compilated system
if [ ! -x $BUILDROOT/build_dir/linux-$PLATFORM* ]; then 
  echo -e "$YELLOW You don't have an already compiled system, I'll build a minimal one for you "
  REPLAY="y"
else
  echo -e "$GREEN Do you want to build a minimal OpenWRT system?[y/n]$WHITE"
  read REPLAY
fi

if [ $REPLAY == 'y' ] || [ $REPLAY == 'Y' ]; then
  # Configure and compile a minimal owrt system
  echo -e "$GREEN Building images... $WHITE"
  
  cp $TOOLS/kernel_configs/config.$PLATFORM.$CODENAME $BUILDROOT/.config 2>/dev/null
  
  if [ "$?" -ne "0" ]; then 
    echo -e "$YELLOW we don't have a preconfigured kernel configuration for $CODENAME on $PLATFORM"
    echo -e "$YELLOW Please create a config file by yourself"
    exit 2
  fi

  echo -e " $YELLOW * Jumpin in:$WHITE"
  pushd $BUILDROOT  
  eval $PKG_CMD
  echo -e "$GREEN Setting up OpenWRT configuration $WHITE"
  make oldconfig > /dev/null
  echo -e "$GREEN Compiling OpenWrt... $WHITE"
  make > $TOOLS/compile.log
  popd

else 
  echo -e "$GREEN Assuming No"
fi

#Copy custom file to target os
echo -e "$GREEN Copying file...$WHITE"
mkdir $ROOTFS/etc/owispmanager 2>/dev/null
cp -R $TOOLS/common.sh $TOOLS/owispmanager.sh $TOOLS/web $ROOTFS/etc/owispmanager 2>/dev/null
mkdir $ROOTFS/etc/openvpn 2>/dev/null
cp -R $TOOLS/openvpn/* $ROOTFS/etc/openvpn/ 2>/dev/null
find $ROOTFS/etc/owispmanager -iname "*.svn" -exec rm -Rf {} \; 2>/dev/null
chmod +x $ROOTFS/etc/owispmanager/owispmanager.sh
cp $TOOLS/htpdate/htpdate.init $ROOTFS/etc/init.d/htpdate
cp $TOOLS/htpdate/htpdate.default $ROOTFS/etc/default/htpdate
if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to copy files..."
  exit 2
fi

echo -e "$GREEN Installing boot script"
cat << EOF > $ROOTFS/etc/inittab
::sysinit:/etc/init.d/rcS S boot
::shutdown:/etc/init.d/rcS K stop
tts/0::askfirst:/bin/ash --login
ttyS0::askfirst:/bin/ash --login
tty1::askfirst:/bin/ash --login
::respawn:/etc/owispmanager/owispmanager.sh
EOF
if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to install inittab"
  exit 2
fi

echo -e "$GREEN Configuring openwrt default firmware:"

echo -e "$YELLOW * Disabling unneeded services"
if [ "$DISABLE_IPTABLES" == "yes" ]; then
  echo -e "$YELLOW * Disabling iptables"
  rm $ROOTFS/etc/rc.d/S45firewall 2>/dev/null 
  mkdir $ROOTFS/etc/modules.d/disabled 2>/dev/null
  mv $ROOTFS/etc/modules.d/*-ipt-* $ROOTFS/etc/modules.d/disabled/ 2>/dev/null
fi

rm $ROOTFS/etc/rc.d/S49htpdate $ROOTFS/etc/rc.d/S50httpd $ROOTFS/etc/rc.d/S50uhttpd $ROOTFS/etc/rc.d/S60dnsmasq 2>/dev/null 

echo -e "$YELLOW * Enabling needed services $WHITE"
pushd $ROOTFS
echo "0 */1 * * * (/usr/sbin/ntpdate -s -b -u -t 5 ntp.ien.it || (htpdate -s -t www.google.it & sleep 5; kill $!)) >/dev/null 2>&1" >>  ./etc/crontabs/root
popd

echo -e "$YELLOW * Deploying initial wireless configuration $WHITE"
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

echo -e "$YELLOW * Configuring owispmanager settings $WHITE"
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
option 'inner_server' '$INNER_SERVER'
option 'inner_server_port' '$INNER_SERVER_PORT'

config 'server' 'local'
option 'hide_server_page' '$HIDE_SERVER_PAGE'
option 'setup_wpa_psk' '$WPA_PSK'
option 'setup_wifi_dev' ''
option 'setup_httpd_port' ''
option 'setup_ssid' '$WPA_SSID'
option 'setup_ip' ''
option 'setup_netmask' ''
option 'setup_range_ip_start' ''
option 'setup_range_ip_end' ''
EOF

echo -e "$YELLOW * Configuring password timezone and hostname $WHITE"
sed -i 's/option\ hostname\ OpenWrt/option\ hostname\ Unconfigured/' $ROOTFS/etc/config/system
if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to set default hostname"
  exit 2
fi

sed -i 's/option\ timezone\ UTC/option\ timezone\ \"CET-1CEST-2,M3\.5\.0\/02:00:00,M10\.5\.0\/03:00:00\"/' $ROOTFS/etc/config/system
if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to set timezone"
  exit 2
fi

if [ -n "$ENC_PWD" ]; then
  # Rewrite passwd file entirely
cat << EOF > $ROOTFS/etc/passwd
$ENC_PWD
nobody:*:65534:65534:nobody:/var:/bin/false
daemon:*:65534:65534:daemon:/var:/bin/false
EOF

else
  echo -e "$YELLOW Root password will be ciaociao"
  sed -i 's/root:.*:0:0:root:\/root:\/bin\/ash/root:\$1\$1.OBJgX7\$4VwOsIlaEDcmq9CUrYCHF\/:0:0:root:\/root:\/bin\/ash/' $ROOTFS/etc/passwd
fi

if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to set root password"
  exit 2
else
  echo -e "$GREEN Root password set $WHITE"
fi

echo -e "$YELLOW * Installing repository $WHITE"

cat << EOF > $ROOTFS/etc/opkg.conf
src/gz snapshots $REPO
dest root /
dest ram /tmp
lists_dir ext /var/opkg-lists
option overlay_root /jffs
EOF

if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to set opkg repository $WHITE"
  exit 2
fi

echo -e "$YELLOW * Rebuilding images..."
pushd $BUILDROOT
make target/install
make package/index
popd

echo -e "$YELLOW Done. $WHITE"
if [ "$PLATFORM" == "atheros" ] || [ "$PLATFORM" == "x86" ]; then 
  echo -e "$GREEN Moving Compiled Images into \"builds\" directory $WHITE"
  cp $BINARIES ./builds/ 2>/dev/null
else 
  echo -e "$RED Search your binaries in $BUILDROOT your platform is not tested right now"
fi

echo -e "$GREEN Your system is ready. $WHITE" 

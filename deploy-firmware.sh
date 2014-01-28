#!/bin/bash
#
# This file is part of the OpenWISP Firmware
#
# Copyright (C) 2012 OpenWISP.org
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

  OpenWisp Firmware deployer V 1.2, OpenWisp Suite (C) OpenWISP.org http://openwisp.org

  usage: $0 -s /path/to/sources -a arch [OPTION]

  Read the README.txt file for more instructions

  Options:
  -h: Print this help and exit
  -s: OpenWrt sources path
  -a: Architecture (e.g. atheros)
  -v: VPN Server
  -V: VPN Server Port
  -w: Default wpa-psk
  -e: Configuration essid
  -i: Inner server
  -p: Inner server port
  -P: Root password
  -u: Enable UMTS
  -d: UMTS device
  -m: Enable OLSR mesh
  -G: Autogenerate root password and WPA Key
  -j: Number of jobs in compiling OpenWRT
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
VPN_REMOTE_PORT=""
BUILDROOT=""
TOOLS=$(cd `dirname $0` && pwd)
DISABLE_IPTABLES="yes"
WPA_PSK=""
WPA_SSID=""
DEFAULT_IP=""
INNER_SERVER=""
INNER_SERVER_PORT=""
PASSWORD=""
UMTS_ENABLE="0"
MESH_ENABLE="0"
UMTS_DEVICE="/dev/ttyUSB0"
HIDE_UMTS_PAGE="1"
HIDE_MESH_PAGE="1"
AUTOGEN_PWD="0"
WEIGHT="thin"
JOBS="1"

#Platform specific variables
CODENAME="attitude_adjustment"
RELEASE="12.09-rc1"
PKG_CMD="./scripts/feeds update -a && ./scripts/feeds install -a"
OVERLAY_OPT="option overlay_root /overlay"
REPO=http://downloads.openwrt.org/$CODENAME/$RELEASE/$PLATFORM/generic/packages/

while getopts "muhs:a:v:V:w:e:i:p:P:G:j:d:" OPTION
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
    V)
      VPN_REMOTE_PORT=$OPTARG
      ;;
    w)
      WPA_PSK=$OPTARG
      ;;
    e)
      WPA_SSID=$OPTARG
      ;;
    p)
      INNER_SERVER_PORT=$OPTARG
      ;;
    i)
      INNER_SERVER=$OPTARG
      ;;
    P)
      PASSWORD=$OPTARG
      ;;
    m)
      MESH_ENABLE="1"
      HIDE_MESH_PAGE="0"
      WEIGHT="full"
      ;;
    u)
      UMTS_ENABLE="1"
      HIDE_UMTS_PAGE="0"
      WEIGHT="full"
      ;;
    d)
      UMTS_ENABLE="1"
      WEIGHT="full"
      UMTS_DEVICE=$OPTARG
      ;;
    G)
      AUTOGEN_PWD="1"
      WPA_PSK=owm-`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c10`
      PASSWORD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8`
      WEIGHT="full"
      ;;
    j)
      JOBS=$OPTARG
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

if [ "$PLATFORM" == "avr32" ]; then
  PLATFORM="rb535"
fi


if [ "$WEIGHT" == "full" ]; then
  DISABLE_IPTABLES="no"
fi

echo -e "$RED ********* $YELLOW Deploying Started $RED ********* $WHITE"

if [ -z "$PASSWORD" ]; then
  PASSWORD="ciaociao"
fi

ENC_PWD=`perl $TOOLS/utils/pw.pl $PASSWORD`

if [ -f "$TOOLS/openvpn/ca.crt" ] && [ -z "$VPN_REMOTE" ]; then
  echo ""
  echo -e "$RED ** $YELLOW HINT $RED **"
  echo -e "$RED ** $WHITE You must specify the OpenVPN remote server with -v option"
  echo -e "$RED ** $WHITE If you put your certs on the openvpn folder server configuration page will be hidden"
  echo ""
  usage
  exit 1
elif [ ! -f "$TOOLS/openvpn/client.crt" ]; then
  STATUS="unconfigured"
  HIDE_SERVER_PAGE="0"
else
  STATUS="configured"
  HIDE_SERVER_PAGE="1"
fi

if [ -n "$WPA_PSK" ] && [ ${#WPA_PSK} -lt 14  ]; then
  echo -e "$RED WPA-PSK problem:"
  echo -e "$RED ** $YELLOW HINT $RED**"
  echo -e "$YELLOW WPA-PSK key must be 14 character length"
  usage
  exit 1
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

# Check for a valid BUILDROOT, sets release-specific settings in order to create
# a valid ROOTFS

if [ ! -x "$BUILDROOT/scripts/getver.sh" ] ; then
  echo -e "$RED Invalid openwrt sources path"
  exit 1
fi


# Check for an existing pre-compilated system
if [ ! -x $BUILDROOT/build_dir/linux-$PLATFORM ] || [ ! -x $BUILDROOT/build_dir/linux-$PLATFORM\_* ]; then
  echo -e "$YELLOW You don't have an already compiled system, I'll build a minimal one for you "
  REPLAY="y"
elif [ "$MESH_ENABLE" == "1" ]; then
    echo -e "$RED In order to get mesh interface working I will patch you system....$WHITE"
    pushd $BUILDROOT > /dev/null
    echo -e "$YELLOW"
    patch -p0 < $TOOLS/patches/ibss_wpa-none.patch
    svn up -r25544 $BUILDROOT/package/hostapd/ > /dev/null
    echo -e "$WHITE"
    REPLAY="Y"
    popd >/dev/null
else
  echo -e "$GREEN Do you want to build a minimal OpenWRT system?[y/n]$WHITE"
  read REPLAY
fi

if [ $REPLAY == 'y' ] || [ $REPLAY == 'Y' ]; then
  # Configure and compile a minimal owrt system
  echo -e "$GREEN Building $WEIGHT images... $WHITE"

  if [ "$?" -ne "0" ]; then
    echo -e "$YELLOW we don't have a preconfigured kernel configuration for $CODENAME on $PLATFORM"
    echo -e "$YELLOW Please create a config file by yourself"
    exit 2
  fi

  pushd $BUILDROOT > /dev/null
  echo -e "$GREEN Setting up OpenWRT configuration $WHITE"
  echo -e "$YELLOW Compiling OpenWrt...THIS MAY TAKE SO LONG TIME $WHITE"
  cp $TOOLS/kernel_configs/config.$PLATFORM-$WEIGHT $BUILDROOT/.config 2>/dev/null
  eval $PKG_CMD >/dev/null
  cp $TOOLS/kernel_configs/config.$PLATFORM-$WEIGHT $BUILDROOT/.config 2>/dev/null
  make -j $JOBS
  popd > /dev/null

else
  echo -e "$GREEN Assuming No"
fi
 
ROOTFS=$(find $BUILDROOT/build_dir -name root-$PLATFORM*)

DISABLE_FW_MODULES="mkdir $ROOTFS/etc/modules.d/disabled/; mv $ROOTFS/etc/modules.d/*-ipt-conntrack $ROOTFS/etc/modules.d/*-ipt-nat $ROOTFS/etc/modules.d/disabled/"
UCI_DEFAULT_DIR="uci-defaults"

echo -e "$RED *********$YELLOW Configuring OpenWisp firmware: $RED*********$WHITE"

#Copy custom file to target os
echo -e "$YELLOW * Copying OWF file...$WHITE"
mkdir -p $ROOTFS/etc/owispmanager/tools 2>/dev/null
cp -R $TOOLS/common.sh $TOOLS/owispmanager.sh $TOOLS/web $ROOTFS/etc/owispmanager 2>/dev/null
cp -R $TOOLS/tools/*.sh $ROOTFS/etc/owispmanager/tools 2>/dev/null
mkdir $ROOTFS/etc/openvpn 2>/dev/null
cp -R $TOOLS/openvpn/* $ROOTFS/etc/openvpn/ 2>/dev/null
find $ROOTFS/etc/owispmanager -iname "*.svn" -exec rm -Rf {} \; 2>/dev/null
chmod +x $ROOTFS/etc/owispmanager/owispmanager.sh 2>/dev/null
cp $TOOLS/htpdate/htpdate.init $ROOTFS/etc/init.d/htpdate 2>/dev/null
cp $TOOLS/htpdate/htpdate.default $ROOTFS/etc/$UCI_DEFAULT_DIR/htpdate 2>/dev/null

if [ "$?" -ne "0" ]; then
 echo -e "$RED Failed to copy files..."
  exit 2
fi

echo -e "$YELLOW * Installing boot script"
cat << EOF > $ROOTFS/etc/inittab
::sysinit:/etc/init.d/rcS S boot
::shutdown:/etc/init.d/rcS K stop
#tts/0::askfirst:/bin/login
#ttyS0::askfirst:/bin/login
#tty1::askfirst:/bin/login
::respawn:/etc/owispmanager/owispmanager.sh
EOF

cat << EOF >> $ROOTFS/etc/shells
/bin/login
EOF

if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to install inittab"
  exit 2
fi

echo -e "$YELLOW * Disabling unneeded services"

if [ "$DISABLE_IPTABLES" == "yes" ]; then
  echo -e "$YELLOW * Disabling iptables"
  rm $ROOTFS/etc/rc.d/S*firewall 2>/dev/null
  eval $DISABLE_FW_MODULES
elif [ "$DISABLE_IPTABLES" == "no" ]; then
  echo -e "$YELLOW * Enabling iptables"
  cat << EOF > $ROOTFS/etc/config/firewall
config defaults
  option input            ACCEPT
  option output           ACCEPT
  option forward          DROP
  option disable_ipv6     1

config 'zone' 'owisp_mesh'
  option 'name' 'mesh'
  option 'network' 'mesh'
  option 'input' 'ACCEPT'
  option 'output' 'ACCEPT'
  option 'forward' 'DROP'

config 'forwarding' 'owisp_mesh2mesh'
  option 'src' 'mesh'
  option 'dest' 'mesh'
EOF
fi

rm $ROOTFS/etc/rc.d/S*htpdate $ROOTFS/etc/rc.d/S*ntpdate $ROOTFS/etc/rc.d/S*httpd $ROOTFS/etc/rc.d/S*uhttpd $ROOTFS/etc/rc.d/S*dnsmasq 2>/dev/null

echo -e "$YELLOW * Enabling needed services $WHITE"
pushd $ROOTFS
echo -e "0 */1 * * * (/usr/sbin/ntpdate -s -b -u -t 5 ntp.ien.it || (/usr/sbin/htpdate -s -t www.google.it & sleep 5; kill $!)) >/dev/null 2>&1\n0 2 * * * /sbin/reboot" >  $ROOTFS/etc/crontabs/root

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

config wifi-device  wifi2
  option type     atheros
  option channel  auto
  option disabled 1

config wifi-device  radio0
  option type      mac80211
  option channel  auto
  option disabled 1

config wifi-device radio1
  option type      mac80211
  option channel  auto
  option disabled 1

config wifi-device radio2
  option type      mac80211
  option channel  auto
  option disabled 1

EOF

echo -e "$YELLOW * Deploying initial ethernet nic configuration $WHITE"

cat << EOF > $ROOTFS/etc/config/network
config 'interface' 'loopback'
  option 'ifname' 'lo'
  option 'proto' 'static'
  option 'ipaddr' '127.0.0.1'
  option 'netmask' '255.0.0.0'

config 'interface' 'lan'
  option 'ifname' 'eth0'
  option 'type' 'bridge'
  option 'proto' 'dhcp'
  option 'dns' '8.8.8.8'
  option 'peerdns' '0'

EOF

echo -e "$YELLOW * Configuring owispmanager settings $WHITE"

cat << EOF > $ROOTFS/etc/config/owispmanager
config 'server' 'home'
  option 'address' '$VPN_REMOTE'
  option 'port' '$VPN_REMOTE_PORT'
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
  option 'hide_umts_page' '$HIDE_UMTS_PAGE'
  option 'hide_mesh_page' '$HIDE_MESH_PAGE'
  option 'hide_ethernet_page' '0'
  option 'ethernet_device' 'eth0'
  option 'ethernet_enable' '0'
EOF

if [ "$UMTS_ENABLE" == "1" ]; then

  echo -e "$YELLOW * Configuring UMTS support  $WHITE"

  cat << EOF >> $ROOTFS/etc/config/owispmanager
  option 'umts_device' '$UMTS_DEVICE'
  option 'umts_enable' '1'
EOF

  cat << EOF > $ROOTFS/etc/modules.d/60-usb-serial
usbserial vendor=0x12d1 product=0x1464
EOF

  cat << EOF >> $ROOTFS/etc/config/network
config 'interface' 'umts'
  option 'ifname' 'ppp0'
  option 'device' '$UMTS_DEVICE'
  option 'service' 'umts'
  option 'proto' '3g'
  option 'defaultroute' '0'
  option 'pppd_options' 'noipdefault'
  option 'dns' '8.8.8.8'
  option 'peerdns' '0'
EOF

  mkdir -p $ROOTFS/etc/ppp/ip-down.d $ROOTFS/etc/ppp/ip-up.d
  cp -R $TOOLS/ppp/ip-down.d/del_default_route.sh $ROOTFS/etc/ppp/ip-down.d/del_default_route.sh
  cp -R $TOOLS/ppp/ip-up.d/add_default_route.sh $ROOTFS/etc/ppp/ip-up.d/add_default_route.sh
  chmod +x $ROOTFS/etc/ppp/ip-down.d/del_default_route.sh $ROOTFS/etc/ppp/ip-up.d/add_default_route.sh

  echo -e "$YELLOW * Configuring UMTS init script $WHITE"

  # cp $TOOLS/utils/umts.sh $ROOTFS/etc/owispmanager/umts.sh
  # chmod +x $ROOTFS/etc/owispmanager/umts.sh
  cp -R $TOOLS/utils/umts-wd.sh $ROOTFS/etc/owispmanager/umts-wd.sh
  chmod +x $ROOTFS/etc/owispmanager/umts-wd.sh
  cp -R $TOOLS/utils/apn.sh $ROOTFS/etc/owispmanager/apn.sh
  chmod +x $ROOTFS/etc/owispmanager/apn.sh

  cp -R $TOOLS/utils/usb_serial $ROOTFS/etc/hotplug.d/usb/30-serial
  cp -R $TOOLS/utils/apn_remove $ROOTFS/etc/hotplug.d/usb/40-apn

  cp -R $TOOLS/utils/getreginfo.gcom $ROOTFS/etc/gcom/getreginfo.gcom

  cat << EOF >> $ROOTFS/etc/inittab
#::respawn:/etc/owispmanager/umts.sh
::respawn:/etc/owispmanager/umts-wd.sh
::respawn:/etc/owispmanager/apn.sh
EOF

  sed -i -e 's/failure 5/failure 4/g' -e 's/interval 1/interval 65535/g' $ROOTFS/etc/ppp/options
fi

if [ "$MESH_ENABLE" == "1" ]; then
  cat << EOF >> $ROOTFS/etc/config/owispmanager
  option 'mesh_device' 'wifi1'
  option 'mesh_enable' '0'
EOF

  echo << EOF > $ROOTFS/etc/config/olsrd
EOF

#Disable olsrd key by default USE IT AT YOUR OWN RISK

  echo << EOF > $ROOTFS/etc/olsrd.d/olsrd_secure_key
EOF
fi

if [ "$UMTS_ENABLE" == "1" -o "$MESH_ENABLE" == "1" ]; then

  echo -e "$YELLOW * Configuring failover script $WHITE"

  cp -R $TOOLS/utils/failover.sh $ROOTFS/etc/owispmanager/failover.sh
  chmod +x $ROOTFS/etc/owispmanager/failover.sh

  cat << EOF >> $ROOTFS/etc/inittab
::respawn:/etc/owispmanager/failover.sh
EOF

fi

echo -e "$YELLOW * Configuring password timezone and hostname $WHITE"

# Rewrite passwd file entirely
cat << EOF > $ROOTFS/etc/passwd
$ENC_PWD
daemon:*:1:1:daemon:/var:/bin/false
ftp:*:55:55:ftp:/home/ftp:/bin/false
network:*:101:101:network:/var:/bin/false
nobody:*:65534:65534:nobody:/var:/bin/false
EOF

if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to set root password"
  exit 2
else
  echo -e "$GREEN Root password set $WHITE"
fi

sed -i 's/option[ \t]hostname[ \t].*$/option hostname Unconfigured/' $ROOTFS/etc/config/system
if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to set default hostname"
  exit 2
fi

sed -i 's/option[ \t]timezone[ \t].*$/option timezone \"CET-1CEST-2,M3\.5\.0\/02:00:00,M10\.5\.0\/03:00:00\"/' $ROOTFS/etc/config/system
if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to set timezone"
  exit 2
fi

echo -e "$YELLOW * Installing repository $WHITE"

cat << EOF > $ROOTFS/etc/opkg.conf
src/gz snapshots $REPO
dest root /
dest ram /tmp
lists_dir ext /var/opkg-lists
$OVERLAY_OPT
EOF

if [ "$?" -ne "0" ]; then
  echo -e "$RED Failed to set opkg repository $WHITE"
  exit 2
fi

echo -e "$YELLOW * Rebuilding images..."
pushd $BUILDROOT > /dev/null
make target/install V=s >/dev/null
make package/index V=s  >/dev/null
popd  >/dev/null

BINARIES="$BUILDROOT/bin/$PLATFORM/openwrt-atheros-root.squashfs $BUILDROOT/bin/$PLATFORM/openwrt-atheros-ubnt2-squashfs.bin $BUILDROOT/bin/$PLATFORM/openwrt-atheros-vmlinux.lzma $BUILDROOT/bin/$PLATFORM/openwrt-atheros-ubnt2-pico2-squashfs.bin $BUILDROOT/bin/$PLATFORM/openwrt-x86-generic-combined-squashfs.img  $BUILDROOT/bin/$PLATFORM/openwrt-ar71xx-ubnt-rs-jffs2-factory.bin $BUILDROOT/bin/$PLATFORM/openwrt-atheros-ubnt5-squashfs.bin $BUILDROOT/bin/$PLATFORM/openwrt-ar71xx-ubnt-nano-m-squashfs-factory.bin $BUILDROOT/bin/$PLATFORM/openwrt-ar71xx-dir-825-b1-squashfs-backup-loader.bin"

echo -e "$GREEN Done. $WHITE"
if [ "$PLATFORM" == "atheros" ] || [ "$PLATFORM" == "x86" ] || [ "$PLATFORM" == "ar71xx" ]; then
  echo -e "$RED ********* $YELLOW Moving Compiled Images into \"builds\" directory $WHITE"
  BIN_DIR="$TOOLS/builds/$CODENAME/$PLATFORM/`date '+%d-%m-%y-%H%M%S'`"
  mkdir -p $BIN_DIR
  cp $BINARIES $BIN_DIR 2>/dev/null
else
  echo -e "$RED Search your binaries in $BUILDROOT your platform is not tested right now"
fi

echo -e "$GREEN Your system is ready. $WHITE"
echo -e "$YELLOW ==================================$GREEN Summary $YELLOW================================== $WHITE"
echo -e "|-> Your root password is $RED $PASSWORD $WHITE"

if [ -z "$WPA_PSK" ]; then
  echo -e "|-> Your WPA-PSK key is $RED owm-Ohz6ohngei $WHITE"
else
  echo -e "|-> Your WPA-PSK key is $RED $WPA_PSK $WHITE"
fi

echo -e "|-> You can find your binaries in $RED $BIN_DIR $WHITE"

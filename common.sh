#!/bin/sh
#
# Copyright (C) 2010 CASPUR
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

# Base parameters
ETH0_MAC=`ifconfig eth0 | grep HWaddr | cut -d':' -f2- | cut -d' ' -f4`
SLEEP_TIME=5
UPKEEP_TIME_UNITS=6
CONFCHECK_TIME_UNITS=12
CONFIGURATION_DOMAIN="owispmanager-setup"
IFACE="setup99"
STATUS_FILE_MAXLINES=1000

DEFAULT_CONFIGURATION_IP="172.22.33.1"
DEFAULT_CONFIGURATION_IP_RANGE_START="172.22.33.2"
DEFAULT_CONFIGURATION_IP_RANGE_END="172.22.33.10"
DEFAULT_CONFIGURATION_NMASK="255.255.255.0"
DEFAULT_HTTPD_PORT="8080"
#DEFAULT_WPAPSK="owm-`ifconfig eth0 | grep HWaddr | cut -d':' -f2- | cut -d' ' -f4 | sed 's/://g'`"
DEFAULT_SSID="$CONFIGURATION_DOMAIN"
DEFAULT_WPAPSK="owm-Ohz6ohngei"
DEFAULT_WIFIDEV="wifi0"
MADWIFI_CONFIGURATION_COMMAND="wlanconfig"
# URIs and Paths
CONFIGURATION_TARGZ_REMOTE_URL="get_config/$ETH0_MAC"
CONFIGURATION_TARGZ_MD5_REMOTE_URL="get_config/$ETH0_MAC.md5"
WEB_HOME_PATH="$HOME_PATH/web/"
TMP_PATH="/tmp/"
OWISPMANAGER_UCI_FILE="/etc/config/owispmanager"
CONFIGURATIONS_PATH="$TMP_PATH/owispmanager/"
CONFIGURATION_TARGZ_FILE="$CONFIGURATIONS_PATH/configuration.tar.gz"
CONFIGURATION_TARGZ_MD5_FILE="$CONFIGURATIONS_PATH/configuration.tar.gz.md5"
CONFIGURATIONS_ACTIVE_FILE="$CONFIGURATIONS_PATH/active"
HOSTAPD_FILE="$TMP_PATH/configuration.hostapd"
HOSTAPD_PIDFILE="$TMP_PATH/configuration-hostapd.pid"
HTTPD_PIDFILE="$TMP_PATH/configuration-httpd.pid"
DNSMASQ_PIDFILE="$TMP_PATH/configuration-dnsmasq.pid"
DNSMASQ_LEASE_FILE="$TMP_PATH/configuration-dhcp.leases"
DNSMASQ_RESOLV_FILE="$TMP_PATH/configuration-resolv.conf"
STATUS_FILE="$TMP_PATH/owispmanager.status"
INSTALL_SCRIPT_FILE="$CONFIGURATIONS_PATH/install.sh"
POST_INSTALL_SCRIPT_FILE="$CONFIGURATIONS_PATH/post_install.sh"
UPKEEP_SCRIPT_FILE="$CONFIGURATIONS_PATH/upkeep.sh"
PRE_UNINSTALL_SCRIPT_FILE="$CONFIGURATIONS_PATH/pre_unistall.sh"
UNINSTALL_SCRIPT_FILE="$CONFIGURATIONS_PATH/uninstall.sh"
#openVPN
HIDE_SERVER_PAGE="0"
VPN_IFACE="setup00"
VPN_CHECK_CMD="route -n|grep $VPN_IFACE"
VPN_RESTART_CMD="/etc/init.d/openvpn restart"
CLIENT_CERTIFICATES_FILE="/etc/openvpn/client.crt"
CA_CERTIFICATE_FILE="/etc/openvpn/ca.crt"
INNER_SERVER="10.8.0.1"
INNER_SERVER_PORT="80"
VPN_REMOTE=""
# Status
STATE_UNCONFIGURED="unconfigured"
STATE_CONFIGURED="configured"
# Misc
_APP_NAME="open WISP Manager"
_APP_VERS="1.7"

# -------
# Function:     checkPrereq
# Description:  Check for presence of the tools needed to run
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, 1 on non fatal error, > 1 on fatal error
# Notes:
checkPrereq() {
  local __ret="0"

  # Madwifi-ng tools
  if [ -x "`which $MADWIFI_CONFIGURATION_COMMAND`" ]; then
    echo "madwifi-ng tools ($MADWIFI_CONFIGURATION_COMMAND) are present"
  else
    __ret="2"
    echo "madwifi-ng tools ($MADWIFI_CONFIGURATION_COMMAND) are missing!"
  fi

  # Httpd
  if [ -x "`which httpd`" ]; then
    if [ "`httpd --help 2>&1 | head -1 | cut -d' ' -f1`" != "BusyBox" ]; then
      __ret=`expr $__ret + 1`
      echo "busyBox httpd is missing!"
    else
      echo "busyBox httpd is present (`httpd --help 2>&1 | head -1`)"
    fi
  else
    __ret="2"
    echo "busyBox httpd is missing!"
  fi

  # Hostapd
  if [ -x "`which hostapd`" ]; then
    echo "hostapd is present (`hostapd -v 2>&1 | head -1`)"
  else
    __ret="2"
    echo "hostapd is missing!"
  fi

  # Dnsmasq
  if [ -x "`which dnsmasq`" ]; then
    echo "dnsmasq is present (`dnsmasq -v 2>&1 | head -1`)"
  else
    __ret="2"
    echo "dnsmasq is missing!"
  fi

  # The following ar not "fatal"

  # ntpclient
  if [ -x "`which ntpdate`" ] || [ -x "`which htpdate`" ]; then
    echo "Time synchronization daemon is present"
  else
    if [ "$__ret" -lt "2" ]; then
      __ret="1"
    fi
    echo "Time synchronization daemon is missing!"
  fi

#  curl or wget
  if [ -x "`which curl`" ]; then
    echo "Curl is present (`curl -V 2>&1 | head -1`)"
  else
    if [ -x "`which wget `"  ]; then
      echo "Wget is present"
    else
      if [ "$__ret" -lt "2" ]; then
        __ret="1"
      fi
      echo "Curl or wget are missing!"
      echo "wget is missing!"
    fi
  fi

  # GNU netcat
  if [ -x "`which nc`" ]; then
    if [ "`nc -V 2>&1 | head -1 | cut -d'(' -f2 | cut -d' ' -f2`" == "GNU"  ]; then
      echo "GNU netcat is present (`nc -V 2>&1 | head -1`)"
    else
      if [ "$__ret" -lt "2" ]; then
        __ret="1"
      fi
      echo "GNU netcat is missing!"
    fi
  else
    if [ "$__ret" -lt "2" ]; then
      __ret="1"
    fi
    echo "GNU netcat is missing!"
  fi
  
  return $__ret
}

# -------
# Function:     checkMadwifi
# Description:  Check for presence of $WIFIDEV interface
# Input:        nothing
# Output:       nothing
# Returns:      0 if $WIFIDEV is present, > 0 otherwise
# Notes:
checkMadwifi() {
  if [ -z "`grep $WIFIDEV /proc/net/dev`" ]; then
    echo "$WIFIDEV not found..."
    return 1
  else
    echo "$WIFIDEV up and running!"
    return 0
  fi
}

# -------
# Function:     createUCIConfig
# Description:  Create OWISPMANAGER_UCI_FILE if doesn't exists
# Input:        nothing
# Output:       nothing
# Returns:      nothing
# Notes:
createUCIConfig() {
  touch $OWISPMANAGER_UCI_FILE
  uci show owispmanager.home >/dev/null 2>&1
  if [ "$?" -ne "0" ]; then
    dd if=/dev/null of=$OWISPMANAGER_UCI_FILE count=1 bs=1 >/dev/null 2>&1
    uci rename owispmanager.`uci add owispmanager server`="home"
    uci rename owispmanager.`uci add owispmanager config`="local"
  fi
}

loadStartupConfig() {
  uci_load "owispmanager"
  
  # Set "local" configuration variables
  WPAPSK=$DEFAULT_WPAPSK
  if [ ! -z "$CONFIG_local_wpapsk" ]; then
     WPAPSK=$CONFIG_local_wpapsk
  fi

  WIFIDEV=$DEFAULT_WIFIDEV
  if [ ! -z "$CONFIG_local_wifidev" ]; then
     WIFIDEV=$CONFIG_local_wifidev
  fi

  HTTPD_PORT=$DEFAULT_HTTPD_PORT
  if [ ! -z "$CONFIG_local_httpdport" ]; then
     HTTPD_PORT=$CONFIG_local_httpdport
  fi

  SSID=$DEFAULT_SSID
  if [ ! -z "$CONFIG_local_ssid" ]; then
     SSID=$CONFIG_local_ssid
  fi

  CONFIGURATION_IP=$DEFAULT_CONFIGURATION_IP
  CONFIGURATION_NMASK=$DEFAULT_CONFIGURATION_NMASK
  CONFIGURATION_IP_RANGE_START=$DEFAULT_CONFIGURATION_IP_RANGE_START
  CONFIGURATION_IP_RANGE_END=$DEFAULT_CONFIGURATION_IP_RANGE_END
  if [ ! -z "$CONFIG_local_ip" ] && [ ! -z "$CONFIG_local_nmask" ] && [ ! -z "$CONFIG_local_rangeipstart" ] && [ ! -z "$CONFIG_local_rangeipend" ]; then
     CONFIGURATION_IP=$CONFIG_local_ip
     CONFIGURATION_NMASK=$CONFIG_local_nmask
     CONFIGURATION_IP_RANGE_START=$CONFIG_local_rangeipstart
     CONFIGURATION_IP_RANGE_END=$CONFIG_local_rangeipend
  fi

  # Uncomment for mac80211
  # MADWIFI_CONFIGURATION_COMMAND="wlanconfig"
  # MADWIFI_CONFIGURATION_UP="wlanconfig $IFACE create wlandev $WIFIDEV wlanmode ap"
  # MADWIFI_CONFIGURATION_DOWN="wlanconfig $IFACE destroy"
  # MADWIFI_CONFIGURATION_CHAN="iwconfig $IFACE channel 1"
  # Uncomment for madwifi-ng
  MADWIFI_CONFIGURATION_COMMAND="wlanconfig"
  MADWIFI_CONFIGURATION_UP="wlanconfig $IFACE create wlandev $WIFIDEV wlanmode ap"
  MADWIFI_CONFIGURATION_DOWN="wlanconfig $IFACE destroy"
  MADWIFI_CONFIGURATION_CHAN="iwconfig $IFACE channel 1"

  # Shell commands
  HTTPD_START="start-stop-daemon -S -b -m -p $HTTPD_PIDFILE -a httpd -- -f -p $CONFIGURATION_IP:$HTTPD_PORT -h $WEB_HOME_PATH -r owispmanager"
  HTTPD_STOP="start-stop-daemon -K -p $HTTPD_PIDFILE >/dev/null 2>&1"
  HOSTAPD_START="hostapd -P $HOSTAPD_PIDFILE -B $HOSTAPD_FILE"
  HOSTAPD_STOP="start-stop-daemon -K -p $HOSTAPD_PIDFILE >/dev/null 2>&1"
  DNSMASQ_START="dnsmasq -i $IFACE -I lo -z -a $CONFIGURATION_IP -x $DNSMASQ_PIDFILE -K -D -y -b -E -s $CONFIGURATION_DOMAIN -S /$CONFIGURATION_DOMAIN/ -l $DNSMASQ_LEASE_FILE -r $DNSMASQ_RESOLV_FILE --dhcp-range=$CONFIGURATION_IP_RANGE_START,$CONFIGURATION_IP_RANGE_END,12h"
  DNSMASQ_STOP="start-stop-daemon -K -p $DNSMASQ_PIDFILE >/dev/null 2>&1"

}


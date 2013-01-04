#!/bin/sh
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

# Base parameters
ETH0_MAC=`ifconfig eth0 | grep HWaddr | cut -d':' -f2- | cut -d' ' -f4`
SLEEP_TIME=5
UPKEEP_TIME_UNITS=12
CONFCHECK_TIME_UNITS=24
# OWF Specific settings
CONFIGURATION_DOMAIN="owispmanager-setup"
IFACE="setup99"
STATUS_FILE_MAXLINES=1000
DEFAULT_CONFIGURATION_IP="172.22.33.1"
DEFAULT_CONFIGURATION_IP_RANGE_START="172.22.33.2"
DEFAULT_CONFIGURATION_IP_RANGE_END="172.22.33.10"
DEFAULT_CONFIGURATION_NMASK="255.255.255.0"
DEFAULT_HTTPD_PORT="8080"
DEFAULT_SSID="owf-$ETH0_MAC"
DEFAULT_WPAPSK="owm-Ohz6ohngei"
# URIs and Paths
CONFIGURATION_TARGZ_REMOTE_URL="get_config/$ETH0_MAC"
CONFIGURATION_TARGZ_MD5_REMOTE_URL="get_config/$ETH0_MAC.md5"
WEB_HOME_PATH="$HOME_PATH/web/"
OWM_URL="owm"
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
# openVPN
VPN_FILE="$TMP_PATH/owispmanager.ovpn"
VPN_PIDFILE="$TMP_PATH/owispmanager-ovpn.pid"
OPENVPN_TA_FILE="/etc/openvpn/ta.key"
OPENVPN_CA_FILE="/etc/openvpn/ca.crt"
OPENVPN_CLIENT_FILE="/etc/openvpn/client.crt"
VPN_IFACE="setup00"
DEFAULT_INNER_SERVER="10.8.0.1"
DEFAULT_INNER_SERVER_PORT="80"
# Misc
OLSRD_TXTINFO_PORT="8281"
DEFAULT_MESH_ESSID="OpenWISP-Mesh"
DEFAULT_MESH_CHANNEL="36"
DEFAULT_WIFIDEV="wifi0"
DEFAULT_PHYDEV="phy0"
DEFAULT_WIFI_MODE="80211ng"
MADWIFI_CONFIGURATION_COMMAND="wlanconfig"
MAC80211_CONFIGURATION_COMMAND="iw"
VPN_RESTART_SLEEP_TIME=10
DATE_UPDATE_TIMEOUT=10
DATE_UPDATE_SERVERS_NTP="ntp.ien.it"
DATE_UPDATE_SERVERS_HTTP="www.google.it"


# See load_startup_config() for runtime-defined variables

# Status
STATE_UNCONFIGURED="unconfigured"
STATE_CONFIGURED="configured"
# Misc
_APP_NAME="OpenWISP Firmware"
_APP_VERS="2.0"

# -------
# Function:     check_prerequisites
# Description:  Check for presence of the tools needed to run
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, 1 on non fatal error, > 1 on fatal error
# Notes:
check_prerequisites() {
  local __ret="0"

  # Wi-Fi drivers/tools
  check_driver
  local __driver_check_result="$?"
  if [ "$__driver_check_result" -eq "1" ]; then
    # Madwifi-ng tools
    if [ -x "`which $MADWIFI_CONFIGURATION_COMMAND`" ]; then
      echo "madwifi-ng tools ($MADWIFI_CONFIGURATION_COMMAND) are present"
    else
      __ret="2"
      echo "madwifi-ng tools ($MADWIFI_CONFIGURATION_COMMAND) are missing!"
    fi
  elif [ "$__driver_check_result" -eq "2" ]; then
    # mac80211 tools
    if [ -x "`which $MAC80211_CONFIGURATION_COMMAND`" ]; then
      echo "mac80211 tools ($MAC80211_CONFIGURATION_COMMAND) are present"
    else
      __ret="2"
      echo "mac80211 tools ($MAC80211_CONFIGURATION_COMMAND) are missing!"
    fi
  else
    __ret="2"
    echo "No Wi-Fi driver installed or unsupported Wi-Fi system!"
  fi
    
  # Httpd
  if [ -x "`which uhttpd`" ]; then
    echo "uHTTP Daemon is present!"
  else
    __ret="2"
    echo "HTTPD Daemon is missing"
  fi

  # Hostapd
  if [ -x "`which hostapd`" ]; then
    echo "hostapd is present (`hostapd -v 2>&1 | head -1`)"
  else
    __ret="2"
    echo "hostapd is missing!"
  fi

  if [ -x "`which openvpn`" ]; then
    echo "OpenVPN is present" 
  else
    __ret="2"
    echo "OpenVPN is missing!"
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

  # curl or wget
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
# Function:     check_driver
# Description:  Check for presence of $WIFIDEV/$PHYDEV interface
# Input:        nothing
# Output:       nothing
# Returns:      0 if no supported Wi-Fi iface is present
#               1 if madwifi iface is present
#               2 if mac80211 iface is present
# Notes:
check_driver() {
  if [ ! -z "`grep $WIFIDEV /proc/net/dev`" ]; then
    echo "$WIFIDEV up and running"
    return 1
  elif [ -d "/sys/class/ieee80211/$PHYDEV" ]; then
    echo "$PHYDEV up and running"
    return 2
  else
    echo "device not found"
    return 0
  fi
}

# -------
# Function:     create_uci_config
# Description:  Create OWISPMANAGER_UCI_FILE if doesn't exists
# Input:        nothing
# Output:       nothing
# Returns:      nothing
# Notes:
create_uci_config() {
  touch $OWISPMANAGER_UCI_FILE
  uci show owispmanager.home >/dev/null 2>&1
  if [ "$?" -ne "0" ]; then
    dd if=/dev/null of=$OWISPMANAGER_UCI_FILE count=1 bs=1 >/dev/null 2>&1
    uci rename owispmanager.`uci add owispmanager server`="home"
    uci rename owispmanager.`uci add owispmanager config`="local"
  fi
}

# -------
# Function:     load_startup_config
# Description:  Loads current confguration and sets up the global variables 
#               used by configuration services
# Input:        nothing
# Output:       nothing
# Returns:      nothing
# Notes:
load_startup_config() {
  uci_load "owispmanager"
  
  # Set "local" configuration variables
  # If there are uci keys defined, use them...

  WPAPSK=${CONFIG_local_setup_wpa_psk:-$DEFAULT_WPAPSK}
  WIFIDEV=${CONFIG_local_setup_wifi_dev:-$DEFAULT_WIFIDEV}
  PHYDEV=${CONFIG_local_setup_wifi_dev:-$DEFAULT_PHYDEV}
  HTTPD_PORT=${CONFIG_local_setup_httpd_port:-$DEFAULT_HTTPD_PORT}
  SSID=${CONFIG_local_setup_ssid:-$DEFAULT_SSID}
  INNER_SERVER=${CONFIG_home_inner_server:-$DEFAULT_INNER_SERVER}
  INNER_SERVER_PORT=${CONFIG_home_inner_server_port:-$DEFAULT_INNER_SERVER_PORT}
  WIFIMODE=${CONFIG_local_setup_wifi_mod:-$DEFAULT_WIFI_MODE}

  CONFIGURATION_IP=$DEFAULT_CONFIGURATION_IP
  CONFIGURATION_NMASK=$DEFAULT_CONFIGURATION_NMASK
  CONFIGURATION_IP_RANGE_START=$DEFAULT_CONFIGURATION_IP_RANGE_START
  CONFIGURATION_IP_RANGE_END=$DEFAULT_CONFIGURATION_IP_RANGE_END
  if [ ! -z "$CONFIG_local_setup_ip" ] && [ ! -z "$CONFIG_local_setup_netmask" ] && [ ! -z "$CONFIG_local_setup_range_ip_start" ] && [ ! -z "$CONFIG_local_setup_range_ip_end" ]; then
     CONFIGURATION_IP=$CONFIG_local_setup_ip
     CONFIGURATION_NMASK=$CONFIG_local_setup_netmask
     CONFIGURATION_IP_RANGE_START=$CONFIG_local_setup_range_ip_start
     CONFIGURATION_IP_RANGE_END=$CONFIG_local_setup_range_ip_end
  fi

}

# -------
# Function:     exec_with_timeout
# Description:  Executes a command with timeout
# Input:        A command, a timeout (>5)
# Output:       nothing
# Returns:      Command return value on success, 1 on error
# Notes:
exec_with_timeout() {
  local __command=$1
  local __timeout=$2

  if [ -z "$__command" ]; then
    return 1
  fi

  if [ -z "$__timeout" ]; then
      __timeout=10
  else
    if [ "$__timeout" -lt "5" ]; then
      echo "* WARNING exec_with_timeout(): timeout is too small, setting it to 5 seconds"
      __timeout=5
    fi
  fi

  eval "($__command) &"
  local __pid="$!"

  while [ "$__timeout" -gt "1" ]; do
    kill -0 $__pid >/dev/null 2>&1
    if [ "$?" -eq "0" ]; then
      sleep 1
      __timeout=`expr \( $__timeout - 1 \)`
    else
      wait $__pid >/dev/null 2>&1
      return $?
    fi
  done

  kill $__pid >/dev/null 2>&1
  sleep 1
  kill -0 $__pid >/dev/null 2>&1
  if [ "$?" -eq "0" ]; then
    kill -9 $__pid >/dev/null 2>&1
  fi

  echo "* Command prematurely aborted"

  return 1
}

# -------
# Function:     check_vpn_status
# Description:  Checks setup vpn status
# Input:        nothing
# Output:       nothing
# Returns:      0 if the vpn is up and runnng, !0 otherwise
# Notes:
check_vpn_status() {
  (route -n|grep $VPN_IFACE) >/dev/null 2>&1
  return $?
}

# -------
# Function:     update_date
# Description:  Tries hard to update time
# Input:        nothing
# Output:       nothing
# Returns:      0 on success (date/time updated) !0 otherwise
# Notes:
update_date() {
  local __ret=1

  if [ -x "`which ntpdate`" ]; then
    ntpdate -s -b -u -t $DATE_UPDATE_TIMEOUT $DATE_UPDATE_SERVERS_NTP >/dev/null 2>&1
    __ret=$?
  fi
  if [ "$__ret" -ne "0" -a -x "`which htpdate`" ]; then
    exec_with_timeout "(htpdate -s -t $DATE_UPDATE_SERVERS_HTTP | grep 'No time correction needed') >/dev/null 2>&1" $DATE_UPDATE_TIMEOUT
    __ret= [ "$?" -ne "0" ]
  fi

  return $__ret
}


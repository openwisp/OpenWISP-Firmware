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
# openVPN
VPN_FILE="$TMP_PATH/owispmanager.ovpn"
VPN_PIDFILE="$TMP_PATH/owispmanager-ovpn.pid"
CLIENT_KEY_FILE="/etc/openvpn/client.key"
CLIENT_CERTIFICATE_FILE="/etc/openvpn/client.crt"
CLIENT_TA_FILE="/etc/openvpn/ta.key"
CA_CERTIFICATE_FILE="/etc/openvpn/ca.crt"
VPN_IFACE="setup00"
DEFAULT_INNER_SERVER="10.8.0.1"
DEFAULT_INNER_SERVER_PORT="80"

# See loadStartupConfig() for runtime-defined variables

# Status
STATE_UNCONFIGURED="unconfigured"
STATE_CONFIGURED="configured"
# Misc
_APP_NAME="open WISP Firmware"
_APP_VERS="1.0"

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
  # By default kamikaze uses busybox httpd, backfire uses uhttpd so we need to check
  # wich daemon is installed 

  if [ -x "`which uhttpd`" ]; then
    echo "uHTTP Daemon is present!"
    HTTPD="uhttpd"
  elif [ -x "`which httpd`" ]; then
    echo "busybox HTTP Daemon is present "
    HTTPD="httpd"
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

# -------
# Function:     loadStartupConfig
# Description:  Loads current confguration and sets up the global variables 
#               used by configuration services
# Input:        nothing
# Output:       nothing
# Returns:      nothing
# Notes:
loadStartupConfig() {
  uci_load "owispmanager"
  
  # Set "local" configuration variables
  # If there are uci keys defined, use them...
  WPAPSK=$DEFAULT_WPAPSK
  if [ ! -z "$CONFIG_local_setup_wpa_psk" ]; then
     WPAPSK=$CONFIG_local_setup_wpa_psk
  fi

  WIFIDEV=$DEFAULT_WIFIDEV
  if [ ! -z "$CONFIG_local_setup_wifi_dev" ]; then
     WIFIDEV=$CONFIG_local_setup_wifi_dev
  fi

  HTTPD_PORT=$DEFAULT_HTTPD_PORT
  if [ ! -z "$CONFIG_local_setup_httpd_port" ]; then
     HTTPD_PORT=$CONFIG_local_setup_httpd_port
  fi

  SSID=$DEFAULT_SSID
  if [ ! -z "$CONFIG_local_setup_ssid" ]; then
     SSID=$CONFIG_local_setup_ssid
  fi

  INNER_SERVER=$DEFAULT_INNER_SERVER
  if [ ! -z "$CONFIG_home_inner_server" ]; then
     INNER_SERVER=$CONFIG_home_inner_server
  fi

  INNER_SERVER_PORT=$DEFAULT_INNER_SERVER_PORT
  if [ ! -z "$CONFIG_home_inner_server_port" ]; then
     INNER_SERVER_PORT=$CONFIG_home_inner_server_port
  fi

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

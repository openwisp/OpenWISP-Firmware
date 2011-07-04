#!/bin/bash 
#
# OpenWISP Firmware
# Copyright (C) 2010-2011 CASPUR
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

load_startup_config

# -------
# Function:     start_hostapd
# Description:  Starts HostAP daemon
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, !0 otherwise
# Notes:
start_hostapd() {
  echo "
logger_syslog=-1
logger_syslog_level=2
logger_stdout=-1
logger_stdout_level=2
driver=madwifi
interface=$IFACE
ssid=$SSID
debug=0
wpa=1
wpa_pairwise=TKIP
wpa_passphrase=$WPAPSK" > $HOSTAPD_FILE
  
  hostapd -P $HOSTAPD_PIDFILE -B $HOSTAPD_FILE
  return $?
}

# -------
# Function:     stop_hostapd
# Description:  Stops HostAP daemon
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
stop_hostapd() {
  start-stop-daemon -K -p $HOSTAPD_PIDFILE >/dev/null 2>&1
  return 0
}


# -------
# Function:     create_wifi_interface
# Description:  Creates the wifi setup interface
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
create_wifi_interface() {
  if [ -z "$1" ]; then
    CHAN="1"
  else
    CHAN="$1"
  fi
  wlanconfig $IFACE create wlandev $WIFIDEV wlanmode ap
  if [ "$?" -ne "0" ]; then
    return 1
  fi
  iwconfig $IFACE channel $CHAN
  if [ "$?" -ne "0" ]; then
    return 1
  fi
  ifconfig $IFACE $CONFIGURATION_IP netmask $CONFIGURATION_NMASK up
  if [ "$?" -ne "0" ]; then
    return 1
  fi
  return 0
}

# -------
# Function:     destroy_wifi_interface
# Description:  Destroys the wifi setup interface
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
destroy_wifi_interface() {
  ifconfig $IFACE down 2>/dev/null
  wlanconfig $IFACE destroy 2>/dev/null
  return 0
}


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

load_startup_config

# -------
# Function:     start_hostapd
# Description:  Starts HostAP daemon
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, !0 otherwise
# Notes:        you can enable 802.11n support with ieee80211n=1
start_hostapd() {
  if [ "$WIFIMODE" -eq "80211a" ]; then
    echo "
driver=nl80211
hw_mode=a
channel=48" > $HOSTAPD_FILE
  else
    echo "
driver=nl80211
hw_mode=g
channel=$CHAN" > $HOSTAPD_FILE
  fi

echo "
interface=$IFACE
ctrl_interface=/var/run/hostapd-phy0
auth_algs=1
macaddr_acl=0
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$WPAPSK
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
ssid=$SSID
ignore_broadcast_ssid=0" >> $HOSTAPD_FILE

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

  iw phy $PHYDEV interface add $IFACE type managed

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
  iw dev $IFACE del 2>/dev/null
  return 0
}

#!/bin/sh
#
# OpenWISP Firmware
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


HOME_PATH="/etc/owispmanager/"
. $HOME_PATH/common.sh

. /lib/functions.sh

# -------
# Function:     start_httpd
# Description:  Starts HTTPD daemon
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, !0 otherwise
# Notes:
start_httpd() {
  start-stop-daemon -S -b -m -p $HTTPD_PIDFILE -a uhttpd -- -f -p $CONFIGURATION_IP:$HTTPD_PORT -h $WEB_HOME_PATH -r $CONFIGURATION_DOMAIN
  return $?
}

# -------
# Function:     stop_httpd
# Description:  Stops http daemon
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
stop_httpd() {
  start-stop-daemon -K -p $HTTPD_PIDFILE >/dev/null 2>&1
  return 0
}


# -------
# Function:     start_dns_masq
# Description:  Starts dnsmasq daemon
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, !0 otherwise
# Notes:
start_dns_masq() {
  echo "
  nameserver $CONFIGURATION_IP
  search $CONFIGURATION_DOMAIN
  " > $DNSMASQ_RESOLV_FILE
  
  touch $DNSMASQ_LEASE_FILE
  
  dnsmasq -i $IFACE -I lo -z -a $CONFIGURATION_IP -x $DNSMASQ_PIDFILE -K -D -y -b -E -s $CONFIGURATION_DOMAIN \
          -S /$CONFIGURATION_DOMAIN/ -l $DNSMASQ_LEASE_FILE -r $DNSMASQ_RESOLV_FILE \
          --dhcp-range=$CONFIGURATION_IP_RANGE_START,$CONFIGURATION_IP_RANGE_END,12h
          
  return $?
}

# -------
# Function:     stop_dns_masq
# Description:  Stops dnsmasq daemon
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
stop_dns_masq() {
  start-stop-daemon -K -p $DNSMASQ_PIDFILE >/dev/null 2>&1
  return 0
}

# -------
# Function:     start_vpn
# Description:  Starts the setup vpn
# Input:        nothing
# Output:       nothing
# Returns:      0 if success, !0 otherwise
# Notes:
start_vpn() {
  openvpn --daemon --syslog openvpn_setup --writepid $VPN_PIDFILE --client --comp-lzo --nobind \
          --ca $OPENVPN_CA_FILE --cert $OPENVPN_CLIENT_FILE --key $OPENVPN_CLIENT_FILE \
          --cipher BF-CBC --dev $VPN_IFACE --dev-type tun  --proto tcp --remote $CONFIG_home_address $CONFIG_home_port \
          --resolv-retry infinite --tls-auth $OPENVPN_TA_FILE 1 --verb 1
  return $?
}

# -------
# Function:     stop_vpn
# Description:  Stops the setup vpn
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
stop_vpn() {
  VPN_PID="`cat $VPN_PIDFILE 2>/dev/null`"
  if [ ! -z "$VPN_PID" ]; then
    kill $VPN_PID
    sleep 1
    while [ ! -z "`(cat /proc/$VPN_PID/cmdline|grep openvpn) 2>/dev/null`" ]; do
      kill -9 $VPN_PID 2>/dev/null
    done
  fi
  return 0
}

# -------
# Function:     restart_vpn
# Description:  Restarts the setup vpn
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
restart_vpn() {
  stop_vpn
  start_vpn
  if [ "$?" -eq "0" ]; then
    sleep $VPN_RESTART_SLEEP_TIME
    check_vpn_status
    return $?
  else
    return $?
  fi
}


# -------
# Function:     configuration_retrieveTool
# Description:  Determines which tool should be used to retrieve configuration from server
# Input:        configuration command env variable name
# Output:       retrieving command line
# Returns:      0 on success, 1 on error
# Notes:
configuration_retrieve_command() {
  if [ -x "`which wget`" ]; then
    eval "$1=\"wget -O\""
    return 0
  fi
  if [ -x "`which curl`" ]; then
    eval "$1=\"curl -L -o\""
    return 0
  fi

  echo "* ERROR: cannot retrieve configuration! Please install curl or wget!!"
  return 1

}

# -------
# Function:     vpn_watchdog
# Description:  Check Setup VPN status and restart it if necessary
# Input:        nothing
# Output:       nothing
# Returns:      0 on success (VPN is up and running) !0 otherwise
# Notes:

vpn_watchdog() {
  check_vpn_status
  if [ "$?" -eq "0" ]; then
    return 0
  else
    open_status_log_results
    echo "* VPN is down, trying to restart it"

    update_date
    if [ "$?" -eq "0" ]; then
      echo "* Date/time correctly updated!"
    else
      echo "** Can't update date/time: check network configuration, DNS and NTP and/or HTTP connectivity **"
    fi

    restart_vpn
    if [ "$?" -eq "0" ]; then
      echo "* VPN correctly started"
      close_status_log_results
      return 0
    else
      echo "* Can't start VPN"
      close_status_log_results
      return 1
    fi
  fi
}

# -------
# Function:     configuration_retrieve
# Description:  Retrieves configuration from server and store it in $CONFIGURATION_TARGZ_FILE
# Input:        nothing
# Output:       nothing
# Returns:      0 on success !0 otherwise
# Notes:
configuration_retrieve() {
  open_status_log_results
  
  echo "Retrieving configuration..."
  RETRIEVE_CMD=""
  configuration_retrieve_command RETRIEVE_CMD
  if [ "$?" -ne "0" ]; then
    close_status_log_results
    return 2
  fi

  # Retrieve the configuration
  exec_with_timeout "$RETRIEVE_CMD $CONFIGURATION_TARGZ_FILE http://$INNER_SERVER/$CONFIGURATION_TARGZ_REMOTE_URL >/dev/null 2>&1" 15

  if [ "$?" -eq "0" ]; then
    md5sum $CONFIGURATION_TARGZ_FILE | cut -d' ' -f1 > $CONFIGURATION_TARGZ_MD5_FILE
  else
    echo "* Cannot retrieve configuration from server!"
    close_status_log_results
    return 1
  fi
  close_status_log_results
  return 0
}

# -------
# Function:     is_configuration_changed
# Description:  Retrieves configuration digest from server and compare it with the digest of current configuration
# Input:        nothing
# Output:       nothing
# Returns:      1 configuration changed, 0 configuration unchanged (or an error occurred)
# Notes:
is_configuration_changed() {
  RETRIEVE_CMD=""
  configuration_retrieve_command RETRIEVE_CMD
  if [ "$?" -ne "0" ]; then
    open_status_log_results
    echo "* BUG: shouldn't be here"
    close_status_log_results
    return 0 # Assume configuration isn't changed!
  fi

  exec_with_timeout "$RETRIEVE_CMD $CONFIGURATION_TARGZ_MD5_FILE.tmp http://$INNER_SERVER/$CONFIGURATION_TARGZ_MD5_REMOTE_URL >/dev/null 2>&1" 15
  if [ "$?" -eq "0" ]; then
    # Validates md5 format
    if [ -z "`head -1 $CONFIGURATION_TARGZ_MD5_FILE.tmp | egrep -e \"^[0-9a-z]{32}$\"`" ]; then
      open_status_log_results
      echo "* ERROR: Server send us garbage!"
      close_status_log_results
      return 0 # Assume configuration isn't changed!
    fi
    if [ "`cat $CONFIGURATION_TARGZ_MD5_FILE.tmp`" == "`cat $CONFIGURATION_TARGZ_MD5_FILE`" ]; then
      return 0
    else
      open_status_log_results
      echo "* Configuration changed!"
      close_status_log_results
      return 1
    fi
  else
    open_status_log_results
    echo "* WARNING: Cannot retrieve configuration md5 from server!"
    close_status_log_results
    return 0 # Assume configuration isn't changed!
  fi
}

# -------
# Function:     stop_configuration_services
# Description:  remove vap interface and services (https, hostapd) used in the setup phase
# Input:        nothing
# Output:       nothing
# Returns:      nothing
# Notes:
stop_configuration_services() {
  open_status_log_results
  echo "* Stopping configuration services"

  stop_dns_masq
  stop_httpd
  stop_hostapd

  destroy_wifi_interface

  close_status_log_results
}

# -------
# Function:     start_configuration_services
# Description:  create a vap interface and start the services (https, hostapd) needed in the setup phase
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, 1 on error
# Notes:
start_configuration_services() {
  # Checks if all the configuration services are running
  if [ ! -f "/proc/`cat $HOSTAPD_PIDFILE 2>/dev/null`/status" ] || [ ! -f "/proc/`cat $HTTPD_PIDFILE 2>/dev/null`/status" ] || [ ! -f "/proc/`cat $DNSMASQ_PIDFILE 2>/dev/null`/status" ]; then

    stop_configuration_services

    open_status_log_results
    echo "* Starting configuration services"

    create_wifi_interface 1
    if [ "$?" -ne "0" ]; then
      echo "* BUG: create_wifi_interface failed!"
      stop_configuration_services
      return 1
    fi
    if [ "$?" -eq "0" ]; then
      start_hostapd
    else
      echo "* BUG: Cannot start hostapd!"
      stop_configuration_services
      return 1
    fi
    if [ "$?" -eq "0" ]; then
      start_httpd
    else
      echo "* BUG: Cannot start httpd!"
      stop_configuration_services
      return 1
    fi
    if [ "$?" -eq "0" ]; then
      start_dns_masq
    else
      echo "* BUG: Cannot start dnsmasq!"
      stop_configuration_services
      return 1
    fi

    close_status_log_results
  fi
  return 0
}

# -------
# Function:     configuration_uninstall
# Description:  uninstall configuration retrieved from server
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
configuration_uninstall() {
  open_status_log_results
  echo "* Uninstalling active configuration"

  cd $CONFIGURATIONS_PATH

  $PRE_UNINSTALL_SCRIPT_FILE
  $UNINSTALL_SCRIPT_FILE

  rm -Rf $CONFIGURATIONS_PATH/*

  close_status_log_results
  return 0
}

# -------
# Function:     configuration_install
# Description:  install configuration retrieved from server
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, 1 on error
# Notes:
configuration_install() {
  open_status_log_results
  echo "* Installing new configuration"

  cd $CONFIGURATIONS_PATH

  tar xzf $CONFIGURATION_TARGZ_FILE
  if [ ! "$?" -eq "0" ]; then
    close_status_log_results
    return 1
  fi
  $INSTALL_SCRIPT_FILE
  if [ "$?" -eq "0" ]; then
    if [ -f "$POST_INSTALL_SCRIPT_FILE" ]; then
      $POST_INSTALL_SCRIPT_FILE
    fi
  else
    $UNINSTALL_SCRIPT_FILE
    close_status_log_results
    return 1
  fi

  touch $CONFIGURATIONS_ACTIVE_FILE

  close_status_log_results
  return 0
}

# -------
# Function:     upkeep
# Description:  perform upkeep actions and excecute upkeep user-defined script
# Input:        nothing
# Output:       nothing
# Returns:      nothing
# Notes:
upkeep() {
  if [ -f "$UPKEEP_SCRIPT_FILE" ]; then
    cd $CONFIGURATIONS_PATH
    $UPKEEP_SCRIPT_FILE
  fi
}

open_status_log_results() {
  exec 3>>$STATUS_FILE
  exec 1>&3
  exec 2>&3
  echo "--- `date` ------------------"
}

close_status_log_results() {
  echo ""
  exec 3>&-
  lines=`cat $STATUS_FILE | wc -l`
  if [ "$lines" -gt "$STATUS_FILE_MAXLINES" ]; then
    sed -i 1,`expr $lines - $STATUS_FILE_MAXLINES`\d $STATUS_FILE
  fi
}

# ------------------- MAIN

clean_up() {
  echo "* Cleaning up..."
  echo "* Uninstalling runtime configuration"
  configuration_uninstall
  echo "* Stopping configuration services"  
  stop_configuration_services
  echo "* Goodbye!"  
  echo ""
}

# Signals handling
trap 'clean_up; sync ; exit 1' TERM
trap 'clean_up; sync ; exit 1' INT
trap 'sync' HUP

open_status_log_results

if [ -z "$ETH0_MAC" ]; then
  echo "*** FATAL ERROR *** eth0 MAC address is missing! ***"
  sleep 5
  exit
fi

load_startup_config

echo "* Checking prerequisites... "
check_prerequisites
__ret="$?"
if [ "$__ret" -gt "0" ]; then
  echo "WARNING (Firmware problem): this system doesn't meet all the requisites needed to run $_APP_NAME."
  echo "Please check the status log."
  if [ "$__ret" -gt "1" ]; then
    echo "*** FATAL ERROR ***"
    close_status_log_results
    sleep 10
    exit
  fi
  close_status_log_results
fi
check_driver
__ret=$?
while [ "$__ret" -eq "0" ]; do
  echo "Waiting for device (driver not yet loaded?)"
  sleep 5
  check_driver
  __ret=$?
done
if [ "$__ret" -eq "1" ]; then
  echo "$WIFIDEV ok, let's rock!"
    . $HOME_PATH/tools/madwifi.sh
elif [ "$__ret" -eq "2" ]; then 
  echo "$PHYDEV ok, let's rock!"
    . $HOME_PATH/tools/mac80211.sh
fi

mkdir -p $CONFIGURATIONS_PATH >/dev/null 2>&1
create_uci_config
clean_up
rm -Rf $CONFIGURATIONS_PATH/* >/dev/null 2>&1
echo "* (Re-)starting..."

close_status_log_results

# Starting main loop
upkeep_timer=0
configuration_check_timer=0

while :
do

  # Reload owispmanager uci configuration at each iteration
  uci_load "owispmanager"

  upkeep_timer=`expr \( $upkeep_timer + 1 \) % $UPKEEP_TIME_UNITS`
  configuration_check_timer=`expr \( $configuration_check_timer + 1 \) % $CONFCHECK_TIME_UNITS`

  vpn_watchdog
  __vpn_status="$?"

  if [ "$CONFIG_home_status" == "$STATE_CONFIGURED" ]; then
    if [ -f $CONFIGURATIONS_ACTIVE_FILE ]; then
      # Uci configuration completed and remote configuration applied
      if [ "$upkeep_timer" -eq "0" ]; then
        upkeep
      fi
      if [ "$configuration_check_timer" -eq "0" ]; then
        if [ "$__vpn_status" -eq "0" ]; then
          is_configuration_changed
          if [ "$?" -eq "1" ]; then
            configuration_uninstall
            # If the following fails is likely to be a temporary problem.
            # $CONFIGURATIONS_ACTIVE_FILE was deleted by configuration_uninstall() so
            # next itaration we're going to enter in "setup" state...
            configuration_retrieve
            if [ "$?" -eq "0" ]; then
              # If the following fails is likely to be a temporary problem.
              # $CONFIGURATIONS_ACTIVE_FILE was deleted by configuration_uninstall() so
              # next itaration we're going to enter in "setup" state...
              configuration_install
            fi
          fi
        fi
      fi
    else
      # Uci configuration completed but non yet applied (setup state)
      __ret="0"
      if [ "$__vpn_status" -eq "0" ]; then
        configuration_retrieve
        if [ "$?" -eq "0" ]; then
          # Free resources ASAP for low-end devices
          stop_configuration_services
          # Install the configuration
          configuration_install
          if [ "$?" -ne "0" ]; then
            configuration_uninstall
            __ret="1"
          fi
        else
          # oops, something went wrong: restart configuration services in a moment
          __ret="1"
        fi
      else
        # oops, something went wrong: restart configuration services in a moment
        __ret="1"
      fi

      if [ "$__ret" -ne "0" ]; then
        # Restart configuration services
        start_configuration_services
      fi
    fi
  else #  $CONFIG_home_status == $STATE_UNCONFIGURED or $CONFIG_home_status == ""
    # Uci configuration missing... restart configuration services
    start_configuration_services
  fi
  sleep $SLEEP_TIME

done

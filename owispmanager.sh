#!/bin/ash
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


HOME_PATH="/etc/owispmanager/"
. $HOME_PATH/common.sh

. $PKG_INSTROOT/etc/functions.sh


# -------
# Function:     execWithTimeout
# Description:  Executes a command with timeout
# Input:        A command, a timeout (>5)
# Output:       nothing
# Returns:      Command return value on success, 1 on error
# Notes:
execWithTimeout() {
  local __command=$1
  local __timeout=$2
  
  if [ -z "$__command" ]; then
    return 1
  fi
  
  if [ -z "$__timeout" ]; then
      __timeout=10
  else
    if [ "$__timeout" -lt "5" ]; then
      echo "* WARNING execWithTimeout(): timeout is too small, setting it to 5 seconds"
      __timeout=5
    fi
  fi
  
  eval "$__command &" 
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
# Function:     startHttpd
# Description:  Starts HTTPD daemon
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, !0 otherwise
# Notes:
startHttpd() {
  start-stop-daemon -S -b -m -p $HTTPD_PIDFILE -a httpd -- -f -p $CONFIGURATION_IP:$HTTPD_PORT -h $WEB_HOME_PATH -r $CONFIGURATION_DOMAIN
  return $?
}

# -------
# Function:     stopHttpd
# Description:  Stops http daemon
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
stopHttpd() {
  start-stop-daemon -K -p $HTTPD_PIDFILE >/dev/null 2>&1
  return 0
}

# -------
# Function:     startHostapd
# Description:  Starts HostAP daemon
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, !0 otherwise
# Notes:
startHostapd() {
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
# Function:     stopHostapd
# Description:  Stops HostAP daemon
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
stopHostapd() {
  start-stop-daemon -K -p $HOSTAPD_PIDFILE >/dev/null 2>&1
  return 0
}

# -------
# Function:     startDnsmasq
# Description:  Starts dnsmasq daemon
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, !0 otherwise
# Notes:
startDnsmasq() {
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
# Function:     stopDnsmasq
# Description:  Stops dnsmasq daemon
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
stopDnsmasq() {
  start-stop-daemon -K -p $DNSMASQ_PIDFILE >/dev/null 2>&1
  return 0
}

# -------
# Function:     checkVpnStatus
# Description:  Checks setup vpn status
# Input:        nothing
# Output:       nothing
# Returns:      0 if the vpn is up and runnng, !0 otherwise
# Notes:
checkVpnStatus() {
  (route -n|grep $VPN_IFACE) >/dev/null 2>&1
  return $?
}

# -------
# Function:     startVpn
# Description:  Starts the setup vpn
# Input:        nothing
# Output:       nothing
# Returns:      0 if success, !0 otherwise
# Notes:
startVpn() {
  openvpn --daemon --syslog openvpn_setup --writepid $VPN_PIDFILE --client --comp-lzo --nobind \
          --ca $CA_CERTIFICATE_FILE --cert $CLIENT_CERTIFICATE_FILE --key $CLIENT_KEY_FILE \
          --cipher BF-CBC --dev $VPN_IFACE --dev-type tun  --proto tcp --remote $CONFIG_home_address $CONFIG_home_port \
          --resolv-retry infinite --tls-auth $CLIENT_TA_FILE 1 --verb 1
  return $?
}

# -------
# Function:     stopVpn
# Description:  Stops the setup vpn
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
stopVpn() {
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
# Function:     restartVpn
# Description:  Restarts the setup vpn
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
restartVpn() {
  stopVpn
  startVpn
  if [ "$?" -eq "0" ]; then
    sleep 1
    checkVpnStatus
    return $?
  else
    return $?
  fi
}

# -------
# Function:     createWiFiInterface
# Description:  Creates the wifi setup interface
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
createWiFiInterface() {
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
# Function:     destroyWiFiInterface
# Description:  Destroys the wifi setup interface
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
destroyWiFiInterface() {
  ifconfig $IFACE down 2>/dev/null
  wlanconfig $IFACE destroy 2>/dev/null
  return 0
}

# -------
# Function:     configurationRetrieveTool
# Description:  Determines which tool should be used to retrieve configuration from server
# Input:        configuration command env variable name
# Output:       retrieving command line
# Returns:      0 on success, 1 on error
# Notes:
configurationRetrieveCommand() {
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
# Function:     updateDate
# Description:  Tries hard to update time
# Input:        nothing
# Output:       nothing
# Returns:      0 on success (date/time updated) !0 otherwise
# Notes:
updateDate() {
  local __ret=1
  
  if [ -x "`which ntpdate`" ]; then
    ntpdate -s -b -u -t 5 ntp.ien.it
    __ret=$?
  fi
  if [ "$__ret" -ne "0" ] && [ -x "`which htpdate`" ]; then
    execWithTimeout "htpdate -s -t www.google.com | grep 'No time correction
    needed'" 5
    __ret= [ "$?" -ne "0" ] # Bad htpdate bug!
  fi
  
  return $__ret

}

# -------
# Function:     vpnWatchdog
# Description:  Check Setup VPN status and restart it if necessary
# Input:        nothing
# Output:       nothing
# Returns:      0 on success (VPN is up and running) !0 otherwise
# Notes:
vpnWatchdog() {
  checkVpnStatus
  if [ "$?" -eq "0" ]; then
    return 0
  else
    openStatusLogResults
    echo "* VPN is down, trying to restart it"
    
    if [ "`date -I | cut -d'-' -f1`" -eq "1970" ]; then
      echo "* Wrong date... I'll try to update it"
      updateDate
      if [ "$?" -eq "0" ]; then
        echo "* Date/time correctly updated!"
      else
        echo "** Can't update date/time: check network configuration, DNS and NTP and/or HTTP connectivity **"
      fi
    fi
    
    restartVpn
    if [ "$?" -eq "0" ]; then
      echo "* VPN correctly started"
      closeStatusLogResults
      return 0
    else
      echo "* Can't start VPN"
      closeStatusLogResults
      return 1
    fi
  fi
}

# -------
# Function:     configurationRetrieve
# Description:  Retrieves configuration from server and store it in $CONFIGURATION_TARGZ_FILE
# Input:        nothing
# Output:       nothing
# Returns:      0 on success !0 otherwise
# Notes:
configurationRetrieve() {
  openStatusLogResults
  
  echo "Retrieving configuration..."
  RETRIEVE_CMD=""
  configurationRetrieveCommand RETRIEVE_CMD
  if [ "$?" -ne "0" ]; then
    closeStatusLogResults
    return 2
  fi
  
  # Retrieve the configuration
  execWithTimeout "$RETRIEVE_CMD $CONFIGURATION_TARGZ_FILE http://$INNER_SERVER/$CONFIGURATION_TARGZ_REMOTE_URL >/dev/null 2>&1" 15
  
  if [ "$?" -eq "0" ]; then
    md5sum $CONFIGURATION_TARGZ_FILE | cut -d' ' -f1 > $CONFIGURATION_TARGZ_MD5_FILE
  else
    echo "* Cannot retrieve configuration from server!"
    closeStatusLogResults
    return 1
  fi
  closeStatusLogResults
  return 0
}

# -------
# Function:     configurationChanged
# Description:  Retrieves configuration digest from server and compare it with the digest of current configuration
# Input:        nothing
# Output:       nothing
# Returns:      1 configuration changed, 0 configuration unchanged (or an error occurred)
# Notes:
configurationChanged() {
  RETRIEVE_CMD=""
  configurationRetrieveCommand RETRIEVE_CMD
  if [ "$?" -ne "0" ]; then
    openStatusLogResults
    echo "* BUG: shouldn't be here"
    closeStatusLogResults
    return 0 # Assume configuration isn't changed!
  fi

  execWithTimeout "$RETRIEVE_CMD $CONFIGURATION_TARGZ_MD5_FILE.tmp http://$INNER_SERVER/$CONFIGURATION_TARGZ_MD5_REMOTE_URL >/dev/null 2>&1" 15
  if [ "$?" -eq "0" ]; then
    # Validates md5 format
    if [ -z "`head -1 $CONFIGURATION_TARGZ_MD5_FILE.tmp | egrep -e \"^[0-9a-z]{32}$\"`" ]; then
      openStatusLogResults
      echo "* ERROR: Server send us garbage!"
      closeStatusLogResults
      return 0 # Assume configuration isn't changed!
    fi
    if [ "`cat $CONFIGURATION_TARGZ_MD5_FILE.tmp`" == "`cat $CONFIGURATION_TARGZ_MD5_FILE`" ]; then
      return 0
    else
      openStatusLogResults
      echo "* Configuration changed!"
      closeStatusLogResults
      return 1
    fi
  else
    openStatusLogResults
    echo "* WARNING: Cannot retrieve configuration md5 from server!"
    closeStatusLogResults
    return 0 # Assume configuration isn't changed!
  fi
}

# -------
# Function:     stopConfigurationServices
# Description:  remove vap interface and services (https, hostapd) used in the setup phase
# Input:        nothing
# Output:       nothing
# Returns:      nothing
# Notes:
stopConfigurationServices() {
  openStatusLogResults
  echo "* Stopping configuration services"

  stopDnsmasq
  stopHttpd
  stopHostapd
  
  destroyWiFiInterface

  closeStatusLogResults
}

# -------
# Function:     startConfigurationServices
# Description:  create a vap interface and start the services (https, hostapd) needed in the setup phase
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, 1 on error
# Notes:
startConfigurationServices() {
  # Checks if all the configuration services are running
  if [ ! -f "/proc/`cat $HOSTAPD_PIDFILE 2>/dev/null`/status" ] || [ ! -f "/proc/`cat $HTTPD_PIDFILE 2>/dev/null`/status" ] || [ ! -f "/proc/`cat $DNSMASQ_PIDFILE 2>/dev/null`/status" ]; then
    
    stopConfigurationServices
    
    openStatusLogResults
    echo "* Starting configuration services"

    createWiFiInterface 1
    if [ "$?" -ne "0" ]; then
      echo "* BUG: createWiFiInterface failed!"
      stopConfigurationServices
      return 1
    fi
    if [ "$?" -eq "0" ]; then
      startHostapd
    else
      echo "* BUG: Cannot start hostapd!"
      stopConfigurationServices
      return 1
    fi
    if [ "$?" -eq "0" ]; then
      startHttpd
    else
      echo "* BUG: Cannot start httpd!"
      stopConfigurationServices
      return 1
    fi
    if [ "$?" -eq "0" ]; then
      startDnsmasq
    else
      echo "* BUG: Cannot start dnsmasq!"
      stopConfigurationServices
      return 1
    fi

    closeStatusLogResults
  fi
  return 0
}

# -------
# Function:     configurationUninstall
# Description:  uninstall configuration retrieved from server
# Input:        nothing
# Output:       nothing
# Returns:      0
# Notes:
configurationUninstall() {
  openStatusLogResults
  echo "* Uninstalling active configuration"

  cd $CONFIGURATIONS_PATH

  $PRE_UNINSTALL_SCRIPT_FILE
  $UNINSTALL_SCRIPT_FILE

  rm -Rf $CONFIGURATIONS_PATH/*

  closeStatusLogResults
  return 0
}

# -------
# Function:     configurationInstall
# Description:  install configuration retrieved from server
# Input:        nothing
# Output:       nothing
# Returns:      0 on success, 1 on error
# Notes:
configurationInstall() {
  openStatusLogResults
  echo "* Installing new configuration"

  cd $CONFIGURATIONS_PATH
  
  tar xzf $CONFIGURATION_TARGZ_FILE
  if [ ! "$?" -eq "0" ]; then
    closeStatusLogResults
    return 1
  fi
  $INSTALL_SCRIPT_FILE
  if [ "$?" -eq "0" ]; then
    if [ -f "$POST_INSTALL_SCRIPT_FILE" ]; then
      $POST_INSTALL_SCRIPT_FILE
    fi
  else
    $UNINSTALL_SCRIPT_FILE
    closeStatusLogResults
    return 1
  fi
  
  touch $CONFIGURATIONS_ACTIVE_FILE

  closeStatusLogResults
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

openStatusLogResults() {
  exec 3>>$STATUS_FILE
  exec 1>&3
  exec 2>&3
  echo "--- `date` ------------------"
}

closeStatusLogResults() {
  echo ""
  exec 3>&-
  lines=`cat $STATUS_FILE | wc -l`
  if [ "$lines" -gt "$STATUS_FILE_MAXLINES" ]; then
    sed -i 1,`expr $lines - $STATUS_FILE_MAXLINES`\d $STATUS_FILE
  fi
}

checkReset() {
  if   [ ! -z "`cat /proc/cpuinfo|grep AR2317`" ]; then
    # Atherso SoC AR2317
    gpioctl dirin 6 > /dev/null
    gpioctl get 6 > /dev/null
    if [ "$?" -eq "64" ]; then
      openStatusLogResults
      echo "* Reset button pressed..."
      echo "** Erasing rootfs_data **"
      mtd -r erase mtd3
      closeStatusLogResults
      sleep 100
      exit 1
    fi
  #elif 
  # TODO: other hardware
  fi
}


# ------------------- MAIN

# Check and serve reset botton
checkReset

cleanUp() {
  echo "* Cleaning up..."
  echo "* Uninstalling runtime configuration"
  configurationUninstall
  echo "* Stopping configuration services"  
  stopConfigurationServices
  echo "* Goodbye!"  
  echo ""
}

# Signals handling
trap 'cleanUp; sync ; exit 1' TERM
trap 'cleanUp; sync ; exit 1' INT
trap 'sync' HUP

openStatusLogResults

if [ -z "$ETH0_MAC" ]; then
  echo "*** FATAL ERROR *** eth0 MAC address is missing! ***"
  sleep 5
  exit
fi

loadStartupConfig

echo "* Checking prerequisites... "
checkPrereq
__ret="$?"
if [ "$__ret" -gt "0" ]; then
  echo "WARNING (Firmware problem): this system doesn't meet all the requisites needed to run $_APP_NAME."
  echo "Please check the status log."
  if [ "$__ret" -gt "1" ]; then
    echo "*** FATAL ERROR ***"
    closeStatusLogResults
    sleep 10
    exit
  fi
  closeStatusLogResults
else
  checkMadwifi
  __ret=$?
  while [ "$__ret" -ne "0" ]; do
    echo "Waiting for $WIFIDEV (madwifi-ng driver not yet loaded?)"
    sleep 5
    checkMadwifi
    __ret=$?
  done
  echo "$WIFIDEV ok, let's rock!"
fi

mkdir -p $CONFIGURATIONS_PATH >/dev/null 2>&1
createUCIConfig
cleanUp
rm -Rf $CONFIGURATIONS_PATH/* >/dev/null 2>&1
echo "* (Re-)starting..."

closeStatusLogResults

# Starting main loop
upkeep_timer=0
configuration_check_timer=0

while :
do
  
  # Reload owispmanager uci configuration at each iteration
  uci_load "owispmanager"
  
  upkeep_timer=`expr \( $upkeep_timer + 1 \) % $UPKEEP_TIME_UNITS`
  configuration_check_timer=`expr \( $configuration_check_timer + 1 \) % $CONFCHECK_TIME_UNITS`

  vpnWatchdog
  local __vpn_status="$?"

  if [ "$CONFIG_home_status" == "$STATE_CONFIGURED" ]; then
    if [ -f $CONFIGURATIONS_ACTIVE_FILE ]; then
      # Uci configuration completed and remote configuration applied
      if [ "$upkeep_timer" -eq "0" ]; then
        upkeep
      fi
      if [ "$configuration_check_timer" -eq "0" ]; then
        if [ "$__vpn_status" -eq "0" ]; then
          configurationChanged
          if [ "$?" -eq "1" ]; then
            configurationUninstall
            # If the following fails is likely to be a temporary problem.
            # $CONFIGURATIONS_ACTIVE_FILE was deleted by configurationUninstall() so
            # next itaration we're going to enter in "setup" state...
            configurationRetrieve
            if [ "$?" -eq "0" ]; then
              # If the following fails is likely to be a temporary problem.
              # $CONFIGURATIONS_ACTIVE_FILE was deleted by configurationUninstall() so
              # next itaration we're going to enter in "setup" state...
              configurationInstall
            fi
          fi
        fi
      fi
    else
      # Uci configuration completed but non yet applied (setup state)
      local __ret="0"
      if [ "$__vpn_status" -eq "0" ]; then
        configurationRetrieve
        if [ "$?" -eq "0" ]; then
          # Free resources ASAP for low-end devices
          stopConfigurationServices
          # Install the configuration
          configurationInstall
          if [ "$?" -ne "0" ]; then
            configurationUninstall
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
        startConfigurationServices
      fi
    fi
  else #  $CONFIG_home_status == $STATE_UNCONFIGURED or $CONFIG_home_status == ""
    # Uci configuration missing... restart configuration services
    startConfigurationServices
  fi
  sleep $SLEEP_TIME
  
done

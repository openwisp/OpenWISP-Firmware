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
# Function:     configurationRetrieveTool
# Description:  Determines which tool should be used to retrieve configuration from server
# Input:        nothing
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
# Function:     checkVPN
# Description:  Check Setup VPN status and restart it if necessary
# Input:        nothing
# Output:       nothing
# Returns:      0 on success (VPN is up and running) !0 otherwise
# Notes:
checkVPN() {
  
  # In order to modify or customize check and restart command 
  # please view "common.sh" file
  eval $VPN_CHECK_CMD

  if [ "$?" -ne "0" ]; then
    openStatusLogResults
    echo "* VPN is down, trying to restart it"
    eval $VPN_RESTART_CMD
    sleep 3 # This is useful to avoid problem when restarting
    eval $VPN_CHECK_CMD

    if [ "$?" -ne "0" ]; then
      echo "* Cannot start VPN"
      closeStatusLogResults
      return 1
    fi
  fi
  
  return 0
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
  if [ "$?" -eq "0" ]; then
    RETRIEVE_CMD="$RETRIEVE_CMD $CONFIGURATION_TARGZ_FILE http://`echo \"$INNER_SERVER\" | sed 's/[^0-9\.\:a-zA-Z-]//g'`/$CONFIGURATION_TARGZ_REMOTE_URL >/dev/null 2>&1"
  else
    closeStatusLogResults
    return 2
  fi
  
  eval $RETRIEVE_CMD
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
  if [ "$?" -eq "0" ]; then
    RETRIEVE_CMD="$RETRIEVE_CMD $CONFIGURATION_TARGZ_MD5_FILE.tmp http://$INNER_SERVER/$CONFIGURATION_TARGZ_MD5_REMOTE_URL >/dev/null 2>&1"
  else
    openStatusLogResults
    echo "* BUG: shouldn't be here"
    closeStatusLogResults
    return 0 # Assume configuration isn't changed!
  fi

  eval $RETRIEVE_CMD
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

  eval $DNSMASQ_STOP 2>/dev/null
  eval $HTTPD_STOP 2>/dev/null
  eval $HOSTAPD_STOP 2>/dev/null
  ifconfig $IFACE down 2>/dev/null
  eval $MADWIFI_CONFIGURATION_DOWN 2>/dev/null
  rm -f $HOSTAPD_FILE $DNSMASQ_RESOLV_FILE 2>/dev/null

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
wpa_passphrase=$WPAPSK
" > $HOSTAPD_FILE

    echo "
nameserver $CONFIGURATION_IP
search $CONFIGURATION_DOMAIN
" > $DNSMASQ_RESOLV_FILE
    touch $DNSMASQ_LEASE_FILE


    eval $MADWIFI_CONFIGURATION_UP
    if [ "$?" -eq "0" ]; then
      eval $MADWIFI_CONFIGURATION_CHAN
      ifconfig $IFACE $CONFIGURATION_IP netmask $CONFIGURATION_NMASK up
    else
      echo "* BUG: ifconfig failed!"
      stopConfigurationServices
      return 1
    fi
    if [ "$?" -eq "0" ]; then
      eval $HOSTAPD_START
    else
      echo "* BUG: Cannot start hostapd!"
      stopConfigurationServices
      return 1
    fi
    if [ "$?" -eq "0" ]; then
      eval $HTTPD_START
    else
      echo "* BUG: Cannot start httpd!"
      stopConfigurationServices
      return 1
    fi
    if [ "$?" -eq "0" ]; then
      eval $DNSMASQ_START
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

  eval $PRE_UNINSTALL_SCRIPT_FILE
  eval $UNINSTALL_SCRIPT_FILE

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
  eval $INSTALL_SCRIPT_FILE
  if [ "$?" -eq "0" ]; then
    if [ -f "$POST_INSTALL_SCRIPT_FILE" ]; then
      eval $POST_INSTALL_SCRIPT_FILE
    fi
  else
    eval $UNINSTALL_SCRIPT_FILE
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
    cd $CONFIGURATIONS_PATiH
    eval $UPKEEP_SCRIPT_FILE
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

# ------------------- MAIN
cleanUp() {
  echo "* Cleaning up..."
  echo ""
  stopConfigurationServices
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

  checkVPN ; VPN_STATUS="$?"

  if [ "$CONFIG_home_status" == "$STATE_CONFIGURED" ]; then
    if [ -f $CONFIGURATIONS_ACTIVE_FILE ]; then
      # Uci configuration completed and remote configuration applied
      if [ "$upkeep_timer" -eq "0" ]; then
        upkeep
      fi
      if [ "$configuration_check_timer" -eq "0" ]; then
        if [ "$VPN_STATUS" -eq "0" ]; then
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
      RET="0"
      if [ "$VPN_STATUS" -eq "0" ]; then
        configurationRetrieve
        if [ "$?" -eq "0" ]; then
          configurationInstall
          if [ "$?" -ne "0" ]; then
            RET="1"
          fi
        else
          RET="1"
        fi
      else
        RET="1"
      fi
      
      if [ "$RET" -eq "0" ]; then
        stopConfigurationServices
      else
        startConfigurationServices
      fi
    fi
  else #  $CONFIG_home_status == $STATE_UNCONFIGURED or $CONFIG_home_status == ""
    # Uci configuration missing
    startConfigurationServices
  fi
  sleep $SLEEP_TIME
  
done


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

. /etc/functions.sh

INTERFACES="br-lan 3g-umts"
INTERFACES_METRICS="0 20"
TEST_IPS="8.8.8.8 8.8.4.4 193.201.40.14"
SLEEP_TIME=3
PING_WAIT_TIME=3

# -------
# Function:     get_interface_default_route_priority()
# Description:  Gets the configured default route priority for an interface 
# Input:        An interface
# Output:       The configured priority for the specified interface
# Returns:      0 on success, 1 on error
# Notes:
get_interface_default_route_priority() {
  [ -z "$1" ] && return 1;

  local _i=0
  local _interface
  for _interface in $INTERFACES; do
    if [ "$1" == "$_interface" ]; then
      local _metric
      for _metric in $INTERFACES_METRICS; do
        if [ "$_i" -eq "0" ]; then
          echo "$_metric"
          return 0
        fi 
        _i=`expr $_i - 1` 
      done
      return 1
    fi
    _i=`expr $_i + 1` 
  done
  
  echo "0"
  return 0
}

# -------
# Function:     get_interface_default_route_metric()
# Description:  Gets the current metric for the default route that use the specified interface 
# Input:        An interface
# Output:       The current metric for the default route that use the specified interface 
# Returns:      0 on success, 1 on error
# Notes:
get_interface_default_route_metric() {
  [ -z "$1" ] && return 1;
  
  local _metric=`grep -E "$1[[:space:]]+00000000" /proc/net/route | awk '{print $7}'`
  echo "${_metric:-0}"
  
  return 0  
}

# -------
# Function:     set_interface_default_route_metric()
# Description:  Sets the metric for the default route that use the specified interface 
# Input:        An interface
# Output:       Nothing
# Returns:      0 on success, 1 on error
# Notes:        This function flushes the route cache: to be called only if strictly necessary
set_interface_default_route_metric() {
  local _interface="$1"
  local _metric="`echo $2 | sed 's/[^0-9]//g'`"

  [ -z "$_interface" -o -z "$_metric" ] && return 1;

  local _route=`ip route show | grep "^default via .* dev $_interface"`
  [ -z "$_route" ] && return 1;
  
  local _route_without_metric=`echo "$_route" | awk ' { print $1 " " $2 " " $3 " " $4 " " $5 }'`
  
  ip route del $_route
  ip route add $_route_without_metric metric $_metric
  ip route flush cache
  
  return 0
}

# -------
# Function:     interface_default_route_test()
# Description:  Tests the default route using the specified interface 
# Input:        An interface
# Output:       Nothing
# Returns:      0 if the default route using the specified interface can be used, 1 otherwise
# Notes:
interface_default_route_test() {
  local _interface="$1"

  [ -z "$_interface" ] && return 1;
  
  local _ret=1
  for _ip in $TEST_IPS; do
    ping -c 3 -w $PING_WAIT_TIME -I $_interface $_ip >/dev/null 2>&1
    _ret=`expr $_ret \* $?`
    [ "$_ret" -eq "0" ] && break;
  done

  return $_ret
}


# Main()

# Test the presence of needed application

[ -x "/bin/ping" ] || { echo "ping is missing!"; exit 1; }
[ -x "/usr/sbin/ip" -o "/bin/ip" ] || { echo "ip route is missing!"; exit 1; }
[ -x "/usr/bin/awk" ] || { echo "awk is missing!"; exit 1; }
[ -x "/bin/sed" ] || { echo "sed is missing!"; exit 1; }

#
# loop forever
#   for each configured interface
#     if the associated default route can be used
#       set this default route to the configured interface priority
#     else
#       set this default route to the configured interface priority + 1000
#
#   sleep
#

while true; do
      
  for interface in $INTERFACES ; do
 
    priority=`get_interface_default_route_priority $interface`; [ "$?" -eq "0" ] || break;
    metric=`get_interface_default_route_metric $interface`; [ "$?" -eq "0" ] || break;
                                                                   
    interface_default_route_test $interface
    if [ "$?" -eq "0" ]; then
      # Interface can be used                                    
                                                                
      if [ "$metric" -gt "$priority" ]; then                   
        set_interface_default_route_metric $interface $priority
      fi
    else                                                           
      # Interface shouldn't be used                                    
      new_priority="`expr $priority + 1000`"
      if [ "$metric" -lt "$new_priority" ]; then
        set_interface_default_route_metric $interface $new_priority
      fi
    fi
  done

  sleep $SLEEP_TIME
done

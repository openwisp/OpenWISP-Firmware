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

while true; do

  DEVICES=`lsusb | grep -v "root hub" | cut -d ' ' -f 6`

  for DEV in $DEVICES; do

    vendor=`echo $DEV | cut -d ' ' -f 6 | cut -d':' -f1`
    product=`echo $DEV| cut -d ' ' -f 6 | cut -d':' -f2`

    for i in $(ls /etc/usb_modeswitch.d/$vendor:*); do

      value=$(grep $product $i)

      if [ -n "$value" ]; then
        
        TARGET_PRODUCT=`cat $i | grep TargetProduct | sed 's/^TargetProduct= *\(.*\) */\1/'`
        TARGET_VENDOR=`cat $i | grep TargetVendor | sed 's/^TargetVendor= *\(.*\) */\1/'`
        
        rmmod usbserial >/dev/null 2>&1
        insmod usbserial vendor="$TARGET_VENDOR" product="$TARGET_PRODUCT" >/dev/null 2>&1
        
        FILE_NAME="$i"
        break
      fi
    done
    [ -n "$FILE_NAME" ] || break;
  done

  if [ -n "$FILE_NAME" ]; then
    if [ ! -c "/dev/ttyUSB0" ]; then
      usb_modeswitch -c $FILE_NAME >/dev/null 2>&1
      sleep 2
      if [ ! -c "/dev/ttyUSB0" ]; then
        continue
      fi
    fi

    ifup umts  >/dev/null 2>&1
    sleep 10

    while [ -n "`ifconfig 3g-umts 2>/dev/null | grep inet`" ]; do
      sleep 10
    done
  else
    sleep 5
  fi

done

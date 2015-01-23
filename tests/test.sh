#!/bin/bash

# 1 device flashing
# 2 dhcp lease
# 3 test ssid available
# 4 dhcp leased over 
# 5 redirect to captive portal

# $1 is firmware file to test
# $2 is max wait time
MAXWAIT_TIME=50

# VARS for 1
IFACE_FLASH='eth0'


set -e
# 1 flash the device, we assume that it is a ap51 flashable device
sudo chmod 777 /dev/ttyACM0
stty -F /dev/ttyACM0 raw ispeed 15200 ospeed 15200 cs8 -ignpar -cstopb -echo
# All relays on
echo 'd' > /dev/ttyACM0
sleep 1
# Turn relay 1 off
echo 'o' > /dev/ttyACM0

make -C ap51flash
timeout $(MAXWAIT_TIME) ./ap51flash/ap51flash $(IFACE_FLASH) $1
if [[ $? -eq 124 ]]; then
	exit 2
fi

# 2  dhcp-lease 

sudo aptitude -y install libidn11-dev
sudo killall dnsmasq

make -C dnsmasq
sudo ifconfig $(IFACE_FLASH) 192.168.2.1
timeout $(MAXWAIT_TIME) sudo ./dnsmasq/src/dnsmasq --dhcp-range 192.168.2.2,192.168.2.3,4 -d -i eth1
if [[ $? -ne 8 ]]; then
	exit 2
fi

# 3 test ssid available

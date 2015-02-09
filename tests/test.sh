#!/bin/bash

# 1 device flashing
# 2 dhcp lease
# 3 test ssid available

# $1 is firmware file to test
# $2 is max wait time
MAXWAIT_TIME=50

# VARS for 1
IFACE_FLASH='eth1'
SUDO="sudo"
TIMEOUT="timeout $MAXWAIT_TIME "

if [[ -z $1 ]]; then
	echo "Image missing"
	exit 8
fi

set -x

function pre_condition {
	echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward
}

function flash {
	# 1 flash the device, we assume that it is a ap51 flashable device
	$SUDO chmod 777 /dev/ttyACM0
	stty -F /dev/ttyACM0 raw ispeed 15200 ospeed 15200 cs8 -ignpar -cstopb -echo
	# All relays on
	echo 'd' > /dev/ttyACM0
	sleep 1
	# Turn relay 1 off
	echo 'o' > /dev/ttyACM0

	make -C ap51flash
	sudo ifconfig eth1 up
	timeout 200 $SUDO ./ap51flash/ap51-flash $IFACE_FLASH $1
	if [[ $? -eq 124 ]]; then
		exit 2
	fi
}

function dhcp {
	# 2  dhcp-lease
	rm -f /tmp/dhcpd_leased
	$SUDO ifconfig $IFACE_FLASH 192.168.99.1
	timeout 200 python ./vendor/tiny-dhcp.py -a 192.168.99.1 -i $IFACE_FLASH > /tmp/dhcpd_leased
	if [[ $? -ne 0 ]]; then
		exit 2
	fi
	if [[ ! -f /tmp/dhcpd_leased ]]; then
		exit 3
	fi
}


function wifi_up_safe_mode {
	# 3 test ssid available
	SSID=""
	for a in `seq 1 30`; do
		sleep 10
		SSID=`sudo iw wlan0 scan | grep SSID | grep -o 'owf-.*'` #FIXME wlan0 is param
		if [[ -n "$SSID" ]]; then
			break
		fi
	done
	if [[ $SSID != "owf-`tail -n 1 /tmp/dhcpd_leased`" ]]; then
		exit 2
	fi
}

function wifi_up {
	echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
	sudo iptables -t nat -A POSTROUTING -o eth3 -j MASQUERADE

	# 3 test ssid available
	SSID=""
	for a in `seq 1 30`; do
		sleep 10
		SSID=`sudo iw wlan0 scan | grep SSID | grep -o 'Test2WiFi'` #FIXME wlan0 is param
		if [[ -n "$SSID" ]]; then
			break
		fi
	done
	if [[ $SSID != "Test2WiFi" ]]; then
		exit 2
	fi

}

function wifi_connect {
	sudo iw dev wlan0 connect -w Test2Wifi || exit 2
	sudo dhclient wlan0
}

pre_condition
flash $1
dhcp
wifi_up_safe_mode
wifi_up
#wifi_connect # Untested
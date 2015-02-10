#!/bin/bash

# $1 is firmware file to test

# define default for ifaces if not set in env
WAN_IFACE=${WAN_IFACE:-eth0}
LAN_IFACE=${LAN_IFACE:-eth1}
WLAN_IFACE=${WLAN_IFACE:-wlan0}

SERIAL_PORT=${SERIAL_PORT:-/dev/ttyACM0}

SUDO="sudo"

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
	$SUDO chmod 777 $SERIAL_PORT
	stty -F $SERIAL_PORT raw ispeed 15200 ospeed 15200 cs8 -ignpar -cstopb -echo
	# All relays on
	echo 'd' > $SERIAL_PORT
	sleep 1
	# Turn relay 1 off
	echo 'o' > $SERIAL_PORT

	make -C ap51flash
	sudo ifconfig $LAN_IFACE up
	timeout 200 $SUDO ./ap51flash/ap51-flash $LAN_IFACE $1
	if [[ $? -eq 124 ]]; then
		exit 2
	fi
}

function dhcp {
	# 2  dhcp-lease
	rm -f /tmp/dhcpd_leased
	$SUDO ifconfig $LAN_IFACE 192.168.99.1
	timeout 200 python ./vendor/tiny-dhcp.py -a 192.168.99.1 -i $LAN_IFACE > /tmp/dhcpd_leased
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
		SSID=`sudo iw $WLAN_IFACE scan | grep SSID | grep -o 'owf-.*'`
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
		SSID=`sudo iw $WLAN_IFACE scan | grep SSID | grep -o 'Test2WiFi'`
		if [[ -n "$SSID" ]]; then
			break
		fi
	done
	if [[ $SSID != "Test2WiFi" ]]; then
		exit 2
	fi

}

function wifi_connect {
	sudo iw dev $WLAN_IFACE connect -w Test2Wifi || exit 2
	sudo dhclient $WLAN_IFACE
}


# lists of the tests that should be run in order
TESTS="pre_condition flash dhcp wifi_up_safe_mode wifi_up wifi_connect"

for test_name in $TESTS; do
	$test_name $* #forward all cmds args to function
done

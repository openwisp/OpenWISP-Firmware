#!/bin/bash

# $1 is the board method
# $2 is firmware file to test
# $3 is the number of the first n-th test that could be skipped

# all command parameters are passed as is at test functions

# define default for ifaces if not set in env
WAN_IFACE=${WAN_IFACE:-eth0}
LAN_IFACE=${LAN_IFACE:-eth1}
WLAN_IFACE=${WLAN_IFACE:-wlan0}

SERIAL_PORT=${SERIAL_PORT:-/dev/ttyACM0}

SUDO="sudo"

if [[ -z $1 ]]; then
	echo "board not set"
	exit 9
else
	source boards/$1.sh
fi

if [[ -z $2 ]]; then
	echo "Image missing"
	exit 8
fi

set -x

function pre_condition {
	echo 0 | sudo tee /proc/sys/net/ipv4/ip_forward
}

function dhcp {
	# 2  dhcp-lease
	$SUDO rm -f /tmp/dhcpd_leased
	$SUDO ifconfig $LAN_IFACE 192.168.99.1
	$SUDO timeout 200 python ./vendor/tiny-dhcp.py -a 192.168.99.1 -i $LAN_IFACE -d 8.8.8.8 > /tmp/dhcpd_leased
	if [[ $? -ne 0 ]]; then
		exit 2
	fi
	if [[ ! -f /tmp/dhcpd_leased ]]; then
		exit 3
	fi

	LEASED_IP=`head -n 1 /tmp/dhcpd_leased`
	ping $LEASED_IP -c 2 || exit 2
}


function wifi_up_safe_mode {
	# 3 test ssid available
	SSID=""
	for a in `seq 1 30`; do
		sleep 10
		SSID=`$SUDO iw $WLAN_IFACE scan | grep SSID | grep -o 'owf-.*'`
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
	sudo iptables -t nat -A POSTROUTING -o $WAN_IFACE -j MASQUERADE

	# 3 test ssid available
	SSID=""
	for a in `seq 1 30`; do
		sleep 10
		SSID=`$SUDO iw $WLAN_IFACE scan | grep SSID | grep -o 'Test2WiFi'`
		if [[ -n "$SSID" ]]; then
			break
		fi
	done
	if [[ $SSID != "Test2WiFi" ]]; then
		exit 2
	fi

}

function wifi_connect {
	$SUDO iw dev $WLAN_IFACE connect -w Test2Wifi || exit 2
	$SUDO dhclient $WLAN_IFACE
}


# lists of the tests that should be run in order
TESTS="pre_condition board_flash dhcp wifi_up_safe_mode wifi_up wifi_connect board_power_off"

if [ "$3" ]; then
	TESTS=`echo $TESTS | cut -d " " -f $3-`
fi

for test_name in $TESTS; do
	$test_name $* #forward all cmds args to function
done

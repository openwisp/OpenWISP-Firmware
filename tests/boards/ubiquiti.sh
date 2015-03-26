# a board support file MUST implement the function:
#	- board_flash
#	- board_power_off

# USB-RLY02
RLYO2[0]="p" #on
RLYO2[1]="f" #off
# USB-RLY16
RLY16[0]="e" #on
RLY16[1]="o" #off

TYPE=$1

board_flash() {
	# 1 flash the device, we assume that it is a ap51 flashable device
	board_reset

	make -C ap51flash
	sudo ifconfig $LAN_IFACE up
	$SUDO timeout 500 ./ap51flash/ap51-flash $LAN_IFACE $2
	if [[ $? -eq 124 ]]; then
		exit 2
	fi
	board_reset
}


board_power_off() {
	# rly2 off
	eval echo \${$TYPE[1]} > $SERIAL_PORT
}

board_reset() {
	$SUDO chmod 777 $SERIAL_PORT
	stty -F $SERIAL_PORT raw ispeed 15200 ospeed 15200 cs8 -ignpar -cstopb -echo

	# Board reset
	eval echo \${$TYPE[1]} > $SERIAL_PORT
	sleep 2
	# rly2 on
	eval echo \${$TYPE[0]} > $SERIAL_PORT
}

shutdown_test() {
	# Board shutdown

}

# a board support file MUST implement the function:
#	- board_flash
#	- board_power_off

function board_flash {
	# 1 flash the device, we assume that it is a ap51 flashable device
	$SUDO chmod 777 $SERIAL_PORT
	stty -F $SERIAL_PORT raw ispeed 15200 ospeed 15200 cs8 -ignpar -cstopb -echo
	# rly2 off
	echo 'p' > $SERIAL_PORT
	sleep 2
	# rly2 on
	echo 'f' > $SERIAL_PORT

	make -C ap51flash
	sudo ifconfig $LAN_IFACE up
	$SUDO timeout 500 ./ap51flash/ap51-flash $LAN_IFACE $2
	if [[ $? -eq 124 ]]; then
		exit 2
	fi
	# power reset
	echo 'p' > $SERIAL_PORT
	sleep 2
	# rly2 on
	echo 'f' > $SERIAL_PORT
}


function board_power_off {
	# rly2 off
	echo 'p' > $SERIAL_PORT
}
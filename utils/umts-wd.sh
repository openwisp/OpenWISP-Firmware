#!/bin/sh

IFACE="3g-umts"
COM_PORT=$(uci get network.umts.device)
SERVICE_PORT="/dev/ttyUSB2"
TEST_IP="8.8.8.8"
PING_NUM=10
PING_WAIT_TIME=3
COUNT=0
SLEEP_TIME_IFUP=5
SLEEP_TIME_LOOP=20
REBOOT_CMD="sync ; reboot"
PPPD_FLAG=0

while true; do
  sleep $SLEEP_TIME_LOOP 
  ping -c $PING_NUM -I $IFACE -W $PING_WAIT_TIME $TEST_IP >/dev/null 2>&1 
  RET=$?
  
  if [ $RET -eq 0 ]; then
    COUNT=0
    PPPD_FLAG=0
  elif [ -c $SERVICE_PORT ]; then
    #ifdown umts
    echo -e -n "ATZ\r" > $SERVICE_PORT
    sleep $SLEEP_TIME_IFUP
    #ifup umts
  fi

  COUNT=`expr $COUNT + $RET`

  sleep $SLEEP_TIME_LOOP
  
  if [ $PPPD_FLAG -eq 1 -a $RET != 0 ]; then
    logger $0 "unable to set up 3g connection: restarting system"
    sleep 5
    eval $REBOOT_CMD
  fi

  if [ $COUNT -ge 3 ]; then
    pppd $COM_PORT nodetach &
    LASTPID=$!
    sleep $SLEEP_TIME_IFUP
    ifdown umts
    kill "$LASTPID"
    ifup umts
    PPPD_FLAG=1
  fi
  
done

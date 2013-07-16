#!/bin/sh

SERVICE_PORT="/dev/ttyUSB2"
IMSI_SCRIPT_PATH="/etc/gcom/getimsi.gcom"
REG_SCRIPT_PATH="/etc/gcom/getreginfo.gcom"
H3G_IT_ID="22299"
H3G_IT_APN="datacard.tre.it"
TIM_IT_ID="22201"
TIM_IT_APN="ibox.tim.it"
VODAFONE_IT_ID="22210"
VODAFONE_IT_APN="web.omnitel.it"
WIND_IT_ID="22288"
WIND_IT_APN="internet.wind.biz"

use_gcom() {
  local _scriptname="$1"
  gcom -s $_scriptname -d $SERVICE_PORT
}

while true; do

  APN_NAME=$(uci get network.umts.apn) 
  RET1=$?
  if [ $RET1 != 0 ]; then
    APN_NAME=""
  fi  

  if [ -c $SERVICE_PORT -a -z $APN_NAME ]; then
    IMSI=`use_gcom $IMSI_SCRIPT_PATH | grep "[0-9]\{15\}"`
    RET2=$?
    OP_ID=`echo $IMSI | cut -c -5`

    case $OP_ID in
      $H3G_IT_ID)
      APN_NAME=$H3G_IT_APN
      ;;
      $TIM_IT_ID)
      APN_NAME=$TIM_IT_APN
      ;;
      $VODAFONE_IT_ID)
      APN_NAME=$VODAFONE_IT_APN
      ;;
      $WIND_IT_ID)
      APN_NAME=$WIND_IT_APN
      ;;
      *)
      APN_NAME=""
    esac

    if [ $RET2 -eq 0 -a -n $APN_NAME ]; then
      uci set network.umts.apn=$APN_NAME
      logger $0 "APN is $APN_NAME"
    fi

    STATUS=`use_gcom $REG_SCRIPT_PATH | grep [0-2],[0-5] | cut -d',' -f2 | cut -c 1`
    if [ $STATUS -eq 5 ]; then
      echo -e -n "AT+COPS=2\r" > $SERVICE_PORT
      sleep 5
      echo -e -n "AT+COPS=1,2,$OP_ID\r" > $SERVICE_PORT
      sleep 10
    fi

  fi

  sleep 5 
  
done

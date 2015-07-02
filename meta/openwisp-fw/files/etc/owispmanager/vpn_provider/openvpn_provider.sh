# This openvpn provider for openvpn
# All functions return:      0 if success, !0 otherwise

start_vpn() {
  openvpn --daemon --syslog openvpn_setup --writepid $VPN_PIDFILE --client --comp-lzo --nobind \
          --ca $OPENVPN_CA_FILE --cert $OPENVPN_CLIENT_FILE --key $OPENVPN_CLIENT_FILE \
          --cipher BF-CBC --dev $VPN_IFACE --dev-type tun  --proto tcp --remote $CONFIG_home_address $CONFIG_home_port \
          --resolv-retry infinite --tls-auth $OPENVPN_TA_FILE 1 --verb 1
  return $?
}

stop_vpn() {
  VPN_PID="`cat $VPN_PIDFILE 2>/dev/null`"
  if [ ! -z "$VPN_PID" ]; then
    kill $VPN_PID
    sleep 1
    while [ ! -z "`(cat /proc/$VPN_PID/cmdline|grep openvpn) 2>/dev/null`" ]; do
      kill -9 $VPN_PID 2>/dev/null
    done
  fi
  return 0
}

check_vpn_status() {
  (route -n|grep $VPN_IFACE) >/dev/null 2>&1
  return $?
}

check_prerequisites_vpn() {
  if [ -x "`which openvpn`" ]; then
    echo "OpenVPN is present"
    return 0
  else
    echo "OpenVPN is missing!"
  fi
  return 2
}

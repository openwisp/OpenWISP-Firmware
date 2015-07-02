# This vtun provider for the vpn
# All functions return:      0 if success, !0 otherwise

start_vpn() {
  vtund -f /etc/vtund-client.conf $VTUN_CLIENT $CONFIG_home_address
  return $?
}

stop_vpn() {
  killall vtund
  return 0
}

check_vpn_status() {
  (route -n|grep $VPN_IFACE) >/dev/null 2>&1
  return 0
}

check_prerequisites_vpn() {
  if [ -x "`which vtun`" ]; then
    echo "VTun is present"
    return 0
  else
    echo "VTun is missing!"
  fi
  return 2
}

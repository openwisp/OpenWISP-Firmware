#!/bin/sh

FIREWALL_CONFIG_PATH="/etc/config/firewall"
SYSTEM_CONFIG_PATH="/etc/config/system"
DISABLED_MODULES_PATH="/etc/modules.d/disabled"

## Disabling unneedeed services

# firewall
mkdir -p "$DISABLED_MODULES_PATH"
mv /etc/modules.d/*-ipt-conntrack /etc/modules.d/*-ipt-nat $DISABLED_MODULES_PATH 2>/dev/null

if [ -z "`grep mesh $FIREWALL_CONFIG_PATH`"]; then
  rm /etc/rc.d/S*firewall 2>/dev/null
fi

# htpdate
rm /etc/rc.d/S*htpdate 2>/dev/null

# httpd
rm /etc/rc.d/S*httpd 2>/dev/null

# uhttpd
rm /etc/rc.d/S*uhttpd 2>/dev/null

# dnsmasq
rm /etc/rc.d/S*dnsmasq 2>/dev/null

#odhcpd
rm /etc/rc.d/S*odhcpd 2>/dev/null

## Set hostname
sed -i 's/option[ \t]hostname[ \t].*$/option hostname Unconfigured/' $SYSTEM_CONFIG_PATH

## Set timezone
sed -i 's/option[ \t]timezone[ \t].*$/option timezone \"CET-1CEST-2,M3\.5\.0\/02:00:00,M10\.5\.0\/03:00:00\"/' $SYSTEM_CONFIG_PATH

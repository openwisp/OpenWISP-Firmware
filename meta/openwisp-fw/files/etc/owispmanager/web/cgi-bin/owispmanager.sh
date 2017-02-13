#!/bin/sh
#
# This file is part of the OpenWISP Firmware
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

HOME_PATH="/etc/owispmanager/"
. $HOME_PATH/common.sh

. /lib/functions.sh

_WIFI_CHANNELS="1,2,3,4,5,6,7,8,9,10,11,36,40,44,48,52,56,60,64,149,153,157,161,165"
_BG_CHANNELS_DESCR="1 (802.11bg),2 (802.11bg),3 (802.11bg),4 (802.11bg),5 (802.11bg),6 (802.11bg),7 (802.11bg),8 (802.11bg),9 (802.11bg),10 (802.11bg),11 (802.11bg)"
_A_CHANNELS_DESCR="36 (802.11a),40 (802.11a),44 (802.11a),48 (802.11a),52 (802.11a),56 (802.11a),60 (802.11a),64 (802.11a),149 (802.11a),153 (802.11a),157 (802.11a),161 (802.11a),165 (802.11a)"
_APN="web.omnitel.it,ibox.tim.it,internet.wind,tre.it"
_APN_DESCR="vodafone,tim,wind,tre"

load_web_config() {
  uci_load "owispmanager"

  HIDE_SERVER_PAGE="$CONFIG_local_hide_server_page"
  CURRENT_SERVER="$CONFIG_home_address"
  CURRENT_SERVER_PORT="$CONFIG_home_port"

  HIDE_UMTS_PAGE="$CONFIG_local_hide_umts_page"
  HIDE_MESH_PAGE="$CONFIG_local_hide_mesh_page"
  HIDE_ETHERNET_PAGE="$CONFIG_local_hide_ethernet_page"

  if [ "`cat $OPENVPN_TA_FILE`" != "" -a "`cat $OPENVPN_CA_FILE`" != "" -a "`cat $OPENVPN_CLIENT_FILE`" != ""  ]; then
    CURRENT_CERTS='<font style="color:green">Certificates are present</font>'
  else
    CURRENT_CERTS='<font style="color:red">Please load openvpn certifiates file</font>'
  fi

  uci_load "network"

  if [ "$HIDE_ETHERNET_PAGE" -ne "1" ]; then
    CURRENT_ETHERNET_ADDRESSING="$CONFIG_lan_proto"
    CURRENT_ETHERNET_IP="$CONFIG_lan_ipaddr"
    CURRENT_ETHERNET_NMASK="$CONFIG_lan_netmask"
    CURRENT_ETHERNET_GW="$CONFIG_lan_gateway"
    CURRENT_ETHERNET_DNS="$CONFIG_lan_dns"
  fi

  if [ "$HIDE_UMTS_PAGE" -ne "1" ]; then
    CURRENT_UMTS_ENABLE="$CONFIG_local_umts_enable"

    CURRENT_UMTS_APN="$CONFIG_umts_apn"
    CURRENT_UMTS_PIN="$CONFIG_umts_pincode"
    CURRENT_UMTS_DNS="$CONFIG_umts_dns"
  fi

  if [ "$HIDE_MESH_PAGE" -ne "1" ]; then
    CURRENT_MESH_ENABLE="$CONFIG_local_mesh_enable"
    CURRENT_MESH_DEVICE="${CONFIG_local_mesh_device:-wifi1}"

    CURRENT_MESH_ADDRESSING="$CONFIG_mesh_proto"
    CURRENT_MESH_IP="$CONFIG_mesh_ipaddr"
    CURRENT_MESH_NMASK="$CONFIG_mesh_netmask"
    CURRENT_MESH_DNS="$CONFIG_mesh_dns"

    uci_load "wireless"

    eval CURRENT_MESH_CHANNEL="\$CONFIG_""$CURRENT_MESH_DEVICE""_channel"
    CURRENT_MESH_CHANNEL="${CURRENT_MESH_CHANNEL:-64}"
    CURRENT_MESH_ESSID="$CONFIG_mesh0_ssid"
    CURRENT_MESH_WPA_PSK="$CONFIG_mesh0_key"

    uci_load "olsrd"
    CURRENT_OLSR_PSK="`cat /etc/olsrd.d/olsrd_secure_key 2>/dev/null`"
    if [ -n "$CONFIG_mesh_olsrd_hna_gw_netaddr" ]; then
      CURRENT_OLSR_IS_A_GATEWAY="1"
    else
      CURRENT_OLSR_IS_A_GATEWAY="0"
    fi
  fi

  return 0
}


# -------
# Function:     render_select
# Description:  render an html select
# Input:        the html name of the select
#               the html id of the select
#               a string with a comma separated list of all possible values
#               a string with a comma separated list of all possible description
#               the default value (optional)
# Output:       prints an html select
# Returns:      0 on success, 1 on error
# Notes:
render_select() {
  local name="`echo \"$1\" | sed 's/[^a-zA-Z0-9_]/_/g'`"
  local id="`echo \"$2\" | sed 's/[^a-zA-Z0-9_]/_/g'`"
  local values="`echo \"$3\" | sed 's/[^a-zA-Z0-9_,\.\ \-]/_/g'`"
  local descriptions="`echo \"$4\" | sed 's/[^a-zA-Z0-9_,\.\ \-\(\)\/]/_/g'`"
  local default_value="`echo \"$5\" | sed 's/[^a-zA-Z0-9_,\.\ \-]/_/g'`"

  local values_len=`echo $values | tr "," "\n" | wc -l`
  local descriptions_len=`echo $descriptions | tr "," "\n" | wc -l`

  if [ "$values_len" -ne "$descriptions_len" ]; then
    echo ""
    return 1
  fi

  local value
  local description
  local index=1

  echo "<select name=\"$name\" id=\"$id\">"
  while [ "$index" -le "$values_len" ]; do
    value=`echo "$values" | cut -d',' -f$index`
    description=`echo "$descriptions" | cut -d',' -f$index`
    if [ "$value" == "$default_value" ]; then
      echo "<option value=\"$value\" selected=\"selected\">$description</option>"
    else
      echo "<option value=\"$value\">$description</option>"
    fi
    index=`expr $index + 1`
  done
  echo '</select>'

}

PAGE_STATUS="&nbsp;"
render_page() {
  if [ ! -z "$2" ]; then
    if [ ! -z "$3" ]; then
      REDIRECT="<meta http-equiv=\"refresh\" content=\"$3; url=$2\">"
    else
      REDIRECT="<meta http-equiv=\"refresh\" content=\"1; url=$2\">"
    fi
  else
    REDIRECT=""
  fi

  if [ "$HIDE_SERVER_PAGE" -eq "1" ]; then
    SERVER_PAGE=""
  else
    SERVER_PAGE="<li><a href=\"?page=server\">Home server</a></li>"
  fi

  if [ "$HIDE_UMTS_PAGE" -eq "1" ]; then
    UMTS_PAGE=""
  else
    UMTS_PAGE="<li><a href=\"?page=umts_connectivity\">UMTS connectivity</a></li>"
  fi

  if [ "$HIDE_MESH_PAGE" -eq "1" ]; then
    MESH_PAGE=""
  else
    MESH_PAGE="<li><a href=\"?page=mesh_connectivity\">MESH connectivity</a></li>"
  fi

  if [ "$HIDE_ETHERNET_PAGE" -eq "1" ]; then
    ETHERNET_PAGE=""
  else
    ETHERNET_PAGE="<li><a href=\"?page=ethernet_connectivity\">Ethernet connectivity</a></li>"
  fi

  /bin/cat << EOH
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  $REDIRECT
  <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
  <title>$_APP_NAME configuration</title>

  <link href="/stylesheets/fluid960/reset.css" media="screen" rel="stylesheet" type="text/css" />
  <link href="/stylesheets/fluid960/text.css" media="screen" rel="stylesheet" type="text/css" />
  <link href="/stylesheets/fluid960/grid.css" media="screen" rel="stylesheet" type="text/css" />
  <link href="/stylesheets/fluid960/layout.css" media="screen" rel="stylesheet" type="text/css" />
  <link href="/stylesheets/fluid960/nav.css" media="screen" rel="stylesheet" type="text/css" />

  <link href="/stylesheets/custom.css" media="screen" rel="stylesheet" type="text/css" />

  <!--[if IE 6]><link href="/stylesheets/fluid960/ie6.css" media="screen" rel="stylesheet" type="text/css" /><![endif]-->
  <!--[if IE 7]><link href="/stylesheets/fluid960/ie.css" media="screen" rel="stylesheet" type="text/css" /><![endif]-->

  <script src="/javascripts/jquery.js" type="text/javascript"></script>
  <script src="/javascripts/jquery-ui.js" type="text/javascript"></script>
  <script src="/javascripts/fluid16.js" type="text/javascript"></script>
  <script type="text/javascript">

  </script>
</head>
<body>
  <div class="container_12">
    <div class="grid_12">
      <h1 id="branding">$_APP_NAME</h1>
    </div>
    <div class="clear">&nbsp;</div>

    <div class="grid_12">
      <ul class="nav main">
        <li><a href="?page=access_point">Access Point Information</a></li>
        $UMTS_PAGE
        $MESH_PAGE
        $ETHERNET_PAGE
        $SERVER_PAGE
        <li>
          <a href="?page=wait_redirect" onclick="if (confirm('This is a long test, you are warned... Please confirm.')) { window.location=this.href; return true; }; return false;">
              Site test
          </a>
        </li>
        <li><a href="?page=status">Status and Logs</a></li>
        <li><a href="?page=reboot" onclick="if (confirm('You\'re about to reboot this device... Please confirm.')) { window.location=this.href; return true; }; return false;">Reboot device</a></li>
      </ul>
    </div>
    <div class="clear">&nbsp;</div>

    <div class="grid_12" id="_flash_bar" style="color:green;text-align:right">
      <div id="_flash_bar">
        <strong>$PAGE_STATUS</strong>
      </div>
    </div>
    <div class="clear">&nbsp;</div>

    $1

    <div class="clear">&nbsp;</div>
    <div class="grid_12" id="site_info">
      <div class="box" style="text-align:center">
        <p>$_APP_NAME v. $_APP_VERS - Copyright (C) $_APP_YEAR <a href="http://openwisp.org/"> OpenWISP.org</a></p>
      </div>
    </div>
    <div class="clear">&nbsp;</div>
  </div>
</body>
</html>
EOH
}

server_settings_form() {
  local __form=$(cat << EOF
<script type="text/javascript">
function SelectAll(id) {
  document.getElementById(id).focus();
  document.getElementById(id).select();
}
</script>

<form action="?page=server" class="server_settings" id="server_settings" enctype="multipart/form-data" method="post">
  <fieldset id="_server_fieldset">
    <legend id="_server_legend">
      $_APP_NAME Settings
    </legend>
     <p>
      <b><label for="server_address">OpenVpn Remote Server address</label></b>
      <br />
      <input id="server_address" name="server_address" size="30" type="text" value="$CURRENT_SERVER" />
    </p>
    <p>
      <b><label for="server_port">OpenVPN Remote Server port</label></b>
      <br />
      <input id="server_port" name="server_port" size="30" type="text" value="$CURRENT_SERVER_PORT" />
    </p>
    <p>
      <b><label for="certificates">Certificates (status: $CURRENT_CERTS)</label></b>
      <br />
      <input type="file" id="certificates" name="certificates" size="40" />
    </p>
    <p>
      <input id="server_submit" name="commit" type="submit" value="Ok" />
    </p>
  </fieldset>
</form>
EOF
)

  __form=$(echo $__form | sed 's/\"/\\"/g')
  eval "$1=\"$__form\""
  return 0
}

ethernet_connectivity_form() {
  local addressing_mode_dynamic_checked
  local addressing_mode_static_checked
  local _address_display

  if [ "$CURRENT_ETHERNET_ADDRESSING" == "static" ]; then
   addressing_mode_dynamic_checked=""
   addressing_mode_static_checked="checked=\"checked\""
   _address_display=""
  else
   addressing_mode_dynamic_checked="checked=\"checked\""
   addressing_mode_static_checked=""
   _address_display="display:none;"
  fi

  local __form=$(cat << EOF
<form action="?page=ethernet_connectivity" class="addressing_mode" id="addressing_mode" method="post">
  <fieldset id="_address_fieldset">
    <legend id="_address_legend">
      Network parameters
    </legend>
    <table>
      <thead>
        <tr>
          <th colspan="3">Network configuration</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>
            <input $addressing_mode_dynamic_checked id="addressing_mode_dynamic" name="addressing_mode" onclick="document.getElementById('_address').style.display='none'" type="radio" value="dynamic" /> Dynamic
          </td>
          <td>
            <input $addressing_mode_static_checked id="addressing_mode_static" name="addressing_mode" onclick="document.getElementById('_address').style.display='';" type="radio" value="static" /> Static
          </td>
        </tr>
      </tbody>
    </table>
    <div id="_address" style="$_address_display">
      <p>
        <label for="ip">IP address</label><br />
        <input id="ip" name="ip" size="30" type="text" value="$CURRENT_ETHERNET_IP" />
      </p>
      <p>
        <label for="netmask">Netmask</label><br />
        <input id="netmask" name="netmask" size="30" type="text" value="$CURRENT_ETHERNET_NMASK" />
      </p>
      <p>
        <label for="gateway">Gateway</label><br />
        <input id="gateway" name="gateway" size="30" type="text" value="$CURRENT_ETHERNET_GW" />
      </p>
      <p>
        <label for="dns">Dns</label><br />
        <input id="dns" name="dns" size="30" type="text" value="$CURRENT_ETHERNET_DNS" />
      </p>
    </div>
    <table>
      <thead>
        <tr>
          <th colspan="3">NTP server configuration</th>
        </tr>
      </thead>
    </table>
       <p>
        <label for="ntp_server">NTP server address</label><br />
        <input id="ntp_server" name="ntp_server" size="30" type="text" value="$DATE_UPDATE_SERVERS_NTP" />
       </p>
    <p>
      <input id="addressing_submit" name="commit" type="submit" value="Ok" />
    </p>
  </fieldset>
</form>
EOF
)

  __form=$(echo $__form | sed 's/\"/\\"/g')

  eval "$1=\"$__form\""
  return 0
}

umts_connectivity_form() {
  local _umts_display
  local _umts_enable_checked
  _render_apn_select="`render_select "apn" "apn" "$_APN" "$_APN_DESCR" "$CURRENT_UMTS_APN"`"

  if [ "$CURRENT_UMTS_ENABLE" -eq "1" ]; then
    _umts_enable_checked="checked=\"checked\""
    _umts_display=""
  else
    _umts_enable_checked=""
    _umts_display="display:none;"
  fi

  local __form=$(cat << EOF
<script type="text/javascript">
  function _toggle_umts() {
    if (document.getElementById('umts_enable').checked == true) {
      document.getElementById('_umts').style.display='';
    } else {
      document.getElementById('_umts').style.display='none';
    }
  }
</script>

<form action="?page=umts_connectivity" class="umts_settings" id="umts_mode" method="post">
  <fieldset id="_address_fieldset">
    <legend id="_address_legend">
      Network parameters
    </legend>
    <table>
      <thead>
        <tr>
          <th colspan="3">UMTS Network configuration</th>
        </tr>
      </thead>
    </table>
    <p>
       <label for="umts_enable">Enable UMTS connectivity</label><br />
       <input $_umts_enable_checked id="umts_enable" name="umts_enable" type="checkbox" onclick="_toggle_umts()" />
    </p>
    <div id="_umts" style="$_umts_display">
      <p>
        <label for="apn">APN (UMTS Provider)</label><br />
        $_render_apn_select
      </p>
      <p>
        <label for="pin">PIN Code</label><br />
        <input id="pin" name="pin" size="30" type="text" value="$CURRENT_UMTS_PIN" />
      </p>
      <p>
        <label for="dns">DNS</label><br />
        <input id="dns" name="dns" size="30" type="text" value="$CURRENT_UMTS_DNS" />
      </p>
    </div>
    <p>
      <input id="addressing_submit" name="commit" type="submit" value="Ok" />
    </p>
  </fieldset>
</form>
EOF
)

  __form=$(echo $__form | sed 's/\"/\\"/g')

  eval "$1=\"$__form\""
  return 0
}

mesh_connectivity_form() {
  local _mesh_display
  local _mesh_enable_checked
  local mesh_addressing_mode_dynamic_checked
  local mesh_addressing_mode_static_checked

  _render_mesh_channel_select="`render_select "channel" "channel" "$_WIFI_CHANNELS" "$_BG_CHANNELS_DESCR,$_A_CHANNELS_DESCR" "$CURRENT_MESH_CHANNEL"`"

   mesh_addressing_mode_dynamic_checked=""
   mesh_addressing_mode_static_checked="checked=\"checked\""
   _address_display=""

  if [ "$CURRENT_MESH_ENABLE" -eq "1" ]; then
    _mesh_enable_checked="checked=\"checked\""
    _mesh_display=""
  else
    _mesh_enable_checked=""
    _mesh_display="display:none;"
  fi

  if [ "$CURRENT_OLSR_IS_A_GATEWAY" -eq "1" ]; then
    _olsrd_is_a_gateway_checked="checked=\"checked\""
  else
    _olsrd_is_a_gateway_checked=""
  fi

  local __form=$(cat << EOF
<script>
  function _toggle_mesh() {
    if (document.getElementById('mesh_enable').checked == true) {
      document.getElementById('_mesh').style.display='';
    } else {
      document.getElementById('_mesh').style.display='none';
    }
  }
</script>

<form action="?page=mesh_connectivity" class="mesh_settings" id="mesh_mode" method="post">
  <fieldset id="_address_fieldset">
    <legend id="_address_legend">
      Network parameters
    </legend>
    <table>
      <thead>
        <tr>
          <th colspan="3">MESH Network configuration</th>
        </tr>
      </thead>
    </table>
    <p>
       <label for="mesh_enable">Enable MESH connectivity</label><br />
       <input $_mesh_enable_checked id="mesh_enable" name="mesh_enable" type="checkbox" onclick="_toggle_mesh()" />
    </p>
    <div id="_mesh" style="$_mesh_display">
     <table>
      <tbody>
        <tr>
          <td>
            <input $mesh_addressing_mode_dynamic_checked id="mesh_addressing_mode_dynamic" name="mesh_addressing_mode" onclick="document.getElementById('_address').style.display='none'" type="radio" value="dynamic" /> Automatic Configuration
          </td>
          <td>
            <input $mesh_addressing_mode_static_checked id="mesh_addressing_mode_static" name="mesh_addressing_mode" onclick="document.getElementById('_address').style.display='';" type="radio" value="static" checked/> Manual Configuration
          </td>
        </tr>
      </tbody>
    </table>

    <div id="_address" style="$_address_display">
    <p>
      <label for="ip">IP address</label><br />
      <input id="ip" name="ip" size="30" type="text" value="$CURRENT_MESH_IP" />
    </p>
    <p>
      <label for="netmask">Netmask</label><br />
      <input id="netmask" name="netmask" size="30" type="text" value="$CURRENT_MESH_NMASK" />
    </p>
    <p>
      <label for="essid">eSSID</label><br />
      <input id="essid" name="essid" size="30" type="text" value="$CURRENT_MESH_ESSID" />
    </p>
    <p>
      <label for="channel">Channel</label><br />
       $_render_mesh_channel_select
    </p>

    </div>
    <p>
      <label for="dns">Dns</label><br />
      <input id="dns" name="dns" size="30" type="text" value="$CURRENT_MESH_DNS" />
    </p>
    <p>
      <label for="wpa_psk">WPA Key</label><br />
      <input id="wpa_psk" name="wpa_psk" size="30" type="password" value="$CURRENT_MESH_WPA_PSK" />
    </p>
    <p>
      <label for="is_a_gateway">Mesh Gateway?</label><br />
      <input $_olsrd_is_a_gateway_checked id="is_a_gateway" name="is_a_gateway" type="checkbox" />
    </p>
    <p>
      <label for="olsrd_psk">*EXPERIMENTAL* Mesh (OLSR) Key (<b>minimum 16 chars</b>)</label><br />
      <input id="olsrd_psk" name="olsrd_psk" size="30" type="password" value="$CURRENT_OLSR_PSK" />
    </p>
    </div>
    <p>
      <input id="addressing_submit" name="commit" type="submit" value="Ok" />
    </p>
  </fieldset>
</form>
EOF
)

  __form=$(echo $__form | sed 's/\"/\\"/g')

  eval "$1=\"$__form\""
  return 0
}

render_ethernet_connectivity_page() {
  local __connectivity

  ethernet_connectivity_form __connectivity

  local __content=$(cat << EOC
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="connectivity-block">
      $__connectivity
    </div>
  </div>
</div>
EOC
)

  render_page "$__content"
  return 0
}

render_umts_connectivity_page() {
  local __connectivity

  umts_connectivity_form __connectivity

  local __content=$(cat << EOC
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="connectivity-block">
      $__connectivity
    </div
  </div>
</div>
EOC
)

  render_page "$__content"
  return 0
}

render_mesh_connectivity_page() {
  local __connectivity

  mesh_connectivity_form __connectivity

  local __content=$(cat << EOC
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="connectivity-block">
      $__connectivity
    </div
  </div>
</div>
EOC
)

  render_page "$__content"
  return 0
}

render_server_page() {
  local __server

  server_settings_form __server

  local __content=$(cat << EOC
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="server-block">
      $__server
    </div
  </div>
</div>
EOC
)

  render_page "$__content"
  return 0
}

test_default_gw_present() {
  local result="`route -n | grep "^0\.0\.0\.0" | sed 's/[\ ]*/ /g' | cut -d' ' -f 3`"

  eval "$1=\"$result\""
  if [ "$result" != "" ]; then
    return 1
  else
    return 0
  fi
}

test_default_gw_arp() {
  local gw

  test_default_gw_present gw

  ping -c2 $gw >/dev/null 2>&1
  local result=$(cat /proc/net/arp | grep "^$gw" | sed 's/[\ ]*/ /g' | cut -d' ' -f 5)

  eval "$1=\"$result\""
  if [ -z "$result" -o "$result" == "00:00:00:00:00:00" ]; then
    return 0
  else
    return 1
  fi
}

test_dns() {
  local result=$(exec_with_timeout "(nslookup www.google.com | grep \"^Name\" -A1 | grep \"^Address 1\" | cut -d' ' -f3-4) 2>&1" 10)
  local __ret="$?"

  eval "$1=\"$result\""

  if [ "$__ret" -eq "0" -a "$result" != "" ]; then
    return 1
  fi

  return 0
}

test_trace_small() {
  if [ -z "$CONFIG_home_address" ]; then
    eval "$1=\"Address not present! Please check your configuration.\""
    return 0
  fi

  local server="`echo $CONFIG_home_address | cut -d':' -f1`"

  local result="`traceroute -w 2 -q 2 -m 5 -n -f2 $server 100 2>&1`"

  eval "$1=\"$result\""
  if [ "$result" != "" ]; then
    return 1
  else
    return 0
  fi
}

test_trace_big() {
  if [ -z "$CONFIG_home_address" ]; then
    eval "$1=\"Address not present! Please check your configuration.\""
    return 0
  fi

  local server="`echo $CONFIG_home_address | cut -d':' -f1`"

  local result="`traceroute -w 2 -q 2 -m 5 -n -f2 $server 1460  2>&1`"

  eval "$1=\"$result\""
  if [ "$result" != "" ]; then
    return 1
  else
    return 0
  fi
}

test_configuration_retrieve() {
  if [ -z "$CONFIG_home_address" ]; then
    eval "$1=\"Address not present! Please check your configuration.\""
    return 0
  fi

  check_vpn_status
  if [ "$?" -eq "0" ]; then
     eval "$1=\"VPN is up\""
  else
    eval "$1=\"VPN is down\""
    return 0
  fi

  nc -z -w2 $INNER_SERVER $INNER_SERVER_PORT >/dev/null 2>&1
  if [ "$?" -eq "0" ]; then
    eval "$1=\"$INNER_SERVER is responding on port $INNER_SERVER_PORT\""
    return 1
  else
    #Check if configuration tarball exist
    wget -s http://$INNER_SERVER:$INNER_SERVER_PORT/$CONFIGURATION_TARGZ_REMOTE_URL >/dev/null 2>&1
    wget_rc="$?"

    if [ "$wget_rc" -eq "0" ]; then
      eval "$1=\"MAC Correctly configured\""
    else
      eval "$1\"Check mac address configuration\""
      return 2
    fi

    eval "$1=\"Failed\""
    return 0
  fi

 }

render_access_point_page() {
  local __cpu="`cat /proc/cpuinfo`"
  local __upt="`uptime`"

  local __content=$(cat << EOC
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="access_point-block">
      <fieldset id="_status_fieldset">
        <legend id="_status_legend">
          Access Point Information
        </legend>
        <table>
          <tbody>
            <tr>
              <td><em>Ethernet (eth0) MAC address</em></td>
              <td class="code"><big>$ETH0_MAC</big></td>
            </tr>
            <tr>
              <td><em>CPU Info</em></td>
              <td class="code"><pre>$__cpu</pre></td>
            </tr>
            <tr>
              <td><em>Uptime</em></td>
              <td class="code"><pre>$__upt</pre></td>
            </tr>
          </tbody>
        </table>
      </fieldset>
    </div>
  </div>
</div>
EOC
)

  render_page "$__content" "/" "240"
  return 0
}

render_site_test_page() {
  local gw
  local gw_mac
  local dns
  local ntp
  local trace_small
  local trace_big
  local configuration

  local __content

  local __chead=$(cat << EOH
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="server-block">
    <table>
       <thead>
       <tr>
          <th>
             <b>Test</b>
          </th>
          <th>
             <b>Result</b>
          </th>
       </tr>
       </thead>
       <tbody>
EOH
)

  __content="<tr><td><em>Gateway present?</em></td>"
  test_default_gw_present gw
  if [ "$?" -eq "1" ]; then
    __content="$__content <td><font style="color:green">Yes</font> ( $gw )</td></tr>"

    __content="$__content <tr><td><em>Gateway reachable?</em></td>"
    test_default_gw_arp gw_mac
    if [ "$?" -ne "1" ]; then
      if [ "$CURRENT_UMTS_ENABLE" -eq "1" ]; then
        __content="$__content <td><font style="color:#FDD017">Skipped</font> Default gateway for UMTS connectivity not tested!</td></tr>"
      else
        __content="$__content <td><font style="color:red">No</font>  Please check your connectivity!</td></tr>"
      fi
    else
      __content="$__content <td><font style="color:green">Yes</font> ( $gw_mac )</td></tr>"

      __content="$__content <tr><td><em>Is DNS working?</em></td>"
      test_dns dns
      if [ "$?" -eq "1" ]; then
        __content="$__content <td><font style="color:green">Yes</font> ( $dns )</td></tr>"
      else
        __content="$__content <td><font style="color:red">No</font> Please check your connectivity and your DNS settings!</td></tr>"
      fi

      __content="$__content <tr><td><em>Is NTP working?</em></td>"
      update_date
      if [ "$?" -eq "0" ]; then
        __content="$__content <td><font style="color:green">Yes</font> ( `date` )</td></tr>"
      else
        __content="$__content <td><font style="color:red">No</font> If the following time is wrong (`date`), please check your firewall setting or your Internet connectivity!</td></tr>"
      fi

      if [ ! -z "$CONFIG_home_address" ]; then
        __content="$__content <tr><td><em>Can I download my configuration?</em></td>"
        test_configuration_retrieve configuration
        rc="$?"
        if [ "$rc" -eq "1" ]; then
          __content="$__content <td><font style="color:green">Yes</font> ( $configuration )</td></tr>"
        elif [ "$rc" -eq "2" ]; then
          __content="$__content <td><font style="color:red">No</font> Please check your registered mac address </td></tr>"
        else
          __content="$__content <td><font style="color:red">No</font> Please check your server configuration, your firewall setting and your Internet connectivity! ( $configuration ) </td></tr>"
        fi

        __content="$__content <tr><td><em>Traceroute with small packets</em></td>"
        test_trace_small trace_small
        __content="$__content <td><pre>$trace_small</pre></td></tr>"

        __content="$__content <tr><td><em>Traceroute with large packets</em></td>"
        test_trace_big trace_big
        __content="$__content <td><pre>$trace_big</pre></td></tr>"
      else
        __content="$__content <tr><td colspan="2"><em><font style="color:red">Configuration incomplete!</font> Please configure 'server settings'!</em></td>"
      fi
    fi

  else
    __content="$__content <td><font style="color:red">No</font> Check your connectivity settings!</td></tr>"
  fi

  local __cfoot=$(cat << EOF
         </tbody>
      </table>
    </div>
  </div>
</div>
EOF
)

  render_page "$__chead $__content $__cfoot"
  return 0
}

render_site_test_wait_page() {
  local __content=$(cat << EOC
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="connectivity-block">
      <h1>Please wait...
        <img alt="please wait" border="0" class="spin" height="16" width="16" src="/images/spinner.gif" />
      </h1>
      This could be a looong test... Really, <strong>please</strong> <b>DO NOT</b> reload this page...
    </div>
  </div>
</div>
EOC
)

  render_page "$__content" "?page=site_test"
  return 0
}

render_info_page() {
  local __prereq=""

  if [ "$HIDE_SERVER_PAGE" -eq "1" ]; then
    SERVER_INFOS=""
  else
    SERVER_INFOS="<li><b>Server settings.</b> Configure "home" server and the certificates needed to communicate with it.</li>"
  fi

  load_startup_config
  check_prerequisites >/dev/null 2>&1
  if [ "$?" -ne "0" ]; then
    __prereq="<p><font style=\"color:red\">Firmware problem: this system doesn't meet all the requisites needed to run $_APP_NAME...</font><br />Please check the status log.</p>"
  fi

  local __content=$(cat << EOC
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="server-block">
      $__prereq
      <p>
        <h2>$_APP_NAME configuration tools.</h2>
        Please choose an action from the above menu.
        <ul>
          <li>
            <b>Connectivity settings.</b> Configure basic connectivity: IP address, Netmask, Default gateway and DNS server.
          </li>
          <li>
            <b>Site test.</b> Performs some basic connectivity tests.
          </li>
          $SERVER_INFOS
          <li>
            <b>Status log.</b> Show status log.
          </li>
          <li>
            <b>Reboot device.</b> Reboot device (usually not needed!).
          </li>
        </ul>
      </p>
    </div>
  </div>
</div>
EOC
)

  render_page "$__content"
  return 0
}

render_status_page() {
  local __ROUTE_INFO=""
  local __OLSR_INFO=""
  local __UMTS_INFO=""
  local __LAN_INFO=""

  __ROUTE_INFO=$(cat << EOR
<p>
  <label for="routing_table_pre"><b>Routing table</b></label>
  <pre id="routing_table_pre" name="routing_table_pre">
`route -n | sed -n '1,2!p'`
  </pre>
</p>
EOR
)

  __LAN_INFO=$(cat << EOL
<p>
  <label for="lan_table_pre"><b>LAN Connectivity info</b></label>
  <pre id="lan_table_pre" name="lan_table_pre">
Current LAN Address Mode: $CURRENT_ETHERNET_ADDRESSING
Current LAN IP:           $CURRENT_ETHERNET_IP/$CURRENT_ETHERNET_NMASK
Current LAN Gateway:      $CURRENT_ETHERNET_GW
  </pre>
</p>
EOL
)

  if [ "$CURRENT_UMTS_ENABLE" -eq "1" ]; then
    __UMTS_INFO=$(cat << EOU
<p>
  <label for="usb_table_pre"><b>USB info</b></label>
  <pre id="usb_table_pre" name="usb_table_pre">
`lsusb | grep -v "root hub"`
  </pre>
</p>
<p>
  <label for="umts_table_pre"><b>UMTS info</b></label>
    <pre id="umts_table_pre" name="umts_table_pre">
`ifconfig 3g-umts 2>/dev/null`
    </pre>
</p>
EOU
)
  fi

  if [ "$CURRENT_MESH_ENABLE" -eq "1" ]; then
    __OLSR_INFO=$(cat << EOO
<p>
  <label for="olsrd_table_pre"><b>OLSR daemon status</b></label>
  <pre id="olsrd_table_pre" name="olsrd_table_pre">
`echo "/all" | nc 127.0.0.1 $OLSRD_TXTINFO_PORT | sed -n '1,3!p'`
  </pre>
</p>
EOO
)
  fi

  local __content=$(cat << EOC
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="server-block">
      <fieldset id="_status_fieldset">
        <legend id="_status_legend">
          Status and Logs
        </legend>
        <p>
          <input type="button" value="Refresh" onClick = "window.location.reload();" />
        </p>
        <p>
          <label for="status_textarea"><b>Logs</b></label>
          <textarea id="status_textarea" name="status_textarea" rows="20" cols="60" readonly>`cat $STATUS_FILE`</textarea>
          <script type="text/javascript">
            ta = document.getElementById('status_textarea');
            ta.scrollTop = ta.scrollHeight;
          </script>
        </p>
        $__LAN_INFO
        $__ROUTE_INFO
        $__OLSR_INFO
        $__UMTS_INFO
      </fieldset>
    </div>
  </div>
</div>
EOC
)

  render_page "$__content"
  return 0
}

render_reboot_page() {
  local __content=$(cat << EOC
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="reboot-block">
      <h1>Rebooting...
        <img alt="please wait" border="0" class="spin" height="16" width="16" src="/images/spinner.gif" />
      </h1>
      This will take about 2 minutes... If your browser doesn't redirect you to the home page, click <a href="/">here</a>.
    </div>
  </div>
</div>
EOC
)

  render_page "$__content" "/" "240"
  return 0
}

parse_parameters() {
  if [ -n "`echo $CONTENT_TYPE | grep '^multipart'`" ]; then
    if [ "${REQUEST_METHOD}" = "POST" ]; then
      POST_QUERY_STRING=`dd bs=1 count=${CONTENT_LENGTH} 2>/dev/null`
      local _bondary=`echo $CONTENT_TYPE | sed 's/^.*dary=//' | grep "^[-\'\(\)\+\_\,\.\/\:\=\?\s0-9a-zA-Z]*$"`
      local _i=2
      local _block=
      local _block_len=0
      while true; do
        _block=`echo "$POST_QUERY_STRING" | sed -n "$_i,/$_bondary/p"`
        _block_len=`echo "$_block" | wc -l`
        [ "$_block_len" -le "1" ] && break

        local _parameter_name=`echo "$_block" | sed -n '1!d;s/\(.* name=\"\)\([^\"]*\)\".*$/\2/;p'`
        local _parameter_type=`echo "$_block" | grep "^Content-Type" | cut -d' ' -f2 | sed -e 's/[^ -~]//g'`
        local _parameter_value="`echo "$_block" | sed -e 's/[^ -~]//g' | sed '1,/^$/d;$d'`"

        eval "F_${_parameter_name}=\"`echo "${_parameter_value}"`\""

        _i=`expr $_i + $_block_len`
      done
    fi
  else
    if [ "${REQUEST_METHOD}" = "POST" ]; then
      POST_QUERY_STRING=`dd bs=1 count=${CONTENT_LENGTH} 2>/dev/null`
      if [ "${QUERY_STRING}" != "" ]; then
        QUERY_STRING=${POST_QUERY_STRING}"&"${QUERY_STRING}
      else
        QUERY_STRING=${POST_QUERY_STRING}"&"
      fi
    fi
  fi
  _IFS=${IFS}; IFS=\&
  i=0
  for _VAR in ${QUERY_STRING}; do
    eval "`echo F_${_VAR} | cut -d= -f1`=\"`echo ${_VAR} | cut -d= -f2  | sed 's/+/ /g'| sed 's/\%0[dD]//g' | awk '/%/{while(match($0,/\%[0-9a-fA-F][0-9a-fA-F]/)) {$0=substr($0,1,RSTART-1)sprintf("%c",0+("0x"substr($0,RSTART+1,2)))substr($0,RSTART+3);}}{print}' | sed 's/[^a-zA-Z0-9\:\_\.\=\+\/\ \n\r-]//g'`\""
  done
  IFS=${_IFS}
  unset i _IFS _VAR
}

# -----------------------
echo "Content-type: text/html"; echo

parse_parameters

load_web_config
case $F_page in
  access_point)
    render_access_point_page
    ;;
  ethernet_connectivity)
    if [ "${REQUEST_METHOD}" = "POST" ]; then
      if [ "$F_addressing_mode" == "static" ]; then
        uci_set "network" "lan" "proto" "static"
        uci_set "network" "lan" "ipaddr" "`echo \"$F_ip\" | sed 's/[^0-9\.]//g'`"
        uci_set "network" "lan" "netmask" "`echo \"$F_netmask\" | sed 's/[^0-9\.]//g'`"
        uci_set "network" "lan" "gateway" "`echo \"$F_gateway\" | sed 's/[^0-9\.]//g'`"
        uci_set "network" "lan" "dns" "`echo \"$F_dns\" | sed 's/[^0-9\.\s]//g'`"
      else
        uci_remove "network" "lan" "ipaddr"
        uci_remove "network" "lan" "netmask"
        uci_remove "network" "lan" "gateway"
        uci_remove "network" "lan" "dns"
        uci_set "network" "lan" "proto" "dhcp"
      fi
      uci_commit "network"

      uci_set "system" "ntp" "server" "$F_ntp_server"
      uci_commit "system"

      ifdown lan >/dev/null 2>&1
      rm /etc/resolv.conf >/dev/null 2>&1
      ln -s /tmp/resolv.conf.auto /etc/resolv.conf >/dev/null 2>&1
      ifup lan >/dev/null 2>&1

      PAGE_STATUS="Network configuration committed"
    fi
    load_web_config
    render_ethernet_connectivity_page
    ;;
  umts_connectivity)
    if [ "${REQUEST_METHOD}" = "POST" ]; then
      if [ -n "$F_umts_enable" ]; then
        uci_set "owispmanager" "local" "umts_enable" "1"
        uci_commit "owispmanager"

        uci_remove "network" "umts"
        uci_add "network" "interface" "umts"
        uci_set "network" "umts" "proto" "3g"
        uci_set "network" "umts" "service" "hsdpa"
        uci_set "network" "umts" "apn" "`echo \"$F_apn\" | sed 's/[^0-9a-zA-Z\.]//g'`"
        uci_set "network" "umts" "pincode" "`echo \"$F_pin\" | sed 's/[^0-9]//g'`"
        uci_set "network" "umts" "dns" "`echo \"$F_dns\" | sed 's/[^0-9\.\s]//g'`"
        uci_set "network" "umts" "device" "$CONFIG_local_umts_device"
        uci_set "network" "umts" "peerdns" "0"
        uci_set "network" "umts" "defaultroute" "0"
        uci_set "network" "umts" "keepalive" "5"

        uci_commit "network"

        ifdown umts >/dev/null 2>&1
        # UMTS interface handled by /etc/owispmanager/umts.sh script
      else
        uci_set "owispmanager" "local" "umts_enable" "0"
        uci_commit "owispmanager"

        ifdown umts >/dev/null 2>&1

        uci_remove "network" "umts"
        uci_commit "network"
      fi

      rm /etc/resolv.conf >/dev/null 2>&1
      ln -s /tmp/resolv.conf.auto /etc/resolv.conf >/dev/null 2>&1

      /etc/init.d/firewall restart >/dev/null 2>&1

      PAGE_STATUS="UMTS configuration committed"
    fi
    load_web_config
    render_umts_connectivity_page
    ;;
  mesh_connectivity)
    if [ "${REQUEST_METHOD}" = "POST" ]; then
      if [ -n "$F_mesh_enable" ]; then
        uci_set "owispmanager" "local" "mesh_enable" "1"

        ifdown mesh >/dev/null 2>&1
        uci_remove "network" "mesh"
        uci_add "network" "interface" "mesh"
        uci_set "network" "mesh" "type" "bridge"
        uci_set "network" "mesh" "proto" "static"

       wifi down $CURRENT_MESH_DEVICE >/dev/null 2>&1

        uci_remove "wireless" "mesh0"
        uci_add "wireless" "wifi-iface" "mesh0"
        uci_set "wireless" "mesh0" "device" "$CURRENT_MESH_DEVICE"
        uci_set "wireless" "mesh0" "ifname" "mesh0"
        uci_set "wireless" "mesh0" "network" "mesh"
        uci_set "wireless" "mesh0" "mode" "adhoc"

        if [ -n "$F_wpa_psk" ]; then
          uci_set "wireless" "mesh0" "encryption" "psk-aes"
          uci_set "wireless" "mesh0" "key" "`echo \"$F_wpa_psk\" | sed 's/[^0-9a-zA-Z\s\-\_\.]/\-/g'`"
        fi

        if [ "$F_mesh_addressing_mode" == "static" ]; then

          local essid="`echo \"$F_essid\" | sed 's/[^0-9a-zA-Z\s\-\_\.]/\-/g'`"

          if [ -z "$essid" ]; then
            essid="$DEFAULT_MESH_ESSID"
          fi

          uci_set "network" "mesh" "ipaddr" "`echo \"$F_ip\" | sed 's/[^0-9\.]//g'`"
          uci_set "network" "mesh" "netmask" "`echo \"$F_netmask\" | sed 's/[^0-9\.]//g'`"
          uci_set "wireless" "mesh" "ssid" "$essid"
          uci_set "wireless" "$CURRENT_MESH_DEVICE" "channel" "`echo \"$F_channel\" | sed 's/[^0-9]//g'`"
        else
          uci_set "network" "mesh" "ipaddr" "$(printf "10.%d.%d.%d\n" "0x`echo $ETH0_MAC | cut -d':' -f4`" "0x`echo $ETH0_MAC | cut -d':' -f5`" "0x`echo $ETH0_MAC | cut -d':' -f6`")"
          uci_set "network" "mesh" "netmask" "255.0.0.0"
          uci_set "wireless" "mesh0" "ssid" "$DEFAULT_MESH_ESSID"
          uci_set "wireless" "$CURRENT_MESH_DEVICE" "channel" "$DEFAULT_MESH_CHANNEL"
        fi

        uci_set "network" "mesh" "dns" "`echo \"$F_dns\" | sed 's/[^0-9\.\s]//g'`"
        uci_set "wireless" "$CURRENT_MESH_DEVICE" "disabled" "0"

        if [ "$F_channel" -ge "34" ]; then
          uci_set "wireless" "$CURRENT_MESH_DEVICE" "mode" "a"
        else
          uci_set "wireless" "$CURRENT_MESH_DEVICE" "mode" "bg"
        fi

        /etc/init.d/olsrd stop >/dev/null 2>&1

        uci_remove "olsrd" "mesh_olsrd_protocol"
        uci_add "olsrd" "olsrd" "mesh_olsrd_protocol"
        uci_set "olsrd" "mesh_olsrd_protocol" "IpVersion" "4"

        # Olsr secure plugin
        uci_remove "olsrd" "mesh_olsrd_secure"
        rm /etc/olsrd.d/olsrd_secure_key >/dev/null 2>&1
        if [ -n "$F_olsrd_psk" -a "${#F_olsrd_psk}" -ge "16" ]; then
          uci_add "olsrd" "LoadPlugin" "mesh_olsrd_secure"
          uci_set "olsrd" "mesh_olsrd_secure" "library" "olsrd_secure.so.0.5"
          uci_set "olsrd" "mesh_olsrd_secure" "keyfile" "/etc/olsrd.d/olsrd_secure_key"
          echo "$F_olsrd_psk" > /etc/olsrd.d/olsrd_secure_key
        fi

        # Olsr arp refresh plugin
        uci_remove "olsrd" "mesh_olsrd_arp_refresh"
        uci_add "olsrd" "LoadPlugin" "mesh_olsrd_arp_refresh"
        uci_set "olsrd" "mesh_olsrd_arp_refresh" "library" "olsrd_arprefresh.so.0.1"

        # Olsr txtinfo plugin
        uci_remove "olsrd" "mesh_olsrd_txt_info"
        uci_add "olsrd" "LoadPlugin" "mesh_olsrd_txt_info"
        uci_set "olsrd" "mesh_olsrd_txt_info" "library" "olsrd_txtinfo.so.0.1"
        uci_set "olsrd" "mesh_olsrd_txt_info" "port" "$OLSRD_TXTINFO_PORT"
        uci_set "olsrd" "mesh_olsrd_txt_info" "host" "127.0.0.1"

        uci_remove "olsrd" "mesh_olsrd_interface"
        uci_add "olsrd" "Interface" "mesh_olsrd_interface"
        uci_set "olsrd" "mesh_olsrd_interface" "interface" "mesh"

        if [ -n "$F_is_a_gateway" ]; then
          # This node is a gateway, advertise a default route via hna and configure NAT properly
          uci_add "olsrd" "Hna4" "mesh_olsrd_hna_gw"
          uci_set "olsrd" "mesh_olsrd_hna_gw" "netaddr" "0.0.0.0"
          uci_set "olsrd" "mesh_olsrd_hna_gw" "netmask" "0.0.0.0"

          uci_add "firewall" "zone" "owisp_umts"
          uci_set "firewall" "owisp_umts" "name" "umts"
          uci_set "firewall" "owisp_umts" "network" "umts"
          uci_set "firewall" "owisp_umts" "input" "ACCEPT"
          uci_set "firewall" "owisp_umts" "output" "ACCEPT"
          uci_set "firewall" "owisp_umts" "forward" "DROP"
          uci_set "firewall" "owisp_umts" "masq" "1"
          uci_set "firewall" "owisp_umts" "mtu_fix" "1"

          uci_add "firewall" "zone" "owisp_lan"
          uci_set "firewall" "owisp_lan" "name" "lan"
          uci_set "firewall" "owisp_lan" "network" "lan"
          uci_set "firewall" "owisp_lan" "input" "ACCEPT"
          uci_set "firewall" "owisp_lan" "output" "ACCEPT"
          uci_set "firewall" "owisp_lan" "forward" "DROP"
          uci_set "firewall" "owisp_lan" "masq" "1"
          uci_set "firewall" "owisp_lan" "mtu_fix" "1"

          uci_add "firewall" "forwarding" "owisp_mesh2lan"
          uci_set "firewall" "owisp_mesh2lan" "src" "mesh"
          uci_set "firewall" "owisp_mesh2lan" "dest" "lan"

          uci_add "firewall" "forwarding" "owisp_mesh2umts"
          uci_set "firewall" "owisp_mesh2umts" "src" "mesh"
          uci_set "firewall" "owisp_mesh2umts" "dest" "umts"

          uci_commit "firewall"

          /etc/init.d/firewall restart >/dev/null 2>&1
        else
          uci_remove "olsrd" "mesh_olsrd_hna_gw"
          uci_remove "firewall" "owisp_umts"
          uci_remove "firewall" "owisp_lan"
          uci_remove "firewall" "owisp_mesh2lan"
          uci_remove "firewall" "owisp_mesh2umts"

          uci_commit "firewall"

          /etc/init.d/firewall restart >/dev/null 2>&1
        fi

        uci_commit "owispmanager"
        uci_commit "network"
        uci_commit "wireless"
        uci_commit "olsrd"

        ifup mesh >/dev/null 2>&1
        wifi up $CURRENT_MESH_DEVICE >/dev/null 2>&1

        /etc/init.d/olsrd start >/dev/null 2>&1
        /etc/init.d/olsrd enable >/dev/null 2>&1

      else
        uci_set "owispmanager" "local" "mesh_enable" "0"
        uci_commit "owispmanager"

        wifi down $CURRENT_MESH_DEVICE >/dev/null 2>&1

        uci_set "wireless" "$CURRENT_MESH_DEVICE" "disabled" "1"
        uci_remove "wireless" "mesh0"
        uci_commit "wireless"

        /etc/init.d/olsrd stop >/dev/null 2>&1
        /etc/init.d/olsrd disable >/dev/null 2>&1

        uci_remove "olsrd" "mesh_olsrd_protocol"
        uci_remove "olsrd" "mesh_olsrd_secure"
        uci_remove "olsrd" "mesh_olsrd_arp_refresh"
        uci_remove "olsrd" "mesh_olsrd_txt_info"
        uci_remove "olsrd" "mesh_olsrd_interface"
        uci_remove "olsrd" "mesh_olsrd_hna_gw"
        uci_commit "olsrd"

        ifdown mesh >/dev/null 2>&1

        uci_remove "network" "mesh"
        uci_commit "network"

        /etc/init.d/olsrd stop >/dev/null 2>&1
        /etc/init.d/olsrd disable >/dev/null 2>&1

        /etc/init.d/firewall restart >/dev/null 2>&1
      fi

      rm /etc/resolv.conf >/dev/null 2>&1
      ln -s /tmp/resolv.conf.auto /etc/resolv.conf >/dev/null 2>&1

      PAGE_STATUS="MESH configuration committed"
    fi
    load_web_config
    render_mesh_connectivity_page
    ;;
  server)
    if [ "${REQUEST_METHOD}" = "POST" ]; then
      uci_set "owispmanager" "home" "address" "$F_server_address"
      uci_set "owispmanager" "home" "port" "$F_server_port"
      if [ -n "$F_certificates" ]; then
        CA_FILE=`echo "$F_certificates" |
          sed -n '/^-----BEGIN OWISP CA CERT-----$/,${/^-----END OWISP CA CERT-----$/q;p}' | sed '1d'`
        CLIENT_FILE=`echo "$F_certificates" |
          sed -n '/^-----BEGIN OWISP CLIENT CERTKEY-----$/,${/^-----END OWISP CLIENT CERTKEY-----$/q;p}' | sed '1d'`
        TA_FILE=`echo "$F_certificates" |
          sed -n '/^-----BEGIN OWISP TA KEY-----$/,${/^-----END OWISP TA KEY-----$/q;p}' | sed '1d'`

        if [ -n "$CA_FILE" ]; then
          echo "$CA_FILE" > $OPENVPN_CA_FILE
        fi

        if [ -n "$CLIENT_FILE" ]; then
          echo "$CLIENT_FILE" > $OPENVPN_CLIENT_FILE
        fi

        if [ -n "$TA_FILE" ]; then
          echo "$TA_FILE" > $OPENVPN_TA_FILE
        fi

      fi

      if [ "`cat $OPENVPN_TA_FILE`" != "" -a "`cat $OPENVPN_CA_FILE`" != "" -a "`cat $OPENVPN_CLIENT_FILE`" != "" -a "$F_server_address" != "" ]; then
        uci_set "owispmanager" "home" "status" "configured"
        uci_commit "owispmanager"
        PAGE_STATUS="Server configuration committed"
      else
        uci_set "owispmanager" "home" "status" "unconfigured"
        uci_commit "owispmanager"
        PAGE_STATUS="Server configuration committed (incomplete)"
      fi
    fi
    load_web_config
    render_server_page
    ;;
  wait_redirect)
    render_site_test_wait_page
    ;;
  site_test)
    render_site_test_page
    ;;
  status)
    render_status_page
    ;;
  reboot)
    render_reboot_page
    reboot
    ;;
  *)
    render_info_page
    ;;
esac

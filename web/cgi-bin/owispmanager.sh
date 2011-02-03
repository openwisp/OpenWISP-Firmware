#!/bin/sh
#
# Copyright (C) 2010 CASPUR
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

. $PKG_INSTROOT/etc/functions.sh

load_current_configuration() {
  uci_load "owispmanager"
  uci_load "network"

  CURRENT_ADRESSING="$CONFIG_lan_proto"
  CURRENT_IP="$CONFIG_lan_ipaddr"
  CURRENT_NMASK="$CONFIG_lan_netmask"
  CURRENT_GW="$CONFIG_lan_gateway"
  CURRENT_DNS="$CONFIG_lan_dns"
  CURRENT_SERVER="$CONFIG_home_address"
  HIDE_SERVER_PAGE="$CONFIG_local_hide_server_page"

  if [ -f $CLIENT_CERTIFICATE_FILE ] && [ ! -z "`cat $CLIENT_CERTIFICATE_FILE`" ]; then
    CURRENT_CLIENT_CERTS="Present but not showed..."
  else
    CURRENT_CLIENT_CERTS="Please copy-paste your authentication certificates here..."
  fi
  if [ -f $CA_CERTIFICATE_FILE ] && [ ! -z "`cat $CA_CERTIFICATE_FILE`" ]; then
    CURRENT_CA_CERT="Present but not showed..."
  else
    CURRENT_CA_CERT="Please copy-paste your authentication certificates here..."
  fi
  
  return 0
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
    SERVER_PAGE="<li><a href="?page=server">Server settings</a></li>"
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
      <h1 id="branding"><a href="/"><img alt="$_APP_NAME configuration" border="0" class="wums_logo" height="50" src="/images/logo_caspur.png" width="64" /></a>$_APP_NAME firmware</h1>
    </div>
    <div class="clear">&nbsp;</div>

    <div class="grid_12">
      <ul class="nav main">
        <li><a href="?page=connectivity">Connectivity settings</a></li>
        $SERVER_PAGE
        <li>
          <a href="?page=wait_redirect" onclick="if (confirm('This is a long test, you are warned... Please confirm.')) { window.location=this.href; return true; }; return false;">
              Site test
          </a>
        </li>
        <li><a href="?page=status">Status log</a></li>
        <li><a href="?page=reboot" onclick="if (confirm('You\'re about to reboot this device... Please confirm.')) { window.location=this.href; return true; }; return false;">Reboot device</a></li>
      </ul>
    </div>
    <div class="clear">&nbsp;</div>

    <div class="grid_12" id="_flash_bar"style="color:green;text-align:right">
      <div id="_flash_bar">
        <strong>$PAGE_STATUS</strong>
      </div>
    </div>
    <div class="clear">&nbsp;</div>

    $1

    <div class="clear">&nbsp;</div>
    <div class="grid_12" id="site_info">
      <div class="box" style="text-align:center">
        <p>$_APP_NAME v. $_APP_VERS - Copyright (C) 2010 - <a href="http://www.caspur.it/">CASPUR</a></p>
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
  
<form action="?page=server" class="server_settings" id="server_settings" method="post">
  <fieldset id="_server_fieldset">
    <legend id="_server_legend">
      $_APP_NAME Settings
    </legend>
     <p>
      <b><label for="server_address">OpenVpn Remote Server address</label></b>
      <br />
      <input id="server_address" name="server_address" size="30" type="text" value="$CURRENT_SERVER"/>
    </p>
    <p>
      <b><label for="server_port">OpenVPN Remote Server port</label></b>
      <br />
      <input id="server_port" name="server_port" size="30" type="text" value="1194"/>
    </p>
    <p>
      <b><label for="client_certificates">Client certificates</label></b>
      <br />
      <textarea id="client_certificates" name="client_certificates" rows="10" cols="60" onClick="SelectAll('client_certificates');">$CURRENT_CLIENT_CERTS</textarea>
    </p>
    <p>
      <b><label for="ca_certificate">CA Certificate</label></b>
      <br />
      <textarea id="ca_certificate" name="ca_certificate" rows="10" cols="60" onClick="SelectAll('ca_certificate');">$CURRENT_CA_CERT</textarea>
    </p>
    <p>
      <input id="server_submit" name="commit" type="submit" value="Commit and reboot"  onclick="if (confirm('You\'re about to reboot this device... Please confirm.')) { window.location=this.href; return true; }; return false;"</input>

    </p>
  </fieldset>
</form>
EOF
)

  __form=$(echo $__form | sed 's/\"/\\"/g')
  eval "$1=\"$__form\""
  return 0
}

basic_connectivity_form() {
  local addressing_mode_dynamic_checked
  local addressing_mode_static_checked
  local _address_display

  if [ "$CURRENT_ADRESSING" == "static" ]; then
   addressing_mode_dynamic_checked=""
   addressing_mode_static_checked="checked=\"checked\""
   _address_display=""
  else
   addressing_mode_dynamic_checked="checked=\"checked\""
   addressing_mode_static_checked=""
   _address_display="display:none;"
  fi
   
  local __form=$(cat << EOF
<form action="?page=connectivity" class="addressing_mode" id="addressing_mode" method="post">
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
        <input id="ip" name="ip" size="30" type="text" value="$CURRENT_IP" />
      </p>
      <p>
        <label for="netmask">Netmask</label><br />
        <input id="netmask" name="netmask" size="30" type="text" value="$CURRENT_NMASK" />
      </p>
      <p>
        <label for="gateway">Gateway</label><br />
        <input id="gateway" name="gateway" size="30" type="text" value="$CURRENT_GW" />
      </p>
      <p>
        <label for="dns">Dns</label><br />
        <input id="dns" name="dns" size="30" type="text" value="$CURRENT_DNS" />
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

render_connectivity_page() {
  local __connectivity
  
  basic_connectivity_form __connectivity

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
  local result="`cat /proc/net/arp | grep "^$gw" | sed 's/[\ ]*/ /g' | cut -d' ' -f 5`"

  eval "$1=\"$result\""
  if [ "$result" != "" ] && [ "$result" != "00:00:00:00:00:00" ]; then 
    return 1
  else
    return 0
  fi
}

test_dns() {
  local result="`(nslookup www.google.com & sleep 2; kill $!) 2>/dev/null | grep \"^Name\" -A1 | grep \"^Address 1\" | cut -d' ' -f3-4`"

  eval "$1=\"$result\""
  if [ "$result" != "" ]; then 
    return 1
  else
    return 0
  fi
}

test_ntp() {
  local result="`/usr/sbin/ntpdate ntp.ien.it 2>&1 | grep \"adjust time server\"`"

  eval "$1=\"$result\""
  if [ "$result" != "" ]; then 
    return 1
  else
    return 0
  fi
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

  # Fixes vpn up control and server functionality
  eval $VPN_CHECK_CMD
  if [ "$?" -eq "0" ]; then   
     eval "$1=\"VPN is up\""
    return 1
  else
    eval "$1=\"VPN is down\""
    return 0
  fi

  nc -z -w2 $INNER_SERVER $INNER_SERVER_PORT >/dev/null 2>&1
  if [ "$?" -eq "0" ]; then
    eval "$1=\"$INNER_SERVER is responding on port $INNER_SERVER_PORT\""
    return 1
  else
    eval "$1=\"Failed\""
    return 0
  fi
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
    if [ "$?" -eq "1" ]; then
      __content="$__content <td><font style="color:green">Yes</font> ( $gw_mac )</td></tr>"

      __content="$__content <tr><td><em>Is DNS working?</em></td>"
      test_dns dns
      if [ "$?" -eq "1" ]; then
        __content="$__content <td><font style="color:green">Yes</font> ( $dns )</td></tr>"
      else
        __content="$__content <td><font style="color:red">No</font> Please check your connectivity and your DNS settings!</td></tr>"
      fi

      __content="$__content <tr><td><em>Is NTP working?</em></td>"
      test_ntp ntp
      if [ "$?" -eq "1" ]; then
        __content="$__content <td><font style="color:green">Yes</font> ( $ntp )</td></tr>"
      else
        __content="$__content <td><font style="color:red">No</font> If the following time is wrong (`date`), please check your firewall setting or your Internet connectivity!</td></tr>"
      fi

      if [ ! -z "$CONFIG_home_address" ]; then
        __content="$__content <tr><td><em>Can I download my configuration?</em></td>"
        test_configuration_retrieve configuration
        if [ "$?" -eq "1" ]; then
          __content="$__content <td><font style="color:green">Yes</font> ( $configuration )</td></tr>"
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
    else
      __content="$__content <td><font style="color:red">No</font> Check your network connectivity!</td></tr>"
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
  
  checkPrereq >/dev/null 2>&1
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
  local __content=$(cat << EOC
<div class="grid_8 prefix_2 suffix_2">
  <div class="box">
    <div class="block" id="server-block">
      <fieldset id="_status_fieldset">
        <legend id="_status_legend">
          Status log
        </legend>
        <p>
          <input type="button" value="Refresh" onClick = "window.location.reload();" />
        </p>
        <p>
          <textarea id="status_textarea" name="status_textarea" rows="20" cols="60" readonly>`cat $STATUS_FILE`</textarea>
          <script type="text/javascript">
            ta = document.getElementById('status_textarea');
            ta.scrollTop = ta.scrollHeight;
          </script>
        </p>
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
  if [ "${REQUEST_METHOD}" = "POST" ]; then
    POST_QUERY_STRING=`dd bs=1 count=${CONTENT_LENGTH} 2>/dev/null`
    if [ "${QUERY_STRING}" != "" ]; then
      QUERY_STRING=${POST_QUERY_STRING}"&"${QUERY_STRING}
    else
      QUERY_STRING=${POST_QUERY_STRING}"&"
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

load_current_configuration
case $F_page in
  connectivity)
    if [ "${REQUEST_METHOD}" = "POST" ]; then
      if [ "$F_addressing_mode" == "static" ]; then
        uci set network.lan.proto="static"
        uci set network.lan.ipaddr="`echo \"$F_ip\" | sed 's/[^0-9\.]//g'`"
        uci set network.lan.netmask="`echo \"$F_netmask\" | sed 's/[^0-9\.]//g'`"
        uci set network.lan.gateway="`echo \"$F_gateway\" | sed 's/[^0-9\.]//g'`"
        uci set network.lan.dns="`echo \"$F_dns\" | sed 's/[^0-9\.]//g'`"
      else
        uci delete network.lan.ipaddr
        uci delete network.lan.netmask
        uci delete network.lan.gateway
        uci delete network.lan.dns
        uci set network.lan.proto="dhcp"
      fi
      uci commit network
      ifdown lan ; echo "" > /etc/resolv.conf ; ifup lan
      PAGE_STATUS="Network configuration committed"
      load_current_configuration
    fi
    render_connectivity_page
    ;;
  server)
    if [ "${REQUEST_METHOD}" = "POST" ]; then
      uci set owispmanager.home.address="$F_server_address" 2>&1
      uci set openvpn.client_config.remote="$F_server_address $F_server_port"
      if [ ! "$F_client_certificates" == "$CURRENT_CLIENT_CERTS" ]; then
        eval "echo \"$F_client_certificates\" > $CLIENT_CERTIFICATES_FILE"
      fi
      if [ ! "$F_ca_certificate" == "$CURRENT_CA_CERT" ]; then
        eval "echo \"$F_ca_certificate\" > $CA_CERTIFICATE_FILE"
      fi
      if [ "`cat $CA_CERTIFICATE_FILE`" != "" ] && [ "`cat $CLIENT_CERTIFICATES_FILE`" != "" ] && [ "$F_server_address" != "" ]; then
        uci set owispmanager.home.status="configured"
        uci commit owispmanager
        uci commit openvpn
        PAGE_STATUS="Server configuration committed"
      else
        uci set owispmanager.home.status="unconfigured"
        uci commit owispmanager
        uci commit openvpn
        PAGE_STATUS="Server configuration committed (incomplete)"
      fi      
      load_current_configuration
      render_reboot_page
      reboot
    else
      render_server_page
    fi
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

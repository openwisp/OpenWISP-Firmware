## What is it?

Open WISP Firmware is a set of scripts (shell and web cgi) that sits on top of "OpenWrt":http://openwrt.org/.
It provides a daemon for the retrieving the configuration of the following components from a "OpenWISP Manager":https://spider.caspur.it/projects/owm/wiki :

* wifi (currently only for madwifi-ng and ath9k)
* networking
* layer 2 traffic shaping
* openvpn (layer 2, tap)
* cronjobs

Open WISP Firmware also provides a web GUI for:
* configuring basic network parameters
* configuring basic Open WISP server settings
* performing a set of test to spot and resolve most common problems that may prevent Open WISP firmware to work correctly

Open WISP Firmware currently works on OpenWRT Backfire 10.03 

## How to install

Please see the [[InstallationInstructions]]

For Ubiquiti devices flashing (e.g.: nano-pico stations & co.) instructions  see [[FlashingUbiquiti]]
For AboCom WAP2102 and Planex GW-MF54G2 device flashing see [[FlashingAboCom]]
For D-Link devices flashing (e.g.: DIR-825) see [[FlashingDlink]]
For D-Link devices flashing (e.g.: DIR-825) see [[FlashingAlixAndWrap]]

## How to configure a VPN setup server

### setup openVPN server

Sample openVPN configuration (you'll have to generate your own certificates).

```
mode server
tls-server

port 1194
proto tcp

duplicate-cn

dev tun

persist-key
persist-tun

# This must match your configuration
ca /etc/openvpn/auth/ca.pem          
cert /etc/openvpn/auth/server.pem    
key /etc/openvpn/auth/server.key    
dh /etc/openvpn/auth/dh1024.pem     
tls-auth /etc/openvpn/auth/ta.key 0

cipher BF-CBC
comp-lzo

server 10.8.0.0 255.255.0.0

user nobody
group nogroup
keepalive 10 120

status /var/log/openvpn/setup.stats
log /var/log/openvpn/setup.log

verb 1
```

TAP OpenVPN's configuration will be generated through OWM

If you want to upload certificates after compilation you need to create a file formatted as above

<pre><code>
-----BEGIN OWISP CA CERT-----
-----BEGIN CERTIFICATE-----
*PUT YOUR CA CERT HERE*
-----END CERTIFICATE-----
-----END OWISP CA CERT-----

-----BEGIN OWISP CLIENT CERTKEY-----
-----BEGIN CERTIFICATE-----
*PUT YOUR CERTIFICATE HERE*
-----END CERTIFICATE-----
-----BEGIN RSA PRIVATE KEY-----
*PUT YOUR KEY HERE*
-----END RSA PRIVATE KEY-----
-----END OWISP CLIENT CERTKEY-----

-----BEGIN OWISP TA KEY-----
-----BEGIN OpenVPN Static key V1-----
*PUT YOUR TA KEY HERE*
-----END OpenVPN Static key V1-----
-----END OWISP TA KEY-----

</code></pre>

### OpenWISP Manager

Install and configure an OWM instance as usual. Then let it be reached via http through the setup VPN

Sample apache2 configuration snippet
```
   <Location "/owm/get_config">      # Change this to match your configuration
      Order Deny,Allow
      Deny from all
      Allow from 10.8.0.0/16
   </Location>
```

## OWF / OWM FAQ

Q. Where access point configuration are stored? 
A. Configuration are stored in "private" folder in your owm installation as gzipped tarball 

Q. How firmware can recognize configuration changes? 
A. Thanks to an MD5 sum between his tarball and the tarball stored in OWM

Q. How OWF handles different driver for different radio cards?
A. In a loop in owispmanager.sh OWF checks for a brand new card when its recognized by the system so 
  OWF sources a different file for different radio drivers stored in "tools" directory, the function that 
  can handle this feature is "check_firmware" in common.sh called by the check_requisites block in owispmanager 

Q. Which configuration handles OWF itself and wich one will be pushed by OWM?
A. OWF Handles all access point from the boot to the configuration and so on until poweroff, the only configuration that 
  OWM will push into the access point are network related both wired or wireless.

Q. And what about l2vpn_server? 
A. A Layer 2 VPN Server is useful to encapsulate traffic between your device, connected to an access point, and pubblic 
  network, so we can provide an ad-hoc configuration for you all configuration will be stored in the "private/l2vpn_server" folder in your owm installation

Q. How VPN certificated are renewed?
A. Setup VPN will never expire, but l2vpn will expires, when certificate
 will be renewed will be sent to te AP's trough configuration service. 

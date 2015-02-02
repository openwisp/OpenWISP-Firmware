=================
OpenWISP Firmware
=================

**Current Version**: 1.3 alpha

============================ ======================================================================= 
OpenWRT version              Build status 
============================ ======================================================================= 
Trunk                         .. image:: https://ci.publicwifi.it/buildStatus/icon?job=openwisp-edge
14.07 (Barrier Breaker)       .. image:: https://ci.publicwifi.it/buildStatus/icon?job=openwisp-1407 
12.09 (Attitude Adjustment)   .. image:: https://ci.publicwifi.it/buildStatus/icon?job=openwisp-1209 
============================ =======================================================================

Description
-----------

**OpenWISP Firmware** (shortly OWF) is an openwrt package that provides a daemon that periodically retrieves the configuration of the following components from an **OpenWISP Manager** (OWM) server:

- wifi (currently only for madwifi-ng and ath9k)
- networking
- layer 2 traffic shaping
- openvpn (layer 2, tap)
- cronjobs

OpenWISP Firmware also provides a web GUI for:
- configuring basic network parameters
- configuring basic OpenWISP server settings
- performing a set of test to spot and resolve most common problems that may prevent Open WISP firmware to work correctly

See the OWM wiki for more details.

Compiling OWF
-------------

In order to have a fully working OWF you have to compile it yourself.

OWF package supports an *overlay configuration file* that you should provide at compile time, this overlay allows you to include custom configuration. See below for more information on this file.

We strongly suggest to build OpenWRT on a GNU/Linux environment, you can find other pre-requisites here: http://wiki.openwrt.org/doc/howto/build.

If you have a properly configured machine follow this steps inside the OpenWRT root directory::

  cp feeds.conf.default feeds.conf
  echo "src-git eoip https://github.com/agustim/openwrt-linux-eoip.git" >> feeds.conf
  echo "src-git openwisp https://github.com/openwisp/OpenWISP-Firmware.git" >> feeds.conf
  ./scripts/feeds update
  ./scripts/feeds install openwisp-fw
  make menuconfig (choice your arch and include openwisp-fw package and submodule if appropriate)
  export OPENWISP_CONF="http://myserver.com/config_file_example.tar.gz" (see below)
  make

The full version of OWF will support UMTS and mesh capability, but will require better hardware and 
much more space on flash/disk, we recommends an appropriate hardware under this condition.

Our firmware should idealy run on every OpenWRT-complatible devices, but we have tested mainly atheros, x86, ar71xx platforms.

Stable version features:

  * MESH Support  
  * 3G support  
  * wifi support (Both drivers works alone or togheter)  
  * interface failover script  

Overlay Configuration File
--------------------------

The overlay configuration file is a *tar.gz* file that is extracted inside the target rootfs and can potentially overwrite any other config file or add new files inside filesytem.

Here I will provide a structural example of the overlay configuration file that should be provided to be fully compliant with OWM and OWF v1.2::

  etc
  ├── config
  │   └── owispmanager
  ├── openvpn
  │   ├── ca.crt
  │   ├── client.crt
  │   └── ta.key
  └── shadow

This is an exmaple of the contents of ``etc/config/owispmanager``::

  config 'server' 'home'
    option 'address' 'my_OWM_server'
    option 'port' ''
    option 'status' 'configured'
    option 'inner_server' ''
    option 'inner_server_port' ''

  config 'server' 'local'
    option 'hide_server_page' '1'
    option 'setup_wpa_psk' 'owf_safemode_wpakey'
    option 'setup_wifi_dev' ''
    option 'setup_httpd_port' ''
    option 'setup_ssid' ''
    option 'setup_ip' ''
    option 'setup_netmask' ''
    option 'setup_range_ip_start' ''
    option 'setup_range_ip_end' ''
    option 'hide_umts_page' '1'
    option 'hide_mesh_page' '1'
    option 'hide_ethernet_page' '0'
    option 'ethernet_device' 'eth0'
    option 'ethernet_enable' '0'

The ``etc/openvpn/`` directory will contain the RSA certificates to establish a successfull connection with your own **openvpn** server (aka setup vpn) while ``/etc/shadow`` will provide a default password for the root user, here the file content for password "*pass*"::

  root:$1$SwrPpeIH$8MMk3YQiVXl5uQzRgTIvU/:16386:0:99999:7:::
  daemon:*:0:0:99999:7:::
  ftp:*:0:0:99999:7:::
  network:*:0:0:99999:7:::
  nobody:*:0:0:99999:7:::

The overlay configuration file **MUST** be provided using the enviroment variable ``OPENWISP_CONF`` that should be a HTTP URL.

Developing the firmware
-----------------------

If you'd like to work locally on firmare improvement you should use a local OpenWisp Firmware repo clone and a local OpenWrt repo clone. In this configuration you should use the following commands for feed configuration::

  echo "src-link openwisp /path/to/local/git/repo/" >> feeds.conf
  ./scripts/feeds update

Compile Openwrt for multiple architectures
------------------------------------------

Here follows an example script to compile OWF for different arch targets::

  #!/bin/bash

  git clone git://git.openwrt.org/openwrt.git --depth 10
  cd openwrt

  #configure feeds
  cp feeds.conf.default feeds.conf
  echo "src-git openwisp https://github.com/openwisp/openwrt-feed.git" >> feeds.conf
  ./scripts/feeds update
  ./scripts/feeds install openwisp-fw

  export OPENWISP_CONF="http://myserver.com/config_file_example.tar.gz" (see below)

  #config target
  for arch in ar71xx atheros x86; do
    echo "CONFIG_TARGET_$arch=y" > .config;
    echo "CONFIG_PACKAGE_openwisp-fw=y" >> .config
    make defconfig;
    make -j 4;
  done

Copyright
---------

Copyright (C) 2012-2015 OpenWISP.org

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

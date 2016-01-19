.. OpenWISP Firmware documentation master file, created by
   sphinx-quickstart on Thu Mar 26 15:49:28 2015.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

OpenWISP Firmware
=================

OpenWISP Firmware (OWF as short) is a set of scripts (shell and web cgi) that sits on
top of `OpenWrt <http://openwrt.org/>`__. It provides a daemon for
retrieving an OpenWRT configuration of the following components from a
`OpenWISP Manager <https://github.com/openwisp/OpenWISP-Manager/wiki>`__ instance:

- wifi
- networking
- layer 2 traffic shaping
- openvpn (layer 2, tap)
- cronjobs
- custom shell script

OpenWISP Firmware also provides a web GUI for:

- configuring basic network parameters
- configuring basic OpenWISP server settings
- performing a set of test to spot and resolve most common problems that may prevent OWF to work correctly

OpenWISP Firmware currently works on the last OpenWrt release and we are working to keep it up to 
date with OpenWrt edge development.

How to install
--------------

Please see the [[Installation]]

OpenWISP Firmware FAQ
---------------------

Q. Where access point configuration are stored? 

A. Configuration are stored in "private" folder in your owm installation as gzipped tarball

Q. How firmware can recognize configuration changes?

A. Thanks to an MD5 sum between his tarball and the tarball stored in OWM

.. Q. How OWF handles different driver for different radio cards? 

.. A. In a loop in owispmanager.sh OWF checks for a brand new card when its
   recognized by the system so OWF sources a different file for different
   radio drivers stored in "tools" directory, the function that can handle
   this feature is "check\_firmware" in common.sh called by the
   check\_requisites block in owispmanager

Q. Which configuration handles OWF itself and wich one will be pushed by OWM? 

A. OWF Handles all access point from the boot to the configuration
and so on until poweroff, the only configuration that OWM will push into
the access point are network related both wired or wireless.

Q. And what about l2vpn\_server?

A. A Layer 2 VPN Server is useful to encapsulate traffic between your device, 
connected to an access point, and pubblic network, so we can provide an ad-hoc 
configuration for you all configuration will be stored in the "private/l2vpn\_server"
folder in your owm installation.

Q. How VPN certificated are renewed? 

A. Setup VPN will never expire, but l2vpn will expires, when certificate will be renewed
will be sent to te AP's trough configuration service.

Contents:

.. toctree::
   :maxdepth: 2

   /Installation.rst


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

Firmware build and installation
===============================

This page will drive you through the process needed for the build, the installation or the
upgrade of OpenWisp firmware on your APs.

All the firmware are based on the new feed structure that allow us to keep the solution
indipendet from OpenWrt development, modular in packages and with clear deps to external utils.

Build your own OpenWisp Firmware
--------------------------------

In order to have a fully working OpenWisp Firmware you should compile
it by yourself, here a link to the official OpenWrt about the setup of build enviroment wiki on this topic:

- http://wiki.openwrt.org/doc/howto/build

If you have a properly configured machine follow this steps inside the OpenWRT root directory.

1. Append the OWF git repository to OpenWrt feeds list

   ``echo "src-git openwisp https://github.com/openwisp/OpenWISP-Firmware.git" >> feeds.conf``

2. Enable the ``openwisp-fw`` metapackage inside the OpenWrt build system

  ``./scripts/feeds update``

  ``./scripts/feeds install openwisp-fw``

3. Now you should setup e ENV variable and can setup any other Openwrt options included the target machine using  ``make menuconfig``, than you can finally compile the new firmware

  ``export OPENWISP_CONF="http://myserver.com/config_file_example.tar.gz"``
  ``make V=s``


The OPENWISP_CONF var
+++++++++++++++++++++

TODO


Installing the new firmware
---------------------------

TODO

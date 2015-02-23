Functional test for firmware
----------------------------

This directory contains scripts and utility needed to automatically test the main function of OpenWisp-Firmware.

Those test system assume that you are using a jenkins slave that can operate as root,
on pc system with multiple NICs,
the jenkins master should start the build on the appropriate slave. On the slave the enviroment
is used to configure the test.

HARDWARE test component
^^^^^^^^^^^^^^^^^^^^^^^

Below some picture of an actual setup and some information about hardware cabling.

..image:: https://dl.dropboxusercontent.com/u/16893292/fw_panel.jpg
  :scale: 30%

A plastic panel is used to take in place all the tools, APs and cabling.

..image:: https://dl.dropboxusercontent.com/u/16893292/fw_panel_text.jpg
  :scale: 30%


..image:: https://dl.dropboxusercontent.com/u/16893292/fw_server.jpg
  :scale: 30%

The panel is installed next to the jenkins slave to allow simple cabling

..image:: https://dl.dropboxusercontent.com/u/16893292/fw_server_text.jpg
  :scale: 30%


SOFTWARE test component
^^^^^^^^^^^^^^^^^^^^^^^

The test.sh is the entry point for jenkins slave test suite. It is modular and boards/ directory
contains the needed files to customize tests on board based.

Please refer to test.sh for enviroment settings and call arguments.

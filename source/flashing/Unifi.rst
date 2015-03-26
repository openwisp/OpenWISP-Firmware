FlashingUbiquitiUnifi
=====================

.. figure:: http://www.i4wifi.eu/out/pictures/1/ubntuf3p.jpg
   :alt: unifi

   unifi
IP Network Connection
---------------------

-  Configure IP 192.168.1.10/24 on your host on a NIC directly connected
   to the Ubiquiti device
-  You will need a tftp client and (of course) an OpenWRT's Linux image:
-  openwrt-ar71xx-ubnt-nano-m-squashfs-factory.bin

Flashing Via TTL Serial
-----------------------

Open the plastic shell with a little TORX key

.. figure:: https://spider.caspur.it/attachments/92/opened.jpg
   :alt: opened unifi

   opened unifi
Connect your TTL serial to te specified pins

.. figure:: http://openwisp.caspur.it/redmine/attachments/download/93/serial.jpg
   :alt: serial attacched

   serial attacched
Connect via a serial terminal emulator @115200-8N1 as baud rate-parity

Power up your device

.. raw:: html

   <pre>
   U-Boot 1.1.4.2-s481 (Feb  3 2011 - 19:20:26)

   Board: Ubiquiti Networks XM board (rev 1.2 e502)
   DRAM:  64 MB
   Flash:  8 MB
   Net:   eth0, eth1
   Hit any key to stop autoboot:  0
   </pre>

Now it any key (e.g. enter) and launch urescue tftp server

.. raw:: html

   <pre>
   ar7240> urescue
   </pre>

Now you unifi device is ready to get the firmware

.. raw:: html

   <pre>
   Setting default IP 192.168.1.20
   Starting TFTP server...
   Using eth0 (192.168.1.20), address: 0x81000000
   Waiting for connection: |
   </pre>

Now connect to the unifi via the tftp client

.. raw:: html

   <pre>
   $> tftp 192.168.1.20 
   tftp> bin
   tftp> put openwrt-ar71xx-ubnt-nano-m-squashfs-factory.bin
   </pre>

It's ok! let's wait for device to flash and auto-reboot

Now your system is up-and-running and you can connect to device

.. raw:: html

   <pre>
   ~# telnet 192.168.1.1
    === IMPORTANT ============================
     Use 'passwd' to set your login password
     this will disable telnet and enable SSH
    ------------------------------------------

   BusyBox v1.15.3 (2011-05-04 16:47:37 CEST) built-in shell (ash)
   Enter 'help' for a list of built-in commands.

     _______                     ________        __
    |       |.-----.-----.-----.|  |  |  |.----.|  |_
    |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
    |_______||   __|_____|__|__||________||__|  |____|
             |__| W I R E L E S S   F R E E D O M
    Backfire (10.03.1-RC5, r26799) --------------------------
     * 1/3 shot Kahlua    In a shot glass, layer Kahlua
     * 1/3 shot Bailey's  on the bottom, then Bailey's,
     * 1/3 shot Vodka     then Vodka.
    ---------------------------------------------------
   root@OpenWrt:~#
   </pre>


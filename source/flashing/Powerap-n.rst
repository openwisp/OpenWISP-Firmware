FlashingUbiquitiPowerAPN
========================

.. figure:: http://voicecell.net/wp-content/uploads/2011/05/powerAPN.jpg
   :alt: APN

   APN
h2. IP Network Connection

-  Configure IP 192.168.1.10/24 on your host on a NIC directly connected
   to the Ubiquiti device
-  You will need a tftp client and (of course) an OpenWRT's Linux image:
-  openwrt-ar71xx-ubnt-nano-m-squashfs-factory.bin
-  Powercycle the ubiquiti device while pressing the Reset button
-  Wait some seconds until network connection leds start blinking
-  You must connect to the network main port

.. figure:: http://www.aerial.net/shop/imageslarge/UBNT-PowerAPN_Back.jpg
   :alt: Connection

   Connection
Proceed to the following section.

== Flashing via tftp ==

[...]

.. raw:: html

   <pre>
   ~# tftp 192.168.1.20
   tftp> bin 
   tftp> put openwrt-ar71xx-ubnt-nano-m-squashfs-factory.bin
   </pre>

Wait about 1 minute until network connection leds stop blinking.

That's it! :) You can now telnet on your device!

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


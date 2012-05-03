# FlashingUbiquitiRouterstation

## Images

## IP Network Connection

* Configure IP 192.168.1.10/24 on your host on a NIC directly connected to the Ubiquiti device
* You will need a tftp client and (of course) an OpenWRT's Linux image:
 - openwrt-atheros-ubnt2-squashfs.bin
* Powercycle the ubiquiti device while pressing the Reset button
* Wait 2/3 seconds

Proceed to the following section.

== Flashing via tftp ==

[...]

<pre>
~# tftp 192.168.1.20
tftp> bin 
tftp> put openwrt-ar71xx-ubnt-rs-squashfs-factory.bin
</pre>

Wait about 1 minute until signal strength leds stop blinking.

That's it! :) You can now telnet on your device!

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

## Extras!
### GPIOs TBT

TBW
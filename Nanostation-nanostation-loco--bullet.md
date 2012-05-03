# Flashing OpenWRT on Ubiquiti Nanostation/Bullet Devices

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
tftp> put openwrt-atheros-ubnt2-squashfs.bin 
</pre>

Wait about 1 minute until signal strength leds stop blinking.

That's it! :) You can now telnet on your device!

<pre>
~# telnet 192.168.1.1
 === IMPORTANT ============================
  Use 'passwd' to set your login password
  this will disable telnet and enable SSH
 ------------------------------------------

BusyBox v1.11.2 (2009-12-09 19:46:16 CET) built-in shell (ash)
Enter 'help' for a list of built-in commands.

  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 KAMIKAZE (8.09.2, r18529) -------------------------
  * 10 oz Vodka       Shake well with ice and strain
  * 10 oz Triple sec  mixture into 10 shot glasses.
  * 10 oz lime juice  Salute!
 ---------------------------------------------------
root@OpenWrt:~#
</pre>

## Extras!

### GPIOs

### Madwifi Softled

TBW

### Upgrading your system without RedBoot (Not Tested!!!)

It is possible to upgrade your system via the *_mtd_* tool. 

* Listing mtd partion in the system

<pre>
root@OpenWrt:~# cat /proc/mtd
dev:    size   erasesize  name
mtd0: 00030000 00010000 "RedBoot"
mtd1: 000c0000 00010000 "kernel"
mtd2: 002f0000 00010000 "rootfs"
mtd3: 00090000 00010000 "rootfs_data"
mtd4: 0000f000 0000f000 "FIS directory"
mtd5: 00001000 00001000 "RedBoot config"
mtd6: 00010000 00010000 "boardconfig"
</pre>

* Getting the filesystem image

<pre>
root@OpenWrt:/tmp# wget http://yourHost/path/to/openwrt-atheros-root.squashfs
--2009-12-12 01:02:35--  http://yourHost/path/to/openwrt-atheros-root.squashfs
Connecting to 192.168.1.2:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 2752512 (2.6M) [text/plain]
Saving to: `openwrt-atheros-root.squashfs'

100%[=================================================================>] 2,752,512   2.10M/s   in 1.3s    

2009-12-12 01:02:36 (2.10 MB/s) - `openwrt-atheros-root.squashfs' saved [2752512/2752512]
</pre>

* Getting the kernel image

<pre>
root@OpenWrt:/tmp# wget http://yourHost/path/to/openwrt-atheros-vmlinux.lzma 
--2009-12-12 01:04:50--  http://yourHost/path/to/openwrt-atheros-vmlinux.lzma
Connecting to 192.168.1.2:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 786432 (768K) [text/plain]
Saving to: `openwrt-atheros-vmlinux.lzma'

100%[==================================================================>] 786,432     2.16M/s   in 0.3s    

2009-12-12 01:04:51 (2.16 MB/s) - `openwrt-atheros-vmlinux.lzma' saved [786432/786432]
</pre>

* Flashing your NEW kernel image 

<pre>
root@OpenWrt:/tmp# mtd write openwrt-atheros-vmlinux.lzma linux
Unlocking linux ...
Writing from openwrt-atheros-vmlinux.lzma to linux ...     
root@OpenWrt:/tmp# 
</pre>

* Flashing your NEW filesystem image. The -r option reboot the system after the write.

<pre>
root@OpenWrt:/tmp# mtd -r write openwrt-atheros-root.squashfs rootfs 
Unlocking rootfs ...
Writing from openwrt-atheros-root.squashfs to rootfs ...     
Rebooting ...
</pre>

* Here we are ! You can now telnet on your device! ( AGAIN ! :D )

<pre>
~# telnet 192.168.1.1
 === IMPORTANT ============================
  Use 'passwd' to set your login password
  this will disable telnet and enable SSH
 ------------------------------------------

BusyBox v1.11.2 (2009-12-09 19:46:16 CET) built-in shell (ash)
Enter 'help' for a list of built-in commands.

  _______                     ________        __
 |       |.-----.-----.-----.|  |  |  |.----.|  |_
 |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|
 |_______||   __|_____|__|__||________||__|  |____|
          |__| W I R E L E S S   F R E E D O M
 KAMIKAZE (8.09.2, r18529) -------------------------
  * 10 oz Vodka       Shake well with ice and strain
  * 10 oz Triple sec  mixture into 10 shot glasses.
  * 10 oz lime juice  Salute!
 ---------------------------------------------------
root@OpenWrt:~#
</pre>

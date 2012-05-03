# Flashing OpenWRT on Ubiquiti Picostation Devices

![Picostation](http://www.ubnt.com/img/picostation_airoscombo.jpg)

There are three ways to flash this device. 

## Using TFTP

The simplest method that also works with bakfire, similar to the method described here:

https://spider.caspur.it/projects/owf/wiki/FlashingUbiquitiNanostation/

## IP Network Connection

* Configure IP 192.168.1.10/24 on your host on a NIC directly connected to the Ubiquiti device
* You will need a tftp client and (of course) an OpenWRT's Linux image:
 - openwrt-atheros-ubnt2-pico2-squashfs.bin
* Powercycle the ubiquiti device while pressing the Reset button
* Wait 2/3 seconds while signal strenght leds start blinking

<pre>
~# tftp 192.168.1.20
tftp> bin 
tftp> put openwrt-atheros-ubnt2-pico2-squashfs.bin 
</pre>

Wait about 1 minute until signal strength leds stop blinking.

That's it! :) You can now telnet on your device!

<pre>
~# telnet 192.168.1.1 
</pre>


## Serial Connection (Alternative Method)

Skip *_IP Network Connection_* and go to *_Flashing via RedBoot_* section, instruction are identical. So you don't 
have to set your network and telnet to your Ubiquiti, just stop redboot and following our instructions. 

In order to set your terminal here you are some useful instruction for a rs232 ttl serial 3.3v. 

Redboot values 

baud rate = 38400
parity = 1 
Xon/Xoff = 0 
RTS = ON 
DTR = ON

OpenWRT values 

baud rate = 9600
Parity = 1 
Xon/Xoff = 0 
RTS = OFF
DTR = ON

*_NOTE_* You *must* have a TFTP server running on your machine

## Flashing via RedBoot

Yet another method to flash your picostation( it only works with kamikaze )


## IP Network Connection

* Configure IP 192.168.1.10/24 on your host on a NIC directly connected to the device
* You will need a tftp server listening on that IP address and (of course) an OpenWRT's Linux kernel and a root squash filesystem:
 - openwrt-atheros-vmlinux.lzma
 - openwrt-atheros-root.squashfs
* Copy these files to your tftp root directory
* Powercycle the device
* Wait 6/7 seconds, than issue

<pre>
~# telnet 192.168.1.20 9000
</pre>

Proceed to the following section.


*Note*: If you're using a Mac, create a text file named .telnetrc in your home directory with the following content:
<pre>
192.168.1.20
   mode line
</pre>

* Press <ctrl>+C to stop redboot bootstrap

<pre>
~# telnet 192.168.1.20 9000
Trying 192.168.1.20...
Connected to 192.168.1.20.
Escape character is '^]'.
== Executing boot script in 2.510 seconds - enter ^C to abort
^C
</pre>

* You must hit <ctrl>+C as fast as you can
* Hey, you're in ! :)

<pre>
RedBoot>
</pre>

* You should have the following partitions

<pre>
RedBoot> fis list
Name              FLASH addr  Mem addr    Length      Entry point
RedBoot           0xA8000000  0xA8000000  0x00030000  0x00000000
linux             0xA8030000  0x80041000  0x000B0000  0x80041000
rootfs            0xA80E0000  0x80040C00  0x002A0000  0x80040C00
FIS directory     0xA87E0000  0xA87E0000  0x0000F000  0x00000000
RedBoot config    0xA87EF000  0xA87EF000  0x00001000  0x00000000
RedBoot> 
</pre>

* Set IP address and tftp server

<pre>
ip_address -l 192.168.1.20/24 -h 192.168.1.10
</pre>

* Initialize (format) OS flash

<pre>
RedBoot> fis init
About to initialize [format] FLASH image system - continue (y/n)? y
*** Initialize FLASH Image System
Board data is already relocated.
... Erase from 0xa87e0000-0xa87f0000: .
... Program from 0x80ff0000-0x81000000 at 0xa87e0000: .
</pre>

* Load OpenWRT kernel from a tftp server

<pre>
RedBoot> load -r -b %{FREEMEMLO} openwrt-atheros-vmlinux.lzma
Using default protocol (TFTP)
Raw file loaded 0x80040c00-0x80100bff, assumed entry at 0x80040c00
RedBoot>
</pre>

* flash it!

<pre>
RedBoot> fis create -e 0x80041000 -r 0x80041000 linux
... Erase from 0xa8030000-0xa80f0000: ............
... Program from 0x80040c00-0x80100c00 at 0xa8030000: ............
... Erase from 0xa87e0000-0xa87f0000: .
... Program from 0x80ff0000-0x81000000 at 0xa87e0000: .
RedBoot>
</pre>

* 0x80041000 is the mem address of the linux partition in your pico station
* Check free space

<pre>
fis free
</pre>

* Subtract the two values obtained  ... in my case the result is

<pre>
RedBoot> fis free
  0xA80F0000 .. 0xA87E0000
RedBoot>
</pre>

Hence I'll use 0x6F0000 as @fis create@ length.

*_Note_* (TBVerified): with this value you are using all the free space. It would be more convenient (time saving) to use the ''real'' root filesystem size...

For instance, my rootfs size is:

<pre>
~# pushd /tftp/ ; ls -la ; popd
totale 3456
drwxrwxrwx  4 davide admin     136 10 Dic 00:03 .
drwxrwxr-t 34 root   admin    1224  9 Dic 21:30 ..
-rw-r--r--  1 davide admin 2752512 10 Dic 00:03 openwrt-atheros-root.squashfs <----- !!
-rw-r--r--  1 davide admin  786432 10 Dic 00:03 openwrt-atheros-vmlinux.lzma
</pre>

Thus I can use 0x2A0000 (< 0x6F0000) as size parameter in the following command.

* Load the root fileystem from the tftp server 

<pre>
RedBoot> load -r -b %{FREEMEMLO} openwrt-atheros-root.squashfs
Using default protocol (TFTP)
Raw file loaded 0x80040c00-0x802e0bff, assumed entry at 0x80040c00
RedBoot>
</pre>

* Now you can flash it

<pre>
RedBot> fis create -l 0x6F0000 rootfs
... Erase from 0xa80f0000-0xa87e0000: .......................................................................
... Program from 0x80040c00-0x802e0c00 at 0xa80f0000: ..........................................
... Erase from 0xa87e0000-0xa87f0000: .
... Program from 0x80ff0000-0x81000000 at 0xa87e0000: .
RedBoot> 
</pre>

* Reboot

<pre>
RedBoot> reset
</pre>

That's it! :) You can now telnet on your device!

<pre>
~# telnet 192.168.1.1

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

Using Wi-Fi led for Wi-Fi activity

<pre>
sysctl -w dev.wifi0.ledpin=<GPIO (OUT) pin>
sysctl -w dev.wifi0.softled=2
</pre>

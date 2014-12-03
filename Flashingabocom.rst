Flashing OpenWRT on Ubiquiti AboCom WAP2102 and Planex GW-MF54G2 Devices
========================================================================

.. figure:: https://spider.caspur.it/attachments/39/owf-abocom.jpg
   :alt: owf\_abocom

   owf\_abocom
ap51-flash
----------

The device is supported by ap51-flash, a tool for flashing (nearly) all
ap51/ap61 based routers.
https://dev.open-mesh.com/projects/dev/wiki/Ap51-supported-devices

.. raw:: html

   <pre>
     svn checkout http://dev.open-mesh.com/downloads/svn/ap51-flash/trunk/ ap51flash
     cd ap51flash
     make
     sudo ./ap51flash 
   </pre>

Serial Connection
-----------------

Skip **IP Network Connection** and go to **Flashing via RedBoot**
section, instruction are identical. So you don't have to set your
network and telnet to your Ubiquiti, just stop redboot and following our
instructions.

In order to set your terminal here you are some useful instruction for a
rs232 ttl serial 3.3v.

Redboot values

baud rate = 38400 parity = 1 Xon/Xoff = 0 RTS = ON DTR = ON

OpenWRT values

baud rate = 9600 Parity = 1 Xon/Xoff = 0 RTS = OFF DTR = ON

Note: You *must* have a tftp server running on your machine.

IP Network Connection
---------------------

-  Configure IP 192.168.1.10/24 on your host on a NIC directly connected
   to the device
-  You will need a tftp server listening on that IP address and (of
   course) an OpenWRT's Linux kernel and a root squash filesystem:
-  openwrt-atheros-vmlinux.lzma
-  openwrt-atheros-root.squashfs
-  Copy these files to your tftp root directory
-  Powercycle the device
-  Wait 6/7 seconds, than issue

.. raw:: html

   <pre>
   ~# telnet 192.168.1.20 9000
   </pre>

Proceed to the following section.

*Note*: If you're using a Mac, create a text file named .telnetrc in
your home directory with the following content:

.. raw:: html

   <pre>
   192.168.1.20
      mode line
   </pre>

Flashing via RedBoot
--------------------

-  Press +C to stop redboot bootstrap

.. raw:: html

   <pre>
   ~# telnet 192.168.1.20 9000
   Trying 192.168.1.20...
   Connected to 192.168.1.20.
   Escape character is '^]'.
   == Executing boot script in 2.510 seconds - enter ^C to abort
   ^C
   </pre>

-  You must hit +C as fast as you can
-  Hey, you're in ! :)

.. raw:: html

   <pre>
   RedBoot>
   </pre>

-  You should have the following partitions

.. raw:: html

   <pre>
   RedBoot> fis list
   Name              FLASH addr  Mem addr    Length      Entry point
   RedBoot           0xBFC00000  0xBFC00000  0x00030000  0x00000000
   linux             0xBFC30000  0x80041000  0x000B0000  0x80041000
   rootfs            0xBFCE0000  0x80040000  0x002A0000  0x80040000
   FIS directory     0xBFFE0000  0xBFFE0000  0x0000F000  0x00000000
   RedBoot config    0xBFFEF000  0xBFFEF000  0x00001000  0x00000000
   </pre>

-  **NOTE** your init script should be like this otherwise change it or
   the procedure below will not work properly

.. raw:: html

   <pre>
   RedBoot> fconfig
   Run script at boot: true
   Boot script: 
   .. fis load -l linux
   .. go
   </pre>

-  Set IP address and tftp server

.. raw:: html

   <pre>
   ip_address -l 192.168.1.20/24 -h 192.168.1.10
   </pre>

-  Initialize (format) OS flash

.. raw:: html

   <pre>
   RedBoot> fis init
   </pre>

-  Load OpenWRT kernel from a tftp server

.. raw:: html

   <pre>
   RedBoot> load -r -b %{FREEMEMLO} openwrt-atheros-vmlinux.lzma
   Using default protocol (TFTP)
   Raw file loaded 0x80040000-0x800fffff, assumed entry at 0x80040000
   RedBoot>
   </pre>

-  flash it!

.. raw:: html

   <pre>
   RedBoot> fis create -e 0x80041000 -r 0x80041000 linux
   ... Erase from 0xbfc30000-0xbfd00000: .............
   ... Program from 0x80040000-0x80110000 at 0xbfc30000: .............
   ... Erase from 0xbffe0000-0xbfff0000: .
   ... Program from 0x80ff0000-0x81000000 at 0xbffe0000: .
   RedBoot>
   </pre>

-  Check free space

.. raw:: html

   <pre>
   fis free
   </pre>

-  Subtract the two values obtained ... in my case the result is

.. raw:: html

   <pre>
   RedBoot> fis free
     0xBFD00000 .. 0xBFFE0000
   RedBoot>
   </pre>

Hence I'll use 0x2E0000 as *fis create* length.

**Note** (TBVerified): with this value you are using all the free space.
It would be more convenient (time saving) to use the ''real'' root
filesystem size...

For instance, my rootfs size is:

.. raw:: html

   <pre>
   ~# pushd /tftp/ ; ls -la ; popd
   totale 3456
   drwxrwxrwx  4 davide admin     136 10 Dic 00:03 .
   drwxrwxr-t 34 root   admin    1224  9 Dic 21:30 ..
   -rw-r--r--  1 davide admin 2752512 10 Dic 00:03 openwrt-atheros-root.squashfs <----- !!
   -rw-r--r--  1 davide admin  786432 10 Dic 00:03 openwrt-atheros-vmlinux.lzma
   </pre>

Thus I can use 0x2A0000 (< 0x2F0000) as size parameter in the following
command.

-  Load the root fileystem from the tftp server

.. raw:: html

   <pre>
   RedBoot> load -r -b %{FREEMEMLO} openwrt-atheros-root.squashfs
   Using default protocol (TFTP)
   Raw file loaded 0x80040000-0x802dffff, assumed entry at 0x80040000
   RedBoot>
   </pre>

-  C'mon and flash it

.. raw:: html

   <pre>
   RedBoot> fis create -l 0x2E0000 rootfs
   ... Erase from 0xbfcf0000-0xbffe0000: ...............................................
   ... Program from 0x80040000-0x802e0000 at 0xbfcf0000: ..........................................
   ... Erase from 0xbffe0000-0xbfff0000: .
   ... Program from 0x80ff0000-0x81000000 at 0xbffe0000: .
   RedBoot>  
   </pre>

-  Reboot

.. raw:: html

   <pre>
   RedBoot> reset
   </pre>

That's it! :) You can now telnet on your device!

.. raw:: html

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

##. Extras!

###. GPIOs

TBW

Madwifi Softled
~~~~~~~~~~~~~~~

Using Wi-Fi led for Wi-Fi activity

.. raw:: html

   <pre>
   sysctl -w dev.wifi0.ledpin=4
   sysctl -w dev.wifi0.softled=1
   </pre>


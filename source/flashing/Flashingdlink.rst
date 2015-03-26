FlashingDlinkDir825
===================

.. figure:: http://www.channelinsider.com/images/stories/d-link-dir-825-router.jpg
   :alt: DIR-825

   DIR-825
IP Network Connection
---------------------

-  Configure IP 192.168.0.100/24 on your host on a NIC directly
   connected to the DIR-825
-  You will need just a browser

Proceed to the following section.

== Flashing via Firmware update page ==
---------------------------------------

-  Open up favorite internet browser and go to the http://192.168.0.1/,
   use "admin" as the username, and "" as the password (leave the field
   blank).
-  Proceed into the firmware update page, click "Browse" and select the
   openwrt-ar71xx-generic-dir-825-b1-backup-loader.bin freshly compiled
   openwrt image.
-  Click "Update" and let the router reflash itself
-  Change your network configuration into 192.168.1.\*/24 and telnet
   your device

*PLEASE USE BACKFIRE, KAMIKAZE MAY NOT WORK*

== Flashing via Firmware recovery mode ==
-----------------------------------------

-  Powercycle device holding the reset button until the power LED starts
   blinking Orange
-  Set a static IP on your PC to 192.168.0.100 / 255.255.255.0
-  Force your NIC to work at 10/100MB full duplex (if you have a gigabit
   one)
-  Go to http://192.168.0.1 using your MS Internet Explorer (IE7 or a
   browser that can emulate it)
-  Click "Update" and let the router reflash itself
-  Change your network configuration into 192.168.1.\*/24 and telnet
   your device

We have tested the procedure also using a virtual machine

== Flashing via MTD *TBT* ==
----------------------------

*DIRECTLY FROM OPENWRT WIKI*

-  Login as root via SSH
-  Make sure you have enough free memory on /tmp for the new firmware
-  SCP or wget new firmware to /tmp. It is safe to use any of the
   openwrt-ar71xx-generic-dir-825-b1-squashfs-\*.bin images to flash the
   router. Probably the best choice would be
   openwrt-ar71xx-generic-dir-825-b1-squashfs-sysupgrade.bin as the
   smallest one (it does not include any additional data required by
   firmware update web-pages to accept the image).
-  Flash the firmware using one of the following methods: # sysupgrade
   /tmp/openwrt-ar71xx-generic-dir-825-b1-squashfs-sysupgrade.bin # mtd
   -w /tmp/openwrt-ar71xx-dir-825-b1-squashfs-backup-loader.bin firmware
   *(DANGER: do not use this method unless you are absolutelly required
   to do so. Any write to the jffs2 partition may corrupt newly flashed
   firmware and you will be forced to use firmware recovery mode to
   unbrick the router!)*

== Telnet to your device ==
---------------------------

Now you can telnet to your device but your NIC need to be reconfigured
with an IP like 192.168.1.\*/24

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

== Automatic flashing script ==
-------------------------------

In order to flash DIR-825 without using IE7 here it is a flashing script
written in ruby

::

    # Copyright (C) 2011 CASPUR (wifi@caspur.it)
    #
    # This program is free software: you can redistribute it and/or modify
    # it under the terms of the GNU General Public License as published by
    # the Free Software Foundation, either version 3 of the License, or
    # (at your option) any later version.
    #
    # This program is distributed in the hope that it will be useful,
    # but WITHOUT ANY WARRANTY; without even the implied warranty of
    # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    # GNU General Public License for more details.
    #
    # You should have received a copy of the GNU General Public License
    # along with this program.  If not, see <http://www.gnu.org/licenses/>.


    # This script will help you flashing D-LINK DIR-825 devices 'cause  they can be flashed only with IE7
    # Your ETH Address must be 192.168.0.100/24

    require 'socket'

    HOST = "192.168.0.1"
    PATH = "/cgi/index"

    if ARGV.count == 0
      puts "Usage #{$0} <filename>"
      exit 1
    else
      filename = ARGV[0]
      puts "[#{Time.now}] Using firmware file '#{filename}'"
    end

    predata = <<-eopd
    -----------------------------7db12928202b8
    Content-Disposition: form-data; name="files"; filename="#{filename}"
    Content-Type: application/octet-stream

    eopd

    firmware = File.open(filename, "rb") { |io| io.read }

    postdata="\x0d\x0a-----------------------------7db12928202b8--\x0d\x0a"

    # Each line must end with cr/lf characters, and we have to know how many
    # data the script will send to the dir-825 this is why we concatenate it before
    # creating the header

    buffer = predata.gsub(/\n/,"\x0d\x0a") + firmware + postdata

    header = <<-eoh
    POST #{PATH} HTTP/1.1
    Accept: image/jpeg, application/x-ms-application, image/gif, application/xaml+xml, image/pjpeg, application/x-ms-xbap, */*
    Referer: http://#{HOST}/
    Accept-Language: it-IT
    User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0)
    Content-Type: multipart/form-data; boundary=---------------------------7db12928202b8
    Accept-Encoding: gzip, deflate
    Host: #{HOST}
    Content-Length: #{buffer.length}
    Connection: Keep-Alive
    Cache-Control: no-cache

    eoh

    begin
      puts "[#{Time.now}] Firmware file laded (#{firmware.length} bytes)"
      http = TCPSocket.new(HOST, 'www')

      puts "[#{Time.now}] Sending firmware to the device...  "

      http.print header.gsub(/\n/,"\x0d\x0a") + buffer
      resp = http.recv(1012)

      # Let's check if it's all ok
      if resp.match /Don't turn the device off before the Upgrade jobs done/
         puts "\n[#{Time.now}] Finished. Please wait for the device to reboot."
      else
         puts "\n[#{Time.now}] Problem sending firmware to the device. Response from device follows."
         puts resp
       end

      http.close
      rescue Exception => e
      puts "[#{Time.now}] Problem flashing device. Error: '#{e}'"
    end

    exit 0


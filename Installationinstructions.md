## Download our atheros builds

you can find our build on the bottom of this page
Now you can install *owf using opkg* but traffic shaping wont work if your system doesn't have ebtables running. 

## Build your own OpenWisp Firmware

In order to have a fully working OpenWisp Firmware you have to compile OpenWRT by yourself, and you have to get Backfire
_.Our deploy scripts are developed under GNU/Linux so, in order to compile our firmware iWe higly recomend to build OpenWRT 
on a GNU/Linux environment with gcc > 4 you can find other pre-requisites here http://wiki.openwrt.org/doc/howto/build._

If you have a properly configured machine follow this steps: 

You can wget OpenWRT checking out the lastest backfire release through Subversion

<pre>
  ~# svn co svn://svn.openwrt.org/openwrt/branches/backfire backfire
</pre>

Our deploy script will set up a minimal OpenWRT System that can run with our customization, 
you can customize your OpenWRT installation with opkg system, if you want to deploy different firmware 
configuration feel free to modify our files.  

## Prerequisites

In order to install the Open WISP firmware on OpenWRT you will need the following packages:

* GNU tar (You can also enable old gnu compatibility on busybox)
* wget (It works also with the busybox one!)
* htpdate _and/or_ ntpdate
* wireless-tools _and_ kmod-madwifi or ath9k
* uhttpd (a tiny single-threaded http daemon)
* openvpn (_and_ kmod-tun)
* tc (_and_ kmod-sched)
* ebtables (_and_ kmod-ebtables)
* GNU netcat (*not* the Busybox one!)
* hostapd

Our kernel configuration files contains all of this packages due to simplify your work. 
The full version of OWF will require UMTS and OLSRD support, but will require better hardware and 
much more space on disk, we recommends an Alix or a RouterBoard or something similar.
Our firmware should run on every OpenWRT-complatible devices, but we have tested atheros, x86, ar71xx, rb532
 and D-Link DIR-825 platforms

*We higly recomend to compile to use our script to configure your AP you can compile openwrt by yourself but at your risk  *

## Downloading

You can download our build in the bottom of this page or you can check out our stable release.

<pre>
svn co https://spider.caspur.it/svn/owf/tags/owf_1.0/ owf
</pre>

If you want a fully featured firmware you can use our trunk...it is stable as the "stable" release 

<pre>
svn co https://spider.caspur.it/svn/owf/trunk owf
</pre>

## Stable version features:

* MESH Support 
* 3G support
* Added a lot of kernel configuration file for a lot of platform 
* ATH9k and/or madwifi support (Both drivers works alone or togheter) 
* Simplified and almost fully automatic deploy script with a lot of features
* interface failover script
* Full tested backfire support

## Installing
 
*Let's deploy OWF*

In order to deploy our OpenWispFirmware you need to use the deployment script shipped with our release. 
You only need deploy-firmware.sh to fully customize your OWF installation, with this simple script you can set a couple of things:

* A root password ( instead the default one "ciaociao" ) (-P)
* The IP address and port of the internal http server from which ap's can downloads their configurations (-i -p)
* The Address of the OWM server (-v)
* The OpenVPN port of the OWM server (-V)
* The WPA-PSK key (instead of the default one "owm-Ohz6ohngei" ) it must be 14 character long  (-w)
* The configuration ESSID (instead of "owispmager-setup") (-e)
* The Architecture (-a)
* Activate Mesh Networking capabilities with -m option
* Activate UMTS Netwokring capabilities with -u option 
* Autogenerate password and wpa key with -G

For instance:
All you need to know is the OpenWRT source directory  and the default architecture, the most tested architecture is atheros our favourite platform are Ubiquity and Abocoms 

So jump in the openwispfirmware directory then launch 
<pre>
./deploy-firmware -s ~/sources/backfire -a atheros
</pre>
for instance the same command with more options
<pre>
./deploy-firmware.sh -a atheros -s ~/sources/backfire -v my.vpn.server -w 14-char-wpakey  -P root-password
</pre>

Now you can use our images to flash your devices. 

## UMTS and MESH Support

Our MESH-3G firmware support, as the name suggests,  also support UMTS connection provided by USB modems, all you need to know to get this feature working 
is your APN and your SIM pincode. 
We can support all USB modems that usb-modeswitch can support but we have made tests with Huawei K4505 and Huawei E1692. You're encouraged to send us your 
feedback about different model.

Another new feature is MESH support and we use OLSRD. 

UMTS MESH and ETHERNET connectivity are in failover, This means a better network reliability can be provided. 
 
## Known Issues

In order to get OLSRD working with WPA NONE protocol we have to patch wpa_supplicant 
OLSRD secure plugin have a lot of endianess problems so it must be used with homogeneus Access Points 
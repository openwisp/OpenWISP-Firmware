#
# Copyright (C) 2014 OpenWisp.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=openwisp-fw
PKG_VERSION:=$(shell git describe --tags)

include $(INCLUDE_DIR)/package.mk

define Package/openwisp-fw
	SECTION:=openwisp
	CATEGORY:=OpenWisp
	TITLE:=OpenWisp Firmware config files
	MAINTAINER:=info@openwisp.org
	#this is a meta package suitable for any archs...
	PKG_ARCH:=all
	DEPENDS:=+uhttpd +hostapd +openvpn-polarssl +dnsmasq +ntpdate +netcat +tc
	DEPENDS+=+ebtables +tcpdump +ip +kmod-sched +kmod-gre +linux-eoip +kmod-ath5k
endef

define Package/openwisp-fw-mesh
	$(call Package/openwisp-fw)
	TITLE:=OpenWisp Firmware MESH extension
	DEPENDS:=+openwisp-fw +batctl
endef

define Package/openwisp-fw-umts
	$(call Package/openwisp-fw)
	TITLE:=OpenWisp Firmware UMTS extension
	DEPENDS:=+openwisp-fw +comgt +kmod-usb2 +usbutils
endef


define Package/openwisp-fw/description
	 meta package for OpenWisp firmware

	 This package can use extra file from targz fetched through wget using the $OPENWISP_CONF variable
endef

define Package/openwisp-fw-mesh/description
	 meta package for OpenWisp firmware - MESH
endef

define Package/openwisp-fw-umts/description
	 meta package for OpenWisp firmware - UMTS
endef

define Package/openwisp-fw/config
  source "$(SOURCE)/Config.in"
endef

define Build/Compile
endef

define Package/openwisp-fw/install
	$(INSTALL_DIR) $(1)/
	$(CP) -r ./files/* $(1)/
	if [ $(OPENWISP_CONF) ]; then \
		wget $(OPENWISP_CONF) -qO - | tar xvz -C $(1)/; \
	fi
	git describe --tags > $(1)/etc/openwisp_version
endef

define Package/openwisp-fw-mesh/install
	$(INSTALL_DIR) $(1)/
	#$(CP) -r ./files-mesh/* $(1)/
	#TODO fix owispconfig https://github.com/openwisp/OpenWISP-Firmware/blob/umts-improvement/deploy-firmware.sh#L469
endef

define Package/openwisp-fw-umts/install
	$(INSTALL_DIR) $(1)/
	$(CP) -r ./files-umts/* $(1)/
	cat << EOF >> $(1)/etc/config/network
config 'interface' 'umts'
  option 'ifname' 'ppp0'
  option 'device' '/dev/ttyUSB2'
  option 'service' 'umts'
  option 'proto' '3g'
  option 'defaultroute' '0'
  option 'pppd_options' 'noipdefault'
  option 'dns' '8.8.8.8'
  option 'peerdns' '0'
EOF

  sed -i '/#SED_HOOK/a  option hide_umts_page 0' $(1)/etc/config/owispmanager
  sed -i '/#SED_HOOK/a  option umts_device "/dev/ttyUSB2"' $(1)/etc/config/owispmanager
  sed -i '/#SED_HOOK/a  option umts_enable 1' $(1)/etc/config/owispmanager

  cat << EOF >> $(1)/etc/inittab
::respawn:/etc/owispmanager/umts-wd.sh
::respawn:/etc/owispmanager/apn.sh
EOF

endef


$(eval $(call BuildPackage,openwisp-fw))
$(eval $(call BuildPackage,openwisp-fw-mesh))
$(eval $(call BuildPackage,openwisp-fw-umts))

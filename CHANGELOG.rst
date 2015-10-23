1.3.3 [Unreleased]
==================

Bugfixes
--------
- `99e1e59 <https://github.com/openwisp/OpenWISP-Firmware/commit/99e1e597f0a69674c9b586e2a0af3029d5b5d0cc>`__ Added check to prevent infinite loop when sysupgrade from owf1.2 to owf1.3
- `3dd5fac <https://github.com/openwisp/OpenWISP-Firmware/commit/3dd5facc1eb0164bef4c1fb724beff2838971dd6>`__ Fixed firmware version/year in Web interface

1.3.2 [2015-10-06]
==================

Bugfixes
--------
- `f1599ac <https://github.com/openwisp/OpenWISP-Firmware/commit/f1599ac064ca9506da6dded41b553b40a02fd090>`__ fixed backward compatibility with older openwrt versions

1.3.1 [2015-09-21]
==================

Features
--------
- `1330d0e <https://github.com/openwisp/OpenWISP-Firmware/commit/1330d0ef2bba67e5c36288301f943eff3a921fa3>`__ Added support for USB-RLY16
- `#36 <https://github.com/openwisp/OpenWISP-Firmware/pull/36>`__ Chaos Calmer compatibility

Bugfixes
--------
- Fixed compilation procedure and instructions
- `cd956d3 <https://github.com/openwisp/OpenWISP-Firmware/commit/cd956d3cbf6b911e982b3e0976ad9be14089e9c9>`__ Removed unused uci settings #30
- `4efaa0a <https://github.com/openwisp/OpenWISP-Firmware/commit/4efaa0aed410f810d8b9c24e059e95a9acf0aa53>`__ Fixed revision number for polarssl #32

1.3 [2015-03-26]
================

Features
--------
- Converted code in OpenWRT Metapackage "openwisp-fw"
- Declared 4 different metapackages for different uses:
    - openwisp-fw-base (strpped down version)
    - openwisp-fw (standard version)
    - openwisp-fw-mesh (mesh utilities)
    - openwisp-fw-umts (mobile utilities)
- Optional reboot in safe mode when Layer2 VPN goes down
- Added automated tests for essential features:
    - device flashes
    - ip released by DHCP
    - owf SSID is shown
    - wifi serveice SSID is shown
    - connection to wifi service works
- Added 5 GHz support

Changes
-------
- Wireless template defaults to mac80211
- Updated wifi channel list

Bugfixes
--------
- Fixed a bug that prevented devices with no wifi interface to work
- Fixed 802.11n multiradio

1.2 [2013-06-28]
================

Features
--------
- Added "lan info" on status page
- OpenWISP Layout
- Deploy-firmware now works with OpenWRT backfire

Changes
-------
- Renamed ath9k to mac80211

Bugfixes
--------
- Fixed destroy_wifi_interface()

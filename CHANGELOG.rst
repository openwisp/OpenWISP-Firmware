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

 Openwrt feed for OpenWisp firmware
===================================

To add this repo to your OpenWrt installation use:

::
 
  echo "src-git openwisp https://github.com/openwisp/openwrt-feed.git" >> feeds.conf
  ./script/feeds update


If you have a local copy of this repo you can also use symbolic-link:

::
 
  echo "src-link openwisp /path/to/local/git/repo/" >> feeds.conf
  ./script/feeds update


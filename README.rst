 Openwrt feed for OpenWisp firmware
===================================

To add this repo to your OpenWrt installation use:

::

  echo "src-git openwisp https://github.com/openwisp/openwrt-feed.git" >> feeds.conf
  ./scripts/feeds update


If you have a local copy of this repo you can also use symbolic-link:

::

  echo "src-link openwisp /path/to/local/git/repo/" >> feeds.conf
  ./scripts/feeds update


Example to compile Openwrt
--------------------------

::

  git clone git://git.openwrt.org/openwrt.git
  cd openwrt
  cp feeds.conf.default feeds.conf
  echo "src-git openwisp https://github.com/openwisp/openwrt-feed.git" >> feeds.conf
  ./scripts/feeds update
  ./scripts/feeds install -d y openwisp-fw

  export OPENWISP_CONF="http://mysite.com/myextrafiles.tgz"

  #config target
  for arch in ar71xx atheros x86; do
    echo "CONFIG_TARGET_$arch=y" > .config;
    make defconfig;
    make -j 4;
  done

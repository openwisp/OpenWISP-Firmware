#!/bin/bash

#export OPENWISP_CONF="http://myserver.com/config_file_example.tar.gz" (see below)
if [[ -z ${OPENWISP_CONF} ]]; then
  echo "ERROR: $OPENWISP_CONF not defined"
  exit 2;
fi

if [[ ! -f feeds.conf ]]; then
	echo "ERROR: feeds.conf not available"
	exit 3;
fi

echo "src-git openwisp https://github.com/openwisp/openwrt-feed.git" >> feeds.conf
echo "src-git wlansi https://github.com/wlanslovenija/firmware-packages-opkg.git" >> feeds.conf

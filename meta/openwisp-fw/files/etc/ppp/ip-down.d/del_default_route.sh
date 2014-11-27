#!/bin/sh

[ "$1" -eq "3g-umts" ] || ip route del default via $5 dev $1

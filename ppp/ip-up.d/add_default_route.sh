#!/bin/sh

[ "$1" -eq "3g-umts" ] || ip route append default via $5 dev $1 metric 100
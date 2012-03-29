#!/usr/bin/env perl
#
# This file is part of the OpenWISP Firmware
#
# Copyright (C) 2012 OpenWISP.org
#

my $first = "root:" . crypt $ARGV[0], "\$1\$" . join "", (".", "/", 0..9, "A".."Z", "a".."z")[rand 64, rand 64, rand 64, rand 64,rand 64, rand 64,rand 64, rand 64];
my $last =  ":0:0:root:/root:/bin/ash\n"; 
print $first.$last

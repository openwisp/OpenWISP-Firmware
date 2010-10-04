#
# OpenWISP Firmware
# Copyright (C) 2010 CASPUR (Davide Guerri d.guerri@caspur.it)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

PACKAGE_BASE_NAME=owispmanager-firmware-tools
PACKAGE_VERSION=0.1
PACKAGE_NAME=$(PACKAGE_BASE_NAME)-$(PACKAGE_VERSION).tar.gz

all: package

clean:
	rm -f $(PACKAGE_NAME)

package: clean
	find . -type f | grep -v "\.svn" | grep -v "./Makefile" | xargs tar cvzf $(PACKAGE_NAME)


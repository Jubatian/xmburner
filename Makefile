############
# Makefile #
############
#
#  Copyright (C) 2017
#    Sandor Zsuga (Jubatian)
#
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
#
#
# Example makefile for a simple demo
#
#
# make all (or make): build the program
# make clean:         to clean up
#
#


include xmb_defs.mk


# Targets. For now add a dummy target indicating all built.

all: $(XMB_OBJ)/dummy
clean:
	rm    -f $(XMB_OBJ)/dummy
	rm    -f $(XMB_OBJ)/*.o
	rm -d -f $(XMB_OBJ)
	rm    -f $(XMB_BIN)/$(XMB_CRCHEX)
	rm -d -f $(XMB_BIN)


$(XMB_OBJ)/dummy: $(XMB_COMPONENTS)
	touch $(XMB_OBJ)/dummy


# XMBurner rules

include xmb_ruls.mk


.PHONY: all clean

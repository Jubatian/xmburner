################
# Make - rules #
################
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
# This file holds rules to build XMBurner's objects. The xmb_defs.mk file has
# to be included before this.
#
#


# Support environment

$(XMB_OBJ):
	mkdir $(XMB_OBJ)


# Components

$(XMB_OBJ)/%.o: xmburner/%.s xmburner/xmb_defs.h $(XMB_OBJ)
	$(XMB_CC) $(XMB_ASMFLAGS) -c $< -o $@

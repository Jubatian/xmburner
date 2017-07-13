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

$(XMB_OBJ)/xmb_glob.o: xmburner/xmb_glob.s xmburner/xmb_defs.h $(XMB_OBJ)
	$(XMB_CC) $(XMB_ASMFLAGS) -c $< -o $@

$(XMB_OBJ)/xmb_main.o: xmburner/xmb_main.s xmburner/xmb_defs.h $(XMB_OBJ)
	$(XMB_CC) $(XMB_ASMFLAGS) -c $< -o $@

# Components

$(XMB_OBJ)/xmb_creg.o: xmburner/xmb_creg.s xmburner/xmb_defs.h $(XMB_OBJ)
	$(XMB_CC) $(XMB_ASMFLAGS) -c $< -o $@

$(XMB_OBJ)/xmb_cond.o: xmburner/xmb_cond.s xmburner/xmb_defs.h $(XMB_OBJ)
	$(XMB_CC) $(XMB_ASMFLAGS) -c $< -o $@

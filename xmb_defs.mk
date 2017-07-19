######################
# Make - definitions #
######################
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
# This file holds general flags used for compiling XMBurner.
#
#

XMB_CC     ?= avr-gcc
XMB_MCU    ?= atmega644

## Compile options common for all C compilation units.

XMB_CFLAGS  = -mmcu=$(XMB_MCU)
XMB_CFLAGS += -Wall -gdwarf-2 -std=gnu99 -Os -fsigned-char -ffunction-sections
XMB_CFLAGS += -fno-toplevel-reorder -fno-tree-switch-conversion

## Assembly specific flags

XMB_ASMFLAGS  = $(XMB_CFLAGS)
XMB_ASMFLAGS += -x assembler-with-cpp -Wa,-gdwarf2

## XMBurner build directory (objects)

XMB_OBJ = _xmb_o_

## XMBurner components

XMB_COMPONENTS  = $(XMB_OBJ)/xmb_glob.o
XMB_COMPONENTS += $(XMB_OBJ)/xmb_main.o

XMB_COMPONENTS += $(XMB_OBJ)/xmb_creg.o
XMB_COMPONENTS += $(XMB_OBJ)/xmb_cond.o
XMB_COMPONENTS += $(XMB_OBJ)/xmb_jump.o

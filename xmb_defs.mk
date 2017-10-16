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
XMB_NATCC  ?= gcc
XMB_SPATH  ?= .
XMB_OPATH  ?= .

## crchex tool name

XMB_CRCHEX ?= crchex

## Compile options common for all C compilation units.

XMB_CFLAGS  = -mmcu=$(XMB_MCU)
XMB_CFLAGS += -Wall -gdwarf-2 -std=gnu99 -Os -fsigned-char -ffunction-sections
XMB_CFLAGS += -fno-toplevel-reorder -fno-tree-switch-conversion

## Assembly specific flags

XMB_ASMFLAGS  = $(XMB_CFLAGS)
XMB_ASMFLAGS += -x assembler-with-cpp -Wa,-gdwarf2

## Native C compilation options (for tools)

XMB_NATCFS += -Wall -std=gnu99 -Os

## XMBurner build directory (objects, binaries)

XMB_OBJ = $(XMB_OPATH)/_xmb_o_
XMB_BIN = $(XMB_OPATH)/_xmb_b_

## XMBurner objects (can be used as dependency and source for linking)

XMB_OBJECTS  = $(XMB_OBJ)/xmb_jump.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_glob.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_main.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_creg.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_cond.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_crc.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_ram.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_log.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_sub.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_add.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_alex.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_wops.o
XMB_OBJECTS += $(XMB_OBJ)/xmb_bit.o

## crchex tool (can be used as dependency or command)

XMB_CRCHEX_BIN  = $(XMB_BIN)/$(XMB_CRCHEX)

## XMBurner components (can be used as dependency for build all)

XMB_COMPONENTS  = $(XMB_OBJECTS)
XMB_COMPONENTS += $(XMB_CRCHEX_BIN)

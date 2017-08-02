/*
** XMBurner - main definitions
**
** Copyright (C) 2017 Sandor Zsuga (Jubatian)
**
** This Source Code Form is subject to the terms of the Mozilla Public
** License, v. 2.0. If a copy of the MPL was not distributed with this
** file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


#include <avr/io.h>


/*
** Address of fault routine, jumped to when XMBurner detects a fault. It takes
** a single 16 bit parameter in r25:r24 identifying the cause.
**
** You may return from this to the caller (at your own risk). This case you
** should jump (!) to the xmb_glob_tail routine. Note that EIND, if available,
** may not be zero in this fault routine.
*/

#ifndef XMB_FAULT
#define XMB_FAULT xmb_fault
#endif


/*
** Section to place the branch test (xmb_jump) within. Ideally it should be
** placed in the middle of the flash (middle_address - 64 words) so it can
** test the longest carry sequence in the relative branch / jump adder (in a
** 64 KWords flash this would be word address 0x8000 - 64, so relative jumping
** across this boundary can be tested).
*/

#ifndef XMB_JUMP_SECTION
#define XMB_JUMP_SECTION .text
#endif


/*
** Section to place XMBurner ROM data tables within. This section must
** entirely reside in the lower 64 KBytes as these tables are accessed with
** LPM instructions.
*/

#ifndef XMB_RO64_SECTION
#define XMB_RO64_SECTION .text
#endif


/*
** Size of binary for CRC32 checking. This is a 2 or 3 byte Little Endian
** value in ROM (if the MCU's ROM is 64 KBytes or less, only the first 2 bytes
** are used, which should be provided in accordance with the location of the
** CRC. It is provided in this manner so XMBurner components can be compiled
** independently of the application if necessary. The size includes the CRC,
** and must be a multiple of 64.
*/

#ifndef XMB_BSIZE
#define XMB_BSIZE xmb_bsize
#endif


/*
** Only XMega include files have PROGMEM_SIZE defined. For other AVR's, use
** FLASHEND (which is always defined).
*/

#ifndef PROGMEM_SIZE
#define PROGMEM_SIZE (FLASHEND + 1)
#endif

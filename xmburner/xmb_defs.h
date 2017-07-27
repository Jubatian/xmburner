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
** Size of binary for CRC32 checking. This normally should come from the
** makefile as a parameter passed to the compiler along with the proper
** preparation of the binary passing it through the crchex tool.
*/

#ifndef XMB_BSIZE
#error "XMB_BSIZE has to be defined (do you have it in your Makefile?)"
#endif
#if ((XMB_BSIZE & 0xFF) != 0)
#error "XMB_BSIZE must be a multiple of 256!"
#endif

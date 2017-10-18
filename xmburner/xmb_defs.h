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
** Address of watchdog routine, called when XMBurner completes an xmb_run()
** pass. It takes a single 32 bit parameter which one's value is 0xDEADF158.
** You should use this for a comparison, to prevent resetting the watchdog
** when the routine was called by runaway code. The default implementation
** calls WDR, and jumps on XMB_FAULT (0xFF:0xFF) if the comparison fails.
*/

#ifndef XMB_WDRESET
#define XMB_WDRESET xmb_wdreset_default
#endif


/*
** Initialization delay in 256K cycle units. Set it up so the watchdog
** mechanisms guarding your application time out during it (if you have a
** watchdog capable of this which is recommended), ensuring that the
** initialization (xmb_init) can not finish without a watchdog alerting if it
** is recalled in any manner during program execution.
*/

#ifndef XMB_INIT_DELAY
#define XMB_INIT_DELAY 4
#endif


/*
** Address of initialization guard routine. This function should reset the
** application controlled process to a safe default state, and if there is
** any condition by which a false init can be detected, that should be checked
** and reacted here. The default implementation does nothing.
*/

#ifndef XMB_INIT_GUARD
#define XMB_INIT_GUARD xmb_init_guard_default
#endif


/*
** Section to place non-public xmburner components within. This section may
** be used to move these components away from the low 128K if the application
** prevers to be there. If XMB_JUMP_SECTION is set the same as this section,
** and the linker sorts code by input order, the xmb_jump component will be
** the first, so compiling that way also works.
*/

#ifndef XMB_COMP_SECTION
#define XMB_COMP_SECTION .text
#endif


/*
** Section to place the branch test (xmb_jump) within. Ideally it should be
** placed in the middle of the flash (middle_address - 64 words) so it can
** test the longest carry sequence in the relative branch / jump adder (in a
** 64 KWords flash this would be word address 0x8000 - 64, so relative jumping
** across this boundary can be tested).
*/

#ifndef XMB_JUMP_SECTION
#define XMB_JUMP_SECTION XMB_COMP_SECTION
#endif


/*
** Section to place XMBurner ROM data tables within. This section must
** entirely reside in the lower 64 KBytes as these tables are accessed with
** LPM instructions. The .progmem section is normally available especially for
** this purpose.
*/

#ifndef XMB_RO64_SECTION
#define XMB_RO64_SECTION .progmem
#endif


/*
** Set this nonzero to enable splitting xmb_crc_isromok() for large devices.
** This causes calling xmb_run() after each 64Kbyte boundary, which may call a
** watchdog reset. Use this only if your design has to involve a watchdog
** which has a too short timeout even during initialization to run
** xmb_crc_isromok() in one pass. This case xmb_init() has to be called before
** xmb_crc_isromok(). Note that if you have xmb_bsize set a multiple of
** 64 KBytes, the last xmb_run() will happen after the last byte.
*/

#ifndef XMB_CRC_SPLIT
#define XMB_CRC_SPLIT 0
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


/*
** Some headers lack the RAMSIZE definition. For these, calculate it from
** RAMSTART and RAMEND.
*/

#ifndef RAMSIZE
#define RAMSIZE (RAMEND + 1 - RAMSTART)
#endif


/*
** Count of XMBurner components (iterated during xmb_run()).
*/

#define XMB_COMPONENT_COUNT 0x0B


/*
** Count of fault codes provided in r24 (excluding 0xFF) for each component.
** The component may so return fault codes 0x00 to (XMB_FID_CNT_xxxx - 1) and
** 0xFF.
*/

#define XMB_FID_CNT_CREG  7
#define XMB_FID_CNT_COND  7
#define XMB_FID_CNT_JUMP  6
#define XMB_FID_CNT_CRC   4
#define XMB_FID_CNT_RAM   5
#define XMB_FID_CNT_LOG   6
#define XMB_FID_CNT_SUB   7
#define XMB_FID_CNT_ADD   2
#define XMB_FID_CNT_ALEX  7
#define XMB_FID_CNT_WOPS  3
#define XMB_FID_CNT_BIT   4

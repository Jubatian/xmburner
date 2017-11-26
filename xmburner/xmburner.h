/*
** XMBurner - C language interface header
**
** Copyright (C) 2017 Sandor Zsuga (Jubatian)
**
** This Source Code Form is subject to the terms of the Mozilla Public
** License, v. 2.0. If a copy of the MPL was not distributed with this
** file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


#ifndef XMBURNER_H
#define XMBURNER_H


#include "xmb_defs.h"
#include <stdint.h>


/*
** Initializes the ALU tester. Note that it takes a long time (ideally more
** than the timeout of all watchdogs used in the application, see
** XMB_INIT_DELAY).
*/
void     xmb_init(void);


/*
** Main runner. Calling this repeatedely will execute the various ALU tests,
** each pass designed to take less than 10K cycles with up to 16 cycle spans
** running interrupts disabled.
*/
void     xmb_run(void);


/*
** Return next XMBurner component which will run on xmb_run(). The return
** value is between 0 and XMB_COMPONENT_COUNT - 1, inclusive.
*/
uint8_t  xmb_next(void);


/*
** Checks entire RAM. Returns TRUE if the test passed. Note that this should
** only be called during init as a part of a boot up test as it takes
** substantial amount of time.
*/
_Bool    xmb_ram_isramok(void);


/*
** Checks CRC of the entire ROM. Returns TRUE if the test passed. Note that
** this should only be called during init as a part of a boot up test as it
** takes substantial amount of time.
*/
_Bool    xmb_crc_isromok(void);


/*
** Calculates CRC-32 on a given byte of data. Returns new CRC-32 value after
** including the byte.
*/
uint32_t xmb_crc_calc(uint32_t crc, uint8_t byte);


/*
** Generates CRC-32 for a RAM region. After calculating the CRC, it appends to
** the region, so the region passed must be capable to hold at least len + 4
** bytes of data.
*/
void     xmb_crc_genram(void* addr, uint16_t len);


/*
** Checks CRC-32 for a RAM region. The CRC-32 is assumed to be the last 4
** bytes of this region.
*/
_Bool    xmb_crc_isramok(void const* addr, uint16_t len);


#endif

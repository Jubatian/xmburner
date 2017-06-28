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
** You may return from this to the caller (at your own risk). This case set r1
** zero, pop registers r2-r17, YL and YH from stack, and execute a ret.
*/

#ifndef XMB_FAULT
#define XMB_FAULT xmb_fault_def
#endif

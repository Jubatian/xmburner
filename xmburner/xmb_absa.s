;
; XMBurner - (0x0C) Absolute addressing test
;
; Copyright (C) 2018 Sandor Zsuga (Jubatian)
;
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.
;
;
; This component tests:
;
; - LDS and STS instructions.
;
; This test can not run in parallel with DMA accesses (you have to make sure
; there are no DMA transactions running when this is called).
;
; Interrupts are disabled for up to 17 (Mega) / 21 (XMega) cycle periods
; during the test.
;

#include "xmb_defs.h"


.section XMB_COMP_SECTION


.set exec_id_from, 0x9A00C47E
.set exec_id,      0xE4D01197

.set SR_IO,  _SFR_IO_ADDR(SREG)



.global xmb_absa
xmb_absa:

	; All XMBurner components receive the previous component's exec_id in
	; r19:r18:r17:r16, set up by xmb_main.s. No other input parameters are
	; used.

	; Partial set up & Test execution chain

	ldi   ZL,      lo8(xmb_glob_chain)
	ldi   ZH,      hi8(xmb_glob_chain)
	ldi   r20,     ((exec_id      ) & 0xFF) ^ ((exec_id_from      ) & 0xFF)
	eor   r20,     r16
	std   Z + 0,   r20
	ldi   r20,     ((exec_id >>  8) & 0xFF) ^ ((exec_id_from >>  8) & 0xFF)
	eor   r20,     r17
	std   Z + 1,   r20
	subi  r16,     (exec_id_from      ) & 0xFF
	sbci  r17,     (exec_id_from >>  8) & 0xFF
	sbci  r18,     (exec_id_from >> 16) & 0xFF
	sbci  r19,     (exec_id_from >> 24) & 0xFF
	brne  xmb_absa_fault_ff
	brcs  xmb_absa_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_absa_fault_ff
	brcs  xmb_absa_check

xmb_absa_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x0C
	jmp   XMB_FAULT

xmb_absa_check:

	; Test cell pairs using LDS / STS instructions with a goal of trying
	; to detect addressing problems (stuck 0 or stuck 1 address bits)
	; within the available SRAM area. For this, one pass is performed
	; comparing to the bottommost RAM address (most bits zero), and one
	; pass comparing to the topmost RAM address (most bits one).

	in    r1,      SR_IO   ; Save current SREG with whatever 'I' flag it has


	; Pass 1: Compare with RAM bottom

	ldi   r18,     0x69
	ldi   r19,     0x96    ; Test value pair

#if ((RAMSTART + 0x0001) <= RAMEND)

	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x0001 ; Save current contents
	sts   RAMSTART,          r18
	sts   RAMSTART + 0x0001, r19
	lds   r4,      RAMSTART
	lds   r5,      RAMSTART + 0x0001 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0001, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r4,      r18
	rjmp  xmb_absa_fault_00
	cpse  r5,      r19
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0002) <= RAMEND)

	movw  r4,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x0002 ; Save current contents
	sts   RAMSTART,          r4
	sts   RAMSTART + 0x0002, r5
	lds   r20,     RAMSTART
	lds   r21,     RAMSTART + 0x0002 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0002, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r20,     r4
	rjmp  xmb_absa_fault_00
	cpse  r21,     r5
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0004) <= RAMEND)

	movw  r2,      r18
	cli                    ; Disable interrupts
	lds   r8,      RAMSTART
	lds   r9,      RAMSTART + 0x0002 ; Save current contents
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0002, r3
	lds   r6,      RAMSTART
	lds   r7,      RAMSTART + 0x0002 ; Do test write & read pair
	sts   RAMSTART,          r8
	sts   RAMSTART + 0x0002, r9      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r2,      r6
	rjmp  xmb_absa_fault_00
	cpse  r3,      r7
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0008) <= RAMEND)

	movw  YL,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x0008 ; Save current contents
	sts   RAMSTART,          YL
	sts   RAMSTART + 0x0008, YH
	lds   r12,     RAMSTART
	lds   r13,     RAMSTART + 0x0008 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0008, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  YL,      r12
	rjmp  xmb_absa_fault_00
	cpse  YH,      r13
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0010) <= RAMEND)

	movw  r14,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x0010 ; Save current contents
	sts   RAMSTART,          r14
	sts   RAMSTART + 0x0010, r15
	lds   XL,      RAMSTART
	lds   XH,      RAMSTART + 0x0010 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0010, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r14,     XL
	rjmp  xmb_absa_fault_00
	cpse  r15,     XH
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0020) <= RAMEND)

	movw  r8,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x0020 ; Save current contents
	sts   RAMSTART,          r8
	sts   RAMSTART + 0x0020, r9
	lds   r16,     RAMSTART
	lds   r17,     RAMSTART + 0x0020 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0020, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r8,      r16
	rjmp  xmb_absa_fault_00
	cpse  r9,      r17
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0040) <= RAMEND)

	movw  r20,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x0040 ; Save current contents
	sts   RAMSTART,          r20
	sts   RAMSTART + 0x0040, r21
	lds   r8,      RAMSTART
	lds   r9,      RAMSTART + 0x0040 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0040, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r20,     r8
	rjmp  xmb_absa_fault_00
	cpse  r21,     r9
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0080) <= RAMEND)

	movw  r24,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x0080 ; Save current contents
	sts   RAMSTART,          r24
	sts   RAMSTART + 0x0080, r25
	lds   ZL,      RAMSTART
	lds   ZH,      RAMSTART + 0x0080 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0080, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r24,     ZL
	rjmp  xmb_absa_fault_00
	cpse  r25,     ZH
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0100) <= RAMEND)

	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x0100 ; Save current contents
	sts   RAMSTART,          r18
	sts   RAMSTART + 0x0100, r19
	lds   r4,      RAMSTART
	lds   r5,      RAMSTART + 0x0100 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0100, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r4,      r18
	rjmp  xmb_absa_fault_00
	cpse  r5,      r19
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0200) <= RAMEND)

	movw  r4,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x0200 ; Save current contents
	sts   RAMSTART,          r4
	sts   RAMSTART + 0x0200, r5
	lds   r20,     RAMSTART
	lds   r21,     RAMSTART + 0x0200 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0200, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r20,     r4
	rjmp  xmb_absa_fault_00
	cpse  r21,     r5
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0400) <= RAMEND)

	movw  r2,      r18
	cli                    ; Disable interrupts
	lds   r8,      RAMSTART
	lds   r9,      RAMSTART + 0x0400 ; Save current contents
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0400, r3
	lds   r6,      RAMSTART
	lds   r7,      RAMSTART + 0x0400 ; Do test write & read pair
	sts   RAMSTART,          r8
	sts   RAMSTART + 0x0400, r9      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r2,      r6
	rjmp  xmb_absa_fault_00
	cpse  r3,      r7
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x0800) <= RAMEND)

	movw  YL,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x0800 ; Save current contents
	sts   RAMSTART,          YL
	sts   RAMSTART + 0x0800, YH
	lds   r12,     RAMSTART
	lds   r13,     RAMSTART + 0x0800 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x0800, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  YL,      r12
	rjmp  xmb_absa_fault_00
	cpse  YH,      r13
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x1000) <= RAMEND)

	movw  r14,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x1000 ; Save current contents
	sts   RAMSTART,          r14
	sts   RAMSTART + 0x1000, r15
	lds   XL,      RAMSTART
	lds   XH,      RAMSTART + 0x1000 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x1000, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r14,     XL
	rjmp  xmb_absa_fault_00
	cpse  r15,     XH
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x2000) <= RAMEND)

	movw  r8,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x2000 ; Save current contents
	sts   RAMSTART,          r8
	sts   RAMSTART + 0x2000, r9
	lds   r16,     RAMSTART
	lds   r17,     RAMSTART + 0x2000 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x2000, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r8,      r16
	rjmp  xmb_absa_fault_00
	cpse  r9,      r17
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x4000) <= RAMEND)

	movw  r20,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x4000 ; Save current contents
	sts   RAMSTART,          r20
	sts   RAMSTART + 0x4000, r21
	lds   r8,      RAMSTART
	lds   r9,      RAMSTART + 0x4000 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x4000, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r20,     r8
	rjmp  xmb_absa_fault_00
	cpse  r21,     r9
	rjmp  xmb_absa_fault_00

#endif

#if ((RAMSTART + 0x8000) <= RAMEND)

	movw  r24,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMSTART
	lds   r3,      RAMSTART + 0x8000 ; Save current contents
	sts   RAMSTART,          r24
	sts   RAMSTART + 0x8000, r25
	lds   ZL,      RAMSTART
	lds   ZH,      RAMSTART + 0x8000 ; Do test write & read pair
	sts   RAMSTART,          r2
	sts   RAMSTART + 0x8000, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r24,     ZL
	rjmp  xmb_absa_fault_00
	cpse  r25,     ZH
	rjmp  xmb_absa_fault_00

#endif


	; Pass 2: Compare with RAM top

	ldi   r18,     0x3C
	ldi   r19,     0xC3    ; Test value pair

#if ((RAMSTART + 0x0001) <= RAMEND)

	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x0001 ; Save current contents
	sts   RAMEND,          r18
	sts   RAMEND - 0x0001, r19
	lds   r4,      RAMEND
	lds   r5,      RAMEND - 0x0001 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x0001, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r4,      r18
	rjmp  xmb_absa_fault_01
	cpse  r5,      r19
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0002) <= RAMEND)

	movw  r4,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x0002 ; Save current contents
	sts   RAMEND,          r4
	sts   RAMEND - 0x0002, r5
	lds   r20,     RAMEND
	lds   r21,     RAMEND - 0x0002 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x0002, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r20,     r4
	rjmp  xmb_absa_fault_01
	cpse  r21,     r5
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0004) <= RAMEND)

	movw  r2,      r18
	cli                    ; Disable interrupts
	lds   r8,      RAMEND
	lds   r9,      RAMEND - 0x0002 ; Save current contents
	sts   RAMEND,          r2
	sts   RAMEND - 0x0002, r3
	lds   r6,      RAMEND
	lds   r7,      RAMEND - 0x0002 ; Do test write & read pair
	sts   RAMEND,          r8
	sts   RAMEND - 0x0002, r9      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r2,      r6
	rjmp  xmb_absa_fault_01
	cpse  r3,      r7
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0008) <= RAMEND)

	movw  YL,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x0008 ; Save current contents
	sts   RAMEND,          YL
	sts   RAMEND - 0x0008, YH
	lds   r12,     RAMEND
	lds   r13,     RAMEND - 0x0008 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x0008, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  YL,      r12
	rjmp  xmb_absa_fault_01
	cpse  YH,      r13
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0010) <= RAMEND)

	movw  r14,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x0010 ; Save current contents
	sts   RAMEND,          r14
	sts   RAMEND - 0x0010, r15
	lds   XL,      RAMEND
	lds   XH,      RAMEND - 0x0010 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x0010, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r14,     XL
	rjmp  xmb_absa_fault_01
	cpse  r15,     XH
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0020) <= RAMEND)

	movw  r8,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x0020 ; Save current contents
	sts   RAMEND,          r8
	sts   RAMEND - 0x0020, r9
	lds   r16,     RAMEND
	lds   r17,     RAMEND - 0x0020 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x0020, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r8,      r16
	rjmp  xmb_absa_fault_01
	cpse  r9,      r17
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0040) <= RAMEND)

	movw  r20,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x0040 ; Save current contents
	sts   RAMEND,          r20
	sts   RAMEND - 0x0040, r21
	lds   r8,      RAMEND
	lds   r9,      RAMEND - 0x0040 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x0040, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r20,     r8
	rjmp  xmb_absa_fault_01
	cpse  r21,     r9
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0080) <= RAMEND)

	movw  r24,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x0080 ; Save current contents
	sts   RAMEND,          r24
	sts   RAMEND - 0x0080, r25
	lds   ZL,      RAMEND
	lds   ZH,      RAMEND - 0x0080 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x0080, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r24,     ZL
	rjmp  xmb_absa_fault_01
	cpse  r25,     ZH
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0100) <= RAMEND)

	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x0100 ; Save current contents
	sts   RAMEND,          r18
	sts   RAMEND - 0x0100, r19
	lds   r4,      RAMEND
	lds   r5,      RAMEND - 0x0100 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x0100, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r4,      r18
	rjmp  xmb_absa_fault_01
	cpse  r5,      r19
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0200) <= RAMEND)

	movw  r4,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x0200 ; Save current contents
	sts   RAMEND,          r4
	sts   RAMEND - 0x0200, r5
	lds   r20,     RAMEND
	lds   r21,     RAMEND - 0x0200 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x0200, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r20,     r4
	rjmp  xmb_absa_fault_01
	cpse  r21,     r5
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0400) <= RAMEND)

	movw  r2,      r18
	cli                    ; Disable interrupts
	lds   r8,      RAMEND
	lds   r9,      RAMEND - 0x0400 ; Save current contents
	sts   RAMEND,          r2
	sts   RAMEND - 0x0400, r3
	lds   r6,      RAMEND
	lds   r7,      RAMEND - 0x0400 ; Do test write & read pair
	sts   RAMEND,          r8
	sts   RAMEND - 0x0400, r9      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r2,      r6
	rjmp  xmb_absa_fault_01
	cpse  r3,      r7
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x0800) <= RAMEND)

	movw  YL,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x0800 ; Save current contents
	sts   RAMEND,          YL
	sts   RAMEND - 0x0800, YH
	lds   r12,     RAMEND
	lds   r13,     RAMEND - 0x0800 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x0800, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  YL,      r12
	rjmp  xmb_absa_fault_01
	cpse  YH,      r13
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x1000) <= RAMEND)

	movw  r14,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x1000 ; Save current contents
	sts   RAMEND,          r14
	sts   RAMEND - 0x1000, r15
	lds   XL,      RAMEND
	lds   XH,      RAMEND - 0x1000 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x1000, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r14,     XL
	rjmp  xmb_absa_fault_01
	cpse  r15,     XH
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x2000) <= RAMEND)

	movw  r8,      r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x2000 ; Save current contents
	sts   RAMEND,          r8
	sts   RAMEND - 0x2000, r9
	lds   r16,     RAMEND
	lds   r17,     RAMEND - 0x2000 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x2000, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r8,      r16
	rjmp  xmb_absa_fault_01
	cpse  r9,      r17
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x4000) <= RAMEND)

	movw  r20,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x4000 ; Save current contents
	sts   RAMEND,          r20
	sts   RAMEND - 0x4000, r21
	lds   r8,      RAMEND
	lds   r9,      RAMEND - 0x4000 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x4000, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r20,     r8
	rjmp  xmb_absa_fault_01
	cpse  r21,     r9
	rjmp  xmb_absa_fault_01

#endif

#if ((RAMSTART + 0x8000) <= RAMEND)

	movw  r24,     r18
	cli                    ; Disable interrupts
	lds   r2,      RAMEND
	lds   r3,      RAMEND - 0x8000 ; Save current contents
	sts   RAMEND,          r24
	sts   RAMEND - 0x8000, r25
	lds   ZL,      RAMEND
	lds   ZH,      RAMEND - 0x8000 ; Do test write & read pair
	sts   RAMEND,          r2
	sts   RAMEND - 0x8000, r3      ; Restore contents
	out   SR_IO,   r1      ; Enable interrupts (if they were disabled)

	cpse  r24,     ZL
	rjmp  xmb_absa_fault_01
	cpse  r25,     ZH
	rjmp  xmb_absa_fault_01

#endif


	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next


xmb_absa_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x0C
	jmp   XMB_FAULT

xmb_absa_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x0C
	jmp   XMB_FAULT



;
; Test entry points
;
.global xmb_absa_check

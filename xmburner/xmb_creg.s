;
; XMBurner - (0x00) CPU register pattern tests
;
; Copyright (C) 2017 Sandor Zsuga (Jubatian)
;
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.
;
;
; This component tests:
;
; - CPU and critical IO registers for stuck bits and proper addressing.
; - Bit set and clear instructions operating on SREG.
; - The LDI instruction.
; - The LPM instruction.
; - Diverse parameter combinations on EOR, COM, ADC and CPSE instructions.
;
; Critical IO registers are SREG, SPH and SPL.
;
; Interrupts are disabled for up to 8 cycle periods during the test.
;

#include "xmb_defs.h"


.section .text


.set exec_id_from, 0xE0D43BA5
.set exec_id,      0xE0D43BA5

.set SR_IO,  _SFR_IO_ADDR(SREG)
.set SPL_IO, _SFR_IO_ADDR(SPL)
.set SPH_IO, _SFR_IO_ADDR(SPH)


.global xmb_creg
xmb_creg:

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
	brne  xmb_creg_fault_ff
	brcs  xmb_creg_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_creg_fault_ff
	brcs  xmb_creg_cr0

xmb_creg_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_cr0:

	; CPU register test: Load every register with different values, then
	; do the inverse. This catches individual bits stuck set or clear, and
	; due to the different values, is also likely to catch addressing
	; flaws or if writes affect each other across registers. A different
	; checking method is used for the inverse run to reduce the likelihood
	; of common mode failure. Although the lpm instruction uses Z, the
	; fault of ZH:ZL is highly unlikely to mask register faults.
	;
	; Notes on the eor - com combo: The eor may mask a stuck 1 type fault
	; on its target. The com alone would not uncover it, the role of the
	; or block checking for zero is verifying whether the registers could
	; change all its bits from 0xFF to 0x00. Including the xmb_creg_cr1
	; pass, this test is performed for all registers.

	ldi   ZL,      lo8(xmb_creg_lowrd_s)
	ldi   ZH,      hi8(xmb_creg_lowrd_s)
	lpm   r0,      Z+
	lpm   r1,      Z+
	lpm   r2,      Z+
	lpm   r3,      Z+
	lpm   r4,      Z+
	lpm   r5,      Z+
	lpm   r6,      Z+
	lpm   r7,      Z+
	lpm   r8,      Z+
	lpm   r9,      Z+
	lpm   r10,     Z+
	lpm   r11,     Z+
	lpm   r12,     Z+
	lpm   r13,     Z+
	lpm   r14,     Z+
	lpm   r15,     Z+
	lpm   r16,     Z+
	lpm   r17,     Z+
	lpm   r18,     Z+
	lpm   r19,     Z+
	lpm   r20,     Z+
	lpm   r21,     Z+
	lpm   r22,     Z+
	lpm   r23,     Z+
	lpm   r24,     Z+
	lpm   r25,     Z+
	lpm   XL,      Z+
	lpm   XH,      Z+
	lpm   YL,      Z+
	lpm   YH,      Z+
	lpm   ZL,      Z
	ldi   ZH,      0xCA
	eor   r0,      r16
	com   r0
	brne  xmb_creg_fault_00
	eor   r1,      r17
	com   r1
	brne  xmb_creg_fault_00
	eor   r2,      r18
	com   r2
	brne  xmb_creg_fault_00
	eor   r3,      r19
	com   r3
	brne  xmb_creg_fault_00
	eor   r4,      r20
	com   r4
	brne  xmb_creg_fault_00
	eor   r5,      r21
	com   r5
	brne  xmb_creg_fault_00
	eor   r6,      r22
	com   r6
	brne  xmb_creg_fault_00
	eor   r7,      r23
	com   r7
	brne  xmb_creg_fault_00
	eor   r8,      r24
	com   r8
	brne  xmb_creg_fault_00
	eor   r9,      r25
	com   r9
	brne  xmb_creg_fault_00
	eor   r10,     XL
	com   r10
	brne  xmb_creg_fault_00
	eor   r11,     XH
	com   r11
	brne  xmb_creg_fault_00
	eor   r12,     YL
	com   r12
	brne  xmb_creg_fault_00
	eor   r13,     YH
	com   r13
	brne  xmb_creg_fault_00
	eor   r14,     ZL
	com   r14
	brne  xmb_creg_fault_00
	eor   r15,     ZH
	com   r15
	breq  xmb_creg_ovr

xmb_creg_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_ovr:
	or    r0,      r1
	brne  xmb_creg_fault_00
	or    r2,      r3
	brne  xmb_creg_fault_00
	or    r4,      r5
	brne  xmb_creg_fault_00
	or    r6,      r7
	brne  xmb_creg_fault_00
	or    r8,      r9
	brne  xmb_creg_fault_00
	or    r10,     r11
	brne  xmb_creg_fault_00
	or    r12,     r13
	brne  xmb_creg_fault_00
	or    r14,     r15
	brne  xmb_creg_fault_00

xmb_creg_inv:

	ldi   ZL,      lo8(xmb_creg_lowrd_i)
	ldi   ZH,      hi8(xmb_creg_lowrd_i)
	lpm   r0,      Z+
	lpm   r1,      Z+
	lpm   r2,      Z+
	lpm   r3,      Z+
	lpm   r4,      Z+
	lpm   r5,      Z+
	lpm   r6,      Z+
	lpm   r7,      Z+
	lpm   r8,      Z+
	lpm   r9,      Z+
	lpm   r10,     Z+
	lpm   r11,     Z+
	lpm   r12,     Z+
	lpm   r13,     Z+
	lpm   r14,     Z+
	lpm   r15,     Z
	ldi   r16,     0x55
	ldi   r17,     0xAA
	ldi   r18,     0x1E
	ldi   r19,     0x96
	ldi   r20,     0xC3
	ldi   r21,     0xF0
	ldi   r22,     0x72
	ldi   r23,     0x4D
	ldi   r24,     0x63
	ldi   r25,     0x59
	ldi   XL,      0x87
	ldi   XH,      0x99
	ldi   YL,      0xB8
	ldi   YH,      0xA9
	ldi   ZL,      lo8(xmb_creg_lowrd_s + 15)
	ldi   ZH,      hi8(xmb_creg_lowrd_s + 15)
	lpm   ZH,      Z
	ldi   ZL,      0xD1
	sec
	adc   ZH,      r15
	brne  xmb_creg_fault_01
	adc   ZL,      r14
	brne  xmb_creg_fault_01
	adc   YH,      r13
	brne  xmb_creg_fault_01
	adc   YL,      r12
	brne  xmb_creg_fault_01
	adc   XH,      r11
	brne  xmb_creg_fault_01
	adc   XL,      r10
	brne  xmb_creg_fault_01
	adc   r25,     r9
	brne  xmb_creg_fault_01
	adc   r24,     r8
	brne  xmb_creg_fault_01
	adc   r23,     r7
	brne  xmb_creg_fault_01
	adc   r22,     r6
	brne  xmb_creg_fault_01
	adc   r21,     r5
	brne  xmb_creg_fault_01
	adc   r20,     r4
	brne  xmb_creg_fault_01
	adc   r19,     r3
	brne  xmb_creg_fault_01
	adc   r18,     r2
	brne  xmb_creg_fault_01
	adc   r17,     r1
	brne  xmb_creg_fault_01
	adc   r16,     r0
	breq  xmb_creg_cr1

xmb_creg_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_cr1:

	; A second pass of a similar test with different bit patterns and
	; register comparison pairings. The patterns are selected to be
	; distinct from the patterns previously used on each register to
	; increase the chance of detecting bits affecting each other in
	; individual registers.

	ldi   YH,      0x63
	ldi   YL,      0x8B
	ldi   XH,      0x95
	ldi   XL,      0xA5
	ldi   r25,     0x3A
	ldi   r24,     0x74
	ldi   r23,     0x59
	ldi   r22,     0xE4
	ldi   r21,     0x39
	ldi   r20,     0xB1
	ldi   r19,     0xD4
	ldi   r18,     0x2D
	ldi   r17,     0x8E
	ldi   r16,     0xC5
	ldi   ZL,      lo8(xmb_creg_lowrd_1s)
	ldi   ZH,      hi8(xmb_creg_lowrd_1s)
	lpm   r15,     Z+
	lpm   r14,     Z+
	lpm   r13,     Z+
	lpm   r12,     Z+
	lpm   r11,     Z+
	lpm   r10,     Z+
	lpm   r9,      Z+
	lpm   r8,      Z+
	lpm   r7,      Z+
	lpm   r6,      Z+
	lpm   r5,      Z+
	lpm   r4,      Z+
	lpm   r3,      Z+
	lpm   r2,      Z+
	lpm   r1,      Z+
	lpm   r0,      Z
	ldi   ZH,      0x72
	ldi   ZL,      0xC6
	eor   r16,     r15
	com   r16
	brne  xmb_creg_fault_02
	eor   r17,     r14
	com   r17
	brne  xmb_creg_fault_02
	eor   r18,     r13
	com   r18
	brne  xmb_creg_fault_02
	eor   r19,     r12
	com   r19
	brne  xmb_creg_fault_02
	eor   r20,     r11
	com   r20
	brne  xmb_creg_fault_02
	eor   r21,     r10
	com   r21
	brne  xmb_creg_fault_02
	eor   r22,     r9
	com   r22
	brne  xmb_creg_fault_02
	eor   r23,     r8
	com   r23
	brne  xmb_creg_fault_02
	eor   r24,     r7
	com   r24
	brne  xmb_creg_fault_02
	eor   r25,     r6
	com   r25
	brne  xmb_creg_fault_02
	eor   XL,      r5
	com   XL
	brne  xmb_creg_fault_02
	eor   XH,      r4
	com   XH
	brne  xmb_creg_fault_02
	eor   YL,      r3
	com   YL
	brne  xmb_creg_fault_02
	eor   YH,      r2
	com   YH
	brne  xmb_creg_fault_02
	eor   ZL,      r1
	com   ZL
	brne  xmb_creg_fault_02
	eor   ZH,      r0
	com   ZH
	breq  xmb_creg_1ovr

xmb_creg_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_1ovr:
	or    r16,     r17
	brne  xmb_creg_fault_02
	or    r18,     r19
	brne  xmb_creg_fault_02
	or    r20,     r21
	brne  xmb_creg_fault_02
	or    r22,     r23
	brne  xmb_creg_fault_02
	or    r24,     r25
	brne  xmb_creg_fault_02
	or    XL,      XH
	brne  xmb_creg_fault_02
	or    YL,      YH
	brne  xmb_creg_fault_02
	or    ZL,      ZH
	brne  xmb_creg_fault_02

xmb_creg_1inv:

	ldi   ZL,      lo8(xmb_creg_lowrd_1i)
	ldi   ZH,      hi8(xmb_creg_lowrd_1i)
	lpm   r15,     Z+
	lpm   r14,     Z+
	lpm   r13,     Z+
	lpm   r12,     Z+
	lpm   r11,     Z+
	lpm   r10,     Z+
	lpm   r9,      Z+
	lpm   r8,      Z+
	lpm   r7,      Z+
	lpm   r6,      Z+
	lpm   r5,      Z+
	lpm   r4,      Z+
	lpm   r3,      Z+
	lpm   r2,      Z+
	lpm   r1,      Z+
	lpm   r0,      Z
	ldi   ZH,      0x8D
	ldi   ZL,      0x39
	ldi   YH,      0x9C
	ldi   YL,      0x74
	ldi   XH,      0x6A
	ldi   XL,      0x5A
	ldi   r25,     0xC5
	ldi   r24,     0x8B
	ldi   r23,     0xA6
	ldi   r22,     0x1B
	ldi   r21,     0xC6
	ldi   r20,     0x4E
	ldi   r19,     0x2B
	ldi   r18,     0xD2
	ldi   r17,     0x71
	ldi   r16,     0x3A
	sec
	adc   r0,      ZH
	brne  xmb_creg_fault_03
	adc   r1,      ZL
	brne  xmb_creg_fault_03
	adc   r2,      YH
	brne  xmb_creg_fault_03
	adc   r3,      YL
	brne  xmb_creg_fault_03
	adc   r4,      XH
	brne  xmb_creg_fault_03
	adc   r5,      XL
	brne  xmb_creg_fault_03
	adc   r6,      r25
	brne  xmb_creg_fault_03
	adc   r7,      r24
	brne  xmb_creg_fault_03
	adc   r8,      r23
	brne  xmb_creg_fault_03
	adc   r9,      r22
	brne  xmb_creg_fault_03
	adc   r10,     r21
	brne  xmb_creg_fault_03
	adc   r11,     r20
	brne  xmb_creg_fault_03
	adc   r12,     r19
	brne  xmb_creg_fault_03
	adc   r13,     r18
	brne  xmb_creg_fault_03
	adc   r14,     r17
	brne  xmb_creg_fault_03
	adc   r15,     r16
	breq  xmb_creg_sreg

xmb_creg_fault_03:
	ldi   r24,     0x03
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_sreg:

	; Tests of important IO registers. Now assume the CPU registers
	; behave correctly, so things can be saved to them and restored.

	; Status Register. Also test bit clear and set instructions affecting
	; this register.

	in    r0,      SR_IO  ; Store original value ('I' flag)
	ldi   r17,     0x00
	out   SR_IO,   r17    ; Interrupts disabled

	sen
	in    r15,     SR_IO
	sei                   ; Interrupts enabled
	ldi   r18,     0x04
	cpse  r15,     r18    ; ithsvNzc
	rjmp  xmb_creg_fault_04
	in    r14,     SR_IO
	ldi   r19,     0x84
	cpse  r14,     r19    ; IthsvNzc
	rjmp  xmb_creg_fault_04
	ses
	in    r13,     SR_IO
	ldi   r20,     0x94
	cpse  r20,     r13    ; IthSvNzc
	rjmp  xmb_creg_fault_04
	sez
	in    r12,     SR_IO
	ldi   r21,     0x96
	cpse  r21,     r12    ; IthSvNZc
	rjmp  xmb_creg_fault_04
	seh
	in    r11,     SR_IO
	ldi   r22,     0xB6
	cpse  r11,     r22    ; ItHSvNZc
	rjmp  xmb_creg_fault_04
	cls
	in    r10,     SR_IO
	ldi   r23,     0xA6
	cpse  r23,     r10    ; ItHsvNZc
	rjmp  xmb_creg_fault_04
	sec
	in    r9,      SR_IO
	ldi   r24,     0xA7
	cpse  r9,      r24    ; ItHsvNZC
	rjmp  xmb_creg_fault_04
	cln
	in    r8,      SR_IO
	ldi   r25,     0xA3
	cpse  r25,     r8     ; ItHsvnZC
	rjmp  xmb_creg_fault_04
	set
	in    r7,      SR_IO
	ldi   XL,      0xE3
	cpse  XL,      r7     ; ITHsvnZC
	rjmp  xmb_creg_fault_04
	clh
	in    r6,      SR_IO
	ldi   XH,      0xC3
	cpse  r6,      XH     ; IThsvnZC
	rjmp  xmb_creg_fault_04
	sev
	in    r5,      SR_IO
	ldi   YL,      0xCB
	cpse  r5,      YL     ; IThsVnZC
	rjmp  xmb_creg_fault_04
	clz
	in    r4,      SR_IO
	ldi   YH,      0xC9
	cpse  YH,      r4     ; IThsVnzC
	rjmp  xmb_creg_fault_04
	clc
	in    r3,      SR_IO
	ldi   ZL,      0xC8
	cpse  r3,      ZL     ; IThsVnzc
	rjmp  xmb_creg_fault_04
	clt
	in    r2,      SR_IO
	ldi   ZH,      0x88
	cpse  ZH,      r2     ; IthsVnzc
	rjmp  xmb_creg_fault_04
	ldi   r18,     0x08
	ldi   r19,     0x00
	cli                   ; Interrupts disabled
	in    r1,      SR_IO
	cpse  r18,     r1     ; ithsVnzc
	rjmp  xmb_creg_fault_04
	clv
	in    r1,      SR_IO
	out   SR_IO,   r0     ; Restore saved SREG with whatever 'I' flag it had
	cpse  r19,     r1     ; ithsvnzc
	rjmp  xmb_creg_fault_04
	rjmp  xmb_creg_sr1

xmb_creg_fault_04:
	out   SR_IO,   r0     ; Restore saved SREG with whatever 'I' flag it had
	ldi   r24,     0x04
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_sr1:

	ldi   r16,     0xFF
	ldi   r17,     0x00
	out   SR_IO,   r16
	in    r17,     SR_IO
	cpse  r17,     r16
	rjmp  xmb_creg_fault_05
	com   r17
	out   SR_IO,   r17    ; Interrupts disabled
	in    r16,     SR_IO
	cpse  r16,     r17
	rjmp  xmb_creg_fault_05
	out   SR_IO,   r0     ; Restore saved SREG with whatever 'I' flag it had
	rjmp  xmb_creg_sp

xmb_creg_fault_05:
	out   SR_IO,   r0     ; Restore saved SREG with whatever 'I' flag it had
	ldi   r24,     0x05
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_sp:

	; Stack pointer. High bits beyond the internal RAM of the AVR may not
	; be implemented, so mask those.

	in    r2,      SPL_IO
	in    r3,      SPH_IO ; Save current stack pointer

	ldi   r16,     0xFF
	ldi   r17,     0x00
	cli                   ; Interrupts disabled
	out   SPL_IO,  r16
	out   SPH_IO,  r17
	in    r16,     SPH_IO
	in    r17,     SPL_IO
	out   SPL_IO,  r2     ; Restore saved stack pointer
	out   SPH_IO,  r3
	out   SR_IO,   r0     ; Restore saved SREG with whatever 'I' flag it had
	cpi   r16,     0x00
	brne  xmb_creg_fault_06
	cpi   r17,     0xFF
	brne  xmb_creg_fault_06

	ldi   r16,     0xAA
	ldi   r17,     0x55
	cli
	out   SPL_IO,  r16
	out   SPH_IO,  r17
	in    r16,     SPH_IO
	in    r17,     SPL_IO
	out   SPL_IO,  r2     ; Restore saved stack pointer
	out   SPH_IO,  r3
	out   SR_IO,   r0     ; Restore saved SREG with whatever 'I' flag it had
.if (RAMEND < 256)
	andi  r16,     0x00
	cpi   r16,     0x00
.else
.if (RAMEND < 512)
	andi  r16,     0x01
	cpi   r16,     0x01
.else
.if (RAMEND < 1024)
	andi  r16,     0x03
	cpi   r16,     0x01
.else
.if (RAMEND < 2048)
	andi  r16,     0x07
	cpi   r16,     0x05
.else
.if (RAMEND < 4096)
	andi  r16,     0x0F
	cpi   r16,     0x05
.else
.if (RAMEND < 8192)
	andi  r16,     0x1F
	cpi   r16,     0x15
.else
.if (RAMEND < 16384)
	andi  r16,     0x3F
	cpi   r16,     0x15
.else
.if (RAMEND < 32768)
	andi  r16,     0x7F
	cpi   r16,     0x55
.else
	cpi   r16,     0x55
.endif
.endif
.endif
.endif
.endif
.endif
.endif
.endif
	brne  xmb_creg_fault_06
	cpi   r17,     0xAA
	brne  xmb_creg_fault_06

	ldi   r16,     0x00
	ldi   r17,     0xFF
	cli
	out   SPL_IO,  r16
	out   SPH_IO,  r17
	in    r16,     SPH_IO
	in    r17,     SPL_IO
	out   SPL_IO,  r2     ; Restore saved stack pointer
	out   SPH_IO,  r3
	out   SR_IO,   r0     ; Restore saved SREG with whatever 'I' flag it had
.if (RAMEND < 256)
	andi  r16,     0x00
	cpi   r16,     0x00
.else
.if (RAMEND < 512)
	andi  r16,     0x01
	cpi   r16,     0x01
.else
.if (RAMEND < 1024)
	andi  r16,     0x03
	cpi   r16,     0x03
.else
.if (RAMEND < 2048)
	andi  r16,     0x07
	cpi   r16,     0x07
.else
.if (RAMEND < 4096)
	andi  r16,     0x0F
	cpi   r16,     0x0F
.else
.if (RAMEND < 8192)
	andi  r16,     0x1F
	cpi   r16,     0x1F
.else
.if (RAMEND < 16384)
	andi  r16,     0x3F
	cpi   r16,     0x3F
.else
.if (RAMEND < 32768)
	andi  r16,     0x7F
	cpi   r16,     0x7F
.else
	cpi   r16,     0xFF
.endif
.endif
.endif
.endif
.endif
.endif
.endif
.endif
	brne  xmb_creg_fault_06
	cpi   r17,     0x00
	brne  xmb_creg_fault_06

	ldi   r16,     0x55
	ldi   r17,     0xAA
	cli
	out   SPL_IO,  r16
	out   SPH_IO,  r17
	in    r16,     SPH_IO
	in    r17,     SPL_IO
	out   SPL_IO,  r2     ; Restore saved stack pointer
	out   SPH_IO,  r3
	out   SR_IO,   r0     ; Restore saved SREG with whatever 'I' flag it had
.if (RAMEND < 256)
	andi  r16,     0x00
	cpi   r16,     0x00
.else
.if (RAMEND < 512)
	andi  r16,     0x01
	cpi   r16,     0x00
.else
.if (RAMEND < 1024)
	andi  r16,     0x03
	cpi   r16,     0x02
.else
.if (RAMEND < 2048)
	andi  r16,     0x07
	cpi   r16,     0x02
.else
.if (RAMEND < 4096)
	andi  r16,     0x0F
	cpi   r16,     0x0A
.else
.if (RAMEND < 8192)
	andi  r16,     0x1F
	cpi   r16,     0x0A
.else
.if (RAMEND < 16384)
	andi  r16,     0x3F
	cpi   r16,     0x2A
.else
.if (RAMEND < 32768)
	andi  r16,     0x7F
	cpi   r16,     0x2A
.else
	cpi   r16,     0xAA
.endif
.endif
.endif
.endif
.endif
.endif
.endif
.endif
	brne  xmb_creg_fault_06
	cpi   r17,     0x55
	breq  xmb_creg_spe

xmb_creg_fault_06:
	ldi   r24,     0x06
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_spe:

	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next



xmb_creg_lowrd_s:
	.byte 0x55, 0xAA, 0x1E, 0x96, 0xC3, 0xF0, 0x72, 0x4D
	.byte 0x63, 0x59, 0x87, 0x99, 0xB8, 0xA9, 0xD1, 0x35

xmb_creg_lowrd_i:
	.byte 0xAA, 0x55, 0xE1, 0x69, 0x3C, 0x0F, 0x8D, 0xB2
	.byte 0x9C, 0xA6, 0x78, 0x66, 0x47, 0x56, 0x2E, 0xCA

xmb_creg_lowrd_1s:
	.byte 0x3A, 0x71, 0xD2, 0x2B, 0x4E, 0xC6, 0x1B, 0xA6
	.byte 0x8B, 0xC5, 0x5A, 0x6A, 0x74, 0x9C, 0x39, 0x8D

xmb_creg_lowrd_1i:
	.byte 0xC5, 0x8E, 0x2D, 0xD4, 0xB1, 0x39, 0xE4, 0x59
	.byte 0x74, 0x3A, 0xA5, 0x95, 0x8B, 0x63, 0xC6, 0x72



;
; Test entry points
;
.global xmb_creg_cr0
.global xmb_creg_cr1
.global xmb_creg_sreg
.global xmb_creg_sp

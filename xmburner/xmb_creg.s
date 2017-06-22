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
; This component tests CPU and critical IO registers for stuck bits and proper
; addressing. Also tests the bit set and clear instructions operating on SREG.
;
; Preserves interrupt enable status ('I' flag in SREG), but it enables
; interrupts for brief periods even if they were disabled to test the flag.
;

.include "xmb_defs.inc"


.section .text


.set xmb_creg_chain_from 0xE0D43BA5
.set xmb_creg_chain      0xE0D43BA5


.global xmb_creg
xmb_creg:

	; Test execution chain

	subi  r16,     (xmb_reg_chain_from      ) & 0xFF
	sbci  r17,     (xmb_reg_chain_from >>  8) & 0xFF
	sbci  r18,     (xmb_reg_chain_from >> 16) & 0xFF
	sbci  r19,     (xmb_reg_chain_from >> 24) & 0xFF
	breq  xmb_creg_0

xmb_creg_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_0:

	; CPU register test: Load every register with different values, then
	; do the inverse. This catches individual bits stuck set or clear, and
	; due to the different values, is also likely to catch addressing
	; flaws or if writes affect each other across registers. A different
	; checking method is used for the inverse run to reduce the likelihood
	; of common mode failure.

	lds   r0,      xmb_creg_lowrd_s + 0
	lds   r1,      xmb_creg_lowrd_s + 1
	lds   r2,      xmb_creg_lowrd_s + 2
	lds   r3,      xmb_creg_lowrd_s + 3
	lds   r4,      xmb_creg_lowrd_s + 4
	lds   r5,      xmb_creg_lowrd_s + 5
	lds   r6,      xmb_creg_lowrd_s + 6
	lds   r7,      xmb_creg_lowrd_s + 7
	lds   r8,      xmb_creg_lowrd_s + 8
	lds   r9,      xmb_creg_lowrd_s + 9
	lds   r10,     xmb_creg_lowrd_s + 10
	lds   r11,     xmb_creg_lowrd_s + 11
	lds   r12,     xmb_creg_lowrd_s + 12
	lds   r13,     xmb_creg_lowrd_s + 13
	lds   r14,     xmb_creg_lowrd_s + 14
	lds   r15,     xmb_creg_lowrd_s + 15
	ldi   r16,     0xAA
	ldi   r17,     0x55
	ldi   r18,     0xE1
	ldi   r19,     0x69
	ldi   r20,     0x3C
	ldi   r21,     0x0F
	ldi   r22,     0x8D
	ldi   r23,     0xB2
	ldi   r24,     0x9C
	ldi   r25,     0xA6
	ldi   XL,      0x78
	ldi   XH,      0x66
	ldi   YL,      0x47
	ldi   YH,      0x56
	ldi   ZL,      0x2E
	ldi   ZH,      0xCA
	eor   r0,      r16
	brne  xmb_creg_fault_00
	eor   r1,      r17
	brne  xmb_creg_fault_00
	eor   r2,      r18
	brne  xmb_creg_fault_00
	eor   r3,      r19
	brne  xmb_creg_fault_00
	eor   r4,      r20
	brne  xmb_creg_fault_00
	eor   r5,      r21
	brne  xmb_creg_fault_00
	eor   r6,      r22
	brne  xmb_creg_fault_00
	eor   r7,      r23
	brne  xmb_creg_fault_00
	eor   r8,      r24
	brne  xmb_creg_fault_00
	eor   r9,      r25
	brne  xmb_creg_fault_00
	eor   r10,     XL
	brne  xmb_creg_fault_00
	eor   r11,     XH
	brne  xmb_creg_fault_00
	eor   r12,     YL
	brne  xmb_creg_fault_00
	eor   r13,     YH
	brne  xmb_creg_fault_00
	eor   r14,     ZL
	brne  xmb_creg_fault_00
	eor   r15,     ZH
	breq  xmb_creg_inv

xmb_creg_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_inv:

	lds   r0,      xmb_creg_lowrd_i + 0
	lds   r1,      xmb_creg_lowrd_i + 1
	lds   r2,      xmb_creg_lowrd_i + 2
	lds   r3,      xmb_creg_lowrd_i + 3
	lds   r4,      xmb_creg_lowrd_i + 4
	lds   r5,      xmb_creg_lowrd_i + 5
	lds   r6,      xmb_creg_lowrd_i + 6
	lds   r7,      xmb_creg_lowrd_i + 7
	lds   r8,      xmb_creg_lowrd_i + 8
	lds   r9,      xmb_creg_lowrd_i + 9
	lds   r10,     xmb_creg_lowrd_i + 10
	lds   r11,     xmb_creg_lowrd_i + 11
	lds   r12,     xmb_creg_lowrd_i + 12
	lds   r13,     xmb_creg_lowrd_i + 13
	lds   r14,     xmb_creg_lowrd_i + 14
	lds   r15,     xmb_creg_lowrd_i + 15
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
	ldi   ZL,      0xD1
	ldi   ZH,      0x35
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
	breq  xmb_creg_1

xmb_creg_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_1:

	; A second pass of a similar test with different bit patterns and
	; register comparison pairings. The patterns are selected to be
	; distinct from the patterns previously used on each register to
	; increase the chance of detecting bits affecting each other in
	; individual registers.

	ldi   ZH,      0xC5
	ldi   ZL,      0x8E
	ldi   YH,      0x2D
	ldi   YL,      0xD4
	ldi   XH,      0xB1
	ldi   XL,      0x39
	ldi   r25,     0xE4
	ldi   r24,     0x59
	ldi   r23,     0x74
	ldi   r22,     0x3A
	ldi   r21,     0xA5
	ldi   r20,     0x95
	ldi   r19,     0x8B
	ldi   r18,     0x63
	ldi   r17,     0xC6
	ldi   r16,     0x72
	lds   r15,     xmb_creg_lowrd_1s + 15
	lds   r14,     xmb_creg_lowrd_1s + 14
	lds   r13,     xmb_creg_lowrd_1s + 13
	lds   r12,     xmb_creg_lowrd_1s + 12
	lds   r11,     xmb_creg_lowrd_1s + 11
	lds   r10,     xmb_creg_lowrd_1s + 10
	lds   r9,      xmb_creg_lowrd_1s + 9
	lds   r8,      xmb_creg_lowrd_1s + 8
	lds   r7,      xmb_creg_lowrd_1s + 7
	lds   r6,      xmb_creg_lowrd_1s + 6
	lds   r5,      xmb_creg_lowrd_1s + 5
	lds   r4,      xmb_creg_lowrd_1s + 4
	lds   r3,      xmb_creg_lowrd_1s + 3
	lds   r2,      xmb_creg_lowrd_1s + 2
	lds   r1,      xmb_creg_lowrd_1s + 1
	lds   r0,      xmb_creg_lowrd_1s + 0
	eor   r15,     r16
	brne  xmb_creg_fault_02
	eor   r14,     r17
	brne  xmb_creg_fault_02
	eor   r13,     r18
	brne  xmb_creg_fault_02
	eor   r12,     r19
	brne  xmb_creg_fault_02
	eor   r11,     r20
	brne  xmb_creg_fault_02
	eor   r10,     r21
	brne  xmb_creg_fault_02
	eor   r9,      r22
	brne  xmb_creg_fault_02
	eor   r8,      r23
	brne  xmb_creg_fault_02
	eor   r7,      r24
	brne  xmb_creg_fault_02
	eor   r6,      r25
	brne  xmb_creg_fault_02
	eor   r5,      XL
	brne  xmb_creg_fault_02
	eor   r4,      XH
	brne  xmb_creg_fault_02
	eor   r3,      YL
	brne  xmb_creg_fault_02
	eor   r2,      YH
	brne  xmb_creg_fault_02
	eor   r1,      ZL
	brne  xmb_creg_fault_02
	eor   r0,      ZH
	breq  xmb_creg_1inv

xmb_creg_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_1inv:

	ldi   ZH,      0x3A
	ldi   ZL,      0x71
	ldi   YH,      0xD2
	ldi   YL,      0x2B
	ldi   XH,      0x4E
	ldi   XL,      0xC6
	ldi   r25,     0x1B
	ldi   r24,     0xA6
	ldi   r23,     0x8B
	ldi   r22,     0xC5
	ldi   r21,     0x5A
	ldi   r20,     0x6A
	ldi   r19,     0x74
	ldi   r18,     0x9C
	ldi   r17,     0x39
	ldi   r16,     0x8D
	lds   r15,     xmb_creg_lowrd_1i + 15
	lds   r14,     xmb_creg_lowrd_1i + 14
	lds   r13,     xmb_creg_lowrd_1i + 13
	lds   r12,     xmb_creg_lowrd_1i + 12
	lds   r11,     xmb_creg_lowrd_1i + 11
	lds   r10,     xmb_creg_lowrd_1i + 10
	lds   r9,      xmb_creg_lowrd_1i + 9
	lds   r8,      xmb_creg_lowrd_1i + 8
	lds   r7,      xmb_creg_lowrd_1i + 7
	lds   r6,      xmb_creg_lowrd_1i + 6
	lds   r5,      xmb_creg_lowrd_1i + 5
	lds   r4,      xmb_creg_lowrd_1i + 4
	lds   r3,      xmb_creg_lowrd_1i + 3
	lds   r2,      xmb_creg_lowrd_1i + 2
	lds   r1,      xmb_creg_lowrd_1i + 1
	lds   r0,      xmb_creg_lowrd_1i + 0
	sec
	adc   ZH,      r0
	brne  xmb_creg_fault_03
	adc   ZL,      r1
	brne  xmb_creg_fault_03
	adc   YH,      r2
	brne  xmb_creg_fault_03
	adc   YL,      r3
	brne  xmb_creg_fault_03
	adc   XH,      r4
	brne  xmb_creg_fault_03
	adc   XL,      r5
	brne  xmb_creg_fault_03
	adc   r25,     r6
	brne  xmb_creg_fault_03
	adc   r24,     r7
	brne  xmb_creg_fault_03
	adc   r23,     r8
	brne  xmb_creg_fault_03
	adc   r22,     r9
	brne  xmb_creg_fault_03
	adc   r21,     r10
	brne  xmb_creg_fault_03
	adc   r20,     r11
	brne  xmb_creg_fault_03
	adc   r19,     r12
	brne  xmb_creg_fault_03
	adc   r18,     r13
	brne  xmb_creg_fault_03
	adc   r17,     r14
	brne  xmb_creg_fault_03
	adc   r16,     r15
	breq  xmb_creg_ext

xmb_creg_fault_03:
	ldi   r24,     0x03
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_ext:

	; Tests of important IO registers. Now assume the CPU registers
	; behave correctly, so things can be saved to them and restored.

	; Status Register. Also test bit clear and set instructions affecting
	; this register.

	in    r0,      SREG    ; Store original value ('I' flag)

	ldi   r16,     0xFF
	ldi   r17,     0x00
	out   SREG,    r16
	in    r17,     SREG
	cpi   r17,     0xFF
	brne  xmb_creg_fault_04
	com   r17
	out   SREG,    r17
	in    r16,     SREG
	cpi   r16,     0x00
	breq  xmb_creg_sr1

xmb_creg_fault_04:
	out   SREG,    r0     ; Restore saved SREG with whatever 'I' flag it had
	ldi   r24,     0x04
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_sr1:

	sen
	in    r16,     SREG
	cpi   r16,     0x04   ; ithsvNzc
	brne  xmb_creg_fault_05
	ses
	in    r16,     SREG
	cpi   r16,     0x14   ; ithSvNzc
	brne  xmb_creg_fault_05
	sei
	in    r16,     SREG
	cpi   r16,     0x94   ; IthSvNzc
	brne  xmb_creg_fault_05
	sez
	in    r16,     SREG
	cpi   r16,     0x96   ; IthSvNZc
	brne  xmb_creg_fault_05
	seh
	in    r16,     SREG
	cpi   r16,     0xB6   ; ItHSvNZc
	brne  xmb_creg_fault_05
	cls
	in    r16,     SREG
	cpi   r16,     0xA6   ; ItHsvNZc
	brne  xmb_creg_fault_05
	sec
	in    r16,     SREG
	cpi   r16,     0xA7   ; ItHsvNZC
	brne  xmb_creg_fault_05
	cln
	in    r16,     SREG
	cpi   r16,     0xA3   ; ItHsvnZC
	brne  xmb_creg_fault_05
	set
	in    r16,     SREG
	cpi   r16,     0xE3   ; ITHsvnZC
	brne  xmb_creg_fault_05
	cli
	in    r16,     SREG
	cpi   r16,     0x63   ; iTHsvnZC
	brne  xmb_creg_fault_05
	sev
	in    r16,     SREG
	cpi   r16,     0x6B   ; iTHsVnZC
	brne  xmb_creg_fault_05
	clh
	in    r16,     SREG
	cpi   r16,     0x4B   ; iThsVnZC
	brne  xmb_creg_fault_05
	clz
	in    r16,     SREG
	cpi   r16,     0x49   ; iThsVnzC
	brne  xmb_creg_fault_05
	clc
	in    r16,     SREG
	cpi   r16,     0x48   ; iThsVnzc
	brne  xmb_creg_fault_05
	clt
	in    r16,     SREG
	cpi   r16,     0x08   ; ithsVnzc
	brne  xmb_creg_fault_05
	clv
	in    r16,     SREG
	cpi   r16,     0x00   ; ithsvnzc
	breq  xmb_creg_sr2

xmb_creg_fault_05:
	out   SREG,    r0     ; Restore saved SREG with whatever 'I' flag it had
	ldi   r24,     0x05
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_sr2:

	out   SREG,    r0     ; Restore saved SREG with whatever 'I' flag it had

	; Stack pointer. Interrupts are disabled during the tests. High bits
	; beyond the internal RAM of the AVR may not be implemented, so mask
	; those.

	cli
	in    r2,      SPL
	in    r3,      SPH    ; Save current stack pointer

	ldi   r16,     0xFF
	ldi   r17,     0x00
	out   SPL,     r16
	out   SPH,     r17
	in    r16,     SPH
	in    r17,     SPL
	cpi   r16,     0x00
	brne  xmb_creg_fault_06
	cpi   r17,     0xFF
	brne  xmb_creg_fault_06

	ldi   r16,     0xAA
	ldi   r17,     0x55
	out   SPL,     r16
	out   SPH,     r17
	in    r16,     SPH
	in    r17,     SPL
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
	out   SPL,     r16
	out   SPH,     r17
	in    r16,     SPH
	in    r17,     SPL
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
	out   SPL,     r16
	out   SPH,     r17
	in    r16,     SPH
	in    r17,     SPL
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
	breq  xmb_creg_sp

xmb_creg_fault_06:
	out   SREG,    r0     ; Restore saved SREG with whatever 'I' flag it had
	out   SPL,     r2     ; Restore saved stack pointer
	out   SPH,     r3
	ldi   r24,     0x06
	ldi   r25,     0x00
	jmp   XMB_FAULT

xmb_creg_sp:

	out   SREG,    r0     ; Restore saved SREG with whatever 'I' flag it had
	out   SPL,     r2     ; Restore saved stack pointer
	out   SPH,     r3

	; Set up execution chain for next element & Return

	ldi   r16,     (xmb_reg_chain      ) & 0xFF
	ldi   r17,     (xmb_reg_chain >>  8) & 0xFF
	ldi   r18,     (xmb_reg_chain >> 16) & 0xFF
	ldi   r19,     (xmb_reg_chain >> 24) & 0xFF
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

;
; XMBurner - (0x06) Subtract instruction test
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
; - The SUB and SUBI instructions including SREG operations.
; - The CP and CPI instructions for SREG operations.
; - The SBC and SBCI instructions including SREG operations.
; - The CPC instruction for SREG operations.
; - The MOV instruction with some operand combinations.
;
; Interrupts are enabled after this component (it also doesn't disable them).
;

#include "xmb_defs.h"


.section .text


.set exec_id_from, 0x7E3CE0B6
.set exec_id,      0xD0598A1F

.set SR_IO,  _SFR_IO_ADDR(SREG)


.global xmb_sub
xmb_sub:

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
	brne  xmb_sub_fault_ff
	brcs  xmb_sub_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_sub_fault_ff
	brcs  xmb_sub_test

xmb_sub_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x06
	jmp   XMB_FAULT

xmb_sub_test:

	; 8 bit subtraction type instructions are the followings:
	;
	; SUB, CP,  SUBI, CPI
	; SBC, CPC, SBCI
	;
	; The following truth table applies for each bit:
	;
	; +-----+-----+-----++-----+-----+
	; | dst | src |  cy || res |  cy |
	; +=====+=====+=====++=====+=====+
	; |  0  |  0  |  0  ||  0  |  0  |
	; +-----+-----+-----++-----+-----+
	; |  0  |  0  |  1  ||  1  |  1  |
	; +-----+-----+-----++-----+-----+
	; |  0  |  1  |  0  ||  1  |  1  |
	; +-----+-----+-----++-----+-----+
	; |  0  |  1  |  1  ||  0  |  1  |
	; +-----+-----+-----++-----+-----+
	; |  1  |  0  |  0  ||  1  |  0  |
	; +-----+-----+-----++-----+-----+
	; |  1  |  0  |  1  ||  0  |  0  |
	; +-----+-----+-----++-----+-----+
	; |  1  |  1  |  0  ||  0  |  0  |
	; +-----+-----+-----++-----+-----+
	; |  1  |  1  |  1  ||  1  |  1  |
	; +-----+-----+-----++-----+-----+
	;
	; The tests attempt to excercise all input combinations on each of the
	; bits on all of the above instructions, verifying the output (result
	; where available, flags).

	ldi   r16,     0x1E    ; 0x1E (00011110) -
	ldi   r17,     0x1E    ; 0x1E (00011110) -
	ldi   r20,     0x80    ;    0 (       0) Ithsvnzc Input flags
	ldi   r18,     0x00    ; 0x00 (00000000) Result
	ldi   r19,     0x82    ; Output flags:   IthsvnZc (SUB, CP, SUBI, CPI)
	ldi   r22,     0x80    ; Output flags:   Ithsvnzc (SBC, CPC, SBCI)
	movw  r4,      r16
	out   SR_IO,   r20
	sub   r4,      r5      ; SUB
	in    r6,      SR_IO
	cpse  r4,      r18
	rjmp  xmb_sub_fault_00
	cpse  r6,      r19
	rjmp  xmb_sub_fault_00
	mov   r4,      r16
	out   SR_IO,   r20
	cp    r4,      r5      ; CP
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_01
	out   SR_IO,   r20
	subi  r16,     0x1E    ; SUBI
	in    r6,      SR_IO
	cpse  r16,     r18
	rjmp  xmb_sub_fault_02
	cpse  r6,      r19
	rjmp  xmb_sub_fault_02
	mov   r16,     r4
	out   SR_IO,   r20
	cpi   r16,     0x1E    ; CPI
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_03
	out   SR_IO,   r20
	sbc   r4,      r5      ; SBC
	in    r6,      SR_IO
	cpse  r4,      r18
	rjmp  xmb_sub_fault_04
	cpse  r6,      r22
	rjmp  xmb_sub_fault_04
	mov   r4,      r16
	out   SR_IO,   r20
	cpc   r4,      r5      ; CPC
	in    r6,      SR_IO
	cpse  r6,      r22
	rjmp  xmb_sub_fault_05
	out   SR_IO,   r20
	sbci  r16,     0x1E    ; SBCI
	in    r6,      SR_IO
	cpse  r16,     r18
	rjmp  xmb_sub_fault_06
	cpse  r6,      r22
	rjmp  xmb_sub_fault_06

	ldi   XL,      0xE1    ; 0xE1 (11100001) -
	ldi   XH,      0xE1    ; 0xE1 (11100001) -
	ldi   r20,     0xFE    ;    0 (       0) ITHSVNZc Input flags
	ldi   r18,     0x00    ; 0x00 (00000000) Result
	ldi   r19,     0xC2    ; Output flags:   IThsvnZc
	mov   r8,      XL
	out   SR_IO,   r20
	sub   XL,      XH      ; SUB
	in    r6,      SR_IO
	cpse  XL,      r18
	rjmp  xmb_sub_fault_00
	cpse  r6,      r19
	rjmp  xmb_sub_fault_00
	mov   XL,      r8
	out   SR_IO,   r20
	cp    XL,      XH      ; CP
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_01
	out   SR_IO,   r20
	subi  XL,      0xE1    ; SUBI
	in    r6,      SR_IO
	cpse  XL,      r18
	rjmp  xmb_sub_fault_02
	cpse  r6,      r19
	rjmp  xmb_sub_fault_02
	mov   XL,      r8
	out   SR_IO,   r20
	cpi   XL,      0xE1    ; CPI
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_03
	out   SR_IO,   r20
	sbc   XL,      XH      ; SBC
	in    r6,      SR_IO
	cpse  XL,      r18
	rjmp  xmb_sub_fault_04
	cpse  r6,      r19
	rjmp  xmb_sub_fault_04
	mov   XL,      r8
	out   SR_IO,   r20
	cpc   XL,      XH      ; CPC
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_05
	out   SR_IO,   r20
	sbci  XL,      0xE1    ; SBCI
	in    r6,      SR_IO
	cpse  XL,      r18
	rjmp  xmb_sub_fault_06
	cpse  r6,      r19
	rjmp  xmb_sub_fault_06

	ldi   r16,     0x8A    ; 0x8A (10001010) -
	ldi   r17,     0x8B    ; 0x8B (10001011) -
	ldi   r20,     0x81    ;    * (       *) IthsvnzC Input flags
	ldi   r18,     0xFF    ; 0xFF (11111111) Result
	ldi   r19,     0xB5    ; Output flags:   ItHSvNzC
	movw  r10,     r16
	out   SR_IO,   r20
	sub   r10,     r11     ; SUB
	in    r6,      SR_IO
	cpse  r10,     r18
	rjmp  xmb_sub_fault_00
	cpse  r6,      r19
	rjmp  xmb_sub_fault_00
	mov   r10,     r16
	out   SR_IO,   r20
	cp    r10,     r11     ; CP
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_01
	out   SR_IO,   r20
	subi  r16,     0x8B    ; SUBI
	in    r6,      SR_IO
	cpse  r16,     r18
	rjmp  xmb_sub_fault_02
	cpse  r6,      r19
	rjmp  xmb_sub_fault_02
	mov   r16,     r10
	out   SR_IO,   r20
	cpi   r16,     0x8B    ; CPI
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_03
	out   SR_IO,   r20
	ldi   r16,     0x8B    ; 0x8B (10001011) Destination (Carry OK)
	mov   r10,     r16
	sbc   r10,     r11     ; SBC
	in    r6,      SR_IO
	cpse  r10,     r18
	rjmp  xmb_sub_fault_04
	cpse  r6,      r19
	rjmp  xmb_sub_fault_04
	mov   r10,     r16
	out   SR_IO,   r20
	cpc   r10,     r11     ; CPC
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_05
	out   SR_IO,   r20
	sbci  r16,     0x8B    ; SBCI
	in    r6,      SR_IO
	cpse  r16,     r18
	rjmp  xmb_sub_fault_06
	cpse  r6,      r19
	rjmp  xmb_sub_fault_06

	ldi   ZL,      0x74    ; 0x74 (01110100) -
	ldi   ZH,      0x75    ; 0x75 (01110101) -
	ldi   r20,     0xFF    ;    * (       *) ITHSVNZC Input flags
	ldi   r18,     0xFF    ; 0xFF (11111111) Result
	ldi   r19,     0xF5    ; Output flags:   ITHSvNzC
	mov   r1,      ZL
	out   SR_IO,   r20
	sub   ZL,      ZH      ; SUB
	in    r6,      SR_IO
	cpse  ZL,      r18
	rjmp  xmb_sub_fault_00
	cpse  r6,      r19
	rjmp  xmb_sub_fault_00
	mov   ZL,      r1
	out   SR_IO,   r20
	cp    ZL,      ZH      ; CP
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_01
	out   SR_IO,   r20
	subi  ZL,      0x75    ; SUBI
	in    r6,      SR_IO
	cpse  ZL,      r18
	rjmp  xmb_sub_fault_02
	cpse  r6,      r19
	rjmp  xmb_sub_fault_02
	mov   ZL,      r1
	out   SR_IO,   r20
	cpi   ZL,      0x75    ; CPI
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_03
	out   SR_IO,   r20
	ldi   ZH,      0x74    ; 0x74 (01110100) Source (Carry OK)
	sbc   ZL,      ZH      ; SBC
	in    r6,      SR_IO
	cpse  ZL,      r18
	rjmp  xmb_sub_fault_04
	cpse  r6,      r19
	rjmp  xmb_sub_fault_04
	mov   ZL,      r1
	out   SR_IO,   r20
	cpc   ZL,      ZH      ; CPC
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_05
	out   SR_IO,   r20
	sbci  ZL,      0x74    ; SBCI
	in    r6,      SR_IO
	cpse  ZL,      r18
	rjmp  xmb_sub_fault_06
	cpse  r6,      r19
	rjmp  xmb_sub_fault_06

	ldi   YL,      0xAA    ; 0xAA (10101010) -
	ldi   YH,      0x55    ; 0x55 (01010101) -
	ldi   r20,     0x80    ;    0 (       0) Ithsvnzc Input flags
	ldi   r18,     0x55    ; 0x55 (01010101) Result
	ldi   r19,     0x98    ; Output flags:   IthSVnzc
	mov   r7,      YL
	out   SR_IO,   r20
	sub   YL,      YH      ; SUB
	in    r6,      SR_IO
	cpse  YL,      r18
	rjmp  xmb_sub_fault_00
	cpse  r6,      r19
	rjmp  xmb_sub_fault_00
	mov   YL,      r7
	out   SR_IO,   r20
	cp    YL,      YH      ; CP
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_01
	out   SR_IO,   r20
	subi  YL,      0x55    ; SUBI
	in    r6,      SR_IO
	cpse  YL,      r18
	rjmp  xmb_sub_fault_02
	cpse  r6,      r19
	rjmp  xmb_sub_fault_02
	mov   YL,      r7
	out   SR_IO,   r20
	cpi   YL,      0x55    ; CPI
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_03
	out   SR_IO,   r20
	sbc   YL,      YH      ; SBC
	in    r6,      SR_IO
	cpse  YL,      r18
	rjmp  xmb_sub_fault_04
	cpse  r6,      r19
	rjmp  xmb_sub_fault_04
	mov   YL,      r7
	out   SR_IO,   r20
	cpc   YL,      YH      ; CPC
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_05
	out   SR_IO,   r20
	sbci  YL,      0x55    ; SBCI
	in    r6,      SR_IO
	cpse  YL,      r18
	rjmp  xmb_sub_fault_06
	cpse  r6,      r19
	rjmp  xmb_sub_fault_06

	ldi   r16,     0x54    ; 0x54 (01010100) -
	ldi   r17,     0xAA    ; 0xAA (10101010) -
	ldi   r20,     0xFF    ;    * (       *) ITHSVNZC Input flags
	ldi   r18,     0xAA    ; 0xAA (10101010) Result
	ldi   r19,     0xED    ; Output flags:   ITHsVNzC
	movw  r14,     r16
	out   SR_IO,   r20
	sub   r14,     r15     ; SUB
	in    r6,      SR_IO
	cpse  r14,     r18
	rjmp  xmb_sub_fault_00
	cpse  r6,      r19
	rjmp  xmb_sub_fault_00
	mov   r14,     r16
	out   SR_IO,   r20
	cp    r14,     r15     ; CP
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_01
	out   SR_IO,   r20
	subi  r16,     0xAA    ; SUBI
	in    r6,      SR_IO
	cpse  r16,     r18
	rjmp  xmb_sub_fault_02
	cpse  r6,      r19
	rjmp  xmb_sub_fault_02
	mov   r16,     r14
	out   SR_IO,   r20
	cpi   r16,     0xAA    ; CPI
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_03
	out   SR_IO,   r20
	ldi   r16,     0x55    ; 0x55 (01010101) Destination (Carry OK)
	mov   r14,     r16
	sbc   r14,     r15     ; SBC
	in    r6,      SR_IO
	cpse  r14,     r18
	rjmp  xmb_sub_fault_04
	cpse  r6,      r19
	rjmp  xmb_sub_fault_04
	mov   r14,     r16
	out   SR_IO,   r20
	cpc   r14,     r15     ; CPC
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_05
	out   SR_IO,   r20
	sbci  r16,     0xAA    ; SBCI
	in    r6,      SR_IO
	cpse  r16,     r18
	rjmp  xmb_sub_fault_06
	cpse  r6,      r19
	rjmp  xmb_sub_fault_06

	ldi   r16,     0x00    ; 0x00 (00000000) -
	ldi   r17,     0xFF    ; 0xFF (11111111) -
	ldi   r20,     0x81    ;    * (       *) IthsvnzC Input flags
	ldi   r18,     0x01    ; 0x01 (00000001) Result
	ldi   r19,     0xA1    ; Output flags:   ItHsvnzC
	movw  r0,      r16
	out   SR_IO,   r20
	sub   r0,      r1      ; SUB
	in    r6,      SR_IO
	cpse  r0,      r18
	rjmp  xmb_sub_fault_00
	cpse  r6,      r19
	rjmp  xmb_sub_fault_00
	mov   r0,      r16
	out   SR_IO,   r20
	cp    r0,      r1      ; CP
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_01
	out   SR_IO,   r20
	subi  r16,     0xFF    ; SUBI
	in    r6,      SR_IO
	cpse  r16,     r18
	rjmp  xmb_sub_fault_02
	cpse  r6,      r19
	rjmp  xmb_sub_fault_02
	mov   r16,     r0
	out   SR_IO,   r20
	cpi   r16,     0xFF    ; CPI
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_03
	out   SR_IO,   r20
	ldi   r18,     0x00    ; 0x00 (00000000) Result (Carry OK, no Z flag)
	sbc   r0,      r1      ; SBC
	in    r6,      SR_IO
	cpse  r0,      r18
	rjmp  xmb_sub_fault_04
	cpse  r6,      r19
	rjmp  xmb_sub_fault_04
	mov   r0,      r16
	out   SR_IO,   r20
	cpc   r0,      r1      ; CPC
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_05
	out   SR_IO,   r20
	sbci  r16,     0xFF    ; SBCI
	in    r6,      SR_IO
	cpse  r16,     r18
	rjmp  xmb_sub_fault_06
	cpse  r6,      r19
	rjmp  xmb_sub_fault_06

	ldi   r22,     0xFF    ; 0xFF (11111111) -
	ldi   r23,     0x00    ; 0x00 (00000000) -
	ldi   r20,     0xFE    ;    0 (       0) ITHSVNZc Input flags
	ldi   r18,     0xFF    ; 0xFF (11111111) Result
	ldi   r19,     0xD4    ; Output flags:   IThSvNzc
	mov   r7,      r22
	out   SR_IO,   r20
	sub   r22,     r23     ; SUB
	in    r6,      SR_IO
	cpse  r22,     r18
	rjmp  xmb_sub_fault_00
	cpse  r6,      r19
	rjmp  xmb_sub_fault_00
	mov   r22,     r7
	out   SR_IO,   r20
	cp    r22,     r23     ; CP
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_01
	out   SR_IO,   r20
	subi  r22,     0x00    ; SUBI
	in    r6,      SR_IO
	cpse  r22,     r18
	rjmp  xmb_sub_fault_02
	cpse  r6,      r19
	rjmp  xmb_sub_fault_02
	mov   r22,     r7
	out   SR_IO,   r20
	cpi   r22,     0x00    ; CPI
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_03
	out   SR_IO,   r20
	sbc   r22,     r23     ; SBC
	in    r6,      SR_IO
	cpse  r22,     r18
	rjmp  xmb_sub_fault_04
	cpse  r6,      r19
	rjmp  xmb_sub_fault_04
	mov   r22,     r7
	out   SR_IO,   r20
	cpc   r22,     r23     ; CPC
	in    r6,      SR_IO
	cpse  r6,      r19
	rjmp  xmb_sub_fault_05
	out   SR_IO,   r20
	sbci  r22,     0x00    ; SBCI
	in    r6,      SR_IO
	cpse  r22,     r18
	rjmp  xmb_sub_fault_06
	cpse  r6,      r19
	rjmp  xmb_sub_fault_06


	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next


xmb_sub_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x06
	jmp   XMB_FAULT

xmb_sub_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x06
	jmp   XMB_FAULT

xmb_sub_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x06
	jmp   XMB_FAULT

xmb_sub_fault_03:
	ldi   r24,     0x03
	ldi   r25,     0x06
	jmp   XMB_FAULT

xmb_sub_fault_04:
	ldi   r24,     0x04
	ldi   r25,     0x06
	jmp   XMB_FAULT

xmb_sub_fault_05:
	ldi   r24,     0x05
	ldi   r25,     0x06
	jmp   XMB_FAULT

xmb_sub_fault_06:
	ldi   r24,     0x06
	ldi   r25,     0x06
	jmp   XMB_FAULT



;
; Test entry points
;
.global xmb_sub_test

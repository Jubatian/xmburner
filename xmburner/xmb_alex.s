;
; XMBurner - (0x08) ALU Extra instruction test
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
; - The NEG instructions including SREG operations.
; - The INC and DEC instructions including SREG operations.
; - The ASR, LSR and ROR instructions including SREG operations.
; - The SWAP instruction.
;
; Interrupts are enabled after this component (it also doesn't disable them).
;

#include "xmb_defs.h"


.section XMB_COMP_SECTION


.set exec_id_from, 0x4D1CA36B
.set exec_id,      0x76F3D0AE

.set SR_IO,  _SFR_IO_ADDR(SREG)


.global xmb_alex
xmb_alex:

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
	brne  xmb_alex_fault_ff
	brcs  xmb_alex_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_alex_fault_ff
	brcs  xmb_alex_neg

xmb_alex_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x08
	jmp   XMB_FAULT

xmb_alex_neg:

	; NEG instruction test
	;
	; The following truth table applies for each bit:
	;
	; +-----+-----++-----+-----+
	; | dst |  cy || res |  cy |
	; +=====+=====++=====+=====+
	; |  0  |  0  ||  0  |  0  |
	; +-----+-----++-----+-----+
	; |  0  |  1  ||  1  |  1  |
	; +-----+-----++-----+-----+
	; |  1  |  0  ||  1  |  1  |
	; +-----+-----++-----+-----+
	; |  1  |  1  ||  0  |  1  |
	; +-----+-----++-----+-----+
	;
	; The tests attempt to excercise all input combinations on each of the
	; bits on all of the above instructions, verifying the output (result
	; where available, flags).

	ldi   ZL,      0x00    ;-0x00 (00000000)
	ldi   ZH,      0x00    ; 0x00 (00000000) Result
	ldi   XL,      0x80    ; Input flags:    Ithsvnzc
	ldi   XH,      0x82    ; Output flags:   IthsvnZc
	out   SR_IO,   XL
	neg   ZL               ; NEG
	in    r2,      SR_IO
	cpse  ZH,      ZL
	rjmp  xmb_alex_fault_00
	cpse  r2,      XH
	rjmp  xmb_alex_fault_00

	ldi   r21,     0x55    ;-0x55 (01010101)
	ldi   r16,     0xAB    ; 0xAB (10101011) Result
	ldi   XH,      0xFF    ; Input flags:    ITHSVNZC
	ldi   YL,      0xF5    ; Output flags:   ITHSvNzC
	out   SR_IO,   XH
	neg   r21              ; NEG
	in    r2,      SR_IO
	cpse  r21,     r16
	rjmp  xmb_alex_fault_00
	cpse  r2,      YL
	rjmp  xmb_alex_fault_00

	ldi   r20,     0xAB    ;-0xAB (10101011)
	ldi   r21,     0x55    ; 0x55 (01010101) Result
	ldi   YL,      0xFF    ; Input flags:    ITHSVNZC
	ldi   YH,      0xE1    ; Output flags:   ITHsvnzC
	movw  r4,      r20
	out   SR_IO,   YL
	neg   r4               ; NEG
	in    r2,      SR_IO
	cpse  r4,      r5
	rjmp  xmb_alex_fault_00
	cpse  r2,      YH
	rjmp  xmb_alex_fault_00

	ldi   r20,     0x01    ;-0x01 (00000001)
	ldi   r21,     0xFF    ; 0xFF (11111111) Result
	ldi   YL,      0x80    ; Input flags:    Ithsvnzc
	ldi   YH,      0xB5    ; Output flags:   ItHSvNzC
	movw  r0,      r20
	out   SR_IO,   YL
	neg   r0               ; NEG
	in    r2,      SR_IO
	cpse  r0,      r1
	rjmp  xmb_alex_fault_00
	cpse  r2,      YH
	rjmp  xmb_alex_fault_00

	ldi   r17,     0x02    ;-0x02 (00000010)
	ldi   r16,     0xFE    ; 0xFE (11111110) Result
	movw  r8,      r16
	out   SR_IO,   YL
	neg   r9               ; NEG
	in    r2,      SR_IO
	cpse  r9,      r8
	rjmp  xmb_alex_fault_00
	cpse  r2,      YH
	rjmp  xmb_alex_fault_00

	ldi   r25,     0x04    ;-0x04 (00000100)
	ldi   r20,     0xFC    ; 0xFC (11111100) Result
	out   SR_IO,   YL
	neg   r25              ; NEG
	in    r2,      SR_IO
	cpse  r25,     r20
	rjmp  xmb_alex_fault_00
	cpse  r2,      YH
	rjmp  xmb_alex_fault_00

	ldi   r24,     0x08    ;-0x08 (00001000)
	ldi   r20,     0xF8    ; 0xF8 (11111000) Result
	out   SR_IO,   YL
	neg   r24              ; NEG
	in    r2,      SR_IO
	cpse  r24,     r20
	rjmp  xmb_alex_fault_00
	cpse  r2,      YH
	rjmp  xmb_alex_fault_00

	ldi   r17,     0x10    ;-0x10 (00010000)
	ldi   r20,     0xF0    ; 0xF0 (11110000) Result
	ldi   XL,      0xFF    ; Input flags:    ITHSVNZC
	ldi   XH,      0xD5    ; Output flags:   IThSvNzC
	out   SR_IO,   XL
	neg   r17              ; NEG
	in    r2,      SR_IO
	cpse  r17,     r20
	rjmp  xmb_alex_fault_00
	cpse  r2,      XH
	rjmp  xmb_alex_fault_00

	ldi   r17,     0x20    ;-0x20 (00100000)
	ldi   r16,     0xE0    ; 0xE0 (11100000) Result
	movw  r12,     r16
	out   SR_IO,   XL
	neg   r13              ; NEG
	in    r2,      SR_IO
	cpse  r13,     r12
	rjmp  xmb_alex_fault_00
	cpse  r2,      XH
	rjmp  xmb_alex_fault_00

	ldi   r18,     0x40    ;-0x40 (01000000)
	ldi   r19,     0xC0    ; 0xC0 (11000000) Result
	movw  r14,     r18
	out   SR_IO,   XL
	neg   r14              ; NEG
	in    r2,      SR_IO
	cpse  r14,     r15
	rjmp  xmb_alex_fault_00
	cpse  r2,      XH
	rjmp  xmb_alex_fault_00

	ldi   r18,     0x80    ;-0x80 (10000000)
	ldi   r19,     0x80    ; 0x80 (10000000) Result
	ldi   XH,      0xCD    ; Output flags:   IThsVNzC
	out   SR_IO,   XL
	neg   r18              ; NEG
	in    r2,      SR_IO
	cpse  r18,     r19
	rjmp  xmb_alex_fault_00
	cpse  r2,      XH
	rjmp  xmb_alex_fault_00

xmb_alex_idec:

	; INC/DEC instruction test
	;
	; The following truth table applies for each bit:
	;
	; INC
	;
	; +-----+-----++-----+-----+
	; | dst |  cy || res |  cy |
	; +=====+=====++=====+=====+
	; |  0  |  0  ||  0  |  0  |
	; +-----+-----++-----+-----+
	; |  0  |  1  ||  1  |  0  |
	; +-----+-----++-----+-----+
	; |  1  |  0  ||  1  |  0  |
	; +-----+-----++-----+-----+
	; |  1  |  1  ||  0  |  1  |
	; +-----+-----++-----+-----+
	;
	; DEC
	;
	; +-----+-----++-----+-----+
	; | dst |  cy || res |  cy |
	; +=====+=====++=====+=====+
	; |  0  |  0  ||  0  |  0  |
	; +-----+-----++-----+-----+
	; |  0  |  1  ||  1  |  1  |
	; +-----+-----++-----+-----+
	; |  1  |  0  ||  1  |  1  |
	; +-----+-----++-----+-----+
	; |  1  |  1  ||  0  |  1  |
	; +-----+-----++-----+-----+
	;
	; The tests attempt to excercise all input combinations on each of the
	; bits on all of the above instructions, verifying the output (result
	; where available, flags).

	ldi   r18,     0x00    ; 0x00 (00000000) Result (INC) / Dest. (DEC)
	ldi   r19,     0xFF    ; 0xFF (11111111) Result (DEC) / Dest. (INC)
	ldi   ZH,      0x80    ; Input flags:    Ithsvnzc
	ldi   XL,      0x82    ; Output flags:   IthsvnZc (INC)
	ldi   YL,      0x94    ; Output flags:   IthSvNzc (DEC)
	movw  r0,      r18
	out   SR_IO,   ZH
	inc   r19              ; INC
	in    r3,      SR_IO
	cpse  r18,     r19
	rjmp  xmb_alex_fault_01
	cpse  r3,      XL
	rjmp  xmb_alex_fault_01
	out   SR_IO,   ZH
	dec   r0               ; DEC
	in    r3,      SR_IO
	cpse  r1,      r0
	rjmp  xmb_alex_fault_02
	cpse  r3,      YL
	rjmp  xmb_alex_fault_02

	ldi   r21,     0x01    ; 0x01 (00000001) Result (INC) / Dest. (DEC)
	ldi   r20,     0x00    ; 0x00 (00000000) Result (DEC) / Dest. (INC)
	ldi   ZH,      0xFF    ; Input flags:    ITHSVNZC
	ldi   XL,      0xE1    ; Output flags:   ITHsvnzC (INC)
	ldi   YL,      0xE3    ; Output flags:   ITHsvnZC (DEC)
	movw  r4,      r20
	out   SR_IO,   ZH
	inc   r20              ; INC
	in    r3,      SR_IO
	cpse  r21,     r20
	rjmp  xmb_alex_fault_01
	cpse  r3,      XL
	rjmp  xmb_alex_fault_01
	out   SR_IO,   ZH
	dec   r5               ; DEC
	in    r3,      SR_IO
	cpse  r4,      r5
	rjmp  xmb_alex_fault_02
	cpse  r3,      YL
	rjmp  xmb_alex_fault_02

	ldi   r21,     0x02    ; 0x02 (00000010) Result (INC) / Dest. (DEC)
	ldi   r20,     0x01    ; 0x01 (00000001) Result (DEC) / Dest. (INC)
	ldi   YL,      0xE1    ; Output flags:   ITHsvnzC (DEC)
	movw  r4,      r20
	out   SR_IO,   ZH
	inc   r4               ; INC
	in    r3,      SR_IO
	cpse  r5,      r4
	rjmp  xmb_alex_fault_01
	cpse  r3,      XL
	rjmp  xmb_alex_fault_01
	out   SR_IO,   ZH
	dec   r21              ; DEC
	in    r3,      SR_IO
	cpse  r20,     r21
	rjmp  xmb_alex_fault_02
	cpse  r3,      YL
	rjmp  xmb_alex_fault_02

	ldi   r24,     0x04    ; 0x04 (00000100) Result (INC) / Dest. (DEC)
	ldi   r25,     0x03    ; 0x03 (00000011) Result (DEC) / Dest. (INC)
	movw  r8,      r24
	out   SR_IO,   ZH
	inc   r9               ; INC
	in    r3,      SR_IO
	cpse  r8,      r9
	rjmp  xmb_alex_fault_01
	cpse  r3,      XL
	rjmp  xmb_alex_fault_01
	out   SR_IO,   ZH
	dec   r24              ; DEC
	in    r3,      SR_IO
	cpse  r25,     r24
	rjmp  xmb_alex_fault_02
	cpse  r3,      YL
	rjmp  xmb_alex_fault_02

	ldi   r24,     0x08    ; 0x08 (00001000) Result (INC) / Dest. (DEC)
	ldi   r25,     0x07    ; 0x07 (00000111) Result (DEC) / Dest. (INC)
	movw  r8,      r24
	out   SR_IO,   ZH
	inc   r25              ; INC
	in    r3,      SR_IO
	cpse  r24,     r25
	rjmp  xmb_alex_fault_01
	cpse  r3,      XL
	rjmp  xmb_alex_fault_01
	out   SR_IO,   ZH
	dec   r8               ; DEC
	in    r3,      SR_IO
	cpse  r9,      r8
	rjmp  xmb_alex_fault_02
	cpse  r3,      YL
	rjmp  xmb_alex_fault_02

	ldi   r23,     0x10    ; 0x10 (00010000) Result (INC) / Dest. (DEC)
	ldi   r22,     0x0F    ; 0x0F (00001111) Result (DEC) / Dest. (INC)
	movw  r10,     r22
	out   SR_IO,   ZH
	inc   r22              ; INC
	in    r3,      SR_IO
	cpse  r23,     r22
	rjmp  xmb_alex_fault_01
	cpse  r3,      XL
	rjmp  xmb_alex_fault_01
	out   SR_IO,   ZH
	dec   r11              ; DEC
	in    r3,      SR_IO
	cpse  r10,     r11
	rjmp  xmb_alex_fault_02
	cpse  r3,      YL
	rjmp  xmb_alex_fault_02

	ldi   r23,     0x20    ; 0x20 (00100000) Result (INC) / Dest. (DEC)
	ldi   r22,     0x1F    ; 0x1F (00011111) Result (DEC) / Dest. (INC)
	movw  r10,     r22
	out   SR_IO,   ZH
	inc   r10              ; INC
	in    r3,      SR_IO
	cpse  r11,     r10
	rjmp  xmb_alex_fault_01
	cpse  r3,      XL
	rjmp  xmb_alex_fault_01
	out   SR_IO,   ZH
	dec   r23              ; DEC
	in    r3,      SR_IO
	cpse  r22,     r23
	rjmp  xmb_alex_fault_02
	cpse  r3,      YL
	rjmp  xmb_alex_fault_02

	ldi   r16,     0x40    ; 0x40 (01000000) Result (INC) / Dest. (DEC)
	ldi   r17,     0x3F    ; 0x3F (00111111) Result (DEC) / Dest. (INC)
	movw  r14,     r16
	out   SR_IO,   ZH
	inc   r17              ; INC
	in    r3,      SR_IO
	cpse  r16,     r17
	rjmp  xmb_alex_fault_01
	cpse  r3,      XL
	rjmp  xmb_alex_fault_01
	out   SR_IO,   ZH
	dec   r14              ; DEC
	in    r3,      SR_IO
	cpse  r15,     r14
	rjmp  xmb_alex_fault_02
	cpse  r3,      YL
	rjmp  xmb_alex_fault_02

	ldi   r16,     0x80    ; 0x80 (10000000) Result (INC) / Dest. (DEC)
	ldi   r17,     0x7F    ; 0x7F (01111111) Result (DEC) / Dest. (INC)
	ldi   ZH,      0x80    ; Input flags:    Ithsvnzc
	ldi   XL,      0x8C    ; Output flags:   IthsVNzc (INC)
	ldi   YL,      0x98    ; Output flags:   IthSVnzc (DEC)
	movw  r14,     r16
	out   SR_IO,   ZH
	inc   r15              ; INC
	in    r3,      SR_IO
	cpse  r14,     r15
	rjmp  xmb_alex_fault_01
	cpse  r3,      XL
	rjmp  xmb_alex_fault_01
	out   SR_IO,   ZH
	dec   r16              ; DEC
	in    r3,      SR_IO
	cpse  r17,     r16
	rjmp  xmb_alex_fault_02
	cpse  r3,      YL
	rjmp  xmb_alex_fault_02

	ldi   XH,      0xFE    ; 0xFE (11111110) Dest. (INC)
	ldi   YH,      0xFF    ; 0xFF (11111111) Result (INC)
	ldi   ZH,      0x80    ; Input flags:    Ithsvnzc
	ldi   XL,      0x94    ; Output flags:   IthSvNzc
	out   SR_IO,   ZH
	inc   XH               ; INC
	in    r3,      SR_IO
	cpse  XH,      YH
	rjmp  xmb_alex_fault_01
	cpse  r3,      XL
	rjmp  xmb_alex_fault_01

	ldi   XH,      0x01    ; 0x01 (00000001) Dest. (DEC)
	ldi   YH,      0x00    ; 0x00 (00000000) Result (DEC)
	ldi   XL,      0x82    ; Output flags:   IthsvnZc
	out   SR_IO,   ZH
	dec   XH               ; DEC
	in    r3,      SR_IO
	cpse  XH,      YH
	rjmp  xmb_alex_fault_02
	cpse  r3,      XL
	rjmp  xmb_alex_fault_02

xmb_alex_rsh:

	; Right shift type instruction test
	;
	; ASR, LSR, ROR
	;
	; The tests attempt to detect whether there are any stuck bits in the
	; shifter and whether all flags can be set or cleared appropriately.

	ldi   r20,     0x00    ; 0x00 (00000000) >> 1
	ldi   r21,     0xFE    ;    0 (       0) ITHSVNZc Input flags
	ldi   r22,     0x00    ; 0x00 (00000000) Result
	ldi   r23,     0xE2    ; Output flags:   ITHsvnZc
	mov   r9,      r20
	out   SR_IO,   r21
	asr   r20              ; ASR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_03
	cpse  r20,     r22
	rjmp  xmb_alex_fault_03
	mov   r20,     r9
	out   SR_IO,   r21
	lsr   r20              ; LSR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_04
	cpse  r20,     r22
	rjmp  xmb_alex_fault_04
	mov   r20,     r9
	out   SR_IO,   r21
	ror   r20              ; ROR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_05
	cpse  r20,     r22
	rjmp  xmb_alex_fault_05

	ldi   r20,     0x01    ; 0x01 (00000001) >> 1
	ldi   r21,     0x80    ;    0 (       0) Ithsvnzc Input flags
	ldi   r22,     0x00    ; 0x00 (00000000) Result
	ldi   r23,     0x9B    ; Output flags:   IthSVnZC
	mov   r9,      r20
	out   SR_IO,   r21
	asr   r9               ; ASR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_03
	cpse  r9,      r22
	rjmp  xmb_alex_fault_03
	mov   r9,      r20
	out   SR_IO,   r21
	lsr   r9               ; LSR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_04
	cpse  r9,      r22
	rjmp  xmb_alex_fault_04
	mov   r9,      r20
	out   SR_IO,   r21
	ror   r9               ; ROR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_05
	cpse  r9,      r22
	rjmp  xmb_alex_fault_05

	ldi   r25,     0x55    ; 0x55 (01010101) >> 1
	ldi   r21,     0x80    ;    0 (       0) Ithsvnzc Input flags
	ldi   r22,     0x2A    ; 0x2A (00101010) Result
	ldi   r23,     0x99    ; Output flags:   IthSVnzC
	mov   r0,      r25
	out   SR_IO,   r21
	asr   r25              ; ASR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_03
	cpse  r25,     r22
	rjmp  xmb_alex_fault_03
	mov   r25,     r0
	out   SR_IO,   r21
	lsr   r25              ; LSR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_04
	cpse  r25,     r22
	rjmp  xmb_alex_fault_04
	mov   r25,     r0
	out   SR_IO,   r21
	ror   r25              ; ROR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_05
	cpse  r25,     r22
	rjmp  xmb_alex_fault_05

	ldi   r25,     0xAA    ; 0xAA (10101010) >> 1
	ldi   r21,     0xFF    ;    * (       *) ITHSVNZC Input flags
	ldi   r22,     0xD5    ; 0xD5 (11010101) Result
	ldi   r23,     0xEC    ; Output flags:   ITHsVNzc
	mov   r0,      r25
	out   SR_IO,   r21
	asr   r0               ; ASR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_03
	cpse  r0,      r22
	rjmp  xmb_alex_fault_03
	mov   r0,      r25
	out   SR_IO,   r21
	ror   r0               ; ROR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_05
	cpse  r0,      r22
	rjmp  xmb_alex_fault_05
	ldi   r22,     0x55    ; 0x55 (01010101) Result
	ldi   r23,     0xE0    ; Output flags:   ITHsvnzc
	mov   r0,      r25
	out   SR_IO,   r21
	lsr   r0               ; LSR
	in    r4,      SR_IO
	cpse  r4,      r23
	rjmp  xmb_alex_fault_04
	cpse  r0,      r22
	rjmp  xmb_alex_fault_04

xmb_alex_swap:

	; SWAP instruction test

	ldi   r24,     0xA5
	ldi   r25,     0x13
	ldi   ZL,      0x62
	ldi   ZH,      0x8C
	ldi   r18,     0x5A
	ldi   r19,     0x31
	ldi   XL,      0x26
	ldi   XH,      0xC8
	movw  r2,      r24
	movw  r0,      ZL
	movw  r14,     r18
	movw  r10,     XL
	swap  r19
	swap  r14
	swap  XL
	swap  r0
	swap  r24
	swap  r11
	swap  ZH
	swap  r3
	cpse  r0,      r10
	rjmp  xmb_alex_fault_06
	cpse  r3,      r15
	rjmp  xmb_alex_fault_06
	cpse  r11,     r1
	rjmp  xmb_alex_fault_06
	cpse  r14,     r2
	rjmp  xmb_alex_fault_06
	cpse  r19,     r25
	rjmp  xmb_alex_fault_06
	cpse  r24,     r18
	rjmp  xmb_alex_fault_06
	cpse  XL,      ZL
	rjmp  xmb_alex_fault_06
	cpse  ZH,      XH
	rjmp  xmb_alex_fault_06



	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next


xmb_alex_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x08
	jmp   XMB_FAULT

xmb_alex_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x08
	jmp   XMB_FAULT

xmb_alex_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x08
	jmp   XMB_FAULT

xmb_alex_fault_03:
	ldi   r24,     0x03
	ldi   r25,     0x08
	jmp   XMB_FAULT

xmb_alex_fault_04:
	ldi   r24,     0x04
	ldi   r25,     0x08
	jmp   XMB_FAULT

xmb_alex_fault_05:
	ldi   r24,     0x05
	ldi   r25,     0x08
	jmp   XMB_FAULT

xmb_alex_fault_06:
	ldi   r24,     0x06
	ldi   r25,     0x08
	jmp   XMB_FAULT


;
; Test entry points
;
.global xmb_alex_neg
.global xmb_alex_idec
.global xmb_alex_rsh
.global xmb_alex_swap

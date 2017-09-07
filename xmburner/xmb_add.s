;
; XMBurner - (0x07) Addition instruction test
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
; - The ADD instructions including SREG operations.
; - The ADC instructions including SREG operations.
; - The MOV instruction with some operand combinations.
;
; Interrupts are enabled after this component (it also doesn't disable them).
;

#include "xmb_defs.h"


.section .text


.set exec_id_from, 0xD0598A1F
.set exec_id,      0x4D1CA36B

.set SR_IO,  _SFR_IO_ADDR(SREG)


.global xmb_add
xmb_add:

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
	brne  xmb_add_fault_ff
	brcs  xmb_add_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_add_fault_ff
	brcs  xmb_add_test

xmb_add_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x07
	jmp   XMB_FAULT

xmb_add_test:

	; 8 bit addition type instructions are the followings:
	;
	; ADD
	; ADC
	;
	; The following truth table applies for each bit:
	;
	; +-----+-----+-----++-----+-----+
	; | dst | src |  cy || res |  cy |
	; +=====+=====+=====++=====+=====+
	; |  0  |  0  |  0  ||  0  |  0  |
	; +-----+-----+-----++-----+-----+
	; |  0  |  0  |  1  ||  1  |  0  |
	; +-----+-----+-----++-----+-----+
	; |  0  |  1  |  0  ||  1  |  0  |
	; +-----+-----+-----++-----+-----+
	; |  0  |  1  |  1  ||  0  |  1  |
	; +-----+-----+-----++-----+-----+
	; |  1  |  0  |  0  ||  1  |  0  |
	; +-----+-----+-----++-----+-----+
	; |  1  |  0  |  1  ||  0  |  1  |
	; +-----+-----+-----++-----+-----+
	; |  1  |  1  |  0  ||  0  |  1  |
	; +-----+-----+-----++-----+-----+
	; |  1  |  1  |  1  ||  1  |  1  |
	; +-----+-----+-----++-----+-----+
	;
	; The tests attempt to excercise all input combinations on each of the
	; bits on all of the above instructions, verifying the output (result
	; where available, flags).

	ldi   YL,      0x2B    ; 0x2B (00101011) +
	ldi   YH,      0xD4    ; 0xD4 (11010100) +
	ldi   XL,      0x80    ;    0 (       0) Ithsvnzc Input flags
	ldi   XH,      0xFF    ; 0xFF (11111111) Result
	ldi   ZL,      0x94    ; Output flags:   IthSvNzc
	movw  r6,      YL
	out   SR_IO,   XL
	add   r6,      r7      ; ADD
	in    ZH,      SR_IO
	cpse  r6,      XH
	rjmp  xmb_add_fault_00
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_00
	mov   r6,      YL
	out   SR_IO,   XL
	adc   r6,      r7      ; ADC
	in    ZH,      SR_IO
	cpse  r6,      XH
	rjmp  xmb_add_fault_01
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_01

	ldi   YL,      0xD4    ; 0xD4 (11010100) +
	ldi   YH,      0x2B    ; 0x2B (00101011) +
	ldi   XL,      0xFE    ;    0 (       0) ITHSVNZc Input flags
	ldi   XH,      0xFF    ; 0xFF (11111111) Result
	ldi   ZL,      0xD4    ; Output flags:   IThSvNzc
	mov   r11,     YL
	out   SR_IO,   XL
	add   YL,      YH      ; ADD
	in    ZH,      SR_IO
	cpse  YL,      XH
	rjmp  xmb_add_fault_00
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_00
	mov   YL,      r11
	out   SR_IO,   XL
	adc   YL,      YH      ; ADC
	in    ZH,      SR_IO
	cpse  YL,      XH
	rjmp  xmb_add_fault_01
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_01

	ldi   YL,      0x75    ; 0x75 (01110101) +
	ldi   YH,      0x8B    ; 0x8B (10001011) +
	ldi   XL,      0x81    ;    * (       *) IthsvnzC Input flags
	ldi   XH,      0x00    ; 0x00 (00000000) Result
	ldi   ZL,      0xA3    ; Output flags:   ItHsvnZC
	movw  r0,      YL
	out   SR_IO,   XL
	add   r0,      r1      ; ADD
	in    ZH,      SR_IO
	cpse  r0,      XH
	rjmp  xmb_add_fault_00
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_00
	ldi   YL,      0x74    ; 0x74 (01110100) Destination (Carry OK)
	mov   r0,      YL
	out   SR_IO,   XL
	adc   r0,      r1      ; ADC
	in    ZH,      SR_IO
	cpse  r0,      XH
	rjmp  xmb_add_fault_01
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_01

	ldi   r24,     0x8B    ; 0x8B (10001011) +
	ldi   r25,     0x75    ; 0x75 (01110101) +
	ldi   XL,      0xFF    ;    * (       *) ITHSVNZC Input flags
	ldi   XH,      0x00    ; 0x00 (00000000) Result
	ldi   ZL,      0xE3    ; Output flags:   ITHsvnZC
	mov   r15,     r24
	out   SR_IO,   XL
	add   r24,     r25     ; ADD
	in    ZH,      SR_IO
	cpse  r24,     XH
	rjmp  xmb_add_fault_00
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_00
	ldi   r25,     0x74    ; 0x74 (01110100) Source (Carry OK)
	mov   r24,     r15
	out   SR_IO,   XL
	adc   r24,     r25     ; ADC
	in    ZH,      SR_IO
	cpse  r24,     XH
	rjmp  xmb_add_fault_01
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_01

	ldi   YH,      0x55    ; 0x55 (01010101) +
	ldi   YL,      0x55    ; 0x55 (01010101) +
	ldi   XL,      0x80    ;    0 (       0) Ithsvnzc Input flags
	ldi   XH,      0xAA    ; 0xAA (10101010) Result
	ldi   ZL,      0x8C    ; Output flags:   IthsVNzc
	movw  r8,      YL
	out   SR_IO,   XL
	add   r9,      r8      ; ADD
	in    ZH,      SR_IO
	cpse  r9,      XH
	rjmp  xmb_add_fault_00
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_00
	mov   r9,      YH
	out   SR_IO,   XL
	adc   r9,      r8      ; ADC
	in    ZH,      SR_IO
	cpse  r9,      XH
	rjmp  xmb_add_fault_01
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_01

	ldi   r19,     0xAA    ; 0xAA (10101010) +
	ldi   r18,     0xAA    ; 0xAA (10101010) +
	ldi   XL,      0xFF    ;    * (       *) ITHSVNZC Input flags
	ldi   XH,      0x54    ; 0x54 (01010100) Result
	ldi   ZL,      0xF9    ; Output flags:   ITHSVnzC
	mov   r12,     r19
	out   SR_IO,   XL
	add   r19,     r18     ; ADD
	in    ZH,      SR_IO
	cpse  r19,     XH
	rjmp  xmb_add_fault_00
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_00
	ldi   XH,      0x55    ; 0x55 (01010101) Result (Carry OK)
	mov   r19,     r12
	out   SR_IO,   XL
	adc   r19,     r18      ; ADC
	in    ZH,      SR_IO
	cpse  r19,     XH
	rjmp  xmb_add_fault_01
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_01

	ldi   YH,      0xFF    ; 0xFF (11111111) +
	ldi   YL,      0xFF    ; 0xFF (11111111) +
	ldi   XL,      0x81    ;    * (       *) IthsvnzC Input flags
	ldi   XH,      0xFE    ; 0xFE (11111110) Result
	ldi   ZL,      0xB5    ; Output flags:   ItHSvNzC
	movw  r10,     YL
	out   SR_IO,   XL
	add   r11,     r10     ; ADD
	in    ZH,      SR_IO
	cpse  r11,     XH
	rjmp  xmb_add_fault_00
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_00
	ldi   XH,      0xFF    ; 0xFF (11111111) Result (Carry OK)
	mov   r11,     YH
	out   SR_IO,   XL
	adc   r11,     r10     ; ADC
	in    ZH,      SR_IO
	cpse  r11,     XH
	rjmp  xmb_add_fault_01
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_01

	ldi   r21,     0x00    ; 0x00 (00000000) +
	ldi   r20,     0x00    ; 0x00 (00000000) +
	ldi   XL,      0xFE    ;    0 (       0) ITHSVNZc Input flags
	ldi   XH,      0x00    ; 0x00 (00000000) Result
	ldi   ZL,      0xC2    ; Output flags:   IThsvnZc
	mov   r5,      r21
	out   SR_IO,   XL
	add   r21,     r20     ; ADD
	in    ZH,      SR_IO
	cpse  r21,     XH
	rjmp  xmb_add_fault_00
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_00
	mov   r21,     r5
	out   SR_IO,   XL
	adc   r21,     r20     ; ADC
	in    ZH,      SR_IO
	cpse  r21,     XH
	rjmp  xmb_add_fault_01
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_01

	; Extra tests to run operand combinations which cause a c -> C
	; transition and a C -> c transition (Carry flag). Such are not
	; executed in the above 8 tests as the value combinations necessary
	; for them to get full logic coverage doesn't permit it.

	ldi   YH,      0x6C    ; 0x6C (01101100) +
	ldi   YL,      0xC9    ; 0xC9 (11001001) +
	ldi   XL,      0x80    ;    0 (       0) Ithsvnzc Input flags
	ldi   XH,      0x35    ; 0x35 (00110101) Result
	ldi   ZL,      0xA1    ; Output flags:   ItHsvnzC
	movw  r14,     YL
	out   SR_IO,   XL
	add   r15,     r14     ; ADD
	in    ZH,      SR_IO
	cpse  r15,     XH
	rjmp  xmb_add_fault_00
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_00
	mov   r15,     YH
	out   SR_IO,   XL
	adc   r15,     r14     ; ADC
	in    ZH,      SR_IO
	cpse  r15,     XH
	rjmp  xmb_add_fault_01
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_01

	ldi   r23,     0x1B    ; 0x1B (00011011) +
	ldi   r22,     0x23    ; 0x23 (00100011) +
	ldi   XL,      0xFF    ;    * (       *) ITHSVNZC Input flags
	ldi   XH,      0x3E    ; 0x3E (00111110) Result
	ldi   ZL,      0xC0    ; Output flags:   IThsvnzc
	mov   r0,      r23
	out   SR_IO,   XL
	add   r23,     r22     ; ADD
	in    ZH,      SR_IO
	cpse  r23,     XH
	rjmp  xmb_add_fault_00
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_00
	ldi   XH,      0x3F    ; 0x3F (00111111) Result (Carry OK)
	mov   r23,     r0
	out   SR_IO,   XL
	adc   r23,     r22     ; ADC
	in    ZH,      SR_IO
	cpse  r23,     XH
	rjmp  xmb_add_fault_01
	cpse  ZH,      ZL
	rjmp  xmb_add_fault_01


	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next


xmb_add_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x07
	jmp   XMB_FAULT

xmb_add_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x07
	jmp   XMB_FAULT



;
; Test entry points
;
.global xmb_add_test

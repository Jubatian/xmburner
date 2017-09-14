;
; XMBurner - (0x09) Word Operations instruction test
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
; - The ADIW and SBIW instructions including SREG operations.
; - The MOVW instruction.
;
; Interrupts are enabled after this component (it also doesn't disable them).
;

#include "xmb_defs.h"


.section .text


.set exec_id_from, 0x76F3D0AE
.set exec_id,      0x0AB18F43

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
	brne  xmb_wops_fault_ff
	brcs  xmb_wops_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_wops_fault_ff
	brcs  xmb_wops_test

xmb_wops_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x09
	jmp   XMB_FAULT

xmb_wops_test:

	; ADIW instruction test
	;
	; The following truth table applies for bits 0 - 5:
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
	; The following truth table applies for bits 6 - 15:
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
	; The tests attempt to excercise all input combinations on each of the
	; bits, verifying the output (result, flags).

	ldi   ZL,      0x00    ; 0x0000 (00000000 00000000) +
	ldi   ZH,      0x00    ; 0x0000 (00000000 00000000)
	ldi   r16,     0x00    ; 0x0000 (00000000 00000000) Result
	ldi   r17,     0x00
	ldi   r18,     0x80    ; Input flags:    Ithsvnzc
	ldi   r19,     0x82    ; Output flags:   IthsvnZc
	out   SR_IO,   r18
	adiw  ZL,      0x00    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     ZL
	rjmp  xmb_wops_fault_00
	cpse  r17,     ZH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   r24,     0xFF    ; 0xFFFF (11111111 11111111) +
	ldi   r25,     0xFF    ; 0x0001 (00000000 00000001)
	ldi   r16,     0x00    ; 0x0000 (00000000 00000000) Result
	ldi   r17,     0x00
	ldi   r18,     0xFE    ; Input flags:    ITHSVNZc
	ldi   r19,     0xE3    ; Output flags:   ITHsvnZC
	out   SR_IO,   r18
	adiw  r24,     0x01    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     r24
	rjmp  xmb_wops_fault_00
	cpse  r17,     r25
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   YL,      0x55    ; 0xAA55 (10101010 01010101) +
	ldi   YH,      0xAA    ; 0x0015 (00000000 00010101)
	ldi   r16,     0x6A    ; 0xAA6A (10101010 01101010) Result
	ldi   r17,     0xAA
	ldi   r18,     0xFF    ; Input flags:    ITHSVNZC
	ldi   r19,     0xF4    ; Output flags:   ITHSvNzc
	out   SR_IO,   r18
	adiw  YL,      0x15    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     YL
	rjmp  xmb_wops_fault_00
	cpse  r17,     YH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   XL,      0xAA    ; 0x55AA (01010101 10101010) +
	ldi   XH,      0x55    ; 0x002A (00000000 00101010)
	ldi   r16,     0xD4    ; 0x55D4 (01010101 11010100) Result
	ldi   r17,     0x55
	ldi   r18,     0xFF    ; Input flags:    ITHSVNZC
	ldi   r19,     0xE0    ; Output flags:   ITHsvnzc
	out   SR_IO,   r18
	adiw  XL,      0x2A    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     XL
	rjmp  xmb_wops_fault_00
	cpse  r17,     XH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   ZL,      0x2A    ; 0x002A (00000000 00101010) +
	ldi   ZH,      0x00    ; 0x0015 (00000000 00010101)
	ldi   r16,     0x3F    ; 0x003F (00000000 00111111) Result
	ldi   r17,     0x00
	ldi   r18,     0xFF    ; Input flags:    ITHSVNZC
	ldi   r19,     0xE0    ; Output flags:   ITHsvnzc
	out   SR_IO,   r18
	adiw  ZL,      0x15    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     ZL
	rjmp  xmb_wops_fault_00
	cpse  r17,     ZH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   YL,      0xD5    ; 0xFFD5 (11111111 11010101) +
	ldi   YH,      0xFF    ; 0x002A (00000000 00101010)
	ldi   r16,     0xFF    ; 0xFFFF (11111111 11111111) Result
	ldi   r17,     0xFF
	ldi   r18,     0x80    ; Input flags:    Ithsvnzc
	ldi   r19,     0x94    ; Output flags:   IthSvNzc
	out   SR_IO,   r18
	adiw  YL,      0x2A    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     YL
	rjmp  xmb_wops_fault_00
	cpse  r17,     YH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   r24,     0x41    ; 0x0041 (00000000 01000001) +
	ldi   r25,     0x00    ; 0x003F (00000000 00111111)
	ldi   r16,     0x80    ; 0x0080 (00000000 10000000) Result
	ldi   r17,     0x00
	ldi   r18,     0x80    ; Input flags:    Ithsvnzc
	ldi   r19,     0x80    ; Output flags:   Ithsvnzc
	out   SR_IO,   r18
	adiw  r24,     0x3F    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     r24
	rjmp  xmb_wops_fault_00
	cpse  r17,     r25
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   XL,      0xFF    ; 0x00FF (00000000 11111111) +
	ldi   XH,      0x00    ; 0x003F (00000000 00111111)
	ldi   r16,     0x3E    ; 0x013E (00000001 00111110) Result
	ldi   r17,     0x01
	ldi   r18,     0xFF    ; Input flags:    ITHSVNZC
	ldi   r19,     0xE0    ; Output flags:   ITHsvnzc
	out   SR_IO,   r18
	adiw  XL,      0x3F    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     XL
	rjmp  xmb_wops_fault_00
	cpse  r17,     XH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   ZL,      0xF8    ; 0x01F8 (00000001 11111000) +
	ldi   ZH,      0x01    ; 0x0031 (00000000 00110001)
	ldi   r16,     0x29    ; 0x0229 (00000010 00101001) Result
	ldi   r17,     0x02
	out   SR_IO,   r18
	adiw  ZL,      0x31    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     ZL
	rjmp  xmb_wops_fault_00
	cpse  r17,     ZH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   YL,      0xC9    ; 0x03C9 (00000011 11001001) +
	ldi   YH,      0x03    ; 0x003B (00000000 00111011)
	ldi   r16,     0x04    ; 0x0404 (00000100 00000100) Result
	ldi   r17,     0x04
	out   SR_IO,   r18
	adiw  YL,      0x3B    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     YL
	rjmp  xmb_wops_fault_00
	cpse  r17,     YH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   r24,     0xED    ; 0x07ED (00000111 11101101) +
	ldi   r25,     0x07    ; 0x001A (00000000 00011010)
	ldi   r16,     0x07    ; 0x0807 (00001000 00000111) Result
	ldi   r17,     0x08
	out   SR_IO,   r18
	adiw  r24,     0x1A    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     r24
	rjmp  xmb_wops_fault_00
	cpse  r17,     r25
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   XL,      0xF0    ; 0x0FF0 (00001111 11110000) +
	ldi   XH,      0x0F    ; 0x0011 (00000000 00010001)
	ldi   r16,     0x01    ; 0x1001 (00010000 00000001) Result
	ldi   r17,     0x10
	out   SR_IO,   r18
	adiw  XL,      0x11    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     XL
	rjmp  xmb_wops_fault_00
	cpse  r17,     XH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   ZL,      0xED    ; 0x1FED (00011111 11101101) +
	ldi   ZH,      0x1F    ; 0x0037 (00000000 00110111)
	ldi   r16,     0x24    ; 0x2024 (00100000 00100100) Result
	ldi   r17,     0x20
	out   SR_IO,   r18
	adiw  ZL,      0x37    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     ZL
	rjmp  xmb_wops_fault_00
	cpse  r17,     ZH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   YL,      0xFA    ; 0x3FFA (00111111 11111010) +
	ldi   YH,      0x3F    ; 0x0006 (00000000 00000110)
	ldi   r16,     0x00    ; 0x4000 (01000000 00000000) Result
	ldi   r17,     0x40
	out   SR_IO,   r18
	adiw  YL,      0x06    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     YL
	rjmp  xmb_wops_fault_00
	cpse  r17,     YH
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	ldi   r24,     0xF2    ; 0x7FF2 (01111111 11110010) +
	ldi   r25,     0x7F    ; 0x002D (00000000 00101101)
	ldi   r16,     0x1F    ; 0x801F (10000000 00011111) Result
	ldi   r17,     0x80
	ldi   r18,     0x80    ; Input flags:    Ithsvnzc
	ldi   r19,     0x8C    ; Output flags:   IthsVNzc
	out   SR_IO,   r18
	adiw  r24,     0x2D    ; ADIW
	in    r5,      SR_IO
	cpse  r16,     r24
	rjmp  xmb_wops_fault_00
	cpse  r17,     r25
	rjmp  xmb_wops_fault_00
	cpse  r5,      r19
	rjmp  xmb_wops_fault_00

	; SBIW instruction test
	;
	; The following truth table applies for bits 0 - 5:
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
	; The following truth table applies for bits 6 - 15:
	;
	; +-----+-----++-----+-----+
	; | dst |  cy || res |  cy |
	; +=====+=====++=====+=====+
	; |  0  |  0  ||  0  |  0  |
	; +-----+-----++-----+-----+
	; |  0  |  1  ||  1  |  1  |
	; +-----+-----++-----+-----+
	; |  1  |  0  ||  1  |  0  |
	; +-----+-----++-----+-----+
	; |  1  |  1  ||  0  |  0  |
	; +-----+-----++-----+-----+
	;
	; The tests attempt to excercise all input combinations on each of the
	; bits, verifying the output (result, flags).

	ldi   ZL,      0x00    ; 0x0000 (00000000 00000000) -
	ldi   ZH,      0x00    ; 0x0000 (00000000 00000000)
	ldi   r16,     0x00    ; 0x0000 (00000000 00000000) Result
	ldi   r17,     0x00
	ldi   r18,     0x80    ; Input flags:    Ithsvnzc
	ldi   r19,     0x82    ; Output flags:   IthsvnZc
	out   SR_IO,   r18
	adiw  ZL,      0x00    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     ZL
	rjmp  xmb_wops_fault_01
	cpse  r17,     ZH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   r24,     0x00    ; 0x0000 (00000000 00000000) -
	ldi   r25,     0x00    ; 0x0001 (00000000 00000001)
	ldi   r16,     0xFF    ; 0xFFFF (11111111 11111111) Result
	ldi   r17,     0xFF
	ldi   r18,     0xFE    ; Input flags:    ITHSVNZc
	ldi   r19,     0xF5    ; Output flags:   ITHSvNzC
	out   SR_IO,   r18
	sbiw  r24,     0x01    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     r24
	rjmp  xmb_wops_fault_01
	cpse  r17,     r25
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   YL,      0x55    ; 0xAA55 (10101010 01010101) -
	ldi   YH,      0xAA    ; 0x0015 (00000000 00010101)
	ldi   r16,     0x40    ; 0xAA40 (10101010 01000000) Result
	ldi   r17,     0xAA
	ldi   r18,     0xFF    ; Input flags:    ITHSVNZC
	ldi   r19,     0xF4    ; Output flags:   ITHSvNzc
	out   SR_IO,   r18
	sbiw  YL,      0x15    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     YL
	rjmp  xmb_wops_fault_01
	cpse  r17,     YH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   XL,      0xAA    ; 0x55AA (01010101 10101010) -
	ldi   XH,      0x55    ; 0x002A (00000000 00101010)
	ldi   r16,     0x80    ; 0x5580 (01010101 10000000) Result
	ldi   r17,     0x55
	ldi   r18,     0xFF    ; Input flags:    ITHSVNZC
	ldi   r19,     0xE0    ; Output flags:   ITHsvnzc
	out   SR_IO,   r18
	sbiw  XL,      0x2A    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     XL
	rjmp  xmb_wops_fault_01
	cpse  r17,     XH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   ZL,      0x2A    ; 0x002A (00000000 00101010) -
	ldi   ZH,      0x00    ; 0x0015 (00000000 00010101)
	ldi   r16,     0x15    ; 0x0015 (00000000 00010101) Result
	ldi   r17,     0x00
	ldi   r18,     0xFF    ; Input flags:    ITHSVNZC
	ldi   r19,     0xE0    ; Output flags:   ITHsvnzc
	out   SR_IO,   r18
	sbiw  ZL,      0x15    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     ZL
	rjmp  xmb_wops_fault_01
	cpse  r17,     ZH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   YL,      0xD5    ; 0xFFD5 (11111111 11010101) -
	ldi   YH,      0xFF    ; 0x002A (00000000 00101010)
	ldi   r16,     0xAB    ; 0xFFAB (11111111 10101011) Result
	ldi   r17,     0xFF
	ldi   r18,     0x80    ; Input flags:    Ithsvnzc
	ldi   r19,     0x94    ; Output flags:   IthSvNzc
	out   SR_IO,   r18
	sbiw  YL,      0x2A    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     YL
	rjmp  xmb_wops_fault_01
	cpse  r17,     YH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   r24,     0x80    ; 0xFF80 (11111111 10000000) -
	ldi   r25,     0xFF    ; 0x003F (00000000 00111111)
	ldi   r16,     0x41    ; 0xFF41 (11111111 01000001) Result
	ldi   r17,     0xFF
	ldi   r18,     0x80    ; Input flags:    Ithsvnzc
	ldi   r19,     0x94    ; Output flags:   IthSvNzc
	out   SR_IO,   r18
	sbiw  r24,     0x3F    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     r24
	rjmp  xmb_wops_fault_01
	cpse  r17,     r25
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   XL,      0xFF    ; 0xFF00 (11111111 00000000) -
	ldi   XH,      0x00    ; 0x003F (00000000 00111111)
	ldi   r16,     0x41    ; 0xFEC1 (11111110 11000001) Result
	ldi   r17,     0xFE
	ldi   r18,     0xFF    ; Input flags:    ITHSVNZC
	ldi   r19,     0xF4    ; Output flags:   ITHSvNzc
	out   SR_IO,   r18
	sbiw  XL,      0x3F    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     XL
	rjmp  xmb_wops_fault_01
	cpse  r17,     XH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   ZL,      0x1A    ; 0xFE1A (11111110 00011010) -
	ldi   ZH,      0xFE    ; 0x0031 (00000000 00110001)
	ldi   r16,     0xE9    ; 0xFDE9 (11111101 11101001) Result
	ldi   r17,     0xFD
	out   SR_IO,   r18
	sbiw  ZL,      0x31    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     ZL
	rjmp  xmb_wops_fault_01
	cpse  r17,     ZH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   YL,      0x36    ; 0xFC36 (11111100 00110110) -
	ldi   YH,      0xFC    ; 0x003B (00000000 00111011)
	ldi   r16,     0xFB    ; 0xFBFB (11111011 11111011) Result
	ldi   r17,     0xFB
	out   SR_IO,   r18
	sbiw  YL,      0x3B    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     YL
	rjmp  xmb_wops_fault_01
	cpse  r17,     YH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   r24,     0x08    ; 0xF808 (11111000 00001000) -
	ldi   r25,     0xF8    ; 0x001A (00000000 00011010)
	ldi   r16,     0xEE    ; 0xF7EE (11110111 11101110) Result
	ldi   r17,     0xF7
	out   SR_IO,   r18
	sbiw  r24,     0x1A    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     r24
	rjmp  xmb_wops_fault_01
	cpse  r17,     r25
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   XL,      0x0F    ; 0xF00F (11110000 00001111) -
	ldi   XH,      0xF0    ; 0x0011 (00000000 00010001)
	ldi   r16,     0xFE    ; 0xEFFE (11101111 11111110) Result
	ldi   r17,     0xEF
	out   SR_IO,   r18
	sbiw  XL,      0x11    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     XL
	rjmp  xmb_wops_fault_01
	cpse  r17,     XH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   ZL,      0x32    ; 0xE032 (11100000 00110010) -
	ldi   ZH,      0xE0    ; 0x0037 (00000000 00110111)
	ldi   r16,     0xFB    ; 0xDFFB (11011111 11111011) Result
	ldi   r17,     0xDF
	out   SR_IO,   r18
	sbiw  ZL,      0x37    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     ZL
	rjmp  xmb_wops_fault_01
	cpse  r17,     ZH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   YL,      0x05    ; 0xC005 (11000000 00000101) -
	ldi   YH,      0xC0    ; 0x0006 (00000000 00000110)
	ldi   r16,     0xFF    ; 0xBFFF (10111111 11111111) Result
	ldi   r17,     0xBF
	out   SR_IO,   r18
	sbiw  YL,      0x06    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     YL
	rjmp  xmb_wops_fault_01
	cpse  r17,     YH
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	ldi   r24,     0x1C    ; 0x801C (10000000 00011100) -
	ldi   r25,     0x80    ; 0x002D (00000000 00101101)
	ldi   r16,     0xEF    ; 0x7FEF (01111111 11101111) Result
	ldi   r17,     0x7F
	ldi   r18,     0x80    ; Input flags:    Ithsvnzc
	ldi   r19,     0x98    ; Output flags:   IthSVnzc
	out   SR_IO,   r18
	sbiw  r24,     0x2D    ; SBIW
	in    r5,      SR_IO
	cpse  r16,     r24
	rjmp  xmb_wops_fault_01
	cpse  r17,     r25
	rjmp  xmb_wops_fault_01
	cpse  r5,      r19
	rjmp  xmb_wops_fault_01

	; MOVW instruction test

	ldi   ZH,      0x49
	ldi   ZL,      0xE4
	ldi   YH,      0xA5
	ldi   YL,      0x7B
	ldi   XH,      0x6A
	ldi   XL,      0x18
	ldi   r25,     0xCC
	ldi   r24,     0x57
	ldi   r23,     0x91
	ldi   r22,     0xF0
	ldi   r21,     0x23
	ldi   r20,     0xB2
	ldi   r19,     0x06
	ldi   r18,     0x3E
	ldi   r17,     0x8D
	ldi   r16,     0xDF
	movw  r0,      XL
	movw  r8,      ZL
	movw  r2,      r24
	movw  r4,      r22
	movw  r14,     r16
	movw  r6,      r18
	movw  r12,     YL
	movw  r10,     r20
	cpse  r0,      XL
	rjmp  xmb_wops_fault_02
	cpse  r1,      XH
	rjmp  xmb_wops_fault_02
	cpse  r2,      r24
	rjmp  xmb_wops_fault_02
	cpse  r3,      r25
	rjmp  xmb_wops_fault_02
	cpse  r4,      r22
	rjmp  xmb_wops_fault_02
	cpse  r5,      r23
	rjmp  xmb_wops_fault_02
	cpse  r6,      r18
	rjmp  xmb_wops_fault_02
	cpse  r7,      r19
	rjmp  xmb_wops_fault_02
	cpse  r8,      ZL
	rjmp  xmb_wops_fault_02
	cpse  r9,      ZH
	rjmp  xmb_wops_fault_02
	cpse  r10,     r20
	rjmp  xmb_wops_fault_02
	cpse  r11,     r21
	rjmp  xmb_wops_fault_02
	cpse  r12,     YL
	rjmp  xmb_wops_fault_02
	cpse  r13,     YH
	rjmp  xmb_wops_fault_02
	cpse  r14,     r16
	rjmp  xmb_wops_fault_02
	cpse  r15,     r17
	rjmp  xmb_wops_fault_02
	movw  r22,     r0
	movw  YL,      r10
	movw  r20,     r14
	movw  ZL,      r2
	movw  r16,     r8
	movw  r24,     r4
	movw  XL,      r12
	movw  r18,     r6
	cpse  r16,     r8
	rjmp  xmb_wops_fault_02
	cpse  r17,     r9
	rjmp  xmb_wops_fault_02
	cpse  r18,     r6
	rjmp  xmb_wops_fault_02
	cpse  r19,     r7
	rjmp  xmb_wops_fault_02
	cpse  r20,     r14
	rjmp  xmb_wops_fault_02
	cpse  r21,     r15
	rjmp  xmb_wops_fault_02
	cpse  r22,     r0
	rjmp  xmb_wops_fault_02
	cpse  r23,     r1
	rjmp  xmb_wops_fault_02
	cpse  r24,     r4
	rjmp  xmb_wops_fault_02
	cpse  r25,     r5
	rjmp  xmb_wops_fault_02
	cpse  XL,      r12
	rjmp  xmb_wops_fault_02
	cpse  XH,      r13
	rjmp  xmb_wops_fault_02
	cpse  YL,      r10
	rjmp  xmb_wops_fault_02
	cpse  YH,      r11
	rjmp  xmb_wops_fault_02
	cpse  ZL,      r2
	rjmp  xmb_wops_fault_02
	cpse  ZH,      r3
	rjmp  xmb_wops_fault_02


	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next


xmb_wops_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x09
	jmp   XMB_FAULT

xmb_wops_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x09
	jmp   XMB_FAULT

xmb_wops_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x09
	jmp   XMB_FAULT


;
; Test entry points
;
.global xmb_wops_test

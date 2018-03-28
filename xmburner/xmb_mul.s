;
; XMBurner - (0x0B) Multiplication instruction test
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
; - The MUL/MULS/MULSU instructions including SREG operations.
; - The FMUL/FMULS/FMULSU instructions including SREG operations.
; - The ADD/ADC instructions with diverse operands.
; - The NEG instruction with diverse operands.
;
; Performs a complete test covering all possible input combinations, so it can
; detect failures regardless of the implementation of the multiplier.
;
; Interrupts are enabled after this component (it also doesn't disable them).
;

#include "xmb_defs.h"


.section .data


; Current PRNG value for multiplication inputs
xmb_mul_rval:
	.space 2


.section XMB_COMP_SECTION


.set exec_id_from, 0xD5F049E6
.set exec_id,      0x9A00C47E

.set SR_IO,  _SFR_IO_ADDR(SREG)


.global xmb_mul
xmb_mul:

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
	brne  xmb_mul_fault_ff
	brcs  xmb_mul_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_mul_fault_ff
	brcs  xmb_mul_test

xmb_mul_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x0B
	jmp   XMB_FAULT

xmb_mul_test:

	; In each pass 11 of each multiplication types are tested, so a total
	; of 66 multiplications. Using the PRNG each multiplication
	; instruction is eventually tested by every possible operand
	; combination, the PRNG adds variation to this, accelerating the
	; detection of a defect (assuming defects which manifest in a
	; specific range of inputs which is the most likely mode of failure).

	ldi   ZL,      lo8(xmb_mul_rval)
	ldi   ZH,      hi8(xmb_mul_rval)
	ld    r2,      Z+
	ld    r3,      Z+


	; Test block 0

	rcall xmb_mul_prep_mul
	mul   r24,     r22
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	muls  r24,     r22
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r16,     r24
	mulsu r16,     r22
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r16,     r24
	fmul  r16,     r22
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r16,     r24
	fmuls r16,     r22
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r16,     r24
	fmulsu r16,    r22
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2

	; Test block 1

	rcall xmb_mul_prep_mul
	mov   YL,      r24
	mov   r7,      r22
	mul   YL,      r7
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	mov   YL,      r24
	mov   r17,     r22
	muls  YL,      r17
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r18,     r24
	mov   r17,     r22
	mulsu r18,     r17
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r18,     r24
	mov   r17,     r22
	fmul  r18,     r17
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r18,     r24
	mov   r17,     r22
	fmuls r18,     r17
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r18,     r24
	mov   r17,     r22
	fmulsu r18,    r17
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2

	; Test block 2

	rcall xmb_mul_prep_mul
	mov   r11,     r24
	mov   r15,     r22
	mul   r11,     r15
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	mov   YH,      r24
	mov   ZH,      r22
	muls  YH,      ZH
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r19,     r24
	mov   r23,     r22
	mulsu r19,     r23
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r19,     r24
	mov   r23,     r22
	fmul  r19,     r23
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r19,     r24
	mov   r23,     r22
	fmuls r19,     r23
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r19,     r24
	mov   r23,     r22
	fmulsu r19,    r23
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2

	; Test block 3

	rcall xmb_mul_prep_mul
	mov   r5,      r24
	mov   r20,     r22
	mul   r5,      r20
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	mov   r21,     r24
	mov   r20,     r22
	muls  r21,     r20
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r21,     r24
	mov   r20,     r22
	mulsu r21,     r20
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r21,     r24
	mov   r20,     r22
	fmul  r21,     r20
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r21,     r24
	mov   r20,     r22
	fmuls r21,     r20
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r21,     r24
	mov   r20,     r22
	fmulsu r21,    r20
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2

	; Test block 4

	rcall xmb_mul_prep_mul
	mov   r1,      r24
	mov   r0,      r22
	mul   r1,      r0
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	mov   r17,     r24
	mov   r16,     r22
	muls  r17,     r16
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r17,     r24
	mov   r16,     r22
	mulsu r17,     r16
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r17,     r24
	mov   r16,     r22
	fmul  r17,     r16
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r17,     r24
	mov   r16,     r22
	fmuls r17,     r16
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r17,     r24
	mov   r16,     r22
	fmulsu r17,    r16
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2

	; Test block 5

	rcall xmb_mul_prep_mul
	mov   XH,      r24
	mov   r18,     r22
	mul   XH,      r18
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	mov   XH,      r24
	mov   r18,     r22
	muls  XH,      r18
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r23,     r24
	mov   r18,     r22
	mulsu r23,     r18
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r23,     r24
	mov   r18,     r22
	fmul  r23,     r18
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r23,     r24
	mov   r18,     r22
	fmuls r23,     r18
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r23,     r24
	mov   r18,     r22
	fmulsu r23,    r18
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2

	; Test block 6

	rcall xmb_mul_prep_mul
	mov   r20,     r24
	mov   r5,      r22
	mul   r20,     r5
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	mov   r20,     r24
	mov   r21,     r22
	muls  r20,     r21
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r20,     r24
	mov   r21,     r22
	mulsu r20,     r21
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r20,     r24
	mov   r21,     r22
	fmul  r20,     r21
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r20,     r24
	mov   r21,     r22
	fmuls r20,     r21
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r20,     r24
	mov   r21,     r22
	fmulsu r20,    r21
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2

	; Test block 7

	rcall xmb_mul_prep_mul
	mov   r15,     r24
	mov   XL,      r22
	mul   r15,     XL
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	mov   ZH,      r24
	mov   XL,      r22
	muls  ZH,      XL
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r23,     r24
	mov   r20,     r22
	mulsu r23,     r20
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r23,     r24
	mov   r20,     r22
	fmul  r23,     r20
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r23,     r24
	mov   r20,     r22
	fmuls r23,     r20
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r23,     r24
	mov   r20,     r22
	fmulsu r23,    r20
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2

	; Test block 8

	rcall xmb_mul_prep_mul
	mov   r10,     r24
	mov   r6,      r22
	mul   r10,     r6
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	mov   YL,      r24
	muls  YL,      r22
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r18,     r24
	mulsu r18,     r22
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r18,     r24
	fmul  r18,     r22
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r18,     r24
	fmuls r18,     r22
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r18,     r24
	fmulsu r18,    r22
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2

	; Test block 9

	rcall xmb_mul_prep_mul
	mov   r8,      r24
	mov   r19,     r22
	mul   r8,      r19
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	mov   r19,     r22
	muls  r24,     r19
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r16,     r24
	mov   r19,     r22
	mulsu r16,     r19
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r16,     r24
	mov   r19,     r22
	fmul  r16,     r19
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r16,     r24
	mov   r19,     r22
	fmuls r16,     r19
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r16,     r24
	mov   r19,     r22
	fmulsu r16,    r19
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2

	; Test block 10

	rcall xmb_mul_prep_mul
	mov   r23,     r24
	mov   r18,     r22
	mul   r23,     r18
	rcall xmb_mul_test_mul
	brcc  .+2
	rjmp  xmb_mul_fault_00

	rcall xmb_mul_prep_muls
	mov   r23,     r24
	mov   r18,     r22
	muls  r23,     r18
	rcall xmb_mul_test_muls
	brcc  .+2
	rjmp  xmb_mul_fault_01

	rcall xmb_mul_prep_mulsu
	mov   r23,     r24
	mov   r18,     r22
	mulsu r23,     r18
	rcall xmb_mul_test_mulsu
	brcc  .+2
	rjmp  xmb_mul_fault_02

	rcall xmb_mul_prep_fmul
	mov   r23,     r24
	mov   r18,     r22
	fmul  r23,     r18
	rcall xmb_mul_test_fmul
	brcc  .+2
	rjmp  xmb_mul_fault_03

	rcall xmb_mul_prep_fmuls
	mov   r23,     r24
	mov   r18,     r22
	fmuls r23,     r18
	rcall xmb_mul_test_fmuls
	brcc  .+2
	rjmp  xmb_mul_fault_04

	rcall xmb_mul_prep_fmulsu
	mov   r23,     r24
	mov   r18,     r22
	fmulsu r23,    r18
	rcall xmb_mul_test_fmulsu
	brcc  .+2
	rjmp  xmb_mul_fault_05

	rcall xmb_mul_prng_r2


	; Save new PRNG value

	ldi   ZL,      lo8(xmb_mul_rval)
	ldi   ZH,      hi8(xmb_mul_rval)
	st    Z+,      r2
	st    Z+,      r3


	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next


xmb_mul_prng_r2:
	movw  r24,     r2
	rcall xmb_mul_prng
	movw  r2,      r24
	ret


xmb_mul_prep_mul:
	mov   r24,     r2
	mov   r22,     r3
	ret

xmb_mul_prep_muls:
	mov   r24,     r2
	mov   r22,     r3
	subi  r24,     0x55
	subi  r22,     0xAA
	ret

xmb_mul_prep_mulsu:
	mov   r24,     r2
	mov   r22,     r3
	subi  r24,     0x99
	subi  r22,     0x66
	ret

xmb_mul_prep_fmul:
	mov   r24,     r2
	mov   r22,     r3
	subi  r24,     0xCC
	subi  r22,     0x88
	ret

xmb_mul_prep_fmuls:
	mov   r24,     r2
	mov   r22,     r3
	subi  r24,     0x1F
	subi  r22,     0xF1
	ret

xmb_mul_prep_fmulsu:
	mov   r24,     r2
	mov   r22,     r3
	subi  r24,     0x69
	subi  r22,     0x96
	ret


xmb_mul_test_mul:
	in    r19,     SR_IO
	andi  r19,     0x03    ; Mask Z and C flags
	rcall xmb_mul_sw_mul
	in    r18,     SR_IO
	andi  r18,     0x03    ; Mask Z and C flags
	clc
	cpse  r19,     r18
	sec
	cpse  r0,      r24
	sec
	cpse  r1,      r25
	sec
	ret

xmb_mul_test_muls:
	in    r19,     SR_IO
	andi  r19,     0x03    ; Mask Z and C flags
	rcall xmb_mul_sw_muls
	in    r18,     SR_IO
	andi  r18,     0x03    ; Mask Z and C flags
	clc
	cpse  r19,     r18
	sec
	cpse  r0,      r24
	sec
	cpse  r1,      r25
	sec
	ret

xmb_mul_test_mulsu:
	in    r19,     SR_IO
	andi  r19,     0x03    ; Mask Z and C flags
	rcall xmb_mul_sw_mulsu
	in    r18,     SR_IO
	andi  r18,     0x03    ; Mask Z and C flags
	clc
	cpse  r19,     r18
	sec
	cpse  r0,      r24
	sec
	cpse  r1,      r25
	sec
	ret

xmb_mul_test_fmul:
	in    r19,     SR_IO
	andi  r19,     0x03    ; Mask Z and C flags
	rcall xmb_mul_sw_fmul
	in    r18,     SR_IO
	andi  r18,     0x03    ; Mask Z and C flags
	clc
	cpse  r19,     r18
	sec
	cpse  r0,      r24
	sec
	cpse  r1,      r25
	sec
	ret

xmb_mul_test_fmuls:
	in    r19,     SR_IO
	andi  r19,     0x03    ; Mask Z and C flags
	rcall xmb_mul_sw_fmuls
	in    r18,     SR_IO
	andi  r18,     0x03    ; Mask Z and C flags
	clc
	cpse  r19,     r18
	sec
	cpse  r0,      r24
	sec
	cpse  r1,      r25
	sec
	ret

xmb_mul_test_fmulsu:
	in    r19,     SR_IO
	andi  r19,     0x03    ; Mask Z and C flags
	rcall xmb_mul_sw_fmulsu
	in    r18,     SR_IO
	andi  r18,     0x03    ; Mask Z and C flags
	clc
	cpse  r19,     r18
	sec
	cpse  r0,      r24
	sec
	cpse  r1,      r25
	sec
	ret


xmb_mul_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x0B
	jmp   XMB_FAULT

xmb_mul_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x0B
	jmp   XMB_FAULT

xmb_mul_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x0B
	jmp   XMB_FAULT

xmb_mul_fault_03:
	ldi   r24,     0x03
	ldi   r25,     0x0B
	jmp   XMB_FAULT

xmb_mul_fault_04:
	ldi   r24,     0x04
	ldi   r25,     0x0B
	jmp   XMB_FAULT

xmb_mul_fault_05:
	ldi   r24,     0x05
	ldi   r25,     0x0B
	jmp   XMB_FAULT



;
; Initializes multiplication component
;
.global xmb_mul_init
xmb_mul_init:
	ldi   ZL,      lo8(xmb_mul_rval)
	ldi   ZH,      hi8(xmb_mul_rval)
	ldi   r24,     0x49
	st    Z+,      r24
	ldi   r24,     0x9B
	st    Z+,      r24
	ret



;
; Software implementation of the MUL instruction
;
; Inputs:
;     r24: Multiplicand (unsigned)
;     r22: Multiplier (unsigned)
; Outputs:
; r25:r24: Result
;    SREG: Flags (Z and C set according to MUL, other ALU flags undefined)
; Clobbers:
; r20, r21
;
xmb_mul_sw_mul:

	ldi   r20,     0       ; Result low
	ldi   r21,     0       ; Result high
	ldi   r25,     0       ; Multiplicand high

xmb_mul_sw_mul_com:

	sbrc  r22,     0
	add   r20,     r24
	sbrc  r22,     0
	adc   r21,     r25

	lsl   r24
	rol   r25
	sbrc  r22,     1
	add   r20,     r24
	sbrc  r22,     1
	adc   r21,     r25

	lsl   r24
	rol   r25
	sbrc  r22,     2
	add   r20,     r24
	sbrc  r22,     2
	adc   r21,     r25

	lsl   r24
	rol   r25
	sbrc  r22,     3
	add   r20,     r24
	sbrc  r22,     3
	adc   r21,     r25

	lsl   r24
	rol   r25
	sbrc  r22,     4
	add   r20,     r24
	sbrc  r22,     4
	adc   r21,     r25

	lsl   r24
	rol   r25
	sbrc  r22,     5
	add   r20,     r24
	sbrc  r22,     5
	adc   r21,     r25

	lsl   r24
	rol   r25
	sbrc  r22,     6
	add   r20,     r24
	sbrc  r22,     6
	adc   r21,     r25

	lsl   r24
	rol   r25
	sbrc  r22,     7
	add   r20,     r24
	sbrc  r22,     7
	adc   r21,     r25

	ldi   r24,     0
	sez                    ; Z flag by result
	cpse  r20,     r24
	clz
	cpse  r21,     r24
	clz
	sec                    ; C flag by bit 15
	sbrs  r21,     7
	clc

	movw  r24,     r20
	ret



;
; Software implementation of the MULS instruction
;
; Inputs:
;     r24: Multiplicand (signed)
;     r22: Multiplier (signed)
; Outputs:
; r25:r24: Result
;    SREG: Flags (Z and C set according to MULS, other ALU flags undefined)
; Clobbers:
; r20, r21
;
xmb_mul_sw_muls:

	ldi   r20,     0       ; Result low
	ldi   r21,     0       ; Result high
	ldi   r25,     0       ; Multiplicand high
	sbrc  r24,     7
	ldi   r25,     0xFF    ; Sign extend
	sbrs  r22,     7
	rjmp  xmb_mul_sw_mul_com
	neg   r22              ; If multiplier is negative, negate both
	neg   r25              ; (After sign extend on the multiplicand to
	neg   r24              ; handle 0x80 correctly)
	sbci  r25,     0
	rjmp  xmb_mul_sw_mul_com



;
; Software implementation of the MULSU instruction
;
; Inputs:
;     r24: Multiplicand (signed)
;     r22: Multiplier (unsigned)
; Outputs:
; r25:r24: Result
;    SREG: Flags (Z and C set according to MULSU, other ALU flags undefined)
; Clobbers:
; r20, r21
;
xmb_mul_sw_mulsu:

	ldi   r20,     0       ; Result low
	ldi   r21,     0       ; Result high
	ldi   r25,     0       ; Multiplicand high
	sbrc  r24,     7
	ldi   r25,     0xFF    ; Sign extend
	rjmp  xmb_mul_sw_mul_com



;
; Software implementation of the FMUL instruction
;
; Inputs:
;     r24: Multiplicand (unsigned)
;     r22: Multiplier (unsigned)
; Outputs:
; r25:r24: Result
;    SREG: Flags (Z and C set according to FMUL, other ALU flags undefined)
; Clobbers:
; r20, r21
;
xmb_mul_sw_fmul:

	rcall xmb_mul_sw_mul
	add   r24,     r24
	adc   r25,     r25     ; Carry OK for FMUL
	or    r20,     r21     ; Zero flag (r21:r20 also contains result)
	ret



;
; Software implementation of the FMULS instruction
;
; Inputs:
;     r24: Multiplicand (unsigned)
;     r22: Multiplier (unsigned)
; Outputs:
; r25:r24: Result
;    SREG: Flags (Z and C set according to FMULS, other ALU flags undefined)
; Clobbers:
; r20, r21
;
xmb_mul_sw_fmuls:

	rcall xmb_mul_sw_muls
	add   r24,     r24
	adc   r25,     r25     ; Carry OK for FMULS
	or    r20,     r21     ; Zero flag (r21:r20 also contains result)
	ret



;
; Software implementation of the FMULSU instruction
;
; Inputs:
;     r24: Multiplicand (unsigned)
;     r22: Multiplier (unsigned)
; Outputs:
; r25:r24: Result
;    SREG: Flags (Z and C set according to FMULSU, other ALU flags undefined)
; Clobbers:
; r20, r21
;
xmb_mul_sw_fmulsu:

	rcall xmb_mul_sw_mulsu
	add   r24,     r24
	adc   r25,     r25     ; Carry OK for FMULSU
	or    r20,     r21     ; Zero flag (r21:r20 also contains result)
	ret



;
; Simple PRNG covering the full 16 bit range, used to generate test inputs
; for multiplications.
;
; Inputs:
; r25:r24: Current value in sequence
; Outputs:
; r25:r24: Next value in sequence
; Clobbers:
; r23
;
xmb_mul_prng:

	lsl   r24
	rol   r25
	ldi   r23,     0x8B
	adc   r24,     r23
	ldi   r23,     0x77
	adc   r25,     r23
	ldi   r23,     0x8B
	eor   r24,     r23
	ldi   r23,     0x4A
	eor   r25,     r23
	ret



;
; Test entry points
;
.global xmb_mul_test
.global xmb_mul_prng

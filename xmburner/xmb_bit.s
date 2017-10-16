;
; XMBurner - (0x0A) Bit instruction test
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
; - The CBI and SBI instructions.
; - The BST and BLD instructions.
; - The IN and OUT instructions.
;
; The SBI and SBI instructions are tested using GPIOR0 (which is available on
; both the ATMega and ATXMega families), which is restored. Interrupts are
; allowed to use GPIOR0 (the tests are guarded proper for this).
;
; Interrupts are disabled for up to 10 cycle periods during the test.
;

#include "xmb_defs.h"


.section XMB_COMP_SECTION


.set exec_id_from, 0x0AB18F43
.set exec_id,      0xD5F049E6


.set SR_IO,  _SFR_IO_ADDR(SREG)
.set GP0_IO, _SFR_IO_ADDR(GPIOR0)


.global xmb_bit
xmb_bit:

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
	brne  xmb_bit_fault_ff
	brcs  xmb_bit_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_bit_fault_ff
	brcs  xmb_bit_cbi

xmb_bit_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x09
	jmp   XMB_FAULT

xmb_bit_cbi:

	; IO bit clear test, tests whether the CBI instruction can clear each
	; bit of the GPIOR0 register. Interrupts are disabled for the tests to
	; preserve GPIOR0's state.

	in    r1,      SR_IO   ; Save SREG state with whatever 'I' flag it has

	ldi   r16,     0x93
	cli                    ; Interrupts disabled
	in    r0,      GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  r16
	cbi   GP0_IO,  0
	in    r9,      GP0_IO
	ldi   r16,     0x92
	cpse  r9,      r16
	rjmp  xmb_bit_fault_00
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r20,     0xE6
	cli                    ; Interrupts disabled
	in    r22,     GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  r20
	cbi   GP0_IO,  1
	in    r8,      GP0_IO
	ldi   r20,     0xE4
	cpse  r8,      r20
	rjmp  xmb_bit_fault_00
	out   GP0_IO,  r22
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   XH,      0x15
	cli                    ; Interrupts disabled
	in    r13,     GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  XH
	cbi   GP0_IO,  2
	in    r3,      GP0_IO
	ldi   XH,      0x11
	cpse  r3,      XH
	rjmp  xmb_bit_fault_00
	out   GP0_IO,  r13
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   ZH,      0x6F
	cli                    ; Interrupts disabled
	in    r3,      GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  ZH
	cbi   GP0_IO,  3
	in    r10,     GP0_IO
	ldi   ZH,      0x67
	cpse  r10,     ZH
	rjmp  xmb_bit_fault_00
	out   GP0_IO,  r3
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r18,     0xD9
	cli                    ; Interrupts disabled
	in    r8,      GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  r18
	cbi   GP0_IO,  4
	in    r7,      GP0_IO
	ldi   r18,     0xC9
	cpse  r7,      r18
	rjmp  xmb_bit_fault_00
	out   GP0_IO,  r8
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r25,     0x3B
	cli                    ; Interrupts disabled
	in    r10,     GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  r25
	cbi   GP0_IO,  5
	in    r15,     GP0_IO
	ldi   r25,     0x1B
	cpse  r15,     r25
	rjmp  xmb_bit_fault_00
	out   GP0_IO,  r10
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r17,     0xCC
	cli                    ; Interrupts disabled
	in    ZL,      GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  r17
	cbi   GP0_IO,  6
	in    r12,     GP0_IO
	ldi   r17,     0x8C
	cpse  r12,     r17
	rjmp  xmb_bit_fault_00
	out   GP0_IO,  ZL
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   XL,      0xAE
	cli                    ; Interrupts disabled
	in    r6,      GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  XL
	cbi   GP0_IO,  7
	in    r4,      GP0_IO
	ldi   XL,      0x2E
	cpse  r4,      XL
	rjmp  xmb_bit_fault_00
	out   GP0_IO,  r6
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

xmb_bit_sbi:

	; IO bit set test, tests whether the SBI instruction can set each bit
	; of the GPIOR0 register. Interrupts are disabled for the tests to
	; preserve GPIOR0's state.

	in    r10,     SR_IO   ; Save SREG state with whatever 'I' flag it has

	ldi   YL,      0x76
	cli                    ; Interrupts disabled
	in    r1,      GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  YL
	sbi   GP0_IO,  0
	in    r0,      GP0_IO
	ldi   YL,      0x77
	cpse  r0,      YL
	rjmp  xmb_bit_fault_01
	out   GP0_IO,  r1
	out   SR_IO,   r10     ; Restore SREG with whatever 'I' flag it had

	ldi   r24,     0x49
	cli                    ; Interrupts disabled
	in    r23,     GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  r24
	sbi   GP0_IO,  1
	in    r11,     GP0_IO
	ldi   r24,     0x4B
	cpse  r11,     r24
	rjmp  xmb_bit_fault_01
	out   GP0_IO,  r23
	out   SR_IO,   r10     ; Restore SREG with whatever 'I' flag it had

	ldi   r23,     0xF0
	cli                    ; Interrupts disabled
	in    r14,     GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  r23
	sbi   GP0_IO,  2
	in    r1,      GP0_IO
	ldi   r23,     0xF4
	cpse  r1,      r23
	rjmp  xmb_bit_fault_01
	out   GP0_IO,  r14
	out   SR_IO,   r10     ; Restore SREG with whatever 'I' flag it had

	ldi   r19,     0xB2
	cli                    ; Interrupts disabled
	in    r12,     GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  r19
	sbi   GP0_IO,  3
	in    r5,      GP0_IO
	ldi   r19,     0xBA
	cpse  r5,      r19
	rjmp  xmb_bit_fault_01
	out   GP0_IO,  r12
	out   SR_IO,   r10     ; Restore SREG with whatever 'I' flag it had

	ldi   r21,     0x23
	cli                    ; Interrupts disabled
	in    ZL,      GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  r21
	sbi   GP0_IO,  4
	in    r13,     GP0_IO
	ldi   r21,     0x33
	cpse  r13,     r21
	rjmp  xmb_bit_fault_01
	out   GP0_IO,  ZL
	out   SR_IO,   r10     ; Restore SREG with whatever 'I' flag it had

	ldi   YH,      0xDE
	cli                    ; Interrupts disabled
	in    r16,     GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  YH
	sbi   GP0_IO,  5
	in    r6,      GP0_IO
	ldi   YH,      0xFE
	cpse  r6,      YH
	rjmp  xmb_bit_fault_01
	out   GP0_IO,  r16
	out   SR_IO,   r10     ; Restore SREG with whatever 'I' flag it had

	ldi   ZL,      0x25
	cli                    ; Interrupts disabled
	in    r4,      GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  ZL
	sbi   GP0_IO,  6
	in    r14,     GP0_IO
	ldi   ZL,      0x65
	cpse  r14,     ZL
	rjmp  xmb_bit_fault_01
	out   GP0_IO,  r4
	out   SR_IO,   r10     ; Restore SREG with whatever 'I' flag it had

	ldi   r22,     0x47
	cli                    ; Interrupts disabled
	in    r7,      GP0_IO  ; Save GPIOR0 state
	out   GP0_IO,  r22
	sbi   GP0_IO,  7
	in    r2,      GP0_IO
	ldi   r22,     0xC7
	cpse  r2,      r22
	rjmp  xmb_bit_fault_01
	out   GP0_IO,  r7
	out   SR_IO,   r10     ; Restore SREG with whatever 'I' flag it had

xmb_bit_bst:
xmb_bit_bld:

	; Bit store test, tests whether the BST instruction is capable to
	; access each bit position in registers.

	ldi   ZL,      0x01
	ldi   ZH,      0xFE
	movw  r0,      r16
	ldi   YL,      0x02
	ldi   YH,      0xFD
	movw  r2,      r16
	ldi   XL,      0x04
	ldi   XH,      0xFB
	movw  r4,      r16
	ldi   r24,     0x08
	ldi   r25,     0xF7
	movw  r6,      r16
	ldi   r22,     0x10
	ldi   r23,     0xEF
	movw  r8,      r16
	ldi   r20,     0x20
	ldi   r21,     0xDF
	movw  r10,     r16
	ldi   r18,     0x40
	ldi   r19,     0xBF
	movw  r12,     r16
	ldi   r16,     0x80
	ldi   r17,     0x7F
	movw  r14,     r16

	bst   r0,      0
	brts  .+2
	rjmp  xmb_bit_fault_02
	bst   ZH,      0
	brtc  .+2
	rjmp  xmb_bit_fault_02
	bst   YL,      1
	brts  .+2
	rjmp  xmb_bit_fault_02
	bst   r3,      1
	brtc  .+2
	rjmp  xmb_bit_fault_02
	bst   r4,      2
	brts  .+2
	rjmp  xmb_bit_fault_02
	bst   XH,      2
	brtc  .+2
	rjmp  xmb_bit_fault_02
	bst   r24,     3
	brts  .+2
	rjmp  xmb_bit_fault_02
	bst   r7,      3
	brtc  .+2
	rjmp  xmb_bit_fault_02
	bst   r8,      4
	brts  .+2
	rjmp  xmb_bit_fault_02
	bst   r23,     4
	brtc  .+2
	rjmp  xmb_bit_fault_02
	bst   r20,     5
	brts  .+2
	rjmp  xmb_bit_fault_02
	bst   r11,     5
	brtc  .+2
	rjmp  xmb_bit_fault_02
	bst   r12,     6
	brts  .+2
	rjmp  xmb_bit_fault_02
	bst   r19,     6
	brtc  .+2
	rjmp  xmb_bit_fault_02
	bst   r16,     7
	brts  .+2
	rjmp  xmb_bit_fault_02
	bst   r15,     7
	brtc  .+2
	rjmp  xmb_bit_fault_02

	; Bit load test, tests whether the BLD instruction is capable to
	; access each bit position in registers.

	ldi   ZH,      0xFF
	ldi   YL,      0x00

	set
	bld   r1,      0
	cpse  r1,      ZH
	rjmp  xmb_bit_fault_03
	bld   YH,      1
	cpse  YH,      ZH
	rjmp  xmb_bit_fault_03
	bld   r5,      2
	cpse  r5,      ZH
	rjmp  xmb_bit_fault_03
	bld   r25,     3
	cpse  r25,     ZH
	rjmp  xmb_bit_fault_03
	bld   r9,      4
	cpse  r9,      ZH
	rjmp  xmb_bit_fault_03
	bld   r21,     5
	cpse  r21,     ZH
	rjmp  xmb_bit_fault_03
	bld   r13,     6
	cpse  r13,     ZH
	rjmp  xmb_bit_fault_03
	bld   r17,     7
	cpse  r17,     ZH
	rjmp  xmb_bit_fault_03
	clt
	bld   ZL,      0
	cpse  ZL,      YL
	rjmp  xmb_bit_fault_03
	bld   r2,      1
	cpse  r2,      YL
	rjmp  xmb_bit_fault_03
	bld   XL,      2
	cpse  XL,      YL
	rjmp  xmb_bit_fault_03
	bld   r6,      3
	cpse  r6,      YL
	rjmp  xmb_bit_fault_03
	bld   r22,     4
	cpse  r22,     YL
	rjmp  xmb_bit_fault_03
	bld   r10,     5
	cpse  r10,     YL
	rjmp  xmb_bit_fault_03
	bld   r18,     6
	cpse  r18,     YL
	rjmp  xmb_bit_fault_03
	bld   r14,     7
	cpse  r14,     YL
	rjmp  xmb_bit_fault_03


	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next


xmb_bit_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x0A
	jmp   XMB_FAULT

xmb_bit_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x0A
	jmp   XMB_FAULT

xmb_bit_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x0A
	jmp   XMB_FAULT

xmb_bit_fault_03:
	ldi   r24,     0x03
	ldi   r25,     0x0A
	jmp   XMB_FAULT


;
; Test entry points
;
.global xmb_bit_cbi
.global xmb_bit_sbi
.global xmb_bit_bst
.global xmb_bit_bld

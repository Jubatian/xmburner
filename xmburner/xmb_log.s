;
; XMBurner - (0x05) Logic instruction test
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
; - The AND and ANDI instructions including SREG operations.
; - The OR and ORI instructions including SREG operations.
; - The EOR instruction including SREG operations.
; - The COM instruction including SREG operations.
; - The MOV and MOVW instructions (only high register sources for the latter).
;
; Interrupts are enabled after this component (it also doesn't disable them).
;

#include "xmb_defs.h"


.section .text


.set exec_id_from, 0x6B0DE257
.set exec_id,      0x7E3CE0B6

.set SR_IO,  _SFR_IO_ADDR(SREG)


.global xmb_log
xmb_log:

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
	brne  xmb_log_fault_ff
	brcs  xmb_log_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_log_fault_ff
	brcs  xmb_log_test

xmb_log_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x05
	jmp   XMB_FAULT

xmb_log_test:

	; Prepare test values for all tests. These are selected to have a good
	; representation over the possible range, allowing to test all
	; affected flag sets and clears (S, V, N, Z are modified, other flags
	; are not).

	ldi   YL,      0x00
	ldi   YH,      0xFF
	movw  r0,      YL      ; Test values: r0: 0x00; r1: 0xFF
	ldi   r20,     0xA5
	ldi   r21,     0x5A
	movw  r6,      r20     ; Test values: r6: 0xA5; r7: 0x5A
	ldi   r20,     0x96
	ldi   r21,     0x69    ; Test values: r20: 0x96; r21: 0x69
	ldi   r16,     0xED
	ldi   r17,     0xDE
	movw  r10,     r16     ; Test values: r10: 0xED; r11: 0xDE
	ldi   XL,      0x7B
	ldi   XH,      0xB7
	movw  r12,     XL      ; Test values: r12: 0x7B; r13: 0xB7
	ldi   r18,     0x84
	ldi   r19,     0x48
	movw  r14,     r18     ; Test values: r14: 0x84; r15: 0x48
	ldi   ZL,      0x21
	ldi   ZH,      0x12    ; Test values: ZL: 0x21; ZH: 0x12
	ldi   YL,      0x33
	ldi   YH,      0xCC    ; Test values: YL: 0x33; YH: 0xCC
	ldi   r16,     0x80    ; Flag test: r16: Ithsvnzc
	ldi   r17,     0x82    ; Flag test: r17: IthsvnZc
	ldi   r18,     0x94    ; Flag test: r18: IthSvNzc
	ldi   r19,     0xE1    ; Flag test: r19: ITHsvnzC
	ldi   r22,     0xE3    ; Flag test: r22: ITHsvnZC
	ldi   r23,     0xF5    ; Flag test: r23: ITHSvNzC

	; OR & ORI instruction test. Covers all four possible logic
	; combinations for all bits (0d0s, 0d1s, 1d0s, 1d1s) and all possible
	; flag outputs.

	out   SR_IO,   r16     ; Set flags: Ithsvnzc

	mov   r3,      r0      ; 0x00 (00000000) |
	or    r3,      r0      ; 0x00 (00000000)
	cpse  r3,      r0      ; 0x00 (00000000) Result
	rjmp  xmb_log_fault_00
	in    r3,      SR_IO
	cpse  r3,      r17     ; Flags must be: IthsvnZc
	rjmp  xmb_log_fault_00

	mov   r25,     r6      ; 0xA5 (10100101) |
	or    r25,     r21     ; 0x69 (01101001)
	cpse  r25,     r10     ; 0xED (11101101) Result
	rjmp  xmb_log_fault_00
	in    r3,      SR_IO
	cpse  r3,      r18     ; Flags must be: IthSvNzc
	rjmp  xmb_log_fault_00

	mov   r24,     r7      ; 0x5A (01011010) |
	ori   r24,     0x69    ; 0x69 (01101001)
	cpse  r24,     r12     ; 0x7B (01111011) Result
	rjmp  xmb_log_fault_00
	in    r3,      SR_IO
	cpse  r3,      r16     ; Flags must be: Ithsvnzc
	rjmp  xmb_log_fault_00

	out   SR_IO,   r1      ; Set flags: ITHSVNZC

	mov   XL,      r0      ; 0x00 (00000000) |
	ori   XL,      0x00    ; 0x00 (00000000)
	cpse  XL,      r0      ; 0x00 (00000000) Result
	rjmp  xmb_log_fault_00
	in    r3,      SR_IO
	cpse  r3,      r22     ; Flags must be: ITHsvnZC
	rjmp  xmb_log_fault_00

	mov   XH,      r7      ; 0x5A (01011010) |
	ori   XH,      0x96    ; 0x96 (10010110)
	cpse  XH,      r11     ; 0xDE (11011110) Result
	rjmp  xmb_log_fault_00
	in    r3,      SR_IO
	cpse  r3,      r23     ; Flags must be: ITHSvNzC
	rjmp  xmb_log_fault_00

	mov   r2,      r6      ; 0xA5 (10100101) |
	or    r2,      r20     ; 0x96 (10010110)
	cpse  r2,      r13     ; 0xB7 (10110111) Result
	rjmp  xmb_log_fault_00
	in    r3,      SR_IO
	cpse  r3,      r23     ; Flags must be: ITHSvNzC
	rjmp  xmb_log_fault_00

	mov   r9,      r6      ; 0xA5 (10100101) |
	or    r9,      r7      ; 0x5A (01011010)
	cpse  r9,      r1      ; 0xFF (11111111) Result (Testing 0xFF result)
	rjmp  xmb_log_fault_00
	in    r3,      SR_IO
	cpse  r3,      r23     ; Flags must be: ITHSvNzC
	rjmp  xmb_log_fault_00

	mov   XH,      r21     ; 0x69 (01101001) |
	or    XH,      r7      ; 0x5A (01011010)
	cpse  XH,      r12     ; 0x7B (01111011) Result (Just for flag combination)
	rjmp  xmb_log_fault_00
	in    r3,      SR_IO
	cpse  r3,      r19     ; Flags must be: ITHsvnzC
	rjmp  xmb_log_fault_00

	; AND & ANDI instruction test. Covers all four possible logic
	; combinations for all bits (0d0s, 0d1s, 1d0s, 1d1s) and all possible
	; flag outputs.

	out   SR_IO,   r16     ; Set flags: Ithsvnzc

	mov   XL,      r0      ; 0x00 (00000000) &
	andi  XL,      0x00    ; 0x00 (00000000)
	cpse  XL,      r0      ; 0x00 (00000000) Result
	rjmp  xmb_log_fault_01
	in    r3,      SR_IO
	cpse  r3,      r17     ; Flags must be: IthsvnZc
	rjmp  xmb_log_fault_01

	mov   r3,      r7      ; 0x5A (01011010) &
	and   r3,      r20     ; 0x96 (10010110)
	cpse  r3,      ZH      ; 0x12 (00010010) Result
	rjmp  xmb_log_fault_01
	in    r3,      SR_IO
	cpse  r3,      r16     ; Flags must be: Ithsvnzc
	rjmp  xmb_log_fault_01

	mov   r25,     r6      ; 0xA5 (10100101) &
	andi  r25,     0x96    ; 0x96 (10010110)
	cpse  r25,     r13     ; 0x84 (10000100) Result
	rjmp  xmb_log_fault_01
	in    r3,      SR_IO
	cpse  r3,      r18     ; Flags must be: IthSvNzc
	rjmp  xmb_log_fault_01

	out   SR_IO,   r1      ; Set flags: ITHSVNZC

	mov   r8,      r0      ; 0x00 (00000000) &
	and   r8,      r0      ; 0x00 (00000000)
	cpse  r8,      r0      ; 0x00 (00000000) Result
	rjmp  xmb_log_fault_01
	in    r3,      SR_IO
	cpse  r3,      r22     ; Flags must be: ITHsvnZC
	rjmp  xmb_log_fault_01

	mov   r24,     r6      ; 0xA5 (10100101) &
	and   r24,     r21     ; 0x69 (01101001)
	cpse  r24,     ZL      ; 0x21 (00100001) Result
	rjmp  xmb_log_fault_01
	in    r3,      SR_IO
	cpse  r3,      r19     ; Flags must be: ITHsvnzC
	rjmp  xmb_log_fault_01

	mov   r4,      r7      ; 0x5A (01011010) &
	and   r4,      r21     ; 0x69 (01101001)
	cpse  r4,      r15     ; 0x48 (01001000) Result
	rjmp  xmb_log_fault_01
	in    r3,      SR_IO
	cpse  r3,      r19     ; Flags must be: ITHsvnzC
	rjmp  xmb_log_fault_01

	mov   XH,      r1      ; 0xFF (11111111) &
	andi  XH,      0xFF    ; 0xFF (11111111)
	cpse  XH,      r1      ; 0xFF (11111111) Result (Testing 0xFF result & flag combo)
	rjmp  xmb_log_fault_01
	in    r3,      SR_IO
	cpse  r3,      r23     ; Flags must be: ITHSvNzC
	rjmp  xmb_log_fault_01

	; EOR instruction test. Covers all four possible logic combinations
	; for all bits (0d0s, 0d1s, 1d0s, 1d1s) and all possible flag outputs.

	out   SR_IO,   r16     ; Set flags: Ithsvnzc

	mov   r9,      r0      ; 0x00 (00000000) ^
	eor   r9,      r0      ; 0x00 (00000000)
	cpse  r9,      r0      ; 0x00 (00000000) Result
	rjmp  xmb_log_fault_02
	in    r3,      SR_IO
	cpse  r3,      r17     ; Flags must be: IthsvnZc
	rjmp  xmb_log_fault_02

	mov   r25,     r7      ; 0x5A (01011010) ^
	eor   r25,     r20     ; 0x96 (10010110)
	cpse  r25,     YH      ; 0xCC (11001100) Result
	rjmp  xmb_log_fault_02
	in    r3,      SR_IO
	cpse  r3,      r18     ; Flags must be: IthSvNzc
	rjmp  xmb_log_fault_02

	mov   r2,      r6      ; 0xA5 (10100101) ^
	eor   r2,      r20     ; 0x96 (10010110)
	cpse  r2,      YL      ; 0x33 (00110011) Result
	rjmp  xmb_log_fault_02
	in    r3,      SR_IO
	cpse  r3,      r16     ; Flags must be: Ithsvnzc
	rjmp  xmb_log_fault_02

	out   SR_IO,   r1      ; Set flags: ITHSVNZC

	mov   XL,      r1      ; 0xFF (11111111) ^
	eor   XL,      r1      ; 0xFF (11111111)
	cpse  XL,      r0      ; 0x00 (00000000) Result
	rjmp  xmb_log_fault_02
	in    r3,      SR_IO
	cpse  r3,      r22     ; Flags must be: ITHsvnZC
	rjmp  xmb_log_fault_02

	mov   r24,     r6      ; 0xA5 (10100101) ^
	eor   r24,     r21     ; 0x69 (01101001)
	cpse  r24,     YH      ; 0xCC (11001100) Result
	rjmp  xmb_log_fault_02
	in    r3,      SR_IO
	cpse  r3,      r23     ; Flags must be: ITHSvNzC
	rjmp  xmb_log_fault_02

	mov   r8,      r7      ; 0x5A (01011010) ^
	eor   r8,      r21     ; 0x69 (01101001)
	cpse  r8,      YL      ; 0x48 (01001000) Result
	rjmp  xmb_log_fault_02
	in    r3,      SR_IO
	cpse  r3,      r19     ; Flags must be: ITHsvnzC
	rjmp  xmb_log_fault_02

	mov   XH,      r21     ; 0x69 (01101001) ^
	eor   XH,      r20     ; 0x96 (10010110)
	cpse  XH,      r1      ; 0xFF (11111111) Result (Testing 0xFF result)
	rjmp  xmb_log_fault_02
	in    r3,      SR_IO
	cpse  r3,      r23     ; Flags must be: ITHSvNzC
	rjmp  xmb_log_fault_02

	; COM instruction test. Covers all four possible logic combinations
	; for all bits (0d1s, 0d1s; it is an EOR with 0xFF) and all possible
	; flag outputs.

	out   SR_IO,   r16     ; Set flags: Ithsvnzc

	mov   r4,      r1      ; 0xFF (11111111) ^
	com   r4               ; 0xFF (11111111)
	cpse  r4,      r0      ; 0x00 (00000000) Result
	rjmp  xmb_log_fault_03
	in    r3,      SR_IO
	cpse  r3,      r17     ; Flags must be: IthsvnZc
	rjmp  xmb_log_fault_03

	mov   r25,     r7      ; 0x5A (01011010) ^
	com   r25              ; 0xFF (11111111)
	cpse  r25,     r6      ; 0xA5 (10100101) Result
	rjmp  xmb_log_fault_03
	in    r3,      SR_IO
	cpse  r3,      r18     ; Flags must be: IthSvNzc
	rjmp  xmb_log_fault_03

	mov   r5,      r20     ; 0x96 (10010110) ^
	com   r5               ; 0xFF (11111111)
	cpse  r5,      r21     ; 0x69 (01101001) Result
	rjmp  xmb_log_fault_03
	in    r3,      SR_IO
	cpse  r3,      r16     ; Flags must be: Ithsvnzc
	rjmp  xmb_log_fault_03

	out   SR_IO,   r1      ; Set flags: ITHSVNZC

	mov   r24,     r1      ; 0xFF (11111111) ^
	com   r24              ; 0xFF (11111111)
	cpse  r24,     r0      ; 0x00 (00000000) Result
	rjmp  xmb_log_fault_03
	in    r3,      SR_IO
	cpse  r3,      r22     ; Flags must be: ITHsvnZC
	rjmp  xmb_log_fault_03

	mov   XL,      r21     ; 0x69 (01101001) ^
	com   XL               ; 0xFF (11111111)
	cpse  XL,      r20     ; 0x96 (10010110) Result
	rjmp  xmb_log_fault_03
	in    r3,      SR_IO
	cpse  r3,      r23     ; Flags must be: ITHSvNzC
	rjmp  xmb_log_fault_03

	mov   r9,      r6      ; 0xA5 (10100101) ^
	com   r9               ; 0xFF (11111111)
	cpse  r9,      r7      ; 0x5A (01011010) Result
	rjmp  xmb_log_fault_03
	in    r3,      SR_IO
	cpse  r3,      r19     ; Flags must be: ITHsvnzC
	rjmp  xmb_log_fault_03

	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next


xmb_log_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x05
	jmp   XMB_FAULT

xmb_log_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x05
	jmp   XMB_FAULT

xmb_log_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x05
	jmp   XMB_FAULT

xmb_log_fault_03:
	ldi   r24,     0x03
	ldi   r25,     0x05
	jmp   XMB_FAULT



;
; Test entry points
;
.global xmb_log_test

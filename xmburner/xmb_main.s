;
; XMBurner - main logic
;
; Copyright (C) 2017 Sandor Zsuga (Jubatian)
;
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.
;

#include "xmb_defs.h"


.section .text


;
; Default failure handler.
;
.global xmb_fault_def
xmb_fault_def:
	rjmp  .-2
	jmp   0



;
; Initialize.
; void xmb_init(void);
;
; Initializes the ALU tester.
;
.global xmb_init
xmb_init:

	; (Will jump onto a specific init test after setting up)

	ret



;
; Main runner.
; void xmb_run(void);
;
; Calling this repeatedely will execute the various ALU tests, each pass
; designed to take less than 10K cycles.
;
.global xmb_run
xmb_run:

	; Save registers the C ABI requires to preserve

	push  YH
	push  YL
	push  r17
	push  r16
	push  r15
	push  r14
	push  r13
	push  r12
	push  r11
	push  r10
	push  r9
	push  r8
	push  r7
	push  r6
	push  r5
	push  r4
	push  r3
	push  r2

	; Prepare for test entry by reading the execution chain and
	; invalidating it (the test after successful completion will write the
	; correct value in it for the subsequent test).

	ldi   ZL,      lo8(xmb_glob_chain)
	ldi   ZH,      hi8(xmb_glob_chain)
	ldd   r16,     Z + 0
	ldd   r17,     Z + 1
	ldd   r18,     Z + 2
	ldd   r19,     Z + 3
	ldi   r20,     0x00
	std   Z + 2,   r20
	std   Z + 3,   r20

	; Select next test to run

	ldi   r24,     0xFF
	ldi   r25,     0xFF    ; Fault code for bad jumps
	lds   ZL,      glob_next
	lsl   ZL
	andi  ZL,      0xFE
	ldi   ZH,      hi8(pm(xmb_test_table))
	ijmp

;
; 128 entry jump table to the various tests, aligned to 512b boundary.
; The 0x00 padding is a nop slide, even if the "ijmp" above fails, the first
; test will be started.
;
.balign 512, 0x00
xmb_test_table:

	jmp   xmb_creg
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT

	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT

	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT

	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT

	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT

	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT

	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT

	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT
	jmp   XMB_FAULT

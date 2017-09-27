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
; Initialize.
; void xmb_init(void);
;
; Initializes the ALU tester. Note that it takes a long time (ideally more
; than the timeout of all watchdogs used in the application, see
; XMB_INIT_DELAY).
;
.global xmb_init
xmb_init:

	; Initialization guard delay

	ldi   r25,     XMB_INIT_DELAY
	ldi   r24,     0
	ldi   r23,     0
	dec   r23
	nop
	brne  .-6              ; 4 cycles / iteration; 1K cycles
	dec   r24
	brne  .-12             ; 256K cycles
	dec   r25
	brne  .-18             ; XMB_INIT_DELAY * 256K cycles

	; Initialization guard notes:
	; It is not really possible to use anything else here than a watchdog.
	; The initial state of the RAM is undefined, if the system is
	; power-cycled (or suffers a brownout), it might still contain
	; previous values, and it might be desirable depending on the
	; application to start up proper from this condition. It is so not
	; possible to rely on guard values. In any sane design however during
	; init watchdogs should still be uninitialized or timed out.

	; Initialize components which require initialization

	call  xmb_crc_init
	call  xmb_ram_init

	; Initialize execution chain to first component (xmb_creg)
	; Note: this is the exec_id_from value in xmb_creg.s

	ldi   r25,     0x0A
	ldi   r24,     0xB1
	ldi   r23,     0x8F
	ldi   r22,     0x43
	ldi   ZL,      lo8(xmb_glob_chain)
	ldi   ZH,      hi8(xmb_glob_chain)
	st    Z+,      r22
	st    Z+,      r23
	st    Z+,      r24
	st    Z+,      r25
	ldi   r25,     0x00
	sts   xmb_glob_next, r25

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
	lds   ZL,      xmb_glob_next
	lsl   ZL
	andi  ZL,      0xFE
	ldi   ZH,      hi8(pm(xmb_test_table))
#ifdef EIND
	ldi   r20,     hh8(pm(xmb_test_table))
	out   EIND,    r20
#endif
	ijmp

;
; 128 entry jump table to the various tests, aligned to 512b boundary.
; The 0x00 padding is a nop slide, even if the "ijmp" above fails, the first
; test will be started.
;
.balign 512, 0x00
xmb_test_table:

	jmp   xmb_creg
	jmp   xmb_cond
	jmp   xmb_jump
	jmp   xmb_crc
	jmp   xmb_ram
	jmp   xmb_log
	jmp   xmb_sub
	jmp   xmb_add
	jmp   xmb_alex
	jmp   xmb_wops
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



;
; Return next XMBurner component which will run on xmb_run().
; uint8_t xmb_next(void);
;
.global xmb_next
xmb_next:

	lds   r24,     xmb_glob_next
	clr   r25
	ret

;
; XMBurner - globals
;
; Copyright (C) 2017 Sandor Zsuga (Jubatian)
;
; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at http://mozilla.org/MPL/2.0/.
;

#include "xmb_defs.h"


.section .data


;
; Next element in the execution chain. This selects the routine to execute on
; the next call.
;
.global xmb_glob_next
xmb_glob_next:
	.space 1

;
; Execution chain state. This variable contains the 32 bit identifier of the
; last executed routine by which the library can verify whether the execution
; order is still intact.
;
.global xmb_glob_chain
xmb_glob_chain:
	.space 4



.section .text


;
; Trailing code for returning to restore registers for C
;
.global xmb_glob_tail_next
.global xmb_glob_tail
xmb_glob_tail_next:
	ldi   r25,     0xDE
	ldi   r24,     0xAD
	ldi   r23,     0xF1
	ldi   r22,     0x58    ; Comparison parameter for WD reset
	call  XMB_WDRESET
	lds   r0,      xmb_glob_next
	inc   r0
	sts   xmb_glob_next, r0
	ldi   ZL,      lo8(xmb_glob_chain)
	ldi   ZH,      hi8(xmb_glob_chain)
	std   Z + 2,   r18
	std   Z + 3,   r19
xmb_glob_tail:
	clr   r1
#ifdef EIND
	out   EIND,    r1      ; Required for normal C programs
#endif
	pop   r2
	pop   r3
	pop   r4
	pop   r5
	pop   r6
	pop   r7
	pop   r8
	pop   r9
	pop   r10
	pop   r11
	pop   r12
	pop   r13
	pop   r14
	pop   r15
	pop   r16
	pop   r17
	pop   YL
	pop   YH
	ret



;
; Default watchdog reset routine
;
.global xmb_wdreset_default
xmb_wdreset_default:
	ldi   r21,     0xDE
	ldi   r20,     0xAD
	cpse  r25,     r21
	rjmp  xmb_wdreset_default_nr
	cpse  r24,     r20
	rjmp  xmb_wdreset_default_nr
	subi  r23,     0xF1
	brne  xmb_wdreset_default_nr
	subi  r22,     0x58
	brne  xmb_wdreset_default_nr
	wdr
	ret
xmb_wdreset_default_nr:
	ldi   r24,     0xFF
	ldi   r25,     0xFF
	jmp   XMB_FAULT

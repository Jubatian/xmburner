;
; XMBurner - (0x02) Branch tests
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
; - Relative branching using BRBC / BRBS instructions.
; - Relative jumping and calling using the RJMP / RCALL instructions.
;
; The goal is to verify whether in the typical short range (BRBS / BRBC
; instructions' range) the branch targets are calculated properly.
;
; The component should ideally be located in the middle of the flash so it can
; test the longest carry sequence on the relative jump / branch adder. See
; notes for XMB_JUMP_SECTION in xmb_defs.h.
;

#include "xmb_defs.h"


.section XMB_JUMP_SECTION


.set exec_id_from, 0x849AB017
.set exec_id,      0xA9F105DB

.set SR_IO,  _SFR_IO_ADDR(SREG)
.set SPL_IO, _SFR_IO_ADDR(SPL)
.set SPH_IO, _SFR_IO_ADDR(SPH)


.global xmb_jump
xmb_jump:

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
	brne  xmb_jump_fault_ff
	brcs  xmb_jump_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_jump_fault_ff
	brcs  xmb_jump_branch

xmb_jump_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x02
	jmp   XMB_FAULT

xmb_jump_rjump2a:

	rjmp  xmb_jump_rjump2b ; Part of crude large range rjmp test
	ijmp
	rcall xmb_jump_rjump2d
	ijmp

xmb_jump_branch:

	; Tests branch instruction range using always jumping branches. The
	; IJMP instruction is used to target the fault handler in need which
	; is an absolute jump, unlikely to be affected by failures this test
	; tries to detect (anomalies in the adder used for calculating branch
	; targets).
	;
	; It doesn't test all individual possible branches with the assumption
	; that such a flaw only affecting one particular instruction word is
	; very unlikely, rather aims to produce good coverage on the adder
	; logic underneath. Having the branches 3 instruction words apart
	; helps this by generating more diverse binary encodings.

	ldi   ZL,      lo8(pm(xmb_jump_fault_00))
	ldi   ZH,      hi8(pm(xmb_jump_fault_00))
#ifdef EIND
	ldi   r20,     hh8(pm(xmb_jump_fault_00))
	out   EIND,    r20
#endif
	in    r23,     SR_IO
	ori   r23,     0x7F    ; All flags expect 'I' set (which is left as-is)
	out   SR_IO,   r23
	ldi   YH,      hi8(RAMSTART)
	ldi   YL,      0       ; Guard value (note: using LD to prevent modifying SREG)
	ldi   XH,      hi8(RAMSTART + 0x100)
	ldi   XL,      0       ; Guard value (note: using LD to prevent modifying SREG)

	breq  .+126            ; 0
	ijmp
	ld    r0,      Y+      ; 2; YL = 0x01
	brhs  .+114
	ijmp
	ld    r0,      Y+      ; 4; YL = 0x02
	brlt  .+102
	ijmp
	ld    r0,      Y+      ; 6; YL = 0x03
	brcs  .+90
	ijmp
	ld    r0,      Y+      ; 8; YL = 0x04
	brvs  .+78
	ijmp
	ld    r0,      Y+      ; 10; YL = 0x05
	brlt  .+66
	ijmp
	ld    r0,      Y+      ; 12; YL = 0x06
	brts  .+54
	ijmp
	ld    r0,      Y+      ; 14; YL = 0x07
	brmi  .+42
	ijmp
	ld    r0,      Y+      ; 16; YL = 0x08
	breq  .+30
	ijmp
	ld    r0,      Y+      ; 18; YL = 0x09
	brcs  .+18
	ijmp
	ld    r0,      Y+      ; 20; YL = 0x0A
	brhs  .+6
	ijmp
	brcs  xmb_jump_branch0t
	ijmp
	ld    r0,      -X      ; 21; XL = 0xF5
	brmi  .-8
	ijmp
	ld    r0,      -X      ; 19; XL = 0xF6
	brts  .-20
	ijmp
	ld    r0,      -X      ; 17; XL = 0xF7
	brvs  .-32
	ijmp
	ld    r0,      -X      ; 15; XL = 0xF8
	brlt  .-44
	ijmp
	ld    r0,      -X      ; 13; XL = 0xF9
	brhs  .-56
	ijmp
	ld    r0,      -X      ; 11; XL = 0xFA
	breq  .-68
	ijmp
	ld    r0,      -X      ; 9; XL = 0xFB
	brmi  .-80
	ijmp
	ld    r0,      -X      ; 7; XL = 0xFC
	breq  .-92
	ijmp
	ld    r0,      -X      ; 5; XL = 0xFD
	brvs  .-104
	ijmp
	ld    r0,      -X      ; 3; XL = 0xFE
	brts  .-116
	ijmp
	ld    r0,      -X      ; 1; XL = 0xFF
	brcs  .-128
	ijmp

xmb_jump_branch0t:

	ldi   r16,     0x0A
	ldi   r17,     0xF5
	cpse  YL,      r16
	ijmp
	cpse  XL,      r17
	ijmp
	rjmp  xmb_jump_branch1

xmb_jump_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x02
	jmp   XMB_FAULT

xmb_jump_branch1:

	ldi   ZL,      lo8(pm(xmb_jump_fault_01))
	ldi   ZH,      hi8(pm(xmb_jump_fault_01))
#ifdef EIND
	ldi   r20,     hh8(pm(xmb_jump_fault_01))
	out   EIND,    r20
#endif
	in    r23,     SR_IO
	andi  r23,     0x80    ; All flags expect 'I' set (which is left as-is)
	out   SR_IO,   r23

	brne  .+124            ; 0
	ijmp
	ld    r0,      Y+      ; 2; YL = 0x0B
	brhc  .+112
	ijmp
	ld    r0,      Y+      ; 4; YL = 0x0C
	brge  .+100
	ijmp
	ld    r0,      Y+      ; 6; YL = 0x0D
	brcc  .+88
	ijmp
	ld    r0,      Y+      ; 8; YL = 0x0E
	brvc  .+76
	ijmp
	ld    r0,      Y+      ; 10; YL = 0x0F
	brge  .+64
	ijmp
	ld    r0,      Y+      ; 12; YL = 0x10
	brtc  .+52
	ijmp
	ld    r0,      Y+      ; 14; YL = 0x11
	brpl  .+40
	ijmp
	ld    r0,      Y+      ; 16; YL = 0x12
	brne  .+28
	ijmp
	ld    r0,      Y+      ; 18; YL = 0x13
	brcc  .+16
	ijmp
	ld    r0,      Y+      ; 20; YL = 0x14
	brhc  .+4
	ijmp
	brcc  xmb_jump_branch1t
	ld    r0,      -X      ; 21; XL = 0xEA
	brpl  .-6
	ijmp
	ld    r0,      -X      ; 19; XL = 0xEB
	brtc  .-18
	ijmp
	ld    r0,      -X      ; 17; XL = 0xEC
	brvc  .-30
	ijmp
	ld    r0,      -X      ; 15; XL = 0xED
	brge  .-42
	ijmp
	ld    r0,      -X      ; 13; XL = 0xEE
	brhc  .-54
	ijmp
	ld    r0,      -X      ; 11; XL = 0xEF
	brne  .-66
	ijmp
	ld    r0,      -X      ; 9; XL = 0xF0
	brpl  .-78
	ijmp
	ld    r0,      -X      ; 7; XL = 0xF1
	brne  .-90
	ijmp
	ld    r0,      -X      ; 5; XL = 0xF2
	brvc  .-102
	ijmp
	ld    r0,      -X      ; 3; XL = 0xF3
	brtc  .-114
	ijmp
	ld    r0,      -X      ; 1; XL = 0xF4
	brcc  .-126
	ijmp

xmb_jump_branch1t:

	ldi   r16,     0x14
	ldi   r17,     0xEA
	cpse  YL,      r16
	ijmp
	cpse  XL,      r17
	ijmp
	rjmp  xmb_jump_rjump

xmb_jump_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x02
	jmp   XMB_FAULT

xmb_jump_rjump:

	; Tests relative jump instruction range within the [-64 - +63] word
	; range. The IJMP instruction is used to target the fault handler in
	; need which is an absolute jump, unlikely to be affected by failures
	; this test tries to detect (anomalies in the adder used for
	; calculating relative targets).
	;
	; It doesn't test all individual possible relative jumps with the
	; assumption that such a flaw only affecting one particular
	; instruction word is very unlikely, rather aims to produce good
	; coverage on the adder logic underneath. Having the jumps 3
	; instruction words apart helps this by generating more diverse binary
	; encodings.

	ldi   ZL,      lo8(pm(xmb_jump_fault_02))
	ldi   ZH,      hi8(pm(xmb_jump_fault_02))
#ifdef EIND
	ldi   r20,     hh8(pm(xmb_jump_fault_02))
	out   EIND,    r20
#endif
	ldi   YL,      0x80    ; Guard value
	ldi   XL,      0x80    ; Guard value
	in    r24,     SPL_IO
	in    r25,     SPH_IO  ; Stack pointer start value to compare with

	rjmp  .+126            ; 0
	ijmp
	inc   YL               ; 2; YL = 0x81
	rcall .+114
	ijmp
	inc   YL               ; 4; YL = 0x82
	rjmp  .+102
	ijmp
	inc   YL               ; 6; YL = 0x83
	rcall .+90
	ijmp
	inc   YL               ; 8; YL = 0x84
	rjmp  .+78
	ijmp
	inc   YL               ; 10; YL = 0x85
	rcall .+66
	ijmp
	inc   YL               ; 12; YL = 0x86
	rjmp  .+54
	ijmp
	inc   YL               ; 14; YL = 0x87
	rcall .+42
	ijmp
	inc   YL               ; 16; YL = 0x88
	rjmp  .+30
	ijmp
	inc   YL               ; 18; YL = 0x89
	rcall .+18
	ijmp
	inc   YL               ; 20; YL = 0x8A
	rjmp  .+6
	ijmp
	rcall xmb_jump_rjump0t
	ijmp
	dec   XL               ; 21; XL = 0x75
	rjmp  .-8
	ijmp
	dec   XL               ; 19; XL = 0x76
	rcall .-20
	ijmp
	dec   XL               ; 17; XL = 0x77
	rjmp  .-32
	ijmp
	dec   XL               ; 15; XL = 0x78
	rcall .-44
	ijmp
	dec   XL               ; 13; XL = 0x79
	rjmp  .-56
	ijmp
	dec   XL               ; 11; XL = 0x7A
	rcall .-68
	ijmp
	dec   XL               ; 9; XL = 0x7B
	rjmp  .-80
	ijmp
	dec   XL               ; 7; XL = 0x7C
	rcall .-92
	ijmp
	dec   XL               ; 5; XL = 0x7D
	rjmp  .-104
	ijmp
	dec   XL               ; 3; XL = 0x7E
	rcall .-116
	ijmp
	dec   XL               ; 1; XL = 0x7F
	rjmp  .-128
	ijmp

xmb_jump_rjump0t:

	in    r23,     SPH_IO
	in    r22,     SPL_IO  ; Get stack pointer after rcall pushes
	out   SPH_IO,  r25
	out   SPL_IO,  r24     ; Discard pushes from rcalls
#if (PROGMEM_SIZE <= (128 * 1024))
	sbiw  r24,     11 * 2  ; Stack usage corresponding to 11 rcalls
#else
	sbiw  r24,     11 * 3  ; Stack usage corresponding to 11 rcalls
#endif
	cpse  r24,     r22
	ijmp
	cpse  r25,     r23
	ijmp

	ldi   r16,     0x8A
	ldi   r17,     0x75
	cpse  YL,      r16
	ijmp
	cpse  XL,      r17
	ijmp
	rjmp  xmb_jump_rjump1

xmb_jump_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x02
	jmp   XMB_FAULT

xmb_jump_rjump1:

	ldi   ZL,      lo8(pm(xmb_jump_fault_03))
	ldi   ZH,      hi8(pm(xmb_jump_fault_03))
#ifdef EIND
	ldi   r20,     hh8(pm(xmb_jump_fault_03))
	out   EIND,    r20
#endif
	in    r24,     SPL_IO
	in    r25,     SPH_IO  ; Stack pointer start value to compare with

	rcall .+124            ; 0
	ijmp
	inc   YL               ; 2; YL = 0x8B
	rjmp  .+112
	ijmp
	inc   YL               ; 4; YL = 0x8C
	rcall .+100
	ijmp
	inc   YL               ; 6; YL = 0x8D
	rjmp  .+88
	ijmp
	inc   YL               ; 8; YL = 0x8E
	rcall .+76
	ijmp
	inc   YL               ; 10; YL = 0x8F
	rjmp  .+64
	ijmp
	inc   YL               ; 12; YL = 0x90
	rcall .+52
	ijmp
	inc   YL               ; 14; YL = 0x91
	rjmp  .+40
	ijmp
	inc   YL               ; 16; YL = 0x92
	rcall .+28
	ijmp
	inc   YL               ; 18; YL = 0x93
	rjmp  .+16
	ijmp
	inc   YL               ; 20; YL = 0x94
	rcall .+4
	ijmp
	rjmp  xmb_jump_rjump1t
	dec   XL               ; 21; XL = 0x6A
	rcall .-6
	ijmp
	dec   XL               ; 19; XL = 0x6B
	rjmp  .-18
	ijmp
	dec   XL               ; 17; XL = 0x6C
	rcall .-30
	ijmp
	dec   XL               ; 15; XL = 0x6D
	rjmp  .-42
	ijmp
	dec   XL               ; 13; XL = 0x6E
	rcall .-54
	ijmp
	dec   XL               ; 11; XL = 0x6F
	rjmp  .-66
	ijmp
	dec   XL               ; 9; XL = 0x70
	rcall .-78
	ijmp
	dec   XL               ; 7; XL = 0x71
	rjmp  .-90
	ijmp
	dec   XL               ; 5; XL = 0x72
	rcall .-102
	ijmp
	dec   XL               ; 3; XL = 0x73
	rjmp  .-114
	ijmp
	dec   XL               ; 1; XL = 0x74
	rcall .-126
	ijmp

xmb_jump_rjump1t:

	in    r23,     SPH_IO
	in    r22,     SPL_IO  ; Get stack pointer after rcall pushes
	out   SPH_IO,  r25
	out   SPL_IO,  r24     ; Discard pushes from rcalls
#if (PROGMEM_SIZE <= (128 * 1024))
	sbiw  r24,     12 * 2  ; Stack usage corresponding to 12 rcalls
#else
	sbiw  r24,     12 * 3  ; Stack usage corresponding to 12 rcalls
#endif
	cpse  r24,     r22
	ijmp
	cpse  r25,     r23
	ijmp

	ldi   r16,     0x94
	ldi   r17,     0x6A
	cpse  YL,      r16
	ijmp
	cpse  XL,      r17
	ijmp
	rjmp  xmb_jump_rjump2

xmb_jump_fault_03:
	ldi   r24,     0x03
	ldi   r25,     0x02
	jmp   XMB_FAULT

xmb_jump_rjump2:

	; Crude larger range rjmp test, just across this module.

	ldi   ZL,      lo8(pm(xmb_jump_fault_04))
	ldi   ZH,      hi8(pm(xmb_jump_fault_04))
#ifdef EIND
	ldi   r20,     hh8(pm(xmb_jump_fault_04))
	out   EIND,    r20
#endif
	in    r24,     SPL_IO
	in    r25,     SPH_IO  ; Stack pointer start value to compare with

	rjmp  xmb_jump_rjump2a
	ijmp

xmb_jump_fault_04:
	ldi   r24,     0x04
	ldi   r25,     0x02
	jmp   XMB_FAULT

xmb_jump_rjump2e:

	in    r23,     SPH_IO
	in    r22,     SPL_IO  ; Get stack pointer after rcall pushes
	out   SPH_IO,  r25
	out   SPL_IO,  r24     ; Discard pushes from rcalls
#if (PROGMEM_SIZE <= (128 * 1024))
	sbiw  r24,     2 * 2   ; Stack usage corresponding to 2 rcalls
#else
	sbiw  r24,     2 * 3   ; Stack usage corresponding to 2 rcalls
#endif
	cpse  r24,     r22
	ijmp
	cpse  r25,     r23
	ijmp

xmb_jump_skip:

	; Tests skips whether they can properly skip 2 word instructions. On a
	; sane hardware implementation this probably should never fail as the
	; instruction fetch & decode stage of the pipeline should produce this
	; behaviour (which if failed would so much break the CPU that it is
	; unlikely it ever reaches this point), however this may still be
	; useful for testing emulators. 1 word instructions are not tested for
	; unintended 2 word skips (they are commonly used, most easily causing
	; detected failures elsewhere).

	ldi   r24,     0x5A
	mov   r25,     r24

	sbrc  r25,     0
	.word 0x9000           ; LDS r0, <address> opcode
	rjmp  xmb_jump_fault_05
	cpse  r24,     r25
	.word 0x91F0           ; LDS ZH, <address> opcode
	rjmp  xmb_jump_fault_05
	sbrs  r24,     1
	.word 0x9200           ; STS <address>, r0 opcode
	rjmp  xmb_jump_fault_05
	cpse  r25,     r24
	.word 0x93F0           ; STS <address>, ZH opcode
	rjmp  xmb_jump_fault_05
	sbrc  r24,     2
	.word 0x940C           ; JMP <address> opcode
	rjmp  xmb_jump_fault_05
	cpse  r24,     r25
	.word 0x95FD           ; JMP <address> opcode
	rjmp  xmb_jump_fault_05
	sbrs  r25,     3
	.word 0x940E           ; CALL <address> opcode
	rjmp  xmb_jump_fault_05
	cpse  r25,     r24
	.word 0x95FF           ; CALL <address> opcode
	rjmp  xmb_jump_fault_05
	rjmp  xmb_jump_end

xmb_jump_fault_05:
	ldi   r24,     0x05
	ldi   r25,     0x02
	jmp   XMB_FAULT

xmb_jump_end:

	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next

xmb_jump_rjump2b:

	rcall xmb_jump_rjump2c ; Part of crude large range rjmp test
	ijmp
	rjmp  xmb_jump_rjump2e
	ijmp



;
; Test entry points
;
.global xmb_jump_branch
.global xmb_jump_rjump
.global xmb_jump_skip

;
; XMBurner - (0x01) Conditional execution tests
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
; - Conditional branch and skip instructions:
; - BRBS and BRBC instructions (all except for the 'I' flag).
; - SBRS and SBRC instructions.
; - SBIS and SBIC instructions.
; - CPSE instruction.
; - LDI and OUT instructions with diverse parameter combinations.
;
; The goal of the tests is to check for each instruction type whether it can
; evaulate to both results (branch / skip or not branch / skip) depending on
; the condition.
;
; The SBIS and SBIC instructions are tested using GPIOR0 (which is available
; on both the ATMega and ATXMega families), which is restored. Interrupts are
; allowed to use GPIOR0 (the tests are guarded proper for this).
;
; Interrupts are disabled for up to 8 cycle periods during the test.
;

#include "xmb_defs.h"


.section XMB_CODE_SECTION


.set exec_id_from, 0xE0D43BA5
.set exec_id,      0x849AB017

.set SR_IO,  _SFR_IO_ADDR(SREG)
.set GP0_IO, _SFR_IO_ADDR(GPIOR0)


.global xmb_cond
xmb_cond:

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
	brne  xmb_cond_fault_ff
	brcs  xmb_cond_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_cond_fault_ff
	brcs  xmb_cond_brb1

xmb_cond_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x01
	jmp   XMB_FAULT

xmb_cond_brb1:

	; Conditional branch test: Flag bits 1, test BRBS and BRBC
	; instructions accordingly.

	in    r0,      SR_IO   ; Original SREG state to restore 'I' flag

	ldi   r16,     0x01    ; 'C' set
	out   SR_IO,   r16     ; Interrupts disabled
	brcs  .+2              ; 'C'
	rjmp  xmb_cond_fault_00
	brcc  xmb_cond_fault_00
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   r17,     0x02    ; 'Z' set
	out   SR_IO,   r17     ; Interrupts disabled
	breq  .+2              ; 'Z'
	rjmp  xmb_cond_fault_00
	brne  xmb_cond_fault_00
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   r18,     0x04    ; 'N' set
	out   SR_IO,   r18
	brmi  .+2              ; 'N'
	rjmp  xmb_cond_fault_00
	brpl  xmb_cond_fault_00
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   r19,     0x08    ; 'V' set
	out   SR_IO,   r19     ; Interrupts disabled
	brvs  .+2              ; 'V'
	rjmp  xmb_cond_fault_00
	brvc  xmb_cond_fault_00
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   r20,     0x10    ; 'S' set
	out   SR_IO,   r20     ; Interrupts disabled
	brlt  .+2              ; 'S'
	rjmp  xmb_cond_fault_00
	brge  xmb_cond_fault_00
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   r21,     0x20    ; 'H' set
	out   SR_IO,   r21     ; Interrupts disabled
	brhs  .+2              ; 'H'
	rjmp  xmb_cond_fault_00
	brhc  xmb_cond_fault_00
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   r22,     0x40    ; 'T' set
	out   SR_IO,   r22     ; Interrupts disabled
	brts  .+2              ; 'T'
	rjmp  xmb_cond_fault_00
	brtc  xmb_cond_fault_00
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   r23,     0x80    ; 'I' set
	out   SR_IO,   r23     ; Interrupts enabled
	brie  .+2              ; 'I'
	rjmp  xmb_cond_fault_00
	brid  xmb_cond_fault_00
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	rjmp  xmb_cond_brb0

xmb_cond_fault_00:
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had
	ldi   r24,     0x00
	ldi   r25,     0x01
	jmp   XMB_FAULT

xmb_cond_brb0:

	; Conditional branch test: Flag bits 0, test BRBS and BRBC
	; instructions accordingly.

	in    r0,      SR_IO   ; Original SREG state to restore 'I' flag

	ldi   r24,     0xFE    ; 'C' clear
	out   SR_IO,   r24     ; Interrupts enabled
	brcc  .+2              ; 'C'
	rjmp  xmb_cond_fault_01
	brcs  xmb_cond_fault_01
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   r25,     0xFD    ; 'Z' clear
	out   SR_IO,   r25     ; Interrupts enabled
	brne  .+2              ; 'Z'
	rjmp  xmb_cond_fault_01
	breq  xmb_cond_fault_01
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   XL,      0xFB    ; 'N' clear
	out   SR_IO,   XL      ; Interrupts enabled
	brpl  .+2              ; 'N'
	rjmp  xmb_cond_fault_01
	brmi  xmb_cond_fault_01
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   XH,      0xF7    ; 'V' clear
	out   SR_IO,   XH      ; Interrupts enabled
	brvc  .+2              ; 'V'
	rjmp  xmb_cond_fault_01
	brvs  xmb_cond_fault_01
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   YL,      0xEF    ; 'S' clear
	out   SR_IO,   YL      ; Interrupts enabled
	brge  .+2              ; 'S'
	rjmp  xmb_cond_fault_01
	brlt  xmb_cond_fault_01
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   YH,      0xDF    ; 'H' clear
	out   SR_IO,   YH      ; Interrupts enabled
	brhc  .+2              ; 'H'
	rjmp  xmb_cond_fault_01
	brhs  xmb_cond_fault_01
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   ZL,      0xBF    ; 'T' clear
	out   SR_IO,   ZL      ; Interrupts enabled
	brtc  .+2              ; 'T'
	rjmp  xmb_cond_fault_01
	brts  xmb_cond_fault_01
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	ldi   ZH,      0x7F    ; 'I' clear
	out   SR_IO,   ZH      ; Interrupts disabled
	brid  .+2              ; 'I'
	rjmp  xmb_cond_fault_01
	brie  xmb_cond_fault_01
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had

	rjmp  xmb_cond_sbr1

xmb_cond_fault_01:
	out   SR_IO,   r0      ; Restore SREG with whatever 'I' it had
	ldi   r24,     0x01
	ldi   r25,     0x01
	jmp   XMB_FAULT

xmb_cond_sbr1:

	; Register bit skip tests: Tested bits are 1, test SBRS and SBRC
	; instructions accordingly.

	ldi   r16,     0x01
	ldi   r25,     0x02
	ldi   r20,     0x04
	ldi   r17,     0x08
	ldi   r19,     0x10
	ldi   r24,     0x20
	ldi   r18,     0x40
	ldi   r21,     0x80
	sbrc  r16,     0
	rjmp  .+2
	rjmp  xmb_cond_fault_02
	sbrs  r16,     0
	rjmp  xmb_cond_fault_02
	sbrc  r25,     1
	rjmp  .+2
	rjmp  xmb_cond_fault_02
	sbrs  r25,     1
	rjmp  xmb_cond_fault_02
	sbrc  r20,     2
	rjmp  .+2
	rjmp  xmb_cond_fault_02
	sbrs  r20,     2
	rjmp  xmb_cond_fault_02
	sbrc  r17,     3
	rjmp  .+2
	rjmp  xmb_cond_fault_02
	sbrs  r17,     3
	rjmp  xmb_cond_fault_02
	sbrc  r19,     4
	rjmp  .+2
	rjmp  xmb_cond_fault_02
	sbrs  r19,     4
	rjmp  xmb_cond_fault_02
	sbrc  r24,     5
	rjmp  .+2
	rjmp  xmb_cond_fault_02
	sbrs  r24,     5
	rjmp  xmb_cond_fault_02
	sbrc  r18,     6
	rjmp  .+2
	rjmp  xmb_cond_fault_02
	sbrs  r18,     6
	rjmp  xmb_cond_fault_02
	sbrc  r21,     7
	rjmp  .+2
	rjmp  xmb_cond_fault_02
	sbrs  r21,     7
	rjmp  xmb_cond_fault_02
	rjmp  xmb_cond_sbr0

xmb_cond_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x01
	jmp   XMB_FAULT

xmb_cond_sbr0:

	; Register bit skip tests: Tested bits are 0, test SBRS and SBRC
	; instructions accordingly. Tests on the lower registers to have
	; better operand coverage.

	ldi   r16,     0xFE
	ldi   r25,     0xFD
	ldi   r20,     0xFB
	ldi   r17,     0xF7
	ldi   r19,     0xEF
	ldi   r24,     0xDF
	ldi   r18,     0xBF
	ldi   r21,     0x7F
	movw  r4,      r16
	movw  r6,      r20
	movw  r10,     r24
	movw  r12,     r18
	sbrs  r4,      0
	rjmp  .+2
	rjmp  xmb_cond_fault_03
	sbrc  r4,      0
	rjmp  xmb_cond_fault_03
	sbrs  r11,     1
	rjmp  .+2
	rjmp  xmb_cond_fault_03
	sbrc  r11,     1
	rjmp  xmb_cond_fault_03
	sbrs  r6,      2
	rjmp  .+2
	rjmp  xmb_cond_fault_03
	sbrc  r6,      2
	rjmp  xmb_cond_fault_03
	sbrs  r5,      3
	rjmp  .+2
	rjmp  xmb_cond_fault_03
	sbrc  r5,      3
	rjmp  xmb_cond_fault_03
	sbrs  r13,     4
	rjmp  .+2
	rjmp  xmb_cond_fault_03
	sbrc  r13,     4
	rjmp  xmb_cond_fault_03
	sbrs  r10,     5
	rjmp  .+2
	rjmp  xmb_cond_fault_03
	sbrc  r10,     5
	rjmp  xmb_cond_fault_03
	sbrs  r12,     6
	rjmp  .+2
	rjmp  xmb_cond_fault_03
	sbrc  r12,     6
	rjmp  xmb_cond_fault_03
	sbrs  r7,      7
	rjmp  .+2
	rjmp  xmb_cond_fault_03
	sbrc  r7,      7
	rjmp  xmb_cond_fault_03
	rjmp  xmb_cond_sbi1

xmb_cond_fault_03:
	ldi   r24,     0x03
	ldi   r25,     0x01
	jmp   XMB_FAULT

xmb_cond_sbi1:

	; IO bit skip test: Tested bits are 1, tests SBIS and SBIC
	; instructions accordingly. Interrupts are disabled for the test to
	; preserve GPIOR0's state.

	in    r0,      GP0_IO  ; Save GPIOR0 state
	in    r1,      SR_IO   ; Save SREG state with whatever 'I' flag it has

	ldi   r16,     0x01
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbic  GP0_IO,  0
	rjmp  .+2
	rjmp  xmb_cond_fault_04
	sbis  GP0_IO,  0
	rjmp  xmb_cond_fault_04
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0x02
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbic  GP0_IO,  1
	rjmp  .+2
	rjmp  xmb_cond_fault_04
	sbis  GP0_IO,  1
	rjmp  xmb_cond_fault_04
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0x04
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbic  GP0_IO,  2
	rjmp  .+2
	rjmp  xmb_cond_fault_04
	sbis  GP0_IO,  2
	rjmp  xmb_cond_fault_04
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0x08
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbic  GP0_IO,  3
	rjmp  .+2
	rjmp  xmb_cond_fault_04
	sbis  GP0_IO,  3
	rjmp  xmb_cond_fault_04
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0x10
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbic  GP0_IO,  4
	rjmp  .+2
	rjmp  xmb_cond_fault_04
	sbis  GP0_IO,  4
	rjmp  xmb_cond_fault_04
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0x20
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbic  GP0_IO,  5
	rjmp  .+2
	rjmp  xmb_cond_fault_04
	sbis  GP0_IO,  5
	rjmp  xmb_cond_fault_04
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0x40
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbic  GP0_IO,  6
	rjmp  .+2
	rjmp  xmb_cond_fault_04
	sbis  GP0_IO,  6
	rjmp  xmb_cond_fault_04
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0x80
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbic  GP0_IO,  7
	rjmp  .+2
	rjmp  xmb_cond_fault_04
	sbis  GP0_IO,  7
	rjmp  xmb_cond_fault_04
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had
	rjmp  xmb_cond_sbi0

xmb_cond_fault_04:
	ldi   r24,     0x04
	ldi   r25,     0x01
	jmp   XMB_FAULT

xmb_cond_sbi0:

	; IO bit skip test: Tested bits are 0, tests SBIS and SBIC
	; instructions accordingly. Interrupts are disabled for the test to
	; preserve GPIOR0's state.

	in    r0,      GP0_IO  ; Save GPIOR0 state
	in    r1,      SR_IO   ; Save SREG state with whatever 'I' flag it has

	ldi   r16,     0xFE
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbis  GP0_IO,  0
	rjmp  .+2
	rjmp  xmb_cond_fault_05
	sbic  GP0_IO,  0
	rjmp  xmb_cond_fault_05
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0xFD
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbis  GP0_IO,  1
	rjmp  .+2
	rjmp  xmb_cond_fault_05
	sbic  GP0_IO,  1
	rjmp  xmb_cond_fault_05
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0xFB
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbis  GP0_IO,  2
	rjmp  .+2
	rjmp  xmb_cond_fault_05
	sbic  GP0_IO,  2
	rjmp  xmb_cond_fault_05
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0xF7
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbis  GP0_IO,  3
	rjmp  .+2
	rjmp  xmb_cond_fault_05
	sbic  GP0_IO,  3
	rjmp  xmb_cond_fault_05
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0xEF
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbis  GP0_IO,  4
	rjmp  .+2
	rjmp  xmb_cond_fault_05
	sbic  GP0_IO,  4
	rjmp  xmb_cond_fault_05
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0xDF
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbis  GP0_IO,  5
	rjmp  .+2
	rjmp  xmb_cond_fault_05
	sbic  GP0_IO,  5
	rjmp  xmb_cond_fault_05
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0xBF
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbis  GP0_IO,  6
	rjmp  .+2
	rjmp  xmb_cond_fault_05
	sbic  GP0_IO,  6
	rjmp  xmb_cond_fault_05
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had

	ldi   r16,     0x7F
	cli                    ; Interrupts disabled
	out   GP0_IO,  r16
	sbis  GP0_IO,  7
	rjmp  .+2
	rjmp  xmb_cond_fault_05
	sbic  GP0_IO,  7
	rjmp  xmb_cond_fault_05
	out   GP0_IO,  r0
	out   SR_IO,   r1      ; Restore SREG with whatever 'I' flag it had
	rjmp  xmb_cond_cpse

xmb_cond_fault_05:
	ldi   r24,     0x05
	ldi   r25,     0x01
	jmp   XMB_FAULT

xmb_cond_cpse:

	; CPSE instruction test. Note that several operand combinations occur
	; in xmb_creg.s. Here it is tested whether each individual bit in the
	; compare logic works (can detect mismatch).

	ldi   r16,     0x96
	ldi   r17,     0x96
	movw  r0,      r16
	cpse  r0,      r1      ; Equality test
	rjmp  xmb_cond_fault_06
	ldi   r18,     0x69
	ldi   r19,     0x69
	cpse  r19,     r18     ; Equality test
	rjmp  xmb_cond_fault_06
	ldi   r20,     0x87
	ldi   r21,     0x86
	cpse  r20,     r21     ; Inequality on bit 0
	rjmp  .+2
	rjmp  xmb_cond_fault_06
	ldi   r22,     0xE1
	ldi   r23,     0xE3
	cpse  r23,     r22     ; Inequality on bit 1
	rjmp  .+2
	rjmp  xmb_cond_fault_06
	ldi   r24,     0x52
	ldi   r25,     0x56
	cpse  r24,     r25     ; Inequality on bit 2
	rjmp  .+2
	rjmp  xmb_cond_fault_06
	ldi   XL,      0x39
	ldi   XH,      0x31
	cpse  XH,      XL      ; Inequality on bit 3
	rjmp  .+2
	rjmp  xmb_cond_fault_06
	ldi   YL,      0x78
	ldi   YH,      0x68
	cpse  YL,      YH      ; Inequality on bit 4
	rjmp  .+2
	rjmp  xmb_cond_fault_06
	ldi   ZL,      0x94
	ldi   ZH,      0xB4
	cpse  ZH,      ZL      ; Inequality on bit 5
	rjmp  .+2
	rjmp  xmb_cond_fault_06
	ldi   r17,     0xFD
	ldi   r25,     0xBD
	cpse  r25,     r17     ; Inequality on bit 6
	rjmp  .+2
	rjmp  xmb_cond_fault_06
	ldi   r18,     0x2C
	ldi   r22,     0xAC
	cpse  r18,     r22     ; Inequality on bit 7
	rjmp  xmb_cond_end

xmb_cond_fault_06:
	ldi   r24,     0x06
	ldi   r25,     0x01
	jmp   XMB_FAULT

xmb_cond_end:

	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next



;
; Test entry points
;
.global xmb_cond_brb1
.global xmb_cond_sbr1
.global xmb_cond_sbi1
.global xmb_cond_cpse

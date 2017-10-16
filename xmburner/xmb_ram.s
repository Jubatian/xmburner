;
; XMBurner - (0x04) Circular RAM test
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
; - RAM memory functionality (Internal SRAM).
; - LD and ST instructions with X, Y and Z pointers on whole SRAM.
; - LDD and STD instructions with Y and Z pointers + 63 on whole SRAM.
; - PUSH and POP instructions on whole SRAM.
; - LD and ST with post-inc. and pre-dec. with X, Y and Z on whole SRAM.
;
; Coverage should be sufficienty complete for the LD, ST, LDD and STD
; instructions. The displacement variants are tested with the largest
; displacement possible.
;
; This test can not run in parallel with DMA accesses (you have to make sure
; there are no DMA transactions running when this is called).
;
; Needs initialization (xmb_ram_init).
;
; Interrupts are disabled for up to 17 cycle periods during the test.
;
; Provides user accessible functions:
;
; - boole    xmb_ram_isramok(void);
;

#include "xmb_defs.h"


.section .data


; Current position of ptr0 & ptr1 with negated positions
xmb_ram_ptrs:
	.space 2 + 2
	.space 2 + 2


.section XMB_COMP_SECTION


.set exec_id_from, 0x4186EF39
.set exec_id,      0x6B0DE257

.set SR_IO,  _SFR_IO_ADDR(SREG)
.set SPL_IO, _SFR_IO_ADDR(SPL)
.set SPH_IO, _SFR_IO_ADDR(SPH)



.global xmb_ram
xmb_ram:

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
	brne  xmb_ram_fault_ff
	brcs  xmb_ram_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_ram_fault_ff
	brcs  xmb_ram_check

xmb_ram_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x04
	jmp   XMB_FAULT

xmb_ram_check:

	; Test 16 bytes of RAM in one pass. One of the pointers increment
	; normally, the other adds 61 after each test, when the two pointers
	; are equal, that one adding 61 does an extra addition. This in
	; overall produces a good selection of cell pairs from all over the
	; RAM likely testing most possible pairings eventually.

	; Load current pointers

	ldi   XL,      lo8(xmb_ram_ptrs)
	ldi   XH,      hi8(xmb_ram_ptrs)
	ld    ZL,      X+      ; ptr0 Low
	ld    ZH,      X+      ; ptr0 High
	ld    r22,     X+      ; ptr0 Negated Low
	ld    r23,     X+      ; ptr0 Negated High
	com   r22
	cpse  ZL,      r22
	rjmp  xmb_ram_fault_00
	com   r23
	cpse  ZH,      r23
	rjmp  xmb_ram_fault_00
	ld    YL,      X+      ; ptr1 Low
	ld    YH,      X+      ; ptr1 High
	ld    r22,     X+      ; ptr1 Negated Low
	ld    r23,     X+      ; ptr1 Negated High
	com   r22
	cpse  YL,      r22
	rjmp  xmb_ram_fault_00
	com   r23
	cpse  YH,      r23
	rjmp  xmb_ram_fault_00

	; Check 16 RAM cell pairs

	ldi   r16,     16

xmb_ram_clp:

	; Check whether ptr0 (Z) and ptr1 (Y) are equal (Z + 63 is tested
	; with Y)

	movw  r24,     ZL
	adiw  r24,     63
	cpse  r24,     YL
	rjmp  xmb_ram_clpee
	cpse  r25,     YH
	rjmp  xmb_ram_clpee
	adiw  YL,      61      ; When equal, advance ptr1 by 61
	movw  r24,     YL
	subi  r24,     lo8(RAMEND + 1)
	sbci  r25,     hi8(RAMEND + 1)
	brcs  xmb_ram_clpee
	subi  YL,      lo8(RAMSIZE)
	sbci  YH,      hi8(RAMSIZE)
xmb_ram_clpee:

	; Check cell pair

	rcall xmb_ram_celltest
	mov   r24,     r23
	cpi   r24,     0x00
	brne  xmb_ram_fault_xx

	; Advance pointers

	subi  ZL,      0xFF    ; Just avoid adiw for ptr0 for some
	sbci  ZH,      0xFF    ; common mode failure avoidance
	movw  r24,     ZL
	adiw  r24,     63      ; ptr0: Z + 63 is tested, so adjusted
	subi  r24,     lo8(RAMEND + 1)
	sbci  r25,     hi8(RAMEND + 1)
	brcs  xmb_ram_clp0e
	subi  ZL,      lo8(RAMSIZE)
	sbci  ZH,      hi8(RAMSIZE)
xmb_ram_clp0e:
	adiw  YL,      61      ; ptr1 advances by 61
	movw  r24,     YL
	subi  r24,     lo8(RAMEND + 1)
	sbci  r25,     hi8(RAMEND + 1)
	brcs  xmb_ram_clp1e
	subi  YL,      lo8(RAMSIZE)
	sbci  YH,      hi8(RAMSIZE)
xmb_ram_clp1e:

	; Loop

	dec   r16
	brne  xmb_ram_clp

	; Save current pointers

	ldi   XL,      lo8(xmb_ram_ptrs)
	ldi   XH,      hi8(xmb_ram_ptrs)
	st    X+,      ZL      ; ptr0 Low
	st    X+,      ZH      ; ptr0 High
	com   ZL
	st    X+,      ZL      ; ptr0 Negated Low
	com   ZH
	st    X+,      ZH      ; ptr0 Negated High
	st    X+,      YL      ; ptr1 Low
	st    X+,      YH      ; ptr1 High
	com   YL
	st    X+,      YL      ; ptr1 Negated Low
	com   YH
	st    X+,      YH      ; ptr1 Negated High

	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next

xmb_ram_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x04
	jmp   XMB_FAULT

xmb_ram_fault_xx:
	ldi   r25,     0x04
	jmp   XMB_FAULT



;
; Subroutine to test RAM cell pairs & pointer operations.
; Produces fault codes:
; - 0x00 OK
; - 0x01 for cell pair faults
; - 0x02 for displacement faults
; - 0x03 for pointer increment / decrement faults
; - 0x04 for push / pop faults
; When a fault is produced, Y and Z may also be clobbered.
;
; Inputs:
; YH: YL:  Cell 1 address
; ZH: ZL:  Cell 2 address - 63
; Outputs:
;     r23: Fault code
; Clobbers:
; r0, r1 (zero), r18, r19, r20, r21, r22, X
;
xmb_ram_celltest:

	in    r0,      SR_IO   ; Save current SREG with whatever 'I' flag it has

	; Test 0: 0x55 & 0xAA

	ldi   r18,     0x55
	ldi   r19,     0xAA
	movw  XL,      YL

	cli                    ; Disable interrupts
	ld    r20,     Y
	ldd   r21,     Z + 63  ; Save current contents
	st    Y,       r18
	std   Z + 63,  r19
	ld    r22,     X
	ldd   r23,     Z + 63  ; Do test write & read pair
	st    X,       r20
	std   Z + 63,  r21     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r22,     r18
	rjmp  xmb_ram_ctf_01
	cpse  r23,     r19
	rjmp  xmb_ram_ctf_01

	; Test 1: 0xAA & 0x55

	ldi   r21,     0xAA
	ldi   r20,     0x55
	movw  YL,      ZL

	cli                    ; Disable interrupts
	ld    r23,     X
	ldd   r22,     Z + 63  ; Save current contents
	st    X,       r21
	std   Z + 63,  r20
	ld    r19,     X
	ldd   r18,     Y + 63  ; Do test write & read pair
	st    X,       r23
	std   Y + 63,  r22     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r20,     r18
	rjmp  xmb_ram_ctf_01
	cpse  r21,     r19
	rjmp  xmb_ram_ctf_01

	; Test 2: Using low bytes of other cell addresses

	mov   r22,     ZL
	mov   r23,     XL

	cli                    ; Disable interrupts
	ld    r18,     X
	ldd   r19,     Z + 63  ; Save current contents
	st    X,       r22
	std   Z + 63,  r23
	ld    r20,     X
	ldd   r21,     Z + 63  ; Do test write & read pair
	st    X,       r18
	std   Z + 63,  r19     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r22,     r20
	rjmp  xmb_ram_ctf_01
	cpse  r23,     r21
	rjmp  xmb_ram_ctf_01

	; Test 3: Displacement correctness on Z

	ldi   r18,     0x69

	cli                    ; Disable interrupts
	ldd   r22,     Z + 63  ; Save current contents
	std   Z + 63,  r18
	subi  ZL,      0xC1    ; + 63 (0x3F), not using adiw to prevent
	sbci  ZH,      0xFF    ; possible common mode fault
	ld    r20,     Z
	st    Z,       r22     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r18,     r20
	rjmp  xmb_ram_ctf_02

	movw  ZL,      YL      ; Restore original value

	; Test 4: Displacement correctness on Y

	ldi   r20,     0x96

	cli                    ; Disable interrupts
	ldd   r18,     Y + 63  ; Save current contents
	std   Y + 63,  r20
	subi  YL,      0xC1    ; + 63 (0x3F), not using adiw to prevent
	sbci  YH,      0xFF    ; possible common mode fault
	ld    r22,     Y
	st    Y,       r18     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r20,     r22
	rjmp  xmb_ram_ctf_02

	movw  YL,      XL      ; Restore original value

	; Test 5: Pointer predec. store and postinc. load

	movw  r22,     ZL      ; Save Z pointer

	movw  ZL,      XL      ; All three pointers the same, point in RAM
	movw  r20,     XL
	inc   r20              ; Compare value
	brne  .+2              ; (Using inc for the least chance of common
	inc   r21              ; mode failure with the adder of the ptrs)
	ldi   r18,     0x1E

	ld    r1,      X+
	cli                    ; Disable interrupts
	ld    r19,     Y       ; Save current contents
	st    -X,      r18
	ld    r1,      X+
	st    Y,       r19     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r1,      r18
	rjmp  xmb_ram_ctf_03   ; Store & Read back success?
	cpse  XL,      r20
	rjmp  xmb_ram_ctf_03
	cpse  XH,      r21
	rjmp  xmb_ram_ctf_03   ; Pointer correct after operations?
	sbiw  XL,      1

	ld    r1,      Y+
	cli                    ; Disable interrupts
	ld    r19,     Z       ; Save current contents
	st    -Y,      r18
	ld    r1,      Y+
	st    Z,       r19     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r1,      r18
	rjmp  xmb_ram_ctf_03   ; Store & Read back success?
	cpse  YL,      r20
	rjmp  xmb_ram_ctf_03
	cpse  YH,      r21
	rjmp  xmb_ram_ctf_03   ; Pointer correct after operations?
	sbiw  YL,      1

	ld    r1,      Z+
	cli                    ; Disable interrupts
	ld    r19,     X       ; Save current contents
	st    -Z,      r18
	ld    r1,      Z+
	st    X,       r19     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r1,      r18
	rjmp  xmb_ram_ctf_03   ; Store & Read back success?
	cpse  ZL,      r20
	rjmp  xmb_ram_ctf_03
	cpse  ZH,      r21
	rjmp  xmb_ram_ctf_03   ; Pointer correct after operations?
	sbiw  ZL,      1

	; Test 6: Pointer postinc. store and predec load

	ldi   r18,     0xE1

	cli                    ; Disable interrupts
	ld    r19,     Y       ; Save current contents
	st    X+,      r18
	movw  ZL,      XL
	ld    r1,      -X
	st    Y,       r19     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r1,      r18
	rjmp  xmb_ram_ctf_03   ; Store & Read back success?
	cpse  ZL,      r20
	rjmp  xmb_ram_ctf_03
	cpse  ZH,      r21
	rjmp  xmb_ram_ctf_03   ; Pointer correct within operations?
	sbiw  ZL,      1

	cli                    ; Disable interrupts
	ld    r19,     Z       ; Save current contents
	st    Y+,      r18
	movw  XL,      YL
	ld    r1,      -Y
	st    Z,       r19     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r1,      r18
	rjmp  xmb_ram_ctf_03   ; Store & Read back success?
	cpse  XL,      r20
	rjmp  xmb_ram_ctf_03
	cpse  XH,      r21
	rjmp  xmb_ram_ctf_03   ; Pointer correct within operations?
	sbiw  XL,      1

	cli                    ; Disable interrupts
	ld    r19,     X       ; Save current contents
	st    Z+,      r18
	movw  YL,      ZL
	ld    r1,      -Z
	st    X,       r19     ; Restore contents
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	cpse  r1,      r18
	rjmp  xmb_ram_ctf_03   ; Store & Read back success?
	cpse  YL,      r20
	rjmp  xmb_ram_ctf_03
	cpse  YH,      r21
	rjmp  xmb_ram_ctf_03   ; Pointer correct within operations?
	sbiw  YL,      1

	; Test 7: Push & Pop

	ldi   r20,     0xC3
	ldi   r21,     0x3C
	in    r18,     SPL_IO
	in    r19,     SPH_IO

	cli                    ; Disable interrupts
	out   SPL_IO,  ZL
	out   SPH_IO,  ZH
	ld    r1,      Z       ; Save current contents
	push  r20              ; Post-decrements after store
	in    XL,      SPL_IO
	in    XH,      SPH_IO
	pop   r21              ; Pre-increments before load
	st    Z,       r1      ; Restore contents
	in    YL,      SPL_IO
	in    YH,      SPH_IO
	out   SPL_IO,  r18
	out   SPH_IO,  r19
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)

	clr   r1

	cpse  r20,     r21
	rjmp  xmb_ram_ctf_04   ; Store & Read back success?
	cpse  ZL,      YL
	rjmp  xmb_ram_ctf_04
	cpse  ZH,      YH
	rjmp  xmb_ram_ctf_04   ; Address after pop correct?
	adiw  XL,      1
	cpse  XL,      YL
	rjmp  xmb_ram_ctf_04
	cpse  XH,      YH
	rjmp  xmb_ram_ctf_04   ; Address after push correct?

	movw  ZL,      r22     ; Restore Z pointer

	ldi   r23,     0x00
	ret

xmb_ram_ctf_01:
	ldi   r23,     0x01
	ret
xmb_ram_ctf_02:
	ldi   r23,     0x02
	ret
xmb_ram_ctf_03:
	clr   r1
	movw  ZL,      r22     ; Restore Z pointer
	ldi   r23,     0x03
	ret
xmb_ram_ctf_04:
	movw  ZL,      r22     ; Restore Z pointer
	ldi   r23,     0x04
	ret



;
; Initializes RAM component
;
.global xmb_ram_init
xmb_ram_init:

	ldi   r22,     lo8(RAMSTART)
	ldi   r23,     hi8(RAMSTART)
	ldi   r24,     (RAMSTART & 0xFF) ^ 0xFF
	ldi   r25,     (RAMSTART  >>  8) ^ 0xFF
	ldi   ZL,      lo8(xmb_ram_ptrs)
	ldi   ZH,      hi8(xmb_ram_ptrs)
	st    Z+,      r22
	st    Z+,      r23
	st    Z+,      r24
	st    Z+,      r25
	st    Z+,      r22
	st    Z+,      r23
	st    Z+,      r24
	st    Z+,      r25
	ret



.section .text



;
; Checks entire RAM
;
; Outputs:
; r25:r24: 1 if RAM is OK, 0 otherwise.
; Clobbers:
; r0, r18, r19, r20, r21, r22, r23, r24, r25, X, Z
;
.global xmb_ram_isramok
xmb_ram_isramok:

	movw  r24,     YL

	; Load start addresses

	ldi   ZL,      lo8(RAMSTART - 63)
	ldi   ZH,      hi8(RAMSTART - 63)
	ldi   YL,      lo8(RAMSTART + 1)
	ldi   YH,      hi8(RAMSTART + 1)

	; Check loop until RAM end

xmb_ram_isramok_l:

	call  xmb_ram_celltest
	cpi   r23,     0x00
	brne  xmb_ram_isramok_f

	; Increment pointers

	subi  ZL,      0xFF
	sbci  ZH,      0xFF    ; ptr0 advances by 1
	adiw  YL,      61      ; ptr1 advances by 61
	movw  r22,     YL
	subi  r22,     lo8(RAMEND + 1)
	sbci  r23,     hi8(RAMEND + 1)
	brcs  xmb_ram_isramok_0e
	subi  YL,      lo8(RAMSIZE)
	sbci  YH,      hi8(RAMSIZE)
xmb_ram_isramok_0e:

	; Check whether ptr0 (Z) and ptr1 (Y) are equal (Z + 63 is tested
	; with Y)

	movw  r22,     ZL
	subi  r22,     0xC1
	sbci  r23,     0xFF    ; Adds 63 (0x3F)
	cpse  r22,     YL
	rjmp  xmb_ram_isramok_1e
	cpse  r23,     YH
	rjmp  xmb_ram_isramok_1e
	adiw  YL,      61      ; When equal, advance ptr1 with 61
	movw  r18,     YL
	subi  r18,     lo8(RAMEND + 1)
	sbci  r19,     hi8(RAMEND + 1)
	brcs  xmb_ram_isramok_1e
	subi  YL,      lo8(RAMSIZE)
	sbci  YH,      hi8(RAMSIZE)
xmb_ram_isramok_1e:

	; Check end: if Z + 63 (in r23:r22) reached RAM end, then done

	subi  r22,     lo8(RAMEND + 1)
	sbci  r23,     hi8(RAMEND + 1)
	brne  xmb_ram_isramok_l

	; At this point the check succeeded

	movw  YL,      r24
	ldi   r24,     1

xmb_ram_isramok_tail:

	ldi   r25,     0
	ret

xmb_ram_isramok_f:
	movw  YL,      r24
	ldi   r24,     0
	rjmp  xmb_ram_isramok_tail



;
; Test entry points
;
.global xmb_ram_check

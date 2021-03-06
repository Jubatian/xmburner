;
; XMBurner - (0x03) Circular ROM CRC32 check
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
; - Program memory correctness by CRC32.
; - The (E)LPM instruction on a large range (full if CRC covers complete ROM).
; - The LSR, ROR and EOR instructions with diverse parameters, but no flags.
; - The MUL instruction to a limited degree (multiplies by four, no flags).
;
; Needs initialization (xmb_crc_init).
;
; Interrupts are disabled for up to 12 cycle periods during the test.
;
; Provides user accessible functions:
;
; - uint32_t xmb_crc_calc(uint32_t crcval, uint8_t byte);
; - boole    xmb_crc_isromok(void);
; - void     xmb_crc_genram(void* ram, uint16_t len);
; - boole    xmb_crc_isramok(void* ram, uint16_t len);
;

#include "xmb_defs.h"


.section .data


; Current value of CRC calculation
xmb_crc_val:
	.space 4

; Current position in binary (2/3 bytes) and negated position (2/3 bytes)
xmb_crc_pos:
#if (PROGMEM_SIZE > (64 * 1024))
	.space 3 + 3
#else
	.space 2 + 2
#endif


.section XMB_COMP_SECTION


.set exec_id_from, 0xA9F105DB
.set exec_id,      0x4186EF39

#if (PROGMEM_SIZE > (64 * 1024))
.set RPZ_IO, _SFR_IO_ADDR(RAMPZ)
.set SR_IO,  _SFR_IO_ADDR(SREG)
#endif


.global xmb_crc
xmb_crc:

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
	brne  xmb_crc_fault_ff
	brcs  xmb_crc_fault_ff
	subi  r16,     1       ; This has a good chance to detect if either
	sbci  r17,     0       ; the Z flag malfunctions or subi is not
	sbci  r18,     0       ; capable to operate correctly (the C flag has
	sbci  r19,     0       ; to change state).
	brcc  xmb_crc_fault_ff
	brcs  xmb_crc_ccalc

xmb_crc_fault_ff:
	ldi   r24,     0xFF
	ldi   r25,     0x03
	jmp   XMB_FAULT

xmb_crc_ccalc:

	; Calculate CRC for 64 bytes at once, both by table and direct to
	; compare results. This helps testing a few instructions with
	; real-world use-case.

	; Load binary size

	ldi   ZL,      lo8(XMB_BSIZE)
	ldi   ZH,      hi8(XMB_BSIZE)
#if (PROGMEM_SIZE > (64 * 1024))
	ldi   r20,     hh8(XMB_BSIZE)
	clr   r1
	in    r0,      SR_IO   ; Save current SREG with whatever 'I' flag it has
	cli                    ; Disable interrupts
	out   RPZ_IO,  r20
	elpm  r10,     Z+
	elpm  r11,     Z+
	elpm  r12,     Z
	out   RPZ_IO,  r1
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)
#else
	lpm   r10,     Z+
	lpm   r11,     Z
#endif

	; Load current program memory pointer

	ldi   XL,      lo8(xmb_crc_pos)
	ldi   XH,      hi8(xmb_crc_pos)
	ld    ZL,      X+      ; Low
	ld    ZH,      X+      ; High
#if (PROGMEM_SIZE > (64 * 1024))
	ld    r13,     X+      ; Extended
#endif
	ld    r22,     X+      ; Negated Low
	ld    r23,     X+      ; Negated High
#if (PROGMEM_SIZE > (64 * 1024))
	ld    r24,     X+      ; Negated Extended
#endif
	com   r22
	cpse  ZL,      r22
	rjmp  xmb_crc_fault_00
	com   r23
	cpse  ZH,      r23
	rjmp  xmb_crc_fault_00
#if (PROGMEM_SIZE > (64 * 1024))
	com   r24
	cpse  r13,     r24
	rjmp  xmb_crc_fault_00
#endif

	; Load CRC value

	ldi   XL,      lo8(xmb_crc_val)
	ldi   XH,      hi8(xmb_crc_val)
	ld    r22,     X+
	ld    r23,     X+
	ld    r24,     X+
	ld    r25,     X+

	; Prepare for CRC calculation loop

	ldi   r18,     0x20
	ldi   r19,     0x83
	ldi   r20,     0xB8
	ldi   r21,     0xED    ; CRC32 polynomial (0xEDB88320) for direct calculation
	movw  r6,      r18
	movw  r8,      r20     ; Into r9:r8:r7:r6

	; Calculate CRC for 64 bytes

	ldi   r16,     64

xmb_crc_clp:

#if (PROGMEM_SIZE > (64 * 1024))
	clr   r1
	in    r0,      SR_IO   ; Save current SREG with whatever 'I' flag it has
	cli                    ; Disable interrupts
	out   RPZ_IO,  r13     ; Set up extended
	elpm  r20,     Z+
	in    r13,     RPZ_IO
	out   RPZ_IO,  r1
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)
#else
	lpm   r20,     Z+
#endif

	; Direct CRC calculation

	movw  r2,      r22     ; Copy off current CRC value
	movw  r4,      r24     ; from r25:r24:r23:r22 to r5:r4:r3:r2
	eor   r2,      r20
	ldi   r17,     8
xmb_crc_dlp:
	lsr   r5
	ror   r4
	ror   r3
	ror   r2
	brcc  .+8
	eor   r2,      r6
	eor   r3,      r7
	eor   r4,      r8
	eor   r5,      r9
	dec   r17
	brne  xmb_crc_dlp

	; Table CRC calculation

	movw  r14,     ZL      ; Preserve Z pointer
	call  xmb_crc_calc
	movw  ZL,      r14

	; Compare results (must be same)

	cpse  r2,      r22
	rjmp  xmb_crc_fault_01
	cpse  r3,      r23
	rjmp  xmb_crc_fault_01
	cpse  r4,      r24
	rjmp  xmb_crc_fault_01
	cpse  r5,      r25
	rjmp  xmb_crc_fault_01

	dec   r16
	brne  xmb_crc_clp      ; Approx. 10K cycles for the 64 bytes

	; Check increment correctness (whether the increment logic in (E)LPM
	; is capable to operate properly)

	ldi   XL,      lo8(xmb_crc_pos)
	ldi   XH,      hi8(xmb_crc_pos)
	ld    r16,     X+      ; Low
	ld    r17,     X+      ; High
#if (PROGMEM_SIZE > (64 * 1024))
	ld    r18,     X+      ; Extended
#endif
	subi  r16,     0xC0    ; Add 64 (0x40)
	sbci  r17,     0xFF
#if (PROGMEM_SIZE > (64 * 1024))
	sbci  r18,     0xFF
#endif
	cpse  ZL,      r16
	rjmp  xmb_crc_fault_03
	cpse  ZH,      r17
	rjmp  xmb_crc_fault_03
#if (PROGMEM_SIZE > (64 * 1024))
	cpse  r13,     r18
	rjmp  xmb_crc_fault_03
#endif

	; If reached end of binary, check CRC value (must be 0xDEBB20E3), and
	; reset pointer.

	cpse  ZL,      r10
	rjmp  xmb_crc_nend
	cpse  ZH,      r11
	rjmp  xmb_crc_nend
#if (PROGMEM_SIZE > (64 * 1024))
	cpse  r13,     r12
	rjmp  xmb_crc_nend
#endif

	subi  r22,     0xE3
	sbci  r23,     0x20
	sbci  r24,     0xBB
	sbci  r25,     0xDE    ; CRC32 "magic" number (0xDEBB20E3), result if CRC was good
	brne  xmb_crc_fault_02

	ldi   r22,     0xFF
	ldi   r23,     0xFF
	movw  r24,     r22     ; Restart with 0xFFFFFFFF

	clr   ZL
	clr   ZH
#if (PROGMEM_SIZE > (64 * 1024))
	clr   r13
#endif

xmb_crc_nend:

	; Save current program memory pointer

	ldi   XL,      lo8(xmb_crc_pos)
	ldi   XH,      hi8(xmb_crc_pos)
	st    X+,      ZL      ; Low
	st    X+,      ZH      ; High
#if (PROGMEM_SIZE > (64 * 1024))
	st    X+,      r13     ; Extended
#endif
	com   ZL
	st    X+,      ZL      ; Negated Low
	com   ZH
	st    X+,      ZH      ; Negated High
#if (PROGMEM_SIZE > (64 * 1024))
	com   r13
	st    X+,      r13     ; Negated Extended
#endif

	; Save CRC value

	ldi   XL,      lo8(xmb_crc_val)
	ldi   XH,      hi8(xmb_crc_val)
	st    X+,      r22
	st    X+,      r23
	st    X+,      r24
	st    X+,      r25

	; Set up part of execution chain for next element & Return

	ldi   r18,     (exec_id >> 16) & 0xFF
	ldi   r19,     (exec_id >> 24) & 0xFF
	jmp   xmb_glob_tail_next


xmb_crc_fault_00:
	ldi   r24,     0x00
	ldi   r25,     0x03
	jmp   XMB_FAULT

xmb_crc_fault_01:
	ldi   r24,     0x01
	ldi   r25,     0x03
	jmp   XMB_FAULT

xmb_crc_fault_02:
	ldi   r24,     0x02
	ldi   r25,     0x03
	jmp   XMB_FAULT

xmb_crc_fault_03:
	ldi   r24,     0x03
	ldi   r25,     0x03
	jmp   XMB_FAULT



;
; Initializes CRC component
;
.global xmb_crc_init
xmb_crc_init:

	ldi   r24,     0xFF
	ldi   ZL,      lo8(xmb_crc_val)
	ldi   ZH,      hi8(xmb_crc_val)
	st    Z+,      r24
	st    Z+,      r24
	st    Z+,      r24
	st    Z+,      r24     ; CRC starts at 0xFFFFFFFF
	ldi   r25,     0x00
	ldi   ZL,      lo8(xmb_crc_pos)
	ldi   ZH,      hi8(xmb_crc_pos)
	st    Z+,      r25     ; Progmem position: 0x000000
	st    Z+,      r25
#if (PROGMEM_SIZE > (64 * 1024))
	st    Z+,      r25
#endif
	st    Z+,      r24
	st    Z+,      r24
#if (PROGMEM_SIZE > (64 * 1024))
	st    Z+,      r24
#endif
	ret



.section .text



;
; Calculates CRC on a given byte of data
;
; Inputs:
; r25:r24: CRC calculation value, high
; r23:r22: CRC calculation value, low (together they are a proper C uint32_t)
;     r20: Byte to calculate CRC on
; Outputs:
; r25:r24: CRC calculation value, high
; r23:r22: CRC calculation value, low (together they are a proper C uint32_t)
; Clobbers:
; r0, r1 (zero), r20, Z
;
.global xmb_crc_calc
xmb_crc_calc:

	eor   r20,     r22     ; ptr = byte ^ (crcval & 0xFF)
	ldi   ZL,      4
	mul   r20,     ZL
	movw  ZL,      r0
	clr   r1               ; ptr <<= 2
	subi  ZL,      lo8(-(xmb_crc_table))
	sbci  ZH,      hi8(-(xmb_crc_table))
	mov   r22,     r23
	mov   r23,     r24
	mov   r24,     r25     ; crcval >>= 8
	lpm   r20,     Z+
	eor   r22,     r20
	lpm   r20,     Z+
	eor   r23,     r20
	lpm   r20,     Z+
	eor   r24,     r20
	lpm   r25,     Z       ; crcval ^= xmb_crc_table[ptr]
	ret



;
; Checks CRC of the entire ROM
;
; Outputs:
; r25:r24: 1 if CRC is OK, 0 otherwise.
; Clobbers:
; r0, r1 (zero), r18, r19, r20, r21, r22, r23, r24, r25, X, Z
;
.global xmb_crc_isromok
xmb_crc_isromok:

	; Load binary size

	ldi   ZL,      lo8(XMB_BSIZE)
	ldi   ZH,      hi8(XMB_BSIZE)
#if (PROGMEM_SIZE > (64 * 1024))
	ldi   r20,     hh8(XMB_BSIZE)
	clr   r1
	in    r0,      SR_IO   ; Save current SREG with whatever 'I' flag it has
	cli                    ; Disable interrupts
	out   RPZ_IO,  r20
	elpm  r18,     Z+
	elpm  r19,     Z+
	elpm  r20,     Z
	out   RPZ_IO,  r1
	out   SR_IO,   r0      ; Enable interrupts (if they were disabled)
#else
	lpm   r18,     Z+
	lpm   r19,     Z
#endif

	; Start address (0x000000)

	ldi   ZL,      0
	ldi   ZH,      0
#if (PROGMEM_SIZE > (64 * 1024))
	push  r15
	push  r16
	push  r17
	in    r15,     SR_IO   ; Save current SREG with whatever 'I' flag it has
	ldi   r16,     0
	ldi   r17,     0
#endif

	; Start CRC value (0xFFFFFFFF)

	ldi   r22,     0xFF
	ldi   r23,     0xFF
	movw  r24,     r22

	; Prepare & run calculation loop (32 cycles / byte if <= 64K)

	ldi   r21,     4       ; For multiplying by four

xmb_crc_isromok_l:

#if (PROGMEM_SIZE > (64 * 1024))
#if (XMB_CRC_SPLIT == 0)
	cli                    ; Disable interrupts
	out   RPZ_IO,  r16
	elpm  r0,      Z+
	in    r16,     RPZ_IO
	out   RPZ_IO,  r17
	out   SR_IO,   r15     ; Enable interrupts (if they were disabled)
#else
	mov   XL,      r16
	cli                    ; Disable interrupts
	out   RPZ_IO,  r16
	elpm  r0,      Z+
	in    r16,     RPZ_IO
	out   RPZ_IO,  r17
	out   SR_IO,   r15     ; Enable interrupts (if they were disabled)
	cpse  XL,      r16     ; When passing a 64K boundary, call xmb_run
	rjmp  xmb_crc_isromok_rc
xmb_crc_isromok_rcr:
#endif
#else
	lpm   r0,      Z+
#endif
	movw  XL,      ZL
	eor   r0,      r22     ; ptr = byte ^ (crcval & 0xFF)
	mul   r0,      r21     ; r21 = 4, entry size in crc_table
	movw  ZL,      r0
	subi  ZL,      lo8(-(xmb_crc_table))
	sbci  ZH,      hi8(-(xmb_crc_table))
	mov   r22,     r23
	mov   r23,     r24
	mov   r24,     r25     ; crcval >>= 8
	lpm   r0,      Z+
	eor   r22,     r0
	lpm   r0,      Z+
	eor   r23,     r0
	lpm   r0,      Z+
	eor   r24,     r0
	lpm   r25,     Z       ; crcval ^= xmb_crc_table[ptr]
	movw  ZL,      XL
	cpse  ZL,      r18
	rjmp  xmb_crc_isromok_l
	cpse  ZH,      r19
	rjmp  xmb_crc_isromok_l
#if (PROGMEM_SIZE > (64 * 1024))
	cpse  r16,     r20
	rjmp  xmb_crc_isromok_l
	pop   r17
	pop   r16
	pop   r15
#endif

	clr   r1

xmb_crc_isok_tail:

	; Check CRC correctness & done

	subi  r22,     0xE3
	sbci  r23,     0x20
	sbci  r24,     0xBB
	sbci  r25,     0xDE    ; CRC32 "magic" number (0xDEBB20E3), result if CRC was good
	ldi   r24,     0
	ldi   r25,     0
	brne  .+2
	ldi   r24,     1       ; Resulted zero: CRC is correct
	ret

#if ((PROGMEM_SIZE > (64 * 1024)) && (XMB_CRC_SPLIT != 0))
xmb_crc_isromok_rc:

	; Call xmb_run with proper register save & restore

	push  r18
	push  r19
	push  r20
	push  r21
	push  r22
	push  r23
	push  r24
	push  r25
	push  ZL
	push  ZH
	call  xmb_run
	pop   ZH
	pop   ZL
	pop   r25
	pop   r24
	pop   r23
	pop   r22
	pop   r21
	pop   r20
	pop   r19
	pop   r18
	rjmp  xmb_crc_isromok_rcr
#endif



;
; Internal routine for xmb_crc_genram and xmb_crc_isramok
;
; Runs CRC calculation.
;
; Inputs:
; r25:r24: Start address to generate for
; r23:r22: Length of region (CRC is 4 bytes appended to it)
; Outputs:
; XH: XL:  At the end of the RAM region
; r25:r24: CRC value, high
; r23:r22: CRC value, low
; Clobbers:
; r0, r1 (zero), r18, r19, r20, r21, Z
;
xmb_crc_ram_calc:

	; Prepare start and end address

	movw  XL,      r24
	add   r24,     r22
	adc   r25,     r23
	movw  r18,     r24

	; Start CRC value (0xFFFFFFFF)

	ldi   r22,     0xFF
	ldi   r23,     0xFF
	movw  r24,     r22

	; Prepare & run calculation loop (29 cycles / byte)

	ldi   r21,     4       ; For multiplying by four

xmb_crc_ram_l:

	ld    r20,     X+
	eor   r20,     r22     ; ptr = byte ^ (crcval & 0xFF)
	mul   r20,     r21     ; r21 = 4, entry size in crc_table
	movw  ZL,      r0
	subi  ZL,      lo8(-(xmb_crc_table))
	sbci  ZH,      hi8(-(xmb_crc_table))
	mov   r22,     r23
	mov   r23,     r24
	mov   r24,     r25     ; crcval >>= 8
	lpm   r20,     Z+
	eor   r22,     r20
	lpm   r20,     Z+
	eor   r23,     r20
	lpm   r20,     Z+
	eor   r24,     r20
	lpm   r25,     Z       ; crcval ^= xmb_crc_table[ptr]
	cpse  XL,      r18
	rjmp  xmb_crc_ram_l
	cpse  XH,      r19
	rjmp  xmb_crc_ram_l

	clr   r1

	ret



;
; Generates CRC for RAM region
;
; Inputs:
; r25:r24: Start address to generate for
; r23:r22: Length of region (CRC is 4 bytes appended to it)
; Clobbers:
; r0, r1 (zero), r18, r19, r20, r21, r22, r23, r24, r25, X, Z
;
.global xmb_crc_genram
xmb_crc_genram:

	rcall xmb_crc_ram_calc

	; Append CRC negated & done

	com   r22
	com   r23
	com   r24
	com   r25
	st    X+,      r22
	st    X+,      r23
	st    X+,      r24
	st    X+,      r25
	ret



;
; Checks CRC on RAM region
;
; Inputs:
; r25:r24: Start address to check from
; r23:r22: Length of region (CRC is on the end of it)
; Outputs:
; r25:r24: 1 if CRC is OK, 0 otherwise.
; Clobbers:
; r0, r1 (zero), r18, r19, r20, r21, r22, r23, r24, r25, X, Z
;
.global xmb_crc_isramok
xmb_crc_isramok:

	rcall xmb_crc_ram_calc
	rjmp  xmb_crc_isok_tail



.section XMB_RO64_SECTION


;
; CRC32 table
;
xmb_crc_table:
	.byte 0x00, 0x00, 0x00, 0x00
	.byte 0x96, 0x30, 0x07, 0x77
	.byte 0x2C, 0x61, 0x0E, 0xEE
	.byte 0xBA, 0x51, 0x09, 0x99
	.byte 0x19, 0xC4, 0x6D, 0x07
	.byte 0x8F, 0xF4, 0x6A, 0x70
	.byte 0x35, 0xA5, 0x63, 0xE9
	.byte 0xA3, 0x95, 0x64, 0x9E
	.byte 0x32, 0x88, 0xDB, 0x0E
	.byte 0xA4, 0xB8, 0xDC, 0x79
	.byte 0x1E, 0xE9, 0xD5, 0xE0
	.byte 0x88, 0xD9, 0xD2, 0x97
	.byte 0x2B, 0x4C, 0xB6, 0x09
	.byte 0xBD, 0x7C, 0xB1, 0x7E
	.byte 0x07, 0x2D, 0xB8, 0xE7
	.byte 0x91, 0x1D, 0xBF, 0x90
	.byte 0x64, 0x10, 0xB7, 0x1D
	.byte 0xF2, 0x20, 0xB0, 0x6A
	.byte 0x48, 0x71, 0xB9, 0xF3
	.byte 0xDE, 0x41, 0xBE, 0x84
	.byte 0x7D, 0xD4, 0xDA, 0x1A
	.byte 0xEB, 0xE4, 0xDD, 0x6D
	.byte 0x51, 0xB5, 0xD4, 0xF4
	.byte 0xC7, 0x85, 0xD3, 0x83
	.byte 0x56, 0x98, 0x6C, 0x13
	.byte 0xC0, 0xA8, 0x6B, 0x64
	.byte 0x7A, 0xF9, 0x62, 0xFD
	.byte 0xEC, 0xC9, 0x65, 0x8A
	.byte 0x4F, 0x5C, 0x01, 0x14
	.byte 0xD9, 0x6C, 0x06, 0x63
	.byte 0x63, 0x3D, 0x0F, 0xFA
	.byte 0xF5, 0x0D, 0x08, 0x8D
	.byte 0xC8, 0x20, 0x6E, 0x3B
	.byte 0x5E, 0x10, 0x69, 0x4C
	.byte 0xE4, 0x41, 0x60, 0xD5
	.byte 0x72, 0x71, 0x67, 0xA2
	.byte 0xD1, 0xE4, 0x03, 0x3C
	.byte 0x47, 0xD4, 0x04, 0x4B
	.byte 0xFD, 0x85, 0x0D, 0xD2
	.byte 0x6B, 0xB5, 0x0A, 0xA5
	.byte 0xFA, 0xA8, 0xB5, 0x35
	.byte 0x6C, 0x98, 0xB2, 0x42
	.byte 0xD6, 0xC9, 0xBB, 0xDB
	.byte 0x40, 0xF9, 0xBC, 0xAC
	.byte 0xE3, 0x6C, 0xD8, 0x32
	.byte 0x75, 0x5C, 0xDF, 0x45
	.byte 0xCF, 0x0D, 0xD6, 0xDC
	.byte 0x59, 0x3D, 0xD1, 0xAB
	.byte 0xAC, 0x30, 0xD9, 0x26
	.byte 0x3A, 0x00, 0xDE, 0x51
	.byte 0x80, 0x51, 0xD7, 0xC8
	.byte 0x16, 0x61, 0xD0, 0xBF
	.byte 0xB5, 0xF4, 0xB4, 0x21
	.byte 0x23, 0xC4, 0xB3, 0x56
	.byte 0x99, 0x95, 0xBA, 0xCF
	.byte 0x0F, 0xA5, 0xBD, 0xB8
	.byte 0x9E, 0xB8, 0x02, 0x28
	.byte 0x08, 0x88, 0x05, 0x5F
	.byte 0xB2, 0xD9, 0x0C, 0xC6
	.byte 0x24, 0xE9, 0x0B, 0xB1
	.byte 0x87, 0x7C, 0x6F, 0x2F
	.byte 0x11, 0x4C, 0x68, 0x58
	.byte 0xAB, 0x1D, 0x61, 0xC1
	.byte 0x3D, 0x2D, 0x66, 0xB6
	.byte 0x90, 0x41, 0xDC, 0x76
	.byte 0x06, 0x71, 0xDB, 0x01
	.byte 0xBC, 0x20, 0xD2, 0x98
	.byte 0x2A, 0x10, 0xD5, 0xEF
	.byte 0x89, 0x85, 0xB1, 0x71
	.byte 0x1F, 0xB5, 0xB6, 0x06
	.byte 0xA5, 0xE4, 0xBF, 0x9F
	.byte 0x33, 0xD4, 0xB8, 0xE8
	.byte 0xA2, 0xC9, 0x07, 0x78
	.byte 0x34, 0xF9, 0x00, 0x0F
	.byte 0x8E, 0xA8, 0x09, 0x96
	.byte 0x18, 0x98, 0x0E, 0xE1
	.byte 0xBB, 0x0D, 0x6A, 0x7F
	.byte 0x2D, 0x3D, 0x6D, 0x08
	.byte 0x97, 0x6C, 0x64, 0x91
	.byte 0x01, 0x5C, 0x63, 0xE6
	.byte 0xF4, 0x51, 0x6B, 0x6B
	.byte 0x62, 0x61, 0x6C, 0x1C
	.byte 0xD8, 0x30, 0x65, 0x85
	.byte 0x4E, 0x00, 0x62, 0xF2
	.byte 0xED, 0x95, 0x06, 0x6C
	.byte 0x7B, 0xA5, 0x01, 0x1B
	.byte 0xC1, 0xF4, 0x08, 0x82
	.byte 0x57, 0xC4, 0x0F, 0xF5
	.byte 0xC6, 0xD9, 0xB0, 0x65
	.byte 0x50, 0xE9, 0xB7, 0x12
	.byte 0xEA, 0xB8, 0xBE, 0x8B
	.byte 0x7C, 0x88, 0xB9, 0xFC
	.byte 0xDF, 0x1D, 0xDD, 0x62
	.byte 0x49, 0x2D, 0xDA, 0x15
	.byte 0xF3, 0x7C, 0xD3, 0x8C
	.byte 0x65, 0x4C, 0xD4, 0xFB
	.byte 0x58, 0x61, 0xB2, 0x4D
	.byte 0xCE, 0x51, 0xB5, 0x3A
	.byte 0x74, 0x00, 0xBC, 0xA3
	.byte 0xE2, 0x30, 0xBB, 0xD4
	.byte 0x41, 0xA5, 0xDF, 0x4A
	.byte 0xD7, 0x95, 0xD8, 0x3D
	.byte 0x6D, 0xC4, 0xD1, 0xA4
	.byte 0xFB, 0xF4, 0xD6, 0xD3
	.byte 0x6A, 0xE9, 0x69, 0x43
	.byte 0xFC, 0xD9, 0x6E, 0x34
	.byte 0x46, 0x88, 0x67, 0xAD
	.byte 0xD0, 0xB8, 0x60, 0xDA
	.byte 0x73, 0x2D, 0x04, 0x44
	.byte 0xE5, 0x1D, 0x03, 0x33
	.byte 0x5F, 0x4C, 0x0A, 0xAA
	.byte 0xC9, 0x7C, 0x0D, 0xDD
	.byte 0x3C, 0x71, 0x05, 0x50
	.byte 0xAA, 0x41, 0x02, 0x27
	.byte 0x10, 0x10, 0x0B, 0xBE
	.byte 0x86, 0x20, 0x0C, 0xC9
	.byte 0x25, 0xB5, 0x68, 0x57
	.byte 0xB3, 0x85, 0x6F, 0x20
	.byte 0x09, 0xD4, 0x66, 0xB9
	.byte 0x9F, 0xE4, 0x61, 0xCE
	.byte 0x0E, 0xF9, 0xDE, 0x5E
	.byte 0x98, 0xC9, 0xD9, 0x29
	.byte 0x22, 0x98, 0xD0, 0xB0
	.byte 0xB4, 0xA8, 0xD7, 0xC7
	.byte 0x17, 0x3D, 0xB3, 0x59
	.byte 0x81, 0x0D, 0xB4, 0x2E
	.byte 0x3B, 0x5C, 0xBD, 0xB7
	.byte 0xAD, 0x6C, 0xBA, 0xC0
	.byte 0x20, 0x83, 0xB8, 0xED
	.byte 0xB6, 0xB3, 0xBF, 0x9A
	.byte 0x0C, 0xE2, 0xB6, 0x03
	.byte 0x9A, 0xD2, 0xB1, 0x74
	.byte 0x39, 0x47, 0xD5, 0xEA
	.byte 0xAF, 0x77, 0xD2, 0x9D
	.byte 0x15, 0x26, 0xDB, 0x04
	.byte 0x83, 0x16, 0xDC, 0x73
	.byte 0x12, 0x0B, 0x63, 0xE3
	.byte 0x84, 0x3B, 0x64, 0x94
	.byte 0x3E, 0x6A, 0x6D, 0x0D
	.byte 0xA8, 0x5A, 0x6A, 0x7A
	.byte 0x0B, 0xCF, 0x0E, 0xE4
	.byte 0x9D, 0xFF, 0x09, 0x93
	.byte 0x27, 0xAE, 0x00, 0x0A
	.byte 0xB1, 0x9E, 0x07, 0x7D
	.byte 0x44, 0x93, 0x0F, 0xF0
	.byte 0xD2, 0xA3, 0x08, 0x87
	.byte 0x68, 0xF2, 0x01, 0x1E
	.byte 0xFE, 0xC2, 0x06, 0x69
	.byte 0x5D, 0x57, 0x62, 0xF7
	.byte 0xCB, 0x67, 0x65, 0x80
	.byte 0x71, 0x36, 0x6C, 0x19
	.byte 0xE7, 0x06, 0x6B, 0x6E
	.byte 0x76, 0x1B, 0xD4, 0xFE
	.byte 0xE0, 0x2B, 0xD3, 0x89
	.byte 0x5A, 0x7A, 0xDA, 0x10
	.byte 0xCC, 0x4A, 0xDD, 0x67
	.byte 0x6F, 0xDF, 0xB9, 0xF9
	.byte 0xF9, 0xEF, 0xBE, 0x8E
	.byte 0x43, 0xBE, 0xB7, 0x17
	.byte 0xD5, 0x8E, 0xB0, 0x60
	.byte 0xE8, 0xA3, 0xD6, 0xD6
	.byte 0x7E, 0x93, 0xD1, 0xA1
	.byte 0xC4, 0xC2, 0xD8, 0x38
	.byte 0x52, 0xF2, 0xDF, 0x4F
	.byte 0xF1, 0x67, 0xBB, 0xD1
	.byte 0x67, 0x57, 0xBC, 0xA6
	.byte 0xDD, 0x06, 0xB5, 0x3F
	.byte 0x4B, 0x36, 0xB2, 0x48
	.byte 0xDA, 0x2B, 0x0D, 0xD8
	.byte 0x4C, 0x1B, 0x0A, 0xAF
	.byte 0xF6, 0x4A, 0x03, 0x36
	.byte 0x60, 0x7A, 0x04, 0x41
	.byte 0xC3, 0xEF, 0x60, 0xDF
	.byte 0x55, 0xDF, 0x67, 0xA8
	.byte 0xEF, 0x8E, 0x6E, 0x31
	.byte 0x79, 0xBE, 0x69, 0x46
	.byte 0x8C, 0xB3, 0x61, 0xCB
	.byte 0x1A, 0x83, 0x66, 0xBC
	.byte 0xA0, 0xD2, 0x6F, 0x25
	.byte 0x36, 0xE2, 0x68, 0x52
	.byte 0x95, 0x77, 0x0C, 0xCC
	.byte 0x03, 0x47, 0x0B, 0xBB
	.byte 0xB9, 0x16, 0x02, 0x22
	.byte 0x2F, 0x26, 0x05, 0x55
	.byte 0xBE, 0x3B, 0xBA, 0xC5
	.byte 0x28, 0x0B, 0xBD, 0xB2
	.byte 0x92, 0x5A, 0xB4, 0x2B
	.byte 0x04, 0x6A, 0xB3, 0x5C
	.byte 0xA7, 0xFF, 0xD7, 0xC2
	.byte 0x31, 0xCF, 0xD0, 0xB5
	.byte 0x8B, 0x9E, 0xD9, 0x2C
	.byte 0x1D, 0xAE, 0xDE, 0x5B
	.byte 0xB0, 0xC2, 0x64, 0x9B
	.byte 0x26, 0xF2, 0x63, 0xEC
	.byte 0x9C, 0xA3, 0x6A, 0x75
	.byte 0x0A, 0x93, 0x6D, 0x02
	.byte 0xA9, 0x06, 0x09, 0x9C
	.byte 0x3F, 0x36, 0x0E, 0xEB
	.byte 0x85, 0x67, 0x07, 0x72
	.byte 0x13, 0x57, 0x00, 0x05
	.byte 0x82, 0x4A, 0xBF, 0x95
	.byte 0x14, 0x7A, 0xB8, 0xE2
	.byte 0xAE, 0x2B, 0xB1, 0x7B
	.byte 0x38, 0x1B, 0xB6, 0x0C
	.byte 0x9B, 0x8E, 0xD2, 0x92
	.byte 0x0D, 0xBE, 0xD5, 0xE5
	.byte 0xB7, 0xEF, 0xDC, 0x7C
	.byte 0x21, 0xDF, 0xDB, 0x0B
	.byte 0xD4, 0xD2, 0xD3, 0x86
	.byte 0x42, 0xE2, 0xD4, 0xF1
	.byte 0xF8, 0xB3, 0xDD, 0x68
	.byte 0x6E, 0x83, 0xDA, 0x1F
	.byte 0xCD, 0x16, 0xBE, 0x81
	.byte 0x5B, 0x26, 0xB9, 0xF6
	.byte 0xE1, 0x77, 0xB0, 0x6F
	.byte 0x77, 0x47, 0xB7, 0x18
	.byte 0xE6, 0x5A, 0x08, 0x88
	.byte 0x70, 0x6A, 0x0F, 0xFF
	.byte 0xCA, 0x3B, 0x06, 0x66
	.byte 0x5C, 0x0B, 0x01, 0x11
	.byte 0xFF, 0x9E, 0x65, 0x8F
	.byte 0x69, 0xAE, 0x62, 0xF8
	.byte 0xD3, 0xFF, 0x6B, 0x61
	.byte 0x45, 0xCF, 0x6C, 0x16
	.byte 0x78, 0xE2, 0x0A, 0xA0
	.byte 0xEE, 0xD2, 0x0D, 0xD7
	.byte 0x54, 0x83, 0x04, 0x4E
	.byte 0xC2, 0xB3, 0x03, 0x39
	.byte 0x61, 0x26, 0x67, 0xA7
	.byte 0xF7, 0x16, 0x60, 0xD0
	.byte 0x4D, 0x47, 0x69, 0x49
	.byte 0xDB, 0x77, 0x6E, 0x3E
	.byte 0x4A, 0x6A, 0xD1, 0xAE
	.byte 0xDC, 0x5A, 0xD6, 0xD9
	.byte 0x66, 0x0B, 0xDF, 0x40
	.byte 0xF0, 0x3B, 0xD8, 0x37
	.byte 0x53, 0xAE, 0xBC, 0xA9
	.byte 0xC5, 0x9E, 0xBB, 0xDE
	.byte 0x7F, 0xCF, 0xB2, 0x47
	.byte 0xE9, 0xFF, 0xB5, 0x30
	.byte 0x1C, 0xF2, 0xBD, 0xBD
	.byte 0x8A, 0xC2, 0xBA, 0xCA
	.byte 0x30, 0x93, 0xB3, 0x53
	.byte 0xA6, 0xA3, 0xB4, 0x24
	.byte 0x05, 0x36, 0xD0, 0xBA
	.byte 0x93, 0x06, 0xD7, 0xCD
	.byte 0x29, 0x57, 0xDE, 0x54
	.byte 0xBF, 0x67, 0xD9, 0x23
	.byte 0x2E, 0x7A, 0x66, 0xB3
	.byte 0xB8, 0x4A, 0x61, 0xC4
	.byte 0x02, 0x1B, 0x68, 0x5D
	.byte 0x94, 0x2B, 0x6F, 0x2A
	.byte 0x37, 0xBE, 0x0B, 0xB4
	.byte 0xA1, 0x8E, 0x0C, 0xC3
	.byte 0x1B, 0xDF, 0x05, 0x5A
	.byte 0x8D, 0xEF, 0x02, 0x2D



;
; Test entry points
;
.global xmb_crc_ccalc

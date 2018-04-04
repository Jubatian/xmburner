
XMBurner instruction coverage report
==============================================================================

:Author:    Sandor Zsuga (Jubatian)
:License:   MPLv2.0 (version 2.0 of the Mozilla Public License)




Overview
------------------------------------------------------------------------------


This document summarizes the instruction & component coverage of XMBurner's
tests, indicating what is tested in which XMBurner components.




CPU core assumptions
------------------------------------------------------------------------------


The following assumptions are relied upon in the design of XMBurner. It is
assumed that these should hold in sane hardware designs, and existing
implementations provide indications that they indeed hold.

- Instruction processing has independent fetch, decode, and execution stages,
  that is, specific faults can not arise for example for specific parameters
  of the fetch (such as the current value of the Program Counter) and the
  execution stage (such as the ALU operation to perform).

- The execution stage has independent read, operation and write-back stages,
  that is, specific faults can not arise for example for specific parameters
  of the read (such as the source register operand) and the operation (such
  as it being an addition, and not for a subtraction).

These assumptions mean that for example the read of the execution stage is
assumed to be tested once for a given instruction encoding all possible
registers are tested.

However measures are taken to aim for a reasonable coverage for cases when
these assumptions don't fully hold, for example by aiming for diverse source
and destination register coverage for each instruction tested, but designing
completely without adhering to these assumptions is impractical.

It is not possible to produce full operand coverage for each instruction as
due to the Harward architecture of the CPU executing instructions from a ROM,
and that there are 16 instruction bits (65536 possible single word
instructions), it is physically impossible to create a reasonable runtime
test library adhering to such a demand.




Coverage table
------------------------------------------------------------------------------


Below is a coverage table providing the instructions of the CPU and the
XMBurner components which do tests on these.

Components are named by the distinctive fragment of their file name in the
xmburner directory, such as "creg" referring to "xmb_creg.s".

+---------------------+---------------+------------+-------------------------+
| Instruction word    | Mnemonic      | Components | Notes                   |
+=====================+===============+============+=========================+
| 0000 0000 0000 0000 | NOP           ||           || Nothing to test        |
+---------------------+---------------+------------+-------------------------+
| 0000 0001 dddd rrrr | MOVW Rd, Rr   || wops      ||                        |
+---------------------+---------------+------------+-------------------------+
| 0000 0010 dddd rrrr | MULS Rd, Rr   || mul       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0000 0011 0ddd 0rrr | MULSU Rd, Rr  || mul       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0000 0011 0ddd 1rrr | FMUL Rd, Rr   || mul       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0000 0011 1ddd 0rrr | FMULS Rd, Rr  || mul       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0000 0011 1ddd 1rrr | FMULSU Rd, Rr || mul       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0000 01rd dddd rrrr | CPC Rd, Rr    || sub       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0000 10rd dddd rrrr | SBC Rd, Rr    || sub       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0000 11rd dddd rrrr | ADD Rd, Rr    || add       || LSL is ADD Rd, Rd      |
|                     |               || mul       |                         |
+---------------------+---------------+------------+-------------------------+
| 0001 00rd dddd rrrr | CPSE Rd, Rr   || cond      ||                        |
|                     |               || creg      |                         |
+---------------------+---------------+------------+-------------------------+
| 0001 01rd dddd rrrr | CP Rd, Rr     || sub       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0001 10rd dddd rrrr | SUB Rd, Rr    || sub       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0001 11rd dddd rrrr | ADC Rd, Rr    || add       || ROL is ADC Rd, Rd      |
|                     |               || mul       |                         |
|                     |               || creg      |                         |
+---------------------+---------------+------------+-------------------------+
| 0010 00rd dddd rrrr | AND Rd, Rr    || log       || TST is AND Rd, Rd      |
+---------------------+---------------+------------+-------------------------+
| 0010 01rd dddd rrrr | EOR Rd, Rr    || log       || CLR is EOR Rd, Rd      |
|                     |               || creg      |                         |
|                     |               || crc       |                         |
+---------------------+---------------+------------+-------------------------+
| 0010 10rd dddd rrrr | OR Rd, Rr     || log       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0010 11rd dddd rrrr | MOV Rd, Rr    || log       ||                        |
|                     |               || sub       |                         |
|                     |               || add       |                         |
+---------------------+---------------+------------+-------------------------+
| 0011 KKKK dddd KKKK | CPI Rd, K     || sub       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0100 KKKK dddd KKKK | SBCI Rd, K    || sub       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0101 KKKK dddd KKKK | SUBI Rd, K    || sub       ||                        |
+---------------------+---------------+------------+-------------------------+
| 0110 KKKK dddd KKKK | ORI Rd, K     || log       || SBR is ORI Rd, K       |
+---------------------+---------------+------------+-------------------------+
| 0111 KKKK dddd KKKK | ANDI Rd, K    || log       || CBR is ANDI Rd, /K     |
+---------------------+---------------+------------+-------------------------+
| 10q0 qq0d dddd 0qqq | LDD Rd, Z + q || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 10q0 qq0d dddd 1qqq | LDD Rd, Y + q || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 10q0 qq1d dddd 0qqq | STD Z + q, Rd || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 10q0 qq1d dddd 1qqq | STD Y + q, Rd || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 0000 | LDS Rd, k     ||           || Next word is address   |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 0001 | LD Rd, Z+     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 0010 | LD Rd, -Z     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 0100 | LPM Rd, Z     || creg      ||                        |
|                     |               || crc       |                         |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 0101 | LPM Rd, Z+    || crc       ||                        |
|                     |               || creg      |                         |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 0110 | ELPM Rd, Z    || crc       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 0111 | ELPM Rd, Z+   || crc       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 1001 | LD Rd, Y+     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 1010 | LD Rd, -Y     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 1100 | LD Rd, X      || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 1101 | LD Rd, X+     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 1110 | LD Rd, -X     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 000d dddd 1111 | POP Rd        || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 001d dddd 0000 | STS k, Rr     ||           || Next word is address   |
+---------------------+---------------+------------+-------------------------+
| 1001 001r rrrr 0001 | ST Z+, Rr     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 001r rrrr 0010 | ST -Z, Rr     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 001r rrrr 1001 | ST Y+, Rr     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 001r rrrr 1010 | ST -Y, Rr     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 001r rrrr 1100 | ST X, Rr      || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 001r rrrr 1101 | ST X+, Rr     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 001r rrrr 1110 | ST -X, Rr     || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 001d dddd 1111 | PUSH Rd       || ram       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 010d dddd 0000 | COM Rd        || log       ||                        |
|                     |               || creg      |                         |
+---------------------+---------------+------------+-------------------------+
| 1001 010d dddd 0001 | NEG Rd        || alex      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 010d dddd 0010 | SWAP Rd       || alex      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 010d dddd 0011 | INC Rd        || alex      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 010d dddd 0101 | ASR Rd        || alex      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 010d dddd 0110 | LSR Rd        || alex      |                         |
|                     |               || crc       |                         |
+---------------------+---------------+------------+-------------------------+
| 1001 010d dddd 0111 | ROR Rd        || alex      |                         |
|                     |               || crc       |                         |
+---------------------+---------------+------------+-------------------------+
| 1001 010d dddd 1010 | DEC Rd        || alex      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 010k kkkk 110k | JMP k         || #1        || Next word is address   |
+---------------------+---------------+------------+-------------------------+
| 1001 010k kkkk 111k | CALL k        || #1        || Next word is address   |
+---------------------+---------------+------------+-------------------------+
| 1001 0100 0sss 1000 | BSET s        || creg      || SEC, etc are aliases   |
+---------------------+---------------+------------+-------------------------+
| 1001 0100 1sss 1000 | BCLR s        || creg      || CLC, etc are aliases   |
+---------------------+---------------+------------+-------------------------+
| 1001 0100 0000 1001 | IJMP          || #1        ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 0101 0000 1000 | RET           || #1        ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 0101 0000 1001 | ICALL         ||           ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 0101 0001 1000 | RETI          ||           ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 0101 1000 1000 | SLEEP         ||           ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 0101 1001 1000 | BREAK         ||           ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 0101 1010 1000 | WDR           ||           ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 0101 1100 1000 | LPM r0, Z     || creg      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 0101 1110 1000 | SPM Z         ||           ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 0110 KKdd KKKK | ADIW Rd, K    || wops      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 0111 KKdd KKKK | SBIW Rd, K    || wops      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 1000 AAAA Abbb | CBI A, b      || bit       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 1001 AAAA Abbb | SBIC A, b     || cond      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 1010 AAAA Abbb | SBI A, b      || bit       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 1011 AAAA Abbb | SBIS A, b     || cond      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1001 11rd dddd rrrr | MUL Rd, Rr    || mul       ||                        |
|                     |               || crc       |                         |
+---------------------+---------------+------------+-------------------------+
| 1011 0AAd dddd AAAA | IN Rd, A      || creg      ||                        |
|                     |               || bit       |                         |
+---------------------+---------------+------------+-------------------------+
| 1011 1AAd dddd AAAA | OUT A, Rd     || creg      ||                        |
|                     |               || bit       |                         |
|                     |               || cond      |                         |
+---------------------+---------------+------------+-------------------------+
| 1100 kkkk kkkk kkkk | RJMP k        || jump      || Between -64 and +63,   |
|                     |               |            |  otherwise coarse test  |
+---------------------+---------------+------------+-------------------------+
| 1101 kkkk kkkk kkkk | RCALL k       || jump      || Between -64 and +63,   |
|                     |               |            |  otherwise coarse test  |
+---------------------+---------------+------------+-------------------------+
| 1110 KKKK dddd KKKK | LDI Rd, K     || creg      || SER is LDI Rd, 255     |
|                     |               || cond      |                         |
+---------------------+---------------+------------+-------------------------+
| 1111 00kk kkkk ksss | BRBS s, k     || cond      || BRCS, etc are aliases  |
|                     |               || jump      |                         |
+---------------------+---------------+------------+-------------------------+
| 1111 01kk kkkk ksss | BRBC s, k     || cond      || BRCC, etc are aliases  |
|                     |               || jump      |                         |
+---------------------+---------------+------------+-------------------------+
| 1111 100d dddd 0bbb | BLD Rd, b     || bit       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1111 101d dddd 0bbb | BST Rd, b     || bit       ||                        |
+---------------------+---------------+------------+-------------------------+
| 1111 110r rrrr 0bbb | SBRC Rr, b    || cond      ||                        |
+---------------------+---------------+------------+-------------------------+
| 1111 111r rrrr 0bbb | SBRS Rr, b    || cond      ||                        |
+---------------------+---------------+------------+-------------------------+

- (#1): These instructions are tested during executing the entry and exit
  mechanisms of XMBurner (xmb_run() in xmb_main.s, the tail code in
  xmb_glob.s), without them operating correctly, XMBurner components can not
  run, which should be detected by a watchdog (XMB_WDRESET).




Component coverage
------------------------------------------------------------------------------


- The SRAM is fully tested for stuck bits, addressing flaws and other cross
  influences by xmb_ram.s.

- The ROM is tested by a CRC32 algorithm, up to an user specified limit by
  xmb_crc.s.

- The 32 General Purpose Registers are fully tested by xmb_creg.s.

- The SREG, SPH and SPL special function registers are fully tested. GPIOR0 is
  also tested as a necessary resource for certain instruction tests.

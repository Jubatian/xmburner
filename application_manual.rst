
XMBurner application manual
==============================================================================

:Author:    Sandor Zsuga (Jubatian)
:License:   MPLv2.0 (version 2.0 of the Mozilla Public License)




Overview
------------------------------------------------------------------------------


This document serves as a guide on how to use the XMBurner library properly,
most notably so it can serve its intended purpose to the greatest extent.


The purpose of the library
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

XMBurner may be used for two distinct purposes which require a different
approach when integrating it.

- Diagnostic (DIAG): The goal is to detect and report problems in the
  processor while trying to keep running. Examples could be various stress
  tests or environments where the processor can not be replaced, but it would
  be beneficial to know whether it operates correctly (such as space).

- Safety shut down (SAFE): The goal is to enforce a safe system shut down when
  processor malfunction is discovered. This case the most important is to
  prevent the processor operating further (and possibly generating dangerous
  output) when it is no longer capable to run the application correctly.

The "DIAG" and "SAFE" identifications will be used below to indicate whether a
particular requirement applies to either or both.




Hardware environment
------------------------------------------------------------------------------


- DIAG: No particular requirements apply.

- SAFE: An external watchdog is recommended which can either be armed by a
  specific command or has a significantly longer timeout on power-up than
  in normal operation. This is recommneded for properly guarding XMBurner's
  init routine. It is desirable if the watchdog could keep the processor in
  reset instead of restarting it by a pulse (if XMBurner detects an anomaly,
  the processor should no longer be permitted to perform any control).




Compiling and linking environment
------------------------------------------------------------------------------


To use XMBurner, you may copy it at an arbitrary location (within or external
to the application repository) and set up appropriate scripts to build and
link its modules. For normal Makefiles, the xmb_defs.mk and xmb_ruls.mk files
may be included with an appropriate configuration to assist building and
linking.

The XMBurner sources are all assembler, can be compiled with the avr-gcc
compiler package or a compatible assembler to that within this. They use C
preprocessor directives, so preprocessing is required (using the supplied
Makefiles ensure proper compilation). No C language modules are used.

For assembler interfacing, the xmburner/xmb_defs.h file may be included.

For C interfacing, the xmburner/xmburner.h file is provided which exposes the
library's functions to C modules.


Sections
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

It is possible to use XMBurner without defining sections if the application
binary size is below 64 KBytes size, but it is recommended to set up sections
for both DIAG and SAFE applications.

- XMB_RO64_SECTION: This definition should be pointed to a section which
  covers the low 64 KBytes of the ROM. It is used for certain data tables
  which can only be accessed in this region.

- XMB_JUMP_SECTION: This definition should be pointed to 64 words before the
  largest valid power of 2 address of the ROM. This ensures that the jump
  tests exercise the longest carry chain in relative jumps.




Fault detection
------------------------------------------------------------------------------


The xmb_fault routine is responsible for handling detected failures (this
routine name may be modified by the XMB_FAULT definition). No default
implementation is provided, so in order to link, one has to be supplied. The
routine should be written in assembler to be able to track used instructions
ensuring robustness against the already detected failure.

- DIAG: The routine may return by jumping to xmb_glob_tail (which case the
  xmb_run() routine will return normally). Within the routine, diagnostic
  should be performed (to be able to store or report the failure). XMBurner
  will not continue execution, it must be re-initialized.

- SAFE: The routine should attempt to take measures to halt execution. Note
  that XMBurner itself will break its execution chain, so it is quite robust
  on its own (see also the "Using watchdogs" chapter), but taking proper
  measures here to halt execution improves robustness.




Using watchdogs (SAFE)
------------------------------------------------------------------------------


In SAFE applications, a watchdog or watchdogs should be used. The most
important role of the watchdog is preventing the processor to produce
dangerous output (note that this doesn't necessarily mean that the processor
itself should be reset by the watchdog, a device breaking the output path also
serves as a watchdog in this regard).

The XMB_WDRESET definition should be used to point at the routine managing the
watchdogs (this can be a C routine if desired). The routine takes a single 32
bit parameter, XMBurner passes the value 0xDEADF158 on this which the routine
should use to check whether the call came from the intended source.

A default implementation is provided for this routine which resets the
internal watchdog (by the WDR instruction).

The routine is called once for every xmb_run() call if XMBurner didn't detect
any fault (including faults of its execution chain which is broken by any
detected fault).


Guarding initialization with a Watchdog
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The watchdog(s) also serve for guarding the initialization routine of
XMBurner. For this to be effective, a watchdog which can be armed, or one with
significantly longer power-up timeout than normal operation timeout is
required.

The XMB_INIT_DELAY definition should be set to a value which is larger than
the normal timeout of the watchdog. This ensures that if the initialization
routine is executed for any reason during normal operation, it can not
complete without the watchdog timing out (assuming that at least the
instructions and registers performing this delay are still operational).


Guarding initialization with a routine
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The XMB_INIT_GUARD definition could be used to set up a routine which guards
the initialization routine. It could carry out the following tasks:

- Set the outputs to a safe initial state, ensuring that the controlled
  process returns to an acceptable safe state if the initialization routine is
  re-entered.

- Attempt to detect a false initialization if there is any condition which
  could be used for this purpose. On detecting such a condition, it may halt
  the processor.

Using this guard function properly can make the system more robust against
processor faults, but it may not be as efficient in this task like the
recommended watchdog.




ROM CRC calculation
------------------------------------------------------------------------------


The ROM is guarded by a standard CRC32 (the same which is used for example for
PNG or BZIP). This CRC is used to verify whether the ROM contents are still
sound, or that the instructions fetching from the ROM can still operate
correctly.

To calculate and apply this CRC on the binary, the xmbtools/crchex.c program
is provided along with Makefile assistance to use it.

Within the application, the xmb_bsize location (2 or 3 bytes Little Endian
depending on the MCU's ROM size) is used to determine the location of the CRC
(this location name can be changed by the XMB_BSIZE definition). It has to be
filled accordingly to make the CRC check functional.




Boot time tests
------------------------------------------------------------------------------


XMBurner provides routines to perform a full ROM and RAM test during bootup
(xmb_crc_isromok() and xmb_ram_isramok()). These should be used as part of the
application's initialization as they together may take several hundreds of
milliseconds on larger MCUs.

Note that ROM and RAM tests are also performed during runtime, these routines
only ensure that the application doesn't start at all if either the ROM or the
RAM has a fault.

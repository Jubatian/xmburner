
XMBurner
==============================================================================

.. image:: xmburner_logo.svg
   :align: center
   :width: 30%

:Author:    Sandor Zsuga (Jubatian)
:License:   MPLv2.0 (version 2.0 of the Mozilla Public License)




Overview
------------------------------------------------------------------------------


XMBurner is a run time test (self-test) library for the AVR architecture (Mega
and XMega families). It is intended to test the ALU and related core
microprocessor components.

Possible use cases:

- Stress-testing physical hardware in extreme conditions (such as the edges of
  temperature and voltage ranges, high radiation levels).

- Verifying system operation when operating out of specifications (such as
  under overclocking in some hobby hack project).

- Verifying implementations of AVR architecture (emulators, FPGA cores).

- Runtime checking correct operation of autonomous AVR microcontroller based
  systems operating for extended periods.

The project is mostly completed, its interface should be stable. The current
self-test coverage can be observed in coverage_report.rst. Interface
documentations are accessible in the C headers provided in the xmburner
directory and application_manual.rst. You may use UzeBurn (see below in
Related components) as an example on how the library could be used in a real
time environment.



License
------------------------------------------------------------------------------


The project is published under Mozilla Public License version 2.0. The
intention is providing a final product which could be used by anyone
(including closed-source proprietary products) while providing as robust
protection of its freedom as reasonably possible.



Related components
------------------------------------------------------------------------------


The project relies on two other components:

- XMBurner ALU Emulator: https://github.com/jubatian/xmburner_aluemu
  An AVR core emulator forked off from the CUzeBox project which is capable to
  simulate anomalies of the ALU.

- XMBurner Tests: https://github.com/jubatian/xmburner_test
  A test set used to verify the capability of XMBurner to detect anomalies.

- UzeBurn: https://github.com/jubatian/uzeburn
  An application of the library on the Uzebox game console. It may be used as
  an example (note that the goal of this application is diagnostic).

All of these components are published under GNU General Public License
version 3. They are not needed for implementing products using XMBurner.

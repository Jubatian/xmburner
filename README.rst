
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
  under overclocking).

- Verifying implementations of AVR architecture (emulators, FPGA cores).

- Runtime checking correct operation of autonomous AVR microcontroller based
  systems operating for extended periods.

Currently the project is under development, however it is mostly complete,
already testing almost all instructions of an AVR ALU adequately (see
coverage_report.rst). The interface should be stable. You can start using it
in your projects.



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



Stage of development
------------------------------------------------------------------------------


The most important indication of the stage of development is the coverage
report (coverage_report.rst) which describes what CPU components the library
covers. Notably instructions which have no coverage currently will receive
test modules in the future.

Usage as a library is possible, the interface should be already stable. You
may check out the UzeBurn project for an example of how the library could be
used in a realtime environment.

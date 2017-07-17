
XMBurner
==============================================================================

:Author:    Sandor Zsuga (Jubatian)
:License:   MPLv2.0 (version 2.0 of the Mozilla Public License)




Overview
------------------------------------------------------------------------------


XMBurner will be a run time tester for the AVR architecture (Mega and XMega
families). It is intended to test the ALU and related core microprocessor
components.

Possible use cases (goals of the completed product):

- Stress-testing physical hardware in extreme conditions (such as the edges of
  temperature and voltage ranges, high radiation levels).

- Verifying system operation when operating out of specifications (such as
  under overclocking).

- Verifying implementations of AVR architecture (emulators, FPGA cores).

- Runtime checking correct operation of autonomous AVR microcontroller based
  systems operating for extended periods.

Currently the project is under development, not being suitable to serve these
goals in its present form.



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

Both of these components are published under GNU General Public License
version 3. They are not needed for implementing products using XMBurner.

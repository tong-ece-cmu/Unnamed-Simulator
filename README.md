# Unnamed CPU Simulator [![GitHub issues](https://img.shields.io/github/issues/tong-ece-cmu/Unnamed-Simulator)](https://github.com/tong-ece-cmu/Unnamed-Simulator/issues) [![GitHub forks](https://img.shields.io/github/forks/tong-ece-cmu/Unnamed-Simulator)](https://github.com/tong-ece-cmu/Unnamed-Simulator/network) [![GitHub stars](https://img.shields.io/github/stars/tong-ece-cmu/Unnamed-Simulator)](https://github.com/tong-ece-cmu/Unnamed-Simulator/stargazers) [![This Repository uses a generated Social Preview from @pqt/social-preview](https://img.shields.io/badge/%E2%9C%93-Social%20Preview-blue)](https://github.com/pqt/social-preview)


Here stores different CPU designs and their design notes; Experiments with different hardware description languages, Verilog, System C, and System Verilog; Experiments with different hardware design techniques, data forwarding, automated verification, etc. 

## Microarchitectures (The Latest & Greatest on the top)

**architecture03** is a four-stage pipelined RISC-V RV32I CPU written in System Verilog with data forwarding to minimize stall. 

- [Completed] Data Forwarding
- [Completed] Memory module with delay
- [Completed] Automated Assertion Test Cases Checking
- [Completed] 4kB Direct-Mapped Cache - 32 bytes Block Size
- [TODO] Data Forwarding Special Case
- [TODO] Branching
- [TODO] More Assembly Programs for Testing
- [TODO] Dual Core


**architecture02** is a dynamic scheduling CPU written in SystemC, capable of issuing in-order executing out-of-order using the reservation station. 

**architecture01** is a five-stage pipelined CPU written in Verilog, adhered to RISC-V ISA, more specifically RV32I Base Insturction Set, with data forwarding to minimize CPU stall caused by RAW Hazards and dynamic local branch predicator to minimize CPU stall caused by branch hazard. 

## Tool box

**assembler.py** is a RISC-V assembler I wrote. It compiles assembly into machine code in mem file format. I used it to compile assembly test cases. Create a new program string in the python script, point the asem variable to the new program string, and hit the run button of your python IDE to print machine code in console.

**SIEMENS ModelSim PE Student Edition** is the simulator I currently use.

**Xilinx Vivado** is the simulator I used for **architecture01** and part of **architecture03**.

**System C Visual Studio** is the simulator I used for **architecture02**. 

## Other

There are readme files and sometimes development notes for each architecture in their folder. Check the md files.

All architectures adhere to RISC-V Instruction Set Architecture.

The tests are not comprehensive, they are not suppose to be at this early stage. I use them to make sure the functionality I tried to implement is actually working. After things get serious, I will create some elaborated tests to make sure everything will work flawlessly.



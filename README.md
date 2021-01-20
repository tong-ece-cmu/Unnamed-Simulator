# Unnamed CPU Simulator [![GitHub issues](https://img.shields.io/github/issues/tong-ece-cmu/Unnamed-Simulator)](https://github.com/tong-ece-cmu/Unnamed-Simulator/issues) [![GitHub forks](https://img.shields.io/github/forks/tong-ece-cmu/Unnamed-Simulator)](https://github.com/tong-ece-cmu/Unnamed-Simulator/network) [![GitHub stars](https://img.shields.io/github/stars/tong-ece-cmu/Unnamed-Simulator)](https://github.com/tong-ece-cmu/Unnamed-Simulator/stargazers)

Here stores all the CPU designs I made. Experimenting with different hardware description languages, Verilog, System C, and System Verilog. Trying out different microarchitectures. 

## Microarchitectures (Latest & Greatest on the top)

**architecture03** is a four-stage pipelined RISC-V RV32I CPU written in System Verilog with data forwarding to minimize stall. 

- [Completed] Data forwarding
- [Completed] Memory module with delay
- [Happening] Automated Assertion Verification
- [TODO] 4kB Cache
- [TODO] Dual Core


**architecture02** is a dynamic scheduling CPU written in SystemC, capable of issuing in-order executing out-of-order using the reservation station. 

**architecture01** is a five-stage pipelined CPU written in Verilog, adhered to RISC-V ISA, more specifically RV32I Base Insturction Set, with data forwarding to minimize CPU stall caused by RAW Hazards and dynamic local branch predicator to minimize CPU stall caused by branch hazard. 

## Tool box

**assembler.py** is a RISC-V assembler I wrote. It compiles assembly into machine code in mem file format. I used it to compile assembly test cases.

**Xilinx Vivado** is the simulator I currently use.

**System C Visual Studio** is the simulator I used for **architecture02**. 

## Other

There are readme files and sometimes development notes for each architecture in their folder. Check the md files.

All architectures adhere to RISC-V Instruction Set Architecture.



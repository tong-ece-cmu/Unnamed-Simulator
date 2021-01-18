There are readme file for each architecture in their folder.

All architectures adhere to RISC-V 

architecture01 is a five stage pipelined CPU written in Verilog, adhered to RISC-V ISA, more specifically RV32I Base Insturction Set, with data forwarding to minimize CPU stall caused by RAW Hazards and dynamic local branch predicator to minimize CPU stall caused by branch hazard. 

architecture02 is a dynamic scheduling CPU written in SystemC, capable of issuing in-order executing out-of-order using the reservation station. 
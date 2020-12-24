This is a readme about my simulator

Literature Review

Monton's paper
There is an local copy with the file name CARRV2020_paper_7_Monton.pdf
His repository link(where I found his paper): https://github.com/mariusmm/RISC-V-TLM

The paper is about RISC-V simulator using SystemC-TLM-2. 
The author mentioned Spike simulator as the most common simulator for RISC-V ISA.
Different simulators have different focus, on performance, speed, or good visulization. 
SystemC is a set of libraries for the C++ language to help the simulation of hardware based system by an event-driven model.

The author's simulator architecture includes an Instruction Set Simulator(ISS) for RV32I ISA, a bus controller, the main memory and peripherals. Communication is done by TLM-2 sockets.
![Hierarchy.png](https://github.com/mariusmm/RISC-V-TLM/raw/master/doc/)



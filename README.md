This is a readme about my simulator

# Literature Review

## Personal Opinion

What level of abstraction should I use?\
Logic Gate Level? Block Diagram Level?

Should I use RISC-V as the target? That looks too complex.

Can I build a RISC-V simulator without knowledge the RISC-V processor? - NO.\
Is writing a simulator a hard task? - YES.\
Is learning RISC-V architecture a hard task? - YES.\
Is doing two hard task at the same time a good idea? - NO.

What is a simulator and what is it for?\
It's an incomplete model of the real thing. We use it to predict the future with some accuracy. 

What do we want to know about the future of a piece of silicon?\
We want to know the behavior of the whole system. And see if it matches with our expectation.

Use cases of microprocessor.

RISC-V is shiny new and fast, but what's it for? If it's not for anything, then why build a simulator for it?

Drone and avionics.

It really want clock cycle level of accuracy. Fast to run. Able to see where the code is in the silicon. Preferablly at the gate level or below. Be able to see where the data moves between clock cycle to clock cycle.
Multiple component on the flight control board, multiple IC potentially.
The role of the simulator is to act as a detailed spec or interface or contract between hardware and software.

Enable simultaneous development of software and hardware. If they both confront to the simulator, then there shouldn't be any debugging required during the final convergence of the whole system.

Sensor has its model and microprocessor has its model.

Need a detailed survey of different simulator architecture. 


## Monton's paper

There is an local copy with the file name CARRV2020_paper_7_Monton.pdf

His repository link(where I found his paper): https://github.com/mariusmm/RISC-V-TLM

### Summary

The paper is about RISC-V simulator using SystemC-TLM-2. 
The author mentioned Spike simulator as the most common simulator for RISC-V ISA.
Different simulators have different focus, on performance, speed, or good visulization. 
SystemC is a set of libraries for the C++ language to help the simulation of hardware based system by an event-driven model.

The author's simulator architecture includes an Instruction Set Simulator(ISS) for RV32I ISA, a bus controller, the main memory and peripherals. Communication is done by TLM-2 sockets.


![Hierarchy.png](https://github.com/mariusmm/RISC-V-TLM/raw/master/doc/Hierarchy.png)


The CPU includes Instruction Decodes, Execute, Registers. It has some interfaces, Data bus, Instruction bus, IRQ line.

The Bus Controller, includes different TLM socket.

The Memory module simulates a simple RAM memory. It can read a binary file in Intel HEX format obtained from the .elf file.

There is a timer to keep track of simulation time.

Trace module is used as an output console for the simulated CPU.

Performance module takes statistics of the simulation, such as instructions executed, registers accessed, memory accesed.

Log module log each instruction executed. Record instuction's name, address, time and register values or addresses accessed, PC value, current time.

The simulated CPU was able to run FreeRTOS. 

Test compliance, risc-test and riscv-compliance suites.

dhrystone benchmark test is also passed with correct results.

The project code has been statically checked iwht coverity by Synopsis.

Performance of Simulator is about 8 million of simulated instructions per second.

### Commentary:

I imaging getting all the instruction implemented is a lot of work. The instruction set manual for Intel processor is thousands pages long. I'm expecting the RISC-V ISA to be just as complex. It's pretty impressive that the author did all that.

Passed a lot of tests, riscv-compliance suites and dhrystone benchmark, just to name a few. Also able to run complex program like FreeRTOS. Sounds great.

The author used mostly C and some C++ template. I'm assuming he used Linux.

Performance is 8 million of instructions per second. Not sure how that speed compares to the processor execute in real time. The real processor may takes tens of cycle to execute one complex instructions, such as floating point multiply. But majority of the instruction should be executed in one cycle. A normal CPU should operate aroud 2 GHz or more. So the processor in real time should execute 1-2 billion instructions per second. The simulator is orders of magnitudes slower, about 100 times slower. A real CPU execute 1 minute means simulator running 1 hour and 40 minutes. Now, I see why big semiconductor companies need FPGA to speed up the testing.

The author didn't seem to use parallization on host CPU to speed up the simulation.

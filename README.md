This is a readme about my simulator

# Tasks


## Create TCL script for automating simulation run and output checking
TCL command documentation local copy with the name: ug835-vivado-tcl-commands.pdf

List of commands at PDF Page 20.

After opening the TCL shell, use 'source' command to run script.

### Tcl Command Category - Project\
open_project - Open a Vivado project file (.xpr)\
close_project - Close current opened project \


### TCL Command Category - Simulation\

launch_simulation - need to open project first
close_sim - Unload the current simulation without existing Vivado\

get_value - get current value of the selected HDL object(variable, signal, wire, reg)

restart - Rewind simulation to post loading state, time is set to 0.\
run - Run the simulation for the specified time.\


## Create Python script for generating verilog testbench and Tcl scripts

Generate Tcl scripts to check register file content and out_bus content.\
Generate Verilog testbench.\


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

Drone and avionics. Here is a flight computer software repository: https://github.com/UMSATS/Avionics-Flight-Computer

Use FreeRTOS for the Drone firmware? https://en.wikipedia.org/wiki/FreeRTOS

Some videp tutorial for SystemC: http://videos.accellera.org/tlm20sdvvirtual/

It really want clock cycle level of accuracy. Fast to run. Able to see where the code is in the silicon. Preferablly at the gate level or below. Be able to see where the data moves between clock cycle to clock cycle.
Multiple component on the flight control board, multiple IC potentially.
The role of the simulator is to act as a detailed spec or interface or contract between hardware and software.

Enable simultaneous development of software and hardware. If they both confront to the simulator, then there shouldn't be any debugging required during the final convergence of the whole system.

Sensor has its model and microprocessor has its model.

Need a detailed survey of different simulator architecture. 

Get a simulator that can simulate all RISC-V instructions.
Create an architecture for RISC-V. To get beyond ISA simulation and getting clock cycle accuracy, we need to know the architecture.

Be able to run compiled code from compiler.

Is it just a piece of verilog code?

Yes, we can use Vivado HLS to convert C code to Verilog. But the tool chain doesn't seem to be mature.

Verilog is the best suited to model hardware, since it is a hardware description language. Why do we need C or SystemC to describe hardware? SystemC is really just for speeding up the software development process by modeling the SoC. SystemC model suppose to be identical to the hardware. So the proper order is to develop Verilog first, creating the architecture first. Then translate it into SystemC for software driver development.

The usefulness of SystemC model really comes from be exact match with the hardware. This allows the programmer to probe every part of the hardware, it's good for debugging, performance tuning, and power tuning. As measuring timing using the real hardware is hard. We will need real hardware timing module to profiling different part of the hardware, this by itself will introduce error. However, there is one advantage of using hardware, it will be fast. But SystemC can be optimized to run fast, and it's software, we can change it anytime.


I will use Verilog to create an architecture that confront the RISC-V ISA. Then use SystemC to create a software model for it.

There are RISC-V verilog implementation exist.

## DSP Architecture

I found a lecture slide here: http://bwrcs.eecs.berkeley.edu/Classes/CS252/Notes/Lec09-DSP.pdf

I'm sure there are more information online about DSP architecture. DSPs are specialized for audio signal processing. Not really reprogrammable, designed to do one thing. Software is not king. It's really specialized hardware. 


## FreeRTOS

Website here: https://www.freertos.org/tutorial/solution2.html

It an operating system for embeded system. The interesting part is the context switching. The OS will get all the register content, PC, Stack Pointers, Status Register into stack. This is how it does context switching. Therefore, the software can pretend nothing happened and let the OS to handle the scheduling.



## LLVM Compiler

I found it here: https://www.llvm.org/docs/ExtendingLLVM.html

It's advised to not changing the LLVM C compiler because it's difficult. I'm sure there are existing RISC-V compiler. Don't want to increase difficulty.

## Flight Controller

The repository is here: https://github.com/UMSATS/Avionics-Flight-Computer/tree/v2.0.0/AvionicsSoftware-AtollicProject/Src

Potential user of the SoC. It needs Altimeter, Gyroscope, Accelerometer, Pressure Sensor, Buttons, Buzzer, Presistent Data Storage. Interface used: SPI, UART.


## DRAM Interface

I found it here: https://www.brainkart.com/article/DRAM-interfaces_7638/#:~:text=DRAM%20interfaces%20.%20The%20basic%20DRAM%20interface%20.,partial%20address%20is%20latched%20internally%20by%20the%20DRAM.

I am not necessarily creating a DRAM, but its verilog model is useful for the SoC system testing. 

## OpenROAD

The wiki: https://openroad.readthedocs.io/en/latest/user/getting-started.html

It's using CentOS 7. It's for Digital IC layout, the only known alternative for Paid Digital IC layout tool such as Cadense Virtuoso. 


## SkyWater Open Source PDK

Repository here: https://github.com/google/skywater-pdk

Google let us tape out 130 nm technology chip for free. Their Process Development Kit is on Github.


## RISC-V Spec

I found it here: https://riscv.org/technical/specifications/

There is a local copy with the file name: riscv-spec-20191213.pdf


## Spike Simulator for RISC-V ISA

The repository is here: https://github.com/riscv/riscv-isa-sim/tree/master/riscv/insns


## MIPS Architecture

I found it here: http://dictionary.sensagent.com/MIPS%20architecture/en-en/#:~:text=MIPS%20%28originally%20an%20acronym%20for%20Microprocessor%20without%20Interlocked,architectures%20were%2032-bit%2C%20and%20later%20versions%20were%2064-bit.

MIPS is an old technology, it's out of fashion. But it's RISC.


## ATMEGA328P Datasheet

I found it here: https://ww1.microchip.com/downloads/en/DeviceDoc/Atmel-7810-Automotive-Microcontrollers-ATmega328P_Datasheet.pdf

This really shows the problem. It's a datasheet of the microprocessor. It's long, hard to understand, hard to search around, hard for software development. If there was a SystemC model, we can see what the chip is doing in the simulator. We don't need the chip for software development. And we don't really want the chip, as it is just a black box, give it some input and it may give correct output. Not really helpful for debugging.

## Verilog VS SystemC

This article talked about differences between Verilog and SystemC: https://www.design-reuse.com/articles/34931/systemverilog-versus-systemc.html

SystemC is used for speeding up the software development process. SystemC suppose to match exactly to the hardware SoC, so software team can use it to develop software.

SystemVerilog is used for hardware implementation verification.


## Verilog-A

I found it here: https://en.wikipedia.org/wiki/Verilog-A

This is used to model analog IC. People use it to create mixed signal IC, like ADC and amplifier.

## Verilog-A ADC

I found it here: https://www.doulos.com/knowhow/verilog/analog-to-digital-converter/

It's an analog to digital converter written in Verilog-A.


## SystemC to Verilog Converter

I found it here: http://sysc2ver.sourceforge.net/



## SimulAVR

I found it here: https://www.nongnu.org/simulavr/features.html

### Summary

Clock cycle accurate AVR microprocessor simulator. It can simulate ATMEGA328P, the Arduino. It can load ELF file and simulate multiple processors in the same environment and see how they interact.


### Commentary

From other online forum, it seems this is an abandoned project. Took someone a week to get the example simulation working. This simulator has clock cycle level accuracy, which is nice. It may take too long for me to grasp the whole code base and make modifications.


## Nvidia Next Gen Falcon Controller

I found it here: https://www.phoronix.com/scan.php?page=news_item&px=NVIDIA-RISC-V-Next-Gen-Falcon

### Summary

Nvidia is using RISC-V as a base and designed a new ISA for their control CPU on their GPU chip. They showed detailed architecture diagram and talked about their cache structure. The talk also mentioned spike simulator for RISC-V and SystemC in the Q&A at the end.

### Commentary

Spike is just an ISA simulator. Its usefulness is limited for IC design. 


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

After searching around in the code base, the author didn't seem to take the simulation cycle time into account. All instructions seems to take the same amount of time.

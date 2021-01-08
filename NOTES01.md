# Pipeline Structure Analysis


    rise    instruction going in IF, counter is zero, goes to 2 when meet PC modifying instructions
    fall    

    rise    instruction going in ID, counter == 2, Setup read address and rd siganl
    fall    

    rise    instruction going in EXE, register file start read, counter == 3, saved instruction 2
    fall

    rise    instruction going in MEM, datapath start execute, counter == 4, saved instruction 3
    fall

    rise    instruction going in WB, instruction MEM start working, exe result going in register, counter == 5, saved instruction 4
    fall

    rise    instruction get discarded, instruction MEM result going in register, WB start working, counter == 6
    fall

    rise    instruction get discarded, WB finished, counter == 7
    fall


looking at saved instruction 2
if rs1 is same as rd of the next instruction(saved instruction 3)
    if next insturction is load
        insert NOP
    else
        change forward control to use datapath wr_data
else if rs1 is same as rd of the next next instruction(saved instruction 4)
    change forward control to use mem_rd_data


LUI     - rd
AUIPC   - rd

JAL     - rd
JALR    - rd    - rs1

BRANCH  -       - rs1   - rs2

LOAD    - rd    - rs1

STORE   -       - rs1   - rs2

OPIMM   - rd    - rs1   
OP      - rd    - rs1   - rs2


If we first LOAD an register, then immediately followed by a ADDI that use the register being loaded. We will have an RAW hazard. And we can't resolve it by data forwarding. So we have to stall the processor by one cycle. If we detect it at IF stage and insert a NOP, then the data forwarding hardware will have no problem resolve the hazard.

imm[11:0] rs1 000 rd 0010011 ADDI
0000 0000 0000 0001 0 00 0 0001 0 001 0011



imm[12|10:5] rs2 rs1 000 imm[4:1|11] 1100011 BEQ
0000 000 00000 00000 000 01000 1100011



BEQ x0, x1, 12
LI x1, 2
JAL 8
LI x1, 4
NOP



AMD VEGA ISA pdf
https://developer.amd.com/wp-content/resources/Vega_Shader_ISA.pdf


This is where I found it: https://gpuopen.com/documentation/amd-isa-documentation/

About wavefront
https://en.wikipedia.org/wiki/Graphics_Core_Next




## Cache

Cache is an array of sram memory that stores data.
With that array of data, there is also an array of memory that stores addresses for those data.

we need to store addresses because the cache doesn't fit all the data in main memory, so we want to know what data is it that's stored in our cache.

We fetch a block from memory. Use address and fixed block size. Each memory clock cycle, memory gives two byte, double data rate(ddr). Our block size is 32 byte, so it needs 16 cycle to complete a block fetch. Memory clock cycle is usually more than twice as long as cpu cycle. So it takes 32 cpu cycle for memory block fetch.


## target cache structure

rule of thumb for block size is 32-64 byte
we will use 32 byte block size, 5 bit block offset

4 way set associative cache
each set can have 4 block

cache are divided into sets

for a block, there is only one set of places it can go,
firgure out its set, then place anywhere in that set

we will use 4kb l1 cache, that's 2^12 bytes. Need 12 bit to address the l1 cache. 5 bit for block offset. If we are using direct mapped cache, 7 bit(the rest of the 12 bit) will be index, but since we are 4 way set associative. We only need 5 index bit. We will then compare 4 tag in the set. 

32 bit address
0000 0000 0000 0000 0000 00 | 00 000 | 0 0000
tags                        | indx bit    | block offset

22 bit of virtual address need to be translated into 22 bit of physical address

Compare the 22 bit tag with the 4 tags for 4 blocks in the set. If there is a match, cpu can select the l1 cache block and read the word using block offset.

If there isn't a match, signal CPU to Freeze. Choose block to remove, fetch from memory.


## Implementation road map

We will implement direct map cache first
32 byte block size, 5 bit block offset
4 kb L1 cache, 2^12 bytes, 7 bit indexing. 
No virtual addressing, 20 bit of tag.

compare the 20 bit tag with the cache tag field. Make sure the block is valid. If hit, signal cpu to take data. If not hit, signal cpu to wait. signal memory to read data. After block read, signal cpu to take data.


## Cache to memory 

Cache has a block that need to be stored.

It pull wr signal high to notify memory.
It wait until memory is ready.
When the memory is ready, it clock out all the data in block.


## Attention, Thoughts on Cache And Memory Heirachy

There is a bug. wr_data from datapath is not saved by the memory module. This error didn't manifast in the current test, but it will in the future. Save it in memory module, or redesign the thing, such that the datapath will hold the result of LOAD or STORE will memory module is working on it.

There are some diffculty in implementing the cache, more specifically the state machine. The datapath will calculate the address and supply the write data. The register file at the write-back stage will need the read result to save it in register.

We have a memory that simulate off-chip DRAM. It has a state machine which has 16 cycle delay then read or write 32 bit of data each cycle. 

The system of CPU and this simulated off-chip DRAM works somewhat. The behavior is expected long wait time on CPU. And now, we need to insert a 4kB cache inbetween the CPU and DRAM. The cache should have a small delay if it's a hit for both read and write. And the full DRAM delay if it's a miss. 

On read, the CPU pause on LOAD instruction. The cache receive the order and check the tag. If hit, it will present the data to CPU input bus port and unpause the CPU. If miss, the cache signal the DRAM to read. After finish reading the block, the cache will present the data to CPU and unpause the CPU.

On write, the CPU pause on STORE instruction. The cache receive the order and check the tag. If hit, it will overwrite the data in cache and unpause the CPU. If miss, it will first read the DRAM, then overwrite the content from DRAM read, then unpause the CPU.

The state machine in CPU is so messy and convoluted, it's hard to implement the cache. There are few things that cache need CPU to do. Pause the execution and preserve the wr_data(From STORE instruction to write to DRAM), preserve the mem_addr(Used by both STORE and LOAD, memory address), and keep the door open for read data from memory. mem_addr is from Datapath execution. The exe stage first decode the immediate in one cycle. Then the immediate is clocked into flip-flop, and in the next clock cycle, the mem_addr is calculated. Then the mem_addr is clocked into flip-flop which is then seen by the cache and memory system. 

The CPU stores instruction for each stage in 5 registers. Each register used by one stage. On rising edge of clock, the instructions shift through those register to their next stage. And also on rising edge of clock, the datapath clock in the immediate. We have a problem here, at exe stage, the immediate is extracted from the instruction. Then next clock cycle, the datapath execute and compute the result using those immediate. This is grossly wasteful. Extracting immediate is just different connection of wire, there is no logic or computation there, and it for sure doesn't need one clock cycle.
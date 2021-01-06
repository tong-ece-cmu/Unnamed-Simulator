# Pipeline Structure Analysis


    rise    instruction going in IF, counter is zero, goes to one when meet PC modifying instructions
    fall    

    rise    instruction going in ID, counter == 1, Setup read address and rd siganl
    fall    

    rise    instruction going in EXE, register file start read, counter == 2, saved instruction 2
    fall

    rise    instruction going in MEM, datapath start execute, counter == 3, saved instruction 3
    fall

    rise    instruction going in WB, instruction MEM start working, exe result going in register, counter == 4, saved instruction 4
    fall

    rise    instruction get discarded, instruction MEM result going in register, WB start working, counter == 5
    fall

    rise    instruction get discarded, WB finished, counter == 6
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


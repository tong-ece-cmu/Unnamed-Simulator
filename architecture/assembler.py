# -*- coding: utf-8 -*-
"""
Created on Wed Jan  6 09:43:45 2021

@author: Tong
"""
import enum
class TargetOptions(enum.Enum):
   VivadoMem = 1
   SystemcArray = 2

assembler_target = TargetOptions.SystemcArray


'''
Assembly Syntax
LUI     unimplemented
AUIPC   unimplemented
JAL     rd, imm         - jump to pc+imm, store old pc in rd
JALR    unimplemented
BEQ     rs1, rs2, imm   - rs1 == rs2 ? jump to pc+immediate : next
BNE     unimplemented
BLT     unimplemented
BGE     unimplemented
BLTU    unimplemented
BGEU    unimplemented
LB      unimplemented
LH      unimplemented
LW      rd, rs1, imm     - dest, base, offset
LBU     unimplemented
LHU     unimplemented
SB      unimplemented
SH      unimplemented
SW      rs1, rs2, imm   - base, src, offset
ADDI    rd, rs1, imm    - dest, src, immediate
SLTI    unimplemented
SLTIU   unimplemented
XORI    unimplemented
ORI     unimplemented
ANDI    unimplemented
SLLI    unimplemented
SRLI    unimplemented
SRAI    unimplemented
ADD     unimplemented
SUB     unimplemented
SLL     unimplemented
SLT     unimplemented
SLTU    unimplemented
XOR     unimplemented
SRL     unimplemented
SRA     unimplemented
OR      unimplemented
AND     unimplemented
FENCE   unimplemented   - multi-core synchronization related
ECALL   unimplemented   - Operating System Privilege related
EBREAK  unimplemented   - Operating System Privilege related

Assembly alias
NOP     ADDI x0, x0, 0

'''


p1 = '''ADDI x1, x0, 1
BEQ x1, x1, 12
ADDI x1, x1, 2
JAL x0, 8
ADDI x1, x1, 4
ADDI x1, x1, 1
NOP'''

p2 = '''ADDI x1, x0, 3
ADDI x1, x1, 1
ADDI x1, x1, 2
ADDI x1, x1, 1
'''

p3 = '''ADDI x1, x0, 4
SW x0, x1, 0
LW x2, x0, 0
'''
# f = open('..\\HighLevelLanguageTests\\addition.assembly', "r")
# f = open('..\\HighLevelLanguageTests\\branch.assembly', "r")
# asem = f.read()

asem = p3

# for each line
    # get list of tokens, split string on space and comma
    # convert all token except the first to number, register or immediate
    # switch on first token generate machine code
    # print machine code
    
import re


def getOperands(tokens):
    operand = [0, 0, 0]
    for i in range(len(tokens)):
        if (i == 0) : continue
        if (tokens[i][0] == 'x'):
            operand[i-1] = int(tokens[i][1:])
        else:
            operand[i-1] = int(tokens[i])
    return operand


def getMachineCode(token, oprd):
    mc = 0x00000013 # NOP
    if (token[0].lower() == 'lw'):
        opcode = 0x03
        funct3 = 0x2
        rd = oprd[0]
        rs1 = oprd[1]
        imm = oprd[2]
        mc = imm << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode
    elif (token[0].lower() == 'sw'):
        opcode = 0x23
        funct3 = 0x2
        rs1 = oprd[0]
        rs2 = oprd[1]
        imm4_0 = oprd[2] & 0x1F
        imm11_5 = oprd[2] >> 5 & 0x7F
        mc = rs2 << 20 | rs1 << 15 | funct3 << 12 | imm4_0 << 7 | opcode
        mc = imm11_5 << 25 | mc
    elif (token[0].lower() == 'addi'):
        opcode = 0x13
        funct3 = 0x0
        rd = oprd[0]
        rs1 = oprd[1]
        imm = oprd[2]
        mc = imm << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode
    elif (token[0].lower() == 'beq'):
        opcode = 0x63
        funct3 = 0x0
        rs1 = oprd[0]
        rs2 = oprd[1]
        imm11   = oprd[2] >> 11 & 0x1
        imm4_1  = oprd[2] >> 1  & 0xF
        imm10_5 = oprd[2] >> 5  & 0x1F
        imm12   = oprd[2] >> 12 & 0x1
        
        mc = rs1 << 15 | funct3 << 12 | imm4_1 << 8 | imm11 << 7 | opcode
        mc = imm12 << 31 | imm10_5 << 25 | rs2 << 20 | mc
    elif (token[0].lower() == 'nop'):
        opcode = 0x13
        funct3 = 0x0
        rd = 0x0
        rs1 = 0x0
        imm = 0x0
        mc = imm << 20 | rs1 << 15 | funct3 << 12 | rd << 7 | opcode
    elif (token[0].lower() == 'jal'):
        opcode = 0x6F
        rd = oprd[0]
        imm19_12= oprd[1] >> 12 & 0xFF
        imm11   = oprd[1] >> 11 & 0x1
        imm10_1 = oprd[1] >> 1  & 0x3FF
        imm20   = oprd[1] >> 20 & 0x1
        mc = imm10_1 << 21 | imm11 << 20 | imm19_12 << 12 | rd << 7 | opcode
        mc = imm20 << 31 | mc
    return mc



def printInstArray(mc):
    print("0x{0:0{1}X}, ".format(mc, 8))


def printHex(mc):
    # {   # Format identifier
    # 0:  # first parameter
    # #   # use "0x" prefix
    # 0   # fill with zeroes
    # {1} # to a length of n characters (including 0x), defined by the second parameter
    # x   # hexadecimal number, using lowercase letters for a-f
    # }   # End of format identifier
    # https://stackoverflow.com/questions/12638408/decorating-hex-function-to-pad-zeros
    for i in range(4):
        print("{0:#0{1}x}".format((mc >> 8*i) & 0xFF,4))
    print("")

for s in asem.splitlines():
    tokens = re.split(', | |,', s)
    oprd = getOperands(tokens)
    mc = getMachineCode(tokens, oprd)
    
    if assembler_target == TargetOptions.VivadoMem:
        printHex(mc)
    elif assembler_target == TargetOptions.SystemcArray:
        printInstArray(mc)














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

asem = '''ADDI x1, x0, 1
BEQ x1, x1, 12
ADDI x1, x1, 2
JAL x0, 8
ADDI x1, x1, 4
ADDI x1, x1, 1
NOP'''

# for each line
    # get list of tokens, split string on space and comma
    # convert all token except the first to number, register or immediate
    # switch on first token generate machine code
    # print maching code
    
import re

def printInstArray(mc):
    print("0x{0:0{1}X}, ".format(mc, 8))

def getOperands(tokens):
    operand = [0, 0, 0]
    for i in range(len(tokens)):
        if (i == 0) : continue
        if (tokens[i][0] == 'x'):
            operand[i-1] = int(tokens[i][1:])
        else:
            operand[i-1] = int(tokens[i])
    return operand

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


def getMachineCode(token, oprd):
    if (token[0].lower() == 'addi'):
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


for s in asem.splitlines():
    tokens = re.split(', | |,', s)
    oprd = getOperands(tokens)
    mc = getMachineCode(tokens, oprd)
    
    if assembler_target == TargetOptions.VivadoMem:
        printHex(mc)
    elif assembler_target == TargetOptions.SystemcArray:
        printInstArray(mc)














# -*- coding: utf-8 -*-
"""
Created on Sun Dec 27 14:33:38 2020

@author: Tong
"""

header = """# Used Vivado Behavior Simulation
# Start Vivado Tcl Shell
# CD to this tcl script folder
# source -notrace simulationChecker.tcl

open_project ../../unnamed01/unnamed01.xpr
launch_simulation

restart
"""

footer = """

close_sim
close_project

puts ":-)  Simulation Successful - Arhictecture Correct (-:"

"""

def clock_tick():
    return """

run 10 ns
puts ""
puts "time += 10 ns"
"""

def show_out_bus(checking=False, expected=0):
    script = """
set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"
"""
    
    if checking:
        script += """if {{$out_bus != {a}}} {{
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting {b}"
    close_sim
    close_project
}}
""".format(a=expected, b=expected)
    
    return script


def show_register(index, checking=False, expected=0):
    script = """
set r_{a} [get_value -radix unsigned /tb/main_cpu_module/register_module/registers({b})]
puts "r_{c}: $r_{d}"
""".format(a=index, b=index, c=index, d=index)
    
    if checking:
        script += """if {{$r_{a} != {b}}} {{
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting {c}"
    close_sim
    close_project
}}
""".format(a=index, b=expected, c=expected)
    
    return script

def show_PC(checking=False, expected=0):
    script = """
set pc [get_value -radix unsigned /tb/main_cpu_module/PC]
puts "pc: $pc"
"""
    
    if checking:
        script += """if {{$pc != {a}}} {{
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting {b}"
    close_sim
    close_project
}}
""".format(a=expected, b=expected)
    
    return script

def JAL_Get_jump_address(x):
    # x = '82220'
    # 1 00 0001 0001 0 001 0000 0
    # 20, 10-1, 11, 19-12 
    xi = int(x, 16)
    #xi = (((xi >> 31) & 0x1) << 19) | (((xi >> 12) & 0xff) << 11) | (((xi >> 20) & 0x1) << 10) | ((xi >> 21) & 0x3ff)
    xi = (((xi >> 19) & 0x1) << 19) | ((xi & 0xff) << 11) | (((xi >> 8) & 0x1) << 10) | ((xi >> 9) & 0x3ff)
    xi = (0xffe00000 if ((xi >> 19) & 0x1) > 0 else 0) | (xi << 1)
    # xh = hex(xi)
    return xi


options = 'a'
output_script = ''

# LUI x1, 0x1234A
# LUI x1, 0x1234A
# JAL x1, 0x00008
# JAL x1, 0x00008
# JAL x1, -4
# AUIPC x1, 0x22222

if options == 'a':
    output_script = header
    
    pc = 4; # inital nop skipped
    for i in range(30):
        output_script += clock_tick()
        output_script += show_out_bus(False, 10)
        
        if i == 8:
            output_script += show_register(1, True, int('1234a000', 16))
            pc += 4;
        elif i == 12:
            ja = JAL_Get_jump_address('00800')
            output_script += show_register(1, True, pc + 4)
            output_script += show_PC(True, (ja + pc) & 0xffffffff)
            pc = (ja + pc) & 0xffffffff
            print(ja)
        elif i == 16:
            ja = JAL_Get_jump_address('ffdff')
            output_script += show_register(1, True, pc + 4)
            output_script += show_PC(True, (ja + pc) & 0xffffffff)
            pc = (ja + pc) & 0xffffffff
            print(ja)
        elif i == 20:
            ja = JAL_Get_jump_address('00800')
            output_script += show_register(1, True, pc + 4)
            output_script += show_PC(True, (ja + pc) & 0xffffffff)
            pc = (ja + pc) & 0xffffffff
            print(ja)
        elif i == 24:
            output_script += show_register(1, True, pc + int('22222000', 16))
            output_script += show_PC(True, pc + 4)
            pc += 4
        else:
            output_script += show_register(1)
    
    
    
    
    
    output_script += footer
else:
    output_script = header+footer




#%%
file = open('simulationChecker_auto.tcl', 'w')
file.write(output_script)
file.close()


#%%

# x = '82220'
# # 1 00 0001 0001 0 001 0000 0
# # 20, 10-1, 11, 19-12 
# xi = int(x, 16)
# #xi = (((xi >> 31) & 0x1) << 19) | (((xi >> 12) & 0xff) << 11) | (((xi >> 20) & 0x1) << 10) | ((xi >> 21) & 0x3ff)
# xi = (((xi >> 19) & 0x1) << 19) | ((xi & 0xff) << 11) | (((xi >> 8) & 0x1) << 10) | ((xi >> 9) & 0x3ff)
# xi = (0xffe00000 if ((xi >> 19) & 0x1) > 0 else 0) | (xi << 1)
# xh = hex(xi)


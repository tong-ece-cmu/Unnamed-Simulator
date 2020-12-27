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


options = 'a'
output_script = ''

if options == 'a':
    output_script = header
    
    
    for i in range(10):
        output_script += clock_tick()
        output_script += show_out_bus(False, 10)
        
        if i == 6:
            output_script += show_register(1, True, int('1234a000', 16))
        else:
            output_script += show_register(1)
    
    
    
    
    
    output_script += footer
else:
    output_script = header+footer




#%%
file = open('simulationChecker_auto.tcl', 'w')
file.write(output_script)
file.close()














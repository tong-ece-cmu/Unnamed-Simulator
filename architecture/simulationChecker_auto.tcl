# Used Vivado Behavior Simulation
# Start Vivado Tcl Shell
# CD to this tcl script folder
# source -notrace simulationChecker.tcl

open_project ../../unnamed01/unnamed01.xpr
launch_simulation

restart


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"
if {$r_1 != 305438720} {
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting 305438720"
    close_sim
    close_project
}


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"
if {$r_1 != 12} {
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting 12"
    close_sim
    close_project
}

set pc [get_value -radix unsigned /tb/main_cpu_module/PC]
puts "pc: $pc"
if {$pc != 16} {
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting 16"
    close_sim
    close_project
}


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"
if {$r_1 != 20} {
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting 20"
    close_sim
    close_project
}

set pc [get_value -radix unsigned /tb/main_cpu_module/PC]
puts "pc: $pc"
if {$pc != 12} {
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting 12"
    close_sim
    close_project
}


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"
if {$r_1 != 16} {
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting 16"
    close_sim
    close_project
}

set pc [get_value -radix unsigned /tb/main_cpu_module/PC]
puts "pc: $pc"
if {$pc != 20} {
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting 20"
    close_sim
    close_project
}


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"
if {$r_1 != 572661780} {
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting 572661780"
    close_sim
    close_project
}

set pc [get_value -radix unsigned /tb/main_cpu_module/PC]
puts "pc: $pc"
if {$pc != 24} {
    puts "xxxxxxxxxxxx failed xxxxxxxxxxxx"
    puts "expecting 24"
    close_sim
    close_project
}


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns
puts ""
puts "time += 10 ns"

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


close_sim
close_project

puts ":-)  Simulation Successful - Arhictecture Correct (-:"


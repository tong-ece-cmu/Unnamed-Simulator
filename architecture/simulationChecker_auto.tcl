# Used Vivado Behavior Simulation
# Start Vivado Tcl Shell
# CD to this tcl script folder
# source -notrace simulationChecker.tcl

open_project ../../unnamed01/unnamed01.xpr
launch_simulation

restart


run 10 ns

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns

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

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


run 10 ns

set out_bus [get_value -radix unsigned /tb/out_bus]
puts "out_bus: $out_bus"

set r_1 [get_value -radix unsigned /tb/main_cpu_module/register_module/registers(1)]
puts "r_1: $r_1"


close_sim
close_project

puts ":-)  Simulation Successful - Arhictecture Correct (-:"


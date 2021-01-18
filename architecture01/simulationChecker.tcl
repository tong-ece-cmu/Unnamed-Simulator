# Used Vivado Behavior Simulation
# Start Vivado Tcl Shell
# CD to this tcl script folder
# source -notrace simulationChecker.tcl

open_project ../../unnamed01/unnamed01.xpr
launch_simulation

restart

run 10 ns
set wr_data [get_value -radix unsigned /tb/wr_data]
puts "wr_data: $wr_data"
if {$wr_data == 6} {puts "is 2"} else {puts "is not 2"}


run 10 ns
set wr_data [get_value -radix unsigned /tb/wr_data]
puts "wr_data: $wr_data"
if {$wr_data == 6} {puts "is 2"} else {puts "is not 2"}


run 10 ns
set wr_data [get_value -radix unsigned /tb/wr_data]
puts "wr_data: $wr_data"
if {$wr_data == 92} {puts "is 2"} else {puts "is not 2"}


run 10 ns
set wr_data [get_value -radix unsigned /tb/wr_data]
puts "wr_data: $wr_data"
if {$wr_data == 92} {puts "is 2"} else {puts "is not 2"}


run 10 ns
set wr_data [get_value -radix unsigned /tb/wr_data]
puts "wr_data: $wr_data"
if {$wr_data == 6} {puts "is 2"} else {puts "is not 2"}


run 10 ns
set wr_data [get_value -radix unsigned /tb/wr_data]
puts "wr_data: $wr_data"
if {$wr_data == 6} {puts "is 2"} else {puts "is not 2"}


run 10 ns
set wr_data [get_value -radix unsigned /tb/wr_data]
puts "wr_data: $wr_data"
if {$wr_data == 6} {puts "is 2"} else {puts "is not 2"}

close_sim
close_project
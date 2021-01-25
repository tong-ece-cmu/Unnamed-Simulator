project compileall
vsim work.main +ss=1
restart -force
run -all
set a 20 ;
if { $a < 10 } {
    puts "heelo"
} else {
    puts "eeeee"
}
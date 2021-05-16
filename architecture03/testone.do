# to run this file in ModelSim issue this command in Transcript: do testone.do
#TEST_INST1
#TEST_BRANCH_STALL_01
project compileall
#vsim work.main_tb +TEST_BRANCH_STALL_TAKEN=1
vsim work.main_tb +TEST_LOAD_STORE=1
restart -force
run -all

# write transcript barlog.txt, it will be in the same folder as system verillog file
write transcript barlog.txt
project compileall
vsim work.main_tb +TEST_LOAD_STORE=1
restart -force
run -all

vsim work.main_tb +TEST_INST1=1
restart -force
run -all

vsim work.main_tb +TEST_RAW_HANDLING2=1
restart -force
run -all

vsim work.main_tb +TEST_RAW_HANDLING3=1
restart -force
run -all

vsim work.main_tb +TEST_RAW_HANDLING4=1
restart -force
run -all

vsim work.main_tb +TEST_RAW_HANDLING_RS2=1
restart -force
run -all

vsim work.main_tb +TEST_BRANCH_STALL_01=1
restart -force
run -all

vsim work.main_tb +TEST_BRANCH_STALL_TAKEN=1
restart -force
run -all



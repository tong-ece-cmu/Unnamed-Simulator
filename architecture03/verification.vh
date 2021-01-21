`define SIMULATION_FINISH_TIME 600

`define TEST_LOAD_STORE 1
//`define TEST_INST1 1
//`define TEST_RAW_HANDLING2 1
//`define TEST_RAW_HANDLING3 1
//`define TEST_RAW_HANDLING4 1
//`define TEST_RAW_HANDLING_RS2 1
//`define TEST_BRANCH_STALL 1
//`define TEST_BRANCH_STALL_TAKEN 1

`define assert(cond) \
if (cond)\
    $display("Test Passed");\
else\
    $error("Test Failed");

`ifdef TEST_LOAD_STORE

    `define INSTRUCTION_MEMORY_SETTING \
    $readmemh("LoadStore.mem", imem); // Register 2 <- 0x40 and Mem 0 <- 0x20
    
    `define REGISTER_FILE_CHECK \
    $display("check LOAD_STORE");\
    `assert(registers[2] == 32'h40)
    
    `define PASS_CONDITION (registers[2] == 32'h40)

`elsif TEST_INST1
    `define INSTRUCTION_MEMORY_SETTING \
    $readmemh("inst1.mem", imem); // Register 2 should contain 0x40    
    `define REGISTER_FILE_CHECK \
    $display("check INST1");\
    `assert(registers[2] == 32'h40)
    `define PASS_CONDITION (registers[2] == 32'h40)
    
`elsif TEST_RAW_HANDLING2 
    `define INSTRUCTION_MEMORY_SETTING \
    $readmemh("RAWhandling2.mem", imem); // Register 2 should contain 0x40
    `define REGISTER_FILE_CHECK \
    $display("check RAW HANDLING 2");\
    `assert(registers[2] == 32'h40)
    `define PASS_CONDITION (registers[2] == 32'h40)
    
`elsif TEST_RAW_HANDLING3 
    `define INSTRUCTION_MEMORY_SETTING \
    $readmemh("RAWhandling3.mem", imem); // Register 2 should contain 0x40
    `define REGISTER_FILE_CHECK \
    $display("check RAW HANDLING 3");\
    `assert(registers[2] == 32'h40)
    `define PASS_CONDITION (registers[2] == 32'h40)
    
`elsif TEST_RAW_HANDLING4 
    `define INSTRUCTION_MEMORY_SETTING \
    $readmemh("RAWhandling4.mem", imem); // Register 2 should contain 0x40
    `define REGISTER_FILE_CHECK \
    $display("check RAW HANDLING 4");\
    `assert(registers[2] == 32'h40)
    `define PASS_CONDITION (registers[2] == 32'h40)
    
`elsif TEST_RAW_HANDLING_RS2 
    `define INSTRUCTION_MEMORY_SETTING \
    $readmemh("RAWhandlingRS2.mem", imem); // Register 2 should contain 0x40
    `define REGISTER_FILE_CHECK \
    $display("check RAW HANDLING RS2");\
    `assert(registers[2] == 32'h40)
    `define PASS_CONDITION (registers[2] == 32'h40)
    
`elsif TEST_BRANCH_STALL 
    `define INSTRUCTION_MEMORY_SETTING \
    $readmemh("BranchStall.mem", imem); // Register 2 <- 0x03
    `define REGISTER_FILE_CHECK \
    $display("check BRANCH STALL");\
    `assert(registers[2] == 32'h03)
    `define PASS_CONDITION (registers[2] == 32'h3)
    
`elsif TEST_BRANCH_STALL_TAKEN 
    `define INSTRUCTION_MEMORY_SETTING \
    $readmemh("BranchStallTaken.mem", imem); // Register 1 <- 0x06
    `define REGISTER_FILE_CHECK \
    $display("check BRANCH STALL TAKEN");\
    `assert(registers[1] == 32'h06)
    `define PASS_CONDITION (registers[2] == 32'h06)
    
`else
    `define INSTRUCTION_MEMORY_SETTING $display("Memory Setting None");
    
    `define REGISTER_FILE_CHECK $display("check None");
    
    `define PASS_CONDITION (1)

`endif


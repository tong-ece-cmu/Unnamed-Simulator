`define SIMULATION_FINISH_TIME 600

`define TEST_LOAD_STORE 1
//`define TEST_INST1 1
//`define TEST_RAW_HANDLING2 1
//`define TEST_RAW_HANDLING3 1
//`define TEST_RAW_HANDLING4 1
//`define TEST_RAW_HANDLING_RS2 1
//`define TEST_BRANCH_STALL 1
//`define TEST_BRANCH_STALL_TAKEN 1

`ifdef TEST_LOAD_STORE
    // Register 2 <- 0x40 and Mem 0 <- 0x20
    `define INSTRUCTION_MEMORY_SETTING $readmemh("LoadStore.mem", imem); 
    `define REGISTER_FILE_CHECK \
    assert(registers[2] == 32'h40) $display("LOAD_STORE Passed");\
    else $display("LOAD_STORE Failed");
    
    `define PASS_CONDITION (registers[2] == 32'h40)

`elsif TEST_INST1
    // Register 2 should contain 0x40  
    `define INSTRUCTION_MEMORY_SETTING $readmemh("inst1.mem", imem);   
    `define REGISTER_FILE_CHECK \
    assert(registers[2] == 32'h40) $display("INST1 Passed");\
    else $display("INST1 Failed");
    `define PASS_CONDITION (registers[2] == 32'h40)
    
`elsif TEST_RAW_HANDLING2 
    // Register 2 should contain 0x40
    `define INSTRUCTION_MEMORY_SETTING $readmemh("RAWhandling2.mem", imem); 
    `define REGISTER_FILE_CHECK \
    assert(registers[2] == 32'h40) $display("RAW HANDLING 2 Passed");\
    else $display("RAW HANDLING 2 Failed");
    `define PASS_CONDITION (registers[2] == 32'h40)
    
`elsif TEST_RAW_HANDLING3 
    // Register 2 should contain 0x40
    `define INSTRUCTION_MEMORY_SETTING $readmemh("RAWhandling3.mem", imem); 
    `define REGISTER_FILE_CHECK \
    assert(registers[2] == 32'h40) $display("RAW HANDLING 3 Passed");\
    else $display("RAW HANDLING 3 Failed");
    `define PASS_CONDITION (registers[2] == 32'h40)
    
`elsif TEST_RAW_HANDLING4 
    // Register 2 should contain 0x40
    `define INSTRUCTION_MEMORY_SETTING $readmemh("RAWhandling4.mem", imem); 
    `define REGISTER_FILE_CHECK \
    assert(registers[2] == 32'h40) $display("RAW HANDLING 4 Passed");\
    else $display("RAW HANDLING 4 Failed");
    `define PASS_CONDITION (registers[2] == 32'h40)
    
`elsif TEST_RAW_HANDLING_RS2 
    // Register 2 should contain 0x40
    `define INSTRUCTION_MEMORY_SETTING $readmemh("RAWhandlingRS2.mem", imem); 
    `define REGISTER_FILE_CHECK \
    assert(registers[2] == 32'h40) $display("RAW HANDLING RS2 Passed");\
    else $display("RAW HANDLING RS2 Failed");
    `define PASS_CONDITION (registers[2] == 32'h40)
    
`elsif TEST_BRANCH_STALL 
    // Register 2 <- 0x03
    `define INSTRUCTION_MEMORY_SETTING $readmemh("BranchStall.mem", imem); 
    `define REGISTER_FILE_CHECK \
    assert(registers[2] == 32'h03) $display("BRANCH STALL Passed");\
    else $display("BRANCH STALL Failed");
    `define PASS_CONDITION (registers[2] == 32'h3)
    
`elsif TEST_BRANCH_STALL_TAKEN 
    // Register 1 <- 0x06
    `define INSTRUCTION_MEMORY_SETTING $readmemh("BranchStallTaken.mem", imem); 
    `define REGISTER_FILE_CHECK \
    assert(registers[1] == 32'h06) $display("BRANCH STALL TAKEN Passed");\
    else $display("BRANCH STALL TAKEN Failed");
    `define PASS_CONDITION (registers[2] == 32'h06)
    
`else
    `define INSTRUCTION_MEMORY_SETTING $display("No Program for Instruction Memory Specified");
    
    `define REGISTER_FILE_CHECK $display("No Register File Check Specified");
    
    `define PASS_CONDITION (1)

`endif


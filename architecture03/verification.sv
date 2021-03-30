`timescale 1ns / 1ps

`define SIMULATION_FINISH_TIME 600

module counttter #(
string NAME = "blass"
)();


initial begin
    $display("%s", NAME);
end

endmodule

module main_tb();
    reg clk, rst;
    always #5 clk = ~clk;  // Create clock with period=10
    
    main main_module(.*);
    counttter cc();

    bind RegisterFile RegisterFile_verification assert_bind_ip_instance(.*);
    
    initial
    begin
        clk <= 0;
        rst <= 1;
        #10 rst <= 0;

        #`SIMULATION_FINISH_TIME $stop;            // $finish to Quit the simulation

    end

endmodule


module RegisterFile_verification(
input clk,
input [31:0] registers[31:0] // from register file
);


reg[15:0] clk_counter;
reg is_finished;
always #10 begin
    clk_counter <= clk_counter + 1; 
    if (registers[2] == 32'h40 && !is_finished) begin
        $display("cycle count %d", clk_counter);
        is_finished <= 1;
    end
end

initial begin
    is_finished = 0;
    clk_counter = 0;
    
    
    
    #`SIMULATION_FINISH_TIME;
    //`REGISTER_FILE_CHECK
    
    if($test$plusargs("TEST_LOAD_STORE")) begin
        assert(registers[2] == 32'h40) $display("LOAD_STORE Passed");
        else $display("LOAD_STORE Failed");
    end
    else if($test$plusargs("TEST_INST1")) begin
        assert(registers[2] == 32'h40) $display("INST1 Passed");
        else $display("INST1 Failed");
    end
    else if($test$plusargs("TEST_RAW_HANDLING2")) begin
        assert(registers[2] == 32'h40) $display("RAW HANDLING 2 Passed");
        else $display("RAW HANDLING 2 Failed");
    end
    else if($test$plusargs("TEST_RAW_HANDLING3")) begin
        assert(registers[2] == 32'h40) $display("RAW HANDLING 3 Passed");
        else $display("RAW HANDLING 3 Failed");
    end
    else if($test$plusargs("TEST_RAW_HANDLING4")) begin
        assert(registers[2] == 32'h40) $display("RAW HANDLING 4 Passed");
        else $display("RAW HANDLING 4 Failed");
    end
    else if($test$plusargs("TEST_RAW_HANDLING_RS2")) begin
        assert(registers[2] == 32'h40) $display("RAW HANDLING RS2 Passed");
        else $display("RAW HANDLING RS2 Failed");
    end
    else if($test$plusargs("TEST_BRANCH_STALL_01")) begin
        assert(registers[1] == 32'h03) $display("BRANCH STALL 01 Passed");
        else $display("BRANCH STALL 01 Failed");
    end
    else if($test$plusargs("TEST_BRANCH_STALL_TAKEN")) begin
        assert(registers[2] == 32'h06) $display("BRANCH STALL TAKEN Passed");
        else $display("BRANCH STALL TAKEN Failed");
    end
    else
        $display("No Test Performed.");

end

endmodule


module InstructionMemory #(
parameter DATA_WIDTH = 8, 
parameter DEPTH = 256
)(
input clk,
input [31:0] PC,
output [31:0] inst
);

reg [DATA_WIDTH-1:0] imem [DEPTH-1:0];

assign inst = {imem[PC+3], imem[PC+2], imem[PC+1], imem[PC]};


integer i = 0;
initial begin
    
    // Initialize every instruction to NOP
    for (i=0; i<DEPTH; i=i+4) begin
        
        imem[i+0] = 8'h13; 
        imem[i+1] = 8'h00;
        imem[i+2] = 8'h00;
        imem[i+3] = 8'h00;
        
    end
    
    // Load test instructions

    if($test$plusargs("TEST_LOAD_STORE"))
        $readmemh("LoadStore.mem", imem); 
    else if($test$plusargs("TEST_INST1"))
        $readmemh("inst1.mem", imem); 
    else if($test$plusargs("TEST_RAW_HANDLING2"))
        $readmemh("RAWhandling2.mem", imem); 
    else if($test$plusargs("TEST_RAW_HANDLING3"))
        $readmemh("RAWhandling3.mem", imem); 
    else if($test$plusargs("TEST_RAW_HANDLING4"))
        $readmemh("RAWhandling4.mem", imem); 
    else if($test$plusargs("TEST_RAW_HANDLING_RS2"))
        $readmemh("RAWhandlingRS2.mem", imem); 
    else if($test$plusargs("TEST_BRANCH_STALL_01"))
        $readmemh("BranchStall.mem", imem); 
    else if($test$plusargs("TEST_BRANCH_STALL_TAKEN"))
        $readmemh("BranchStallTaken.mem", imem); 

end


endmodule : InstructionMemory


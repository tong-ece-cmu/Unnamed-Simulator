`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/18/2021 04:37:52 PM
// Design Name: 
// Module Name: memory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Data_Memory (
input clk,
input rst,
input [31:0] mem_inst,
input [31:0] exe_result, mem_addr,
output reg [31:0] mem_result,
output reg [31:0] write_back_inst,
output freeze_cpu
);

reg [31:0] dmem [63:0];
logic [31:0] write_back_inst_next;
logic [31:0] mem_result_next;
wire is_load_store;
reg [7:0] delay_counter;
logic [7:0] delay_counter_next;
wire [2:0] funct3 = mem_inst[14:12];

assign is_load_store = mem_inst[6:0] == 7'b0000011 || mem_inst[6:0] == 7'b0100011;
assign freeze_cpu = is_load_store && delay_counter != 4;

logic [31:0] mem_write_next;
always_comb begin
    if (delay_counter == 4 && mem_inst[6:0] == 7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
    begin
        if (funct3 == 3'b000) // SB (Store Byte)
	    begin
	        mem_write_next = {24'b0, exe_result[7:0]};
	    end
	    else if (funct3 == 3'b001) // SH (Store Half Word)
	    begin
	        mem_write_next = {16'b0, exe_result[15:0]};
	    end
	    else if (funct3 == 3'b010) // SW (Store Word)
	    begin
	        mem_write_next = exe_result;
	    end
    end
    else
        mem_write_next = dmem[mem_addr];
end

always_comb begin
    if (rst) begin
        delay_counter_next = 0;
        mem_result_next = exe_result;
    end
    else if (delay_counter == 0) begin
        if (is_load_store) begin
            delay_counter_next = 1;
            mem_result_next = mem_result;
        end
        else begin
            delay_counter_next = 0;
            mem_result_next = exe_result;
        end
    end
    else if (delay_counter > 0 && delay_counter < 4) begin
        delay_counter_next = delay_counter + 1;
        mem_result_next = mem_result;
    end
    else if (delay_counter == 4) begin
         delay_counter_next = 0;
         if (mem_inst[6:0] == 7'b0000011) // LOAD (Load to Register) Spec. PDF-Page 42 )
         begin
            if (funct3 == 3'b000) // LB (Load Byte)
                mem_result_next <= {{24{dmem[mem_addr][7]}}, dmem[mem_addr][7:0]};
            else if (funct3 == 3'b001) // LH (Load Half Word)
                mem_result_next <= {{16{dmem[mem_addr][15]}}, dmem[mem_addr][15:0]};
            else if (funct3 == 3'b010) // LW (Load Word)
                mem_result_next <= dmem[mem_addr];
            else if (funct3 == 3'b100) // LBU (Load Byte Unsigned)
                mem_result_next <= {24'b0, dmem[mem_addr][7:0]};
            else if (funct3 == 3'b101) // LHU (Load Half Word Unsigned)
                mem_result_next <= {16'b0, dmem[mem_addr][15:0]};
            else
                mem_result_next = dmem[mem_addr]; // error 
         end
         else                               // STORE (Store to Memory) Spec. PDF-Page 42 )
            mem_result_next = exe_result; // exe_result not really needed
    end
    else begin
        delay_counter_next = 0;
        mem_result_next = exe_result;
    end
end

always_comb begin
    if (freeze_cpu)     write_back_inst_next = write_back_inst;
    else                write_back_inst_next = mem_inst;
end

always_ff @(posedge clk) begin
    mem_result <= mem_result_next;
    write_back_inst <= write_back_inst_next;
    delay_counter <= delay_counter_next;
    dmem[mem_addr] <= mem_write_next;
end

endmodule : Data_Memory





module RegisterFile (
input clk,
input [4:0] addr1,
input [4:0] addr2,
input [4:0] addr3,
input rd1,
input rd2,
input wr1,
input [31:0] wr_data,
output reg [31:0] rd_data1,
output reg [31:0] rd_data2
);

reg [31:0] registers[31:0];
logic [31:0] next_rd_data1, next_rd_data2, next_wr_data;

always_comb begin
    if (addr1 == 0)             next_rd_data1 = 0; // read register zero return zero
    else if (addr1 == addr3)    next_rd_data1 = wr_data; // read and write at the same time, return written value
    else                        next_rd_data1 = registers[addr1]; // normal register read
    
    if (addr2 == 0)             next_rd_data2 = 0;
    else if (addr2 == addr3)    next_rd_data2 = wr_data;
    else                        next_rd_data2 = registers[addr1];
    
    if (addr3 == 0)             next_wr_data = 0;
    else                        next_wr_data = wr_data;
end


always_ff @ (posedge clk) begin
    // Single Write Port
	if (wr1) registers[addr3] <= next_wr_data;
	
    // Dual Read Port
    if (rd1) rd_data1 <= next_rd_data1;
    if (rd2) rd_data2 <= next_rd_data2;
	
end


initial begin
    `include "verification.vh"
    #`SIMULATION_FINISH_TIME;
    `sayHi
    `REGISTER_FILE_CHECK
    
end


endmodule : RegisterFile


module InstructionMemory(
input clk,
input [31:0] PC,
output [31:0] inst
);

parameter DATA_WIDTH = 8, DEPTH = 256;
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
//    $readmemh("inst1.mem", imem); // Register 2 should contain 0x40
//    $readmemh("RAWhandling2.mem", imem); // Register 2 should contain 0x40
//    $readmemh("RAWhandling3.mem", imem); // Register 2 should contain 0x40
//    $readmemh("RAWhandling4.mem", imem); // Register 2 should contain 0x40
//    $readmemh("RAWhandlingRS2.mem", imem); // Register 2 should contain 0x40
    $readmemh("LoadStore.mem", imem); // Register 2 <- 0x40 and Mem 0 <- 0x20
//    $readmemh("BranchStall.mem", imem); // Register 2 <- 0x03
//    $readmemh("BranchStallTaken.mem", imem); // Register 1 <- 0x06
    
    
end


endmodule : InstructionMemory

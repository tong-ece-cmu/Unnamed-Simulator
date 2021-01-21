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


module Cache (
input clk,
input rst,
input [31:0] mem_inst,
input [31:0] exe_result, mem_addr,
input dram_ready,
input [31:0] dram_result,
output logic [1:0] dram_signal,
output [31:0] dram_addr,
output [31:0] dram_write_data,
output reg [31:0] mem_result,
output reg [31:0] write_back_inst,
output logic freeze_cpu
);

// 4KiB cache, 4 bytes a word
// 4KiB cache, 4 bytes a word, 1024 word
reg [31:0] data [1023:0];

// 4KiB cache, 32 bytes block size, each block 8 words
// 32 bytes block size, each block 8 words
// 4KiB cache, 128 blocks
// 32 bit address, 5 bit block offset, 7 bit cache index, 20 bit tag
reg [19:0] tags [127:0];
reg [127:0] valid;
logic [127:0] valid_next;
wire is_load_store;
wire [6:0] index_field = mem_addr[11:5];
wire [19:0] tag_field = mem_addr[31:12];
wire [11:0] offset_field = mem_addr[4:0];
logic [31:0] mem_result_next;
logic [31:0] write_back_inst_next;
logic [31:0] cache_data_write_next;
assign dram_addr = mem_addr;
assign dram_write_data = exe_result;
//----

localparam SIG_IDLE = 0, SIG_READ = 1, SIG_WRITE = 2;



assign is_load_store = mem_inst[6:0] == 7'b0000011 || mem_inst[6:0] == 7'b0100011;
wire cache_hit = valid[index_field] && tags[index_field] == tag_field;

always_comb begin
    if (is_load_store && !cache_hit && !freeze_cpu) begin
        if (mem_inst[6:0] == 7'b0000011) // LOAD
            cache_data_write_next = dram_result;
        else
            cache_data_write_next = exe_result;
    end
    else
        cache_data_write_next = data[{index_field, offset_field}];
end

// ------------------------ Freeze CPU and Memory Result ------------------------ 
always_comb begin
    if (is_load_store)
    begin
        if (cache_hit) 
        begin // cache hit
            freeze_cpu = 0; 
            mem_result_next = data[{index_field, offset_field}];
            //cache_data_write_next = data[{index_field, offset_field}];
        end
        else
        begin // cache miss
            if (dram_ready == 0) // DRAM is fetching
            begin
                freeze_cpu = 1;
                mem_result_next = mem_result;
                //cache_data_write_next = data[{index_field, offset_field}];
            end
            else    // DRAM fetch complete
            begin
                freeze_cpu = 0;
                mem_result_next = dram_result;
                //cache_data_write_next = dram_result;
            end
        end
    end
    else
    begin
        freeze_cpu = 0;
        mem_result_next = exe_result;
    end
end


// ------------------------ DRAM signals ------------------------ 
always_comb begin
    if (is_load_store)
    begin
        if (valid[index_field] && tags[index_field] == tag_field) 
        begin
            dram_signal = SIG_IDLE;
        end
        else
            dram_signal = mem_inst[6:0] == 7'b0000011 ? SIG_READ : SIG_WRITE; // LOAD is read
    end
    else
        dram_signal = SIG_IDLE;
end


always_comb begin
    if (rst)
        valid_next = 0;
    else
        valid_next = valid;
end

always_comb begin
    if (freeze_cpu)     write_back_inst_next = write_back_inst;
    else                write_back_inst_next = mem_inst;
end

always_ff @(posedge clk) begin
    valid <= valid_next;
    mem_result <= mem_result_next;
    write_back_inst <= write_back_inst_next;
    data[{index_field, offset_field}] = cache_data_write_next;
end

endmodule : Cache

module DRAM (
input clk,
input rst,
input logic [1:0] dram_signal,
input [31:0] dram_addr,
input [31:0] dram_write_data,
output dram_ready,
output logic [31:0] dram_result
);
localparam SIG_IDLE = 0, SIG_READ = 1, SIG_WRITE = 2;
//parameter LATENCY = 20;
parameter LATENCY = 4;
reg [31:0] dmem [63:0];
reg [7:0] delay_counter;
logic [7:0] delay_counter_next;

wire is_read_write = dram_signal == SIG_READ || dram_signal == SIG_WRITE;
wire dram_busy = is_read_write && delay_counter != LATENCY;
assign dram_ready = !dram_busy;

logic [31:0] dram_write_next;

always_comb begin
    if (delay_counter == LATENCY && dram_signal == SIG_WRITE)
        dram_write_next = dram_write_data;
    else
        dram_write_next = dmem[dram_addr];
end

always_comb begin
    if (delay_counter == LATENCY && dram_signal == SIG_READ)
        dram_result = dmem[dram_addr];
    else
        dram_result = 0;
end

always_comb begin
    if (rst) begin
        delay_counter_next = 0;
    end
    else if (delay_counter == 0) begin
        if (dram_signal == SIG_READ || dram_signal == SIG_WRITE) begin
            delay_counter_next = 1;
        end
        else begin
            delay_counter_next = 0;
        end
    end
    else if (delay_counter > 0 && delay_counter < LATENCY) begin
        delay_counter_next = delay_counter + 1;
    end
    else if (delay_counter == LATENCY) begin
         delay_counter_next = 0;
    end
    else begin
        delay_counter_next = 0;
    end
end

always_ff @(posedge clk) begin
    delay_counter <= delay_counter_next;
    dmem[dram_addr] <= dram_write_next;
end



endmodule : DRAM


module Data_Memory (
input clk,
input rst,
input [31:0] mem_inst,
input [31:0] exe_result, mem_addr,
output reg [31:0] mem_result,
output reg [31:0] write_back_inst,
output freeze_cpu
);
//parameter LATENCY = 20;
parameter LATENCY = 4;
reg [31:0] dmem [63:0];
logic [31:0] write_back_inst_next;
logic [31:0] mem_result_next;
wire is_load_store;
reg [7:0] delay_counter;
logic [7:0] delay_counter_next;
wire [2:0] funct3 = mem_inst[14:12];

assign is_load_store = mem_inst[6:0] == 7'b0000011 || mem_inst[6:0] == 7'b0100011;
assign freeze_cpu = is_load_store && delay_counter != LATENCY;

logic [31:0] mem_write_next;
always_comb begin
    if (delay_counter == LATENCY && mem_inst[6:0] == 7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
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
    else if (delay_counter > 0 && delay_counter < LATENCY) begin
        delay_counter_next = delay_counter + 1;
        mem_result_next = mem_result;
    end
    else if (delay_counter == LATENCY) begin
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

`include "verification.svh"

reg[15:0] clk_counter;
reg is_finished;
always #10 begin
    clk_counter <= clk_counter + 1; 
    if (`PASS_CONDITION && !is_finished) begin
        $display("cycle count %d", clk_counter);
        is_finished <= 1;
    end
end
initial begin
    is_finished = 0;
    clk_counter = 0;
    
    
    
    #`SIMULATION_FINISH_TIME;
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
    `include "verification.svh"
    `INSTRUCTION_MEMORY_SETTING
end


endmodule : InstructionMemory

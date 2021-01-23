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


module Cache #(
parameter DATA_WIDTH = 8
)
(
input clk,
input rst,
input [31:0] mem_inst,
input [31:0] exe_result, mem_addr,
input dram_ready,
input [DATA_WIDTH-1:0] dram_result,
output logic [1:0] dram_signal,
output logic [31:0] dram_addr_rd,
output logic [31:0] dram_addr_wr,
output logic [DATA_WIDTH-1:0] dram_write_data,
output reg [31:0] mem_result,
output reg [31:0] write_back_inst,
output logic freeze_cpu
);

// 4KiB cache, 4 bytes a word
// 4KiB cache, 4 bytes a word, 1024 word
reg [DATA_WIDTH-1:0] data [4095:0];

// 4KiB cache, 32 bytes block size, each block 8 words
// 32 bytes block size, each block 32 bytes
// 4KiB cache, 128 blocks
// 32 bit address, 5 bit block offset, 7 bit cache index, 20 bit tag
reg [19:0] tags [127:0];
logic [19:0] tags_next;
reg valid [127:0];
logic valid_next;
wire is_load_store;
wire [6:0] index_field = mem_addr[11:5];
wire [19:0] tag_field = mem_addr[31:12];
wire [4:0] offset_field = mem_addr[4:0];
logic [31:0] mem_result_next;
logic [31:0] write_back_inst_next;
logic [DATA_WIDTH-1:0] cache_data_write_next;
//assign dram_addr = mem_addr;
//assign dram_write_data = exe_result;
//----
localparam BLOCK_SIZE = 32;
localparam SIG_IDLE = 0, SIG_READ = 1, SIG_WRITE = 2;

reg [7:0] cache_counter;
logic [7:0] cache_counter_next;
//wire [4:0] cache_counter_offset = cache_counter_next - 2;
reg [4:0] block_addr_counter;
logic [4:0] block_addr_counter_next;
logic [11:0] cache_data_addr;

wire is_store = mem_inst[6:0] == 7'b0100011; // STORE (Store to Memory) Spec. PDF-Page 42 )
wire is_load = mem_inst[6:0] == 7'b0000011; // LOAD (Load from Memory) Spec. PDF-Page 42 )

assign is_load_store = is_store || is_load;
wire cache_hit = valid[index_field] && tags[index_field] == tag_field;

/*always_comb begin
    if (is_load_store && !cache_hit && !freeze_cpu) begin
        if (mem_inst[6:0] == 7'b0000011) // LOAD
            cache_data_write_next = dram_result;
        else
            cache_data_write_next = exe_result;
    end
    else
        cache_data_write_next = data[{index_field, offset_field}];
end*/
wire [7:0] r_start = 2 + BLOCK_SIZE;

always_comb begin
    if (rst) begin
        cache_counter_next = 0;
        block_addr_counter_next = 0;
    end
    else if (cache_counter == 0) begin
        if (is_load_store && !cache_hit) begin
            if (valid[index_field]) begin
                cache_counter_next = 1;
                block_addr_counter_next = 0;
            end
            else begin
                cache_counter_next = r_start;
                block_addr_counter_next = 0;
            end
        end
        else begin
            cache_counter_next = 0;
            block_addr_counter_next = 0;
        end
    end
    else if (cache_counter == 1) begin
        if (dram_ready) begin
            cache_counter_next = cache_counter + 1;
            block_addr_counter_next = block_addr_counter + 1;
        end
        else begin
            cache_counter_next = cache_counter;
            block_addr_counter_next = block_addr_counter_next;
        end
    end
    else if (cache_counter >= 2 && cache_counter < 2 + BLOCK_SIZE) begin
        cache_counter_next = cache_counter + 1;
        block_addr_counter_next = block_addr_counter + 1;
    end
    else if (cache_counter == r_start) begin
        if (dram_ready) begin
            cache_counter_next = cache_counter + 1;
            block_addr_counter_next = block_addr_counter + 1; // overflow to zero
        end
        else begin
            cache_counter_next = cache_counter;
            block_addr_counter_next = block_addr_counter; // overflow to zero
        end
    end
    else if (cache_counter >= r_start + 1 && cache_counter < r_start + BLOCK_SIZE) begin
        cache_counter_next = cache_counter + 1;
        block_addr_counter_next = block_addr_counter + 1;
    end
    else if (cache_counter == r_start + BLOCK_SIZE) begin
        cache_counter_next = 0;
        block_addr_counter_next = 0;
    end
    else begin
        cache_counter_next = 0;
        block_addr_counter_next = 0;
    end
end

// ------------------------ DRAM Read(LOAD) ------------------------ 
always_comb begin
    if (cache_counter_next == 0 && is_store) begin
        dram_addr_rd = 0;
        cache_data_write_next = exe_result;
        cache_data_addr = {index_field, offset_field};
    end
    if (cache_counter_next >= r_start + 1 && cache_counter_next < r_start + BLOCK_SIZE) begin
        if (block_addr_counter == offset_field && is_store) begin
            dram_addr_rd = {tag_field, index_field, block_addr_counter};
            cache_data_write_next = exe_result[7:0];
            cache_data_addr = {index_field, block_addr_counter};
        end
        else if (block_addr_counter == offset_field + 1 && is_store) begin
            dram_addr_rd = {tag_field, index_field, block_addr_counter};
            cache_data_write_next = exe_result[15:8];
            cache_data_addr = {index_field, block_addr_counter};
        end
        else if (block_addr_counter == offset_field + 2 && is_store) begin
            dram_addr_rd = {tag_field, index_field, block_addr_counter};
            cache_data_write_next = exe_result[23:16];
            cache_data_addr = {index_field, block_addr_counter};
        end
        else if (block_addr_counter == offset_field + 3 && is_store) begin
            dram_addr_rd = {tag_field, index_field, block_addr_counter};
            cache_data_write_next = exe_result[31:24];
            cache_data_addr = {index_field, block_addr_counter};
        end
        else begin
            dram_addr_rd = {tag_field, index_field, block_addr_counter};
            cache_data_write_next = dram_result;
            cache_data_addr = {index_field, block_addr_counter};
        end
    end
    else begin
        dram_addr_rd = 0;
        cache_data_write_next = data[cache_data_addr];
        cache_data_addr = {index_field, block_addr_counter};
    end
end

// ------------------------ DRAM Write(STORE) ------------------------ 
always_comb begin
    if (cache_counter_next >= 2 && cache_counter_next < 2 + BLOCK_SIZE-1) begin
        dram_addr_wr = {tag_field, index_field, block_addr_counter};
        dram_write_data = data[{index_field, block_addr_counter}];
    end
    else begin
        dram_addr_wr = 0;
        dram_write_data = 0;
    end
end

// ------------------------ DRAM signals ------------------------ 
always_comb begin
    if (cache_counter_next >= 1 && cache_counter_next < 2 + BLOCK_SIZE)
        dram_signal = SIG_WRITE;
    else if (cache_counter_next >= r_start && cache_counter_next < r_start + BLOCK_SIZE)
        dram_signal = SIG_READ;
    else
        dram_signal = SIG_IDLE;
end


// Little Endian
// ------------------------ Memory Result ------------------------ 
always_comb begin
    if (is_load)
        mem_result_next = {data[{index_field, offset_field+3}],
                            data[{index_field, offset_field}+2],
                            data[{index_field, offset_field}+1],
                            data[{index_field, offset_field}+0]};
    else
        mem_result_next = exe_result;
end


// ------------------------ Freeze CPU ------------------------ 
always_comb begin
    if (cache_counter_next == 0)
        freeze_cpu = 0;
    else
        freeze_cpu = 1;
end


always_comb begin
    if (rst) begin
        valid_next = 0;
        tags_next = tags[index_field];
    end
    else if (cache_counter == r_start + BLOCK_SIZE) begin
        valid_next = 1;
        tags_next = tag_field;
    end
    else begin
        valid_next = valid[index_field];
        tags_next = tags[index_field];
    end
end

always_comb begin
    if (freeze_cpu)     write_back_inst_next = write_back_inst;
    else                write_back_inst_next = mem_inst;
end

always_ff @(posedge clk) begin
    valid[index_field] <= valid_next;
    tags[index_field] <= tags_next;
    mem_result <= mem_result_next;
    write_back_inst <= write_back_inst_next;
    data[cache_data_addr] <= cache_data_write_next;
    cache_counter <= cache_counter_next;
    block_addr_counter <= block_addr_counter_next;
end

//integer i;
initial begin
    /*
    // Initialize all valid bit to zero, implement it later
    for (i=0; i<128; i=i+1) begin
        #0 valid[i] <= 0;
        
    end
    */

end

endmodule : Cache








module DRAM #(
parameter DATA_WIDTH=8
)
(
input clk,
input rst,
input logic [1:0] dram_signal,
input [31:0] dram_addr_wr,
input [31:0] dram_addr_rd,
input [DATA_WIDTH-1:0] dram_write_data,
output dram_ready,
output logic [DATA_WIDTH-1:0] dram_result
);
localparam SIG_IDLE = 0, SIG_READ = 1, SIG_WRITE = 2;
localparam BLOCK_SIZE = 32;
//parameter LATENCY = 20;
parameter LATENCY = 4;
reg [DATA_WIDTH-1:0] dmem [63:0];
reg [7:0] delay_counter;
logic [7:0] delay_counter_next;

wire is_read_write = dram_signal == SIG_READ || dram_signal == SIG_WRITE;
wire dram_busy = is_read_write && delay_counter >= 0 && delay_counter < LATENCY;
assign dram_ready = !dram_busy;

logic [DATA_WIDTH-1:0] dram_write_next;

// ------------------------ DRAM write ------------------------ 
always_comb begin
    if (delay_counter == LATENCY && dram_signal == SIG_WRITE)
        dram_write_next = dram_write_data;
    else if (delay_counter > LATENCY && delay_counter < LATENCY + BLOCK_SIZE && dram_signal == SIG_WRITE)
        dram_write_next = dram_write_data;
    else
        dram_write_next = dmem[dram_addr_wr];
end

// ------------------------ DRAM read ------------------------ 
always_comb begin
    if (delay_counter == LATENCY && dram_signal == SIG_READ)
        dram_result = dmem[dram_addr_rd];
    else if (delay_counter > LATENCY && delay_counter < LATENCY + BLOCK_SIZE && dram_signal == SIG_READ)
        dram_result = dmem[dram_addr_rd];
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
         delay_counter_next = delay_counter + 1;
    end
    else if (delay_counter > LATENCY && delay_counter < LATENCY + BLOCK_SIZE) begin
         delay_counter_next = delay_counter + 1;
    end
    else if (delay_counter == LATENCY + BLOCK_SIZE) begin
         delay_counter_next = 0;
    end
    else begin
        delay_counter_next = delay_counter;
    end
end

always_ff @(posedge clk) begin
    delay_counter <= delay_counter_next;
    dmem[dram_addr_wr] <= dram_write_next;
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

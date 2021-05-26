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



module cache_cpu_side #(
    parameter DATA_WIDTH = 8
) (
    input clk,
    input rst,

    input [31:0] mem_inst,
    input [31:0] exe_result, mem_addr,

    output reg [31:0] mem_result,
    output reg [31:0] write_back_inst,
    output logic freeze_cpu,

    // output [6:0] cache_index,
    // input valid_bit,
    // input [19:0] tag_bits,
    input cache_hit,
    output logic is_rd,
    output logic is_wr,
    // output [11:0] addr,
    // output [31:0] wr_data,
    input [31:0] rd_data,


    output reg __valid,
    output reg __is_rd,
    output reg [31:0] __addr,
    input __done


);

// logic valid_next;
// wire is_load_store;
wire [6:0] index_field = mem_addr[11:5];
wire [19:0] tag_field = mem_addr[31:12];
wire [4:0] offset_field = mem_addr[4:0];
// logic [31:0] mem_result_next;
// logic [31:0] write_back_inst_next;
// logic [DATA_WIDTH-1:0] cache_data_write_next;
//assign dram_addr = mem_addr;
//assign dram_write_data = exe_result;
//----
// localparam BLOCK_SIZE = 32;
// localparam SIG_IDLE = 0, SIG_READ = 1, SIG_WRITE = 2;

// reg [7:0] cache_counter;
// logic [7:0] cache_counter_next;
//wire [4:0] cache_counter_offset = cache_counter_next - 2;
// reg [4:0] block_addr_counter;
// logic [4:0] block_addr_counter_next;
// logic [11:0] cache_data_addr;

wire is_store = mem_inst[6:0] == 7'b0100011; // STORE (Store to Memory) Spec. PDF-Page 42 )
wire is_load = mem_inst[6:0] == 7'b0000011; // LOAD (Load from Memory) Spec. PDF-Page 42 )

// assign is_rd = is_load;
// assign is_wr = is_store;
// assign addr = {index_field, offset_field};
// assign wr_data = exe_result;

// assign cache_index = index_field;
// assign is_load_store = is_store || is_load;
// wire cache_hit = valid_bit && tag_bits == tag_field;

reg [7:0] state;

always_comb begin : DoneInOneClockCycleHandler
    if ((is_load || is_store) && !cache_hit) begin
        freeze_cpu = 1;
        is_rd = 0;
        is_wr = 0;
    end
    else begin
        freeze_cpu = 0;
        is_rd = is_load;
        is_wr = is_store;
    end
end

always_ff @( posedge clk ) begin : CPUsideHandler
    write_back_inst <= mem_inst;
    mem_result <= exe_result;
    __valid <= 0;

    if (rst) begin
        // valid <= 0;
        state <= 0;
    end
    else if (state == 0) begin
        if (is_load && cache_hit) begin
            mem_result <= rd_data;
        // mem_result <= { data[{index_field, offset_field}+3],
        //                 data[{index_field, offset_field}+2],
        //                 data[{index_field, offset_field}+1],
        //                 data[{index_field, offset_field}+0]};
        end
        else if (is_store && cache_hit) begin
            mem_result <= 0;
            
            // data[{index_field, offset_field}+3] <= exe_result[31:24];
            // data[{index_field, offset_field}+2] <= exe_result[23:16];
            // data[{index_field, offset_field}+1] <= exe_result[15:8];
            // data[{index_field, offset_field}+0] <= exe_result[7:0];
        end
        else if (is_load && !cache_hit) begin
            __valid <= 1;
            __is_rd <= 1;
            __addr <= mem_addr;
            write_back_inst <= write_back_inst;
            state <= 1;
        end
        else if (is_store && !cache_hit) begin
            __valid <= 1;
            __is_rd <= 0;
            __addr <= mem_addr;
            write_back_inst <= write_back_inst;
            state <= 1;
        end
    end
    else if (state == 1) begin
        if (__done) begin
            state <= 0;
            // valid[index_field] <= 1;
            // tags[index_field] <= tag_field;
        end
        else begin
            __valid <= 1;
        end
    end
    

end


endmodule : cache_cpu_side




module cache_dram_side #(
    parameter DATA_WIDTH = 8
) (
    input clk,
    input rst,

    input __valid,
    input valid_bit,
    input __is_rd,
    input [31:0] __addr,
    output reg __done,

    output _dram_side_is_rd,
    output _dram_side_is_wr,
    output [11:0] _dram_side_addr,
    output [31:0] _dram_side_wr_data,
    input [31:0] _dram_side_rd_data
);
    // reg [DATA_WIDTH-1:0] dmem [63:0];

    // logic [7:0] counter_until_this;
    // logic counter_vld;
    // wire counter_reached;
    // wire [7:0] counter_counter;
    // rdy_vld_counter rdyVldCounter(.*);

    reg [7:0] state;

    always_ff @( posedge clk ) begin : dramCommunicationHandler
        __done <= 0;

        if (rst) begin
            state <= 0;
        end
        else if (state == 0) begin
            if (__valid) begin
                if (valid_bit == 0) begin
                    state <= 1; // missed, and this block is empty

                end
                else begin
                    state <= 20; // missed, and this block is not empty
                end
                __done <= 1;
            end
        end
        else if (state == 1) begin
            
        end
        
    end

endmodule : cache_dram_side


module cache_data (
    input clk,
    input rst,

    input rd1,
    input [11:0] addr1,
    output logic [31:0] rd_data1,
    output logic [19:0] tag1,
    output logic valid1,

    input wr1,
    input [31:0] wr_data1,
    input [19:0] wr_tag1

);

    // 4KiB cache, 4 bytes a word
    // 4KiB cache, 4 bytes a word, 1024 word
    reg [31:0] data [1024:0];
    logic [31:0] data_next_wr1;
    // 4KiB cache, 32 bytes block size, each block 8 words
    // 32 bytes block size, each block 32 bytes
    // 4KiB cache, 128 blocks
    // 32 bit address, 5 bit block offset, 7 bit cache index, 20 bit tag
    reg [19:0] tags [127:0];
    logic [19:0] tags_next_wr1;

    reg [127:0] valid;
    logic valid_next_wr1;

    always_comb begin : readCacheData
        rd_data1 = rd1 ? data[addr1[11:2]] : 0;
        tag1 = (rd1 || wr1) ? tags[addr1[11:5]] : 0;
        valid1 = (rd1 || wr1) ? valid[addr1[11:5]] : 0;

        if (wr1) begin
            data_next_wr1 = wr_data1;
            tags_next_wr1 = wr_tag1;
            valid_next_wr1 = 1;
        end
        else begin
            data_next_wr1 = 0;
            tags_next_wr1 = 0;
            valid_next_wr1 = 0;
        end
    end

    always_ff @( posedge clk ) begin : wrtieCacheData
        if (rst) begin
            valid <= 0;
        end
        else if (wr1) begin
            data[addr1[11:2]] <= data_next_wr1;
            tags[addr1[11:5]] <= tags_next_wr1;
            valid[addr1[11:5]] <= valid_next_wr1;
        end
    end


endmodule : cache_data

module Cache #(
parameter DATA_WIDTH = 8,
parameter BLOCK_SIZE = 32
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



output logic dram_is_rd,
output logic [31:0] dram_op_address, // page address

input dram_rdy,
output logic cache_vld,
output logic [DATA_WIDTH-1:0] dram_store,

output logic cache_rdy,
input dram_vld,
input [DATA_WIDTH-1:0] dram_load,



output reg [31:0] mem_result,
output reg [31:0] write_back_inst,
output logic freeze_cpu
);

// 4KiB cache, 4 bytes a word
// 4KiB cache, 4 bytes a word, 1024 word
// reg [DATA_WIDTH-1:0] data [4095:0];

// 4KiB cache, 32 bytes block size, each block 8 words
// 32 bytes block size, each block 32 bytes
// 4KiB cache, 128 blocks
// 32 bit address, 5 bit block offset, 7 bit cache index, 20 bit tag
// reg [19:0] tags [127:0];
// logic [19:0] tags_next;
// reg [127:0] valid;
// logic valid_next;
// wire is_load_store;
wire [6:0] index_field = mem_addr[11:5];
wire [19:0] tag_field = mem_addr[31:12];
wire [4:0] offset_field = mem_addr[4:0];
logic [31:0] mem_result_next;
logic [31:0] write_back_inst_next;
logic [DATA_WIDTH-1:0] cache_data_write_next;
//assign dram_addr = mem_addr;
//assign dram_write_data = exe_result;
//----
// localparam BLOCK_SIZE = 32;
// localparam SIG_IDLE = 0, SIG_READ = 1, SIG_WRITE = 2;

// reg [7:0] cache_counter;
// logic [7:0] cache_counter_next;
//wire [4:0] cache_counter_offset = cache_counter_next - 2;
// reg [4:0] block_addr_counter;
// logic [4:0] block_addr_counter_next;
// logic [11:0] cache_data_addr;

// wire is_store = mem_inst[6:0] == 7'b0100011; // STORE (Store to Memory) Spec. PDF-Page 42 )
// wire is_load = mem_inst[6:0] == 7'b0000011; // LOAD (Load from Memory) Spec. PDF-Page 42 )



wire __valid, __is_rd, __done;
wire [31:0] __addr;

// wire [6:0] cache_index;
// wire valid_bit;
// wire [19:0] tag_bits;

wire is_rd, is_wr;
// wire [11:0] addr;
// wire [31:0] wr_data;
wire [31:0] rd_data;

// cache data wires

wire rd1 = is_rd;
wire [11:0] addr1 = { index_field, offset_field };
wire [31:0] rd_data1;
wire [19:0] tag1;
wire valid1;

wire wr1 = is_wr;
// wire [11:0] addr_w1 = { index_field, offset_field };
wire [31:0] wr_data1 = exe_result;
wire [19:0] wr_tag1 = tag_field;
// wire wr_valid1 = 1;

assign rd_data = rd_data1;
// assign is_load_store = is_store || is_load;
wire cache_hit = valid1 && tag1 == tag_field;

// assign valid_bit = valid[cache_index];
// assign tag_bits = tags[cache_index];

cache_cpu_side cacheCPUSide (.*);

// cache_dram_side cacheDRAMSide (.*);

cache_data cacheData(.*);

// always_comb begin : cacheDataRead
//     rd_data = 0;
//     if (is_rd) begin
//         rd_data = { data[addr+3],
//                     data[addr+2],
//                     data[addr+1],
//                     data[addr+0] };
//     end
    
// end

// always_ff @( posedge clk ) begin : resetValid
//     if (rst) begin
//         valid <= 0;
//     end

//     if (__valid) begin
//         valid[cache_index] <= 1;
//         tags[cache_index] <= tag_field;
//     end

//     if (is_wr) begin
//         data[addr+3] <= wr_data[31:24];
//         data[addr+2] <= wr_data[23:16];
//         data[addr+1] <= wr_data[15:8];
//         data[addr+0] <= wr_data[7:0];
//     end
// end

// logic [7:0] counter_until_this;
// logic counter_vld;
// wire counter_reached;
// wire [7:0] counter_counter;
// rdy_vld_counter rdyVldCounter(.*);


// reg [7:0] state;
// logic [7:0] next_state;

/*

input logic dram_is_rd,
input [31:0] dram_op_address,

input dram_rdy,
output logic cache_vld,
output logic [DATA_WIDTH-1:0] dram_store,

output cache_rdy,
input dram_vld,
input [DATA_WIDTH-1:0] dram_load,

*/








// always_comb begin : cacheLoadStoreHandling
//     freeze_cpu = 0;
//     valid_next = valid;
//     dram_is_rd = 0;

//     if (rst) begin
//         next_state = 0;
//         valid_next = 0;
//     end
//     else if (state == 0) begin
//         if (is_load_store) begin
//             if (valid[index_field]) begin
//                 if (tags[index_field] == tag_field) begin
//                     // hit
//                 end
//                 else begin
//                     // cache miss, need to write back
//                     freeze_cpu = 1;
//                 end
//             end
//             else begin
//                 // cold miss, no write back
//                 freeze_cpu = 1;

//                 dram_is_rd = 1;
//                 dram_op_address = {tag_field, index_field};

//                 cache_vld = 1;
//                 dram_store = 0;

//                 cache_rdy = 1;
//                 next_state = 1;
// // input dram_vld,
// // input [DATA_WIDTH-1:0] dram_load,
//             end
//         end
//         else begin
//             // not memory op, do nothing
//             mem_result_next = exe_result;
//             write_back_inst_next = mem_inst;
//         end
//     end
//     else if (state == 1) begin
//         if (dram_vld) begin
            
//         end
//     end
//     else if (state == 7) begin
//         if (is_load) begin
//             mem_result_next = { data[{index_field, offset_field}+3],
//                                 data[{index_field, offset_field}+2],
//                                 data[{index_field, offset_field}+1],
//                                 data[{index_field, offset_field}+0]};
//             // counter_until_this = LATENCY - 1;
//             // counter_vld = 1;
//             // next_state = 1;
//         end
//         else if (is_store) begin
//             mem_result_next = 0;
//         end
//         else begin
//             mem_result_next = exe_result;
//         end
//     end
// end

// always_ff @( posedge clk ) begin : cacheSequentialBlock
//     state <= next_state;
//     mem_result <= exe_result;
//     write_back_inst <= mem_inst;
//     valid <= valid_next;
// end








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

/*
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
        valid_next = valid | (1 << index_field);
        tags_next = tag_field;
    end
    else begin
        valid_next = valid;
        tags_next = tags[index_field];
    end
end

always_comb begin
    if (freeze_cpu)     write_back_inst_next = write_back_inst;
    else                write_back_inst_next = mem_inst;
end

always_ff @(posedge clk) begin
    valid <= valid_next;
    tags[index_field] <= tags_next;
    mem_result <= mem_result_next;
    write_back_inst <= write_back_inst_next;
    data[cache_data_addr] <= cache_data_write_next;
    cache_counter <= cache_counter_next;
    block_addr_counter <= block_addr_counter_next;
end
*/

endmodule : Cache


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


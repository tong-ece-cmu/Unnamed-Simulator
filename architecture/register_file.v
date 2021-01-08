`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2021 02:35:35 PM
// Design Name: 
// Module Name: register_file
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

module RegisterFile (clk, addr1, addr2, addr3, rd1, rd2, wr1, wr2, wr_data, rd_data1, rd_data2);
input clk;
input [4:0] addr1;
input [4:0] addr2;
input [4:0] addr3;
input rd1;
input rd2;
input wr1;
input wr2;
input [31:0] wr_data;
output reg [31:0] rd_data1;
output reg [31:0] rd_data2;

reg [31:0] registers[31:0];
wire [31:0] next_rd_data1, next_rd_data2, next_wr_data;

// If reading and writing at the same clock cycle, read the new value
assign next_rd_data1 =  addr1 == 0 ? 32'b0 : 
                        addr1 == addr3 ? wr_data : registers[addr1];
assign next_rd_data2 =  addr2 == 0 ? 32'b0 : 
                        addr2 == addr3 ? wr_data : registers[addr2];
assign next_wr_data = (addr3 != 0) ? wr_data : 32'b0;

always @ (posedge clk)
begin
    // Write
	if (wr1 && wr2)
		registers[addr3] <= next_wr_data;
	
    // Read
    if (rd1)
        rd_data1 <= next_rd_data1;
    if (rd2)
        rd_data2 <= next_rd_data2;
	
end

endmodule


module InstructionMemory(clk, PC, inst);
input clk;
input [31:0] PC;
output [31:0] inst;
parameter DATA_WIDTH = 8, DEPTH = 256;
reg [DATA_WIDTH-1:0] imem [DEPTH-1:0];

assign inst = {imem[PC+3], imem[PC+2], imem[PC+1], imem[PC]};

integer i = 0;
integer j = 0;
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


endmodule


module Cache(clk, rst, rd, wr, addr, data_to_cpu, data_to_cpu_valid);

input clk, rst, rd, wr;
output reg data_to_cpu_valid;
input [31:0] addr;
output reg [31:0] data_to_cpu;

reg [7:0] data [4095:0];
reg [19:0] tag [127:0];
reg valid [127:0];
reg [7:0] data_next;
reg [19:0] tag_next;
reg valid_next;

wire [4:0] block_offset =   addr[4:0];
wire [6:0] block_index =    addr[11:5];
wire [19:0] requested_tag = addr[31:12];

always @ (posedge clk)
begin
    data[{block_index, block_offset}] <= data_next;
    tag[block_index] <= tag_next;
    valid[block_index] <= valid_next;
end


always @ (*)
begin
    /*
    tag[index]
    
    */
//    if (rst)
//    begin
//        next_valid
//    end
    if (tag[block_index] == requested_tag && valid[block_index])
    begin
        // cache hit
        data_to_cpu = data[{block_index, block_offset}];
        data_to_cpu_valid = 1'b1;
    end
    else
    begin
        // cache miss
        
    end

end

endmodule

module Mem_user(clk, rst, wr, wr_data, wr_ready);
input clk, rst;
output wr;
output [31:0] wr_data;
input wr_ready;

parameter BURST_AMOUNT = 8'd8;
assign wr = 1'd1;

reg [31:0] cache_data [15:0];
integer i;
initial begin
    for (i=0; i<16; i=i+1) begin
        cache_data[i] = 32'h13000000 + i;
    end
end

reg [7:0] counter;
reg [7:0] counter_next;
always @ (posedge clk)
begin
    counter <= counter_next;
end

assign wr_data = cache_data[counter];
always @ (*)
begin
    if (rst)
    begin
        counter_next <= 8'd0;
    end
    else if(counter < BURST_AMOUNT)
    begin
        if (wr_ready)
        begin
            counter_next <= counter + 8'd1;
        end
        else
        begin
            counter_next <= counter;
        end
    end
    else
    begin
        counter_next <= 8'd0;
    end
end

endmodule

module Mem(clk, rst, rd, wr, addr, wr_data, mem_ready, rd_data, rd_data_valid);
input clk, rst, rd, wr;
input [31:0] addr, wr_data;
output mem_ready;
output [31:0] rd_data;
output reg rd_data_valid;
reg [31:0] wr_data_next;
reg [31:0] rd_data_next;
reg rd_data_valid_next;

reg saved_wr, saved_rd;
reg saved_wr_next, saved_rd_next;

reg [31:0] mem[63:0];
parameter LATENCY=8'd16;
parameter BURST_AMOUNT = 8'd1;

reg [31:0] mem_op_addr;
reg [31:0] mem_op_addr_next;
reg [7:0] counter;
reg [7:0] counter_next;
assign mem_ready = (counter_next == 8'd0) || counter_next > LATENCY;
assign rd_data = rd_data_next;
always @ (posedge clk)
begin
    counter <= counter_next;
    rd_data_valid <= rd_data_valid_next;
    mem_op_addr <= mem_op_addr_next;
    mem[mem_op_addr] <= wr_data_next;
    saved_rd <= saved_rd_next;
    saved_wr <= saved_wr_next;
end
always @ (*)
begin
    if(rst)
    begin
        counter_next <= 8'd0;
        rd_data_valid_next <= 1'd0;
        rd_data_next <= 32'd0;
        mem_op_addr_next <= 32'd0;
        wr_data_next <= mem[mem_op_addr];
        
        saved_rd_next <= 1'd0;
        saved_wr_next <= 1'd0;
    end
    else if (counter == 8'd0)
    begin
        if (rd || wr)
        begin
            counter_next <= counter + 8'd1;
        end
        else begin
            counter_next <= 8'd0;
        end
        rd_data_valid_next <= 1'd0;
        rd_data_next <= 32'd0;
        mem_op_addr_next <= 32'd0;
        wr_data_next <= mem[mem_op_addr];
        
        saved_rd_next <= rd;
        saved_wr_next <= wr;
    end
    else if (counter > 8'd0 && counter < LATENCY)
    begin
        counter_next <= counter + 8'd1;
        rd_data_valid_next <= 1'd0;
        rd_data_next <= 32'd0;
        mem_op_addr_next <= addr;
        wr_data_next <= mem[mem_op_addr];
        
        saved_rd_next <= saved_rd;
        saved_wr_next <= saved_wr;
    end
    else if (counter == LATENCY)
    begin
        if (counter == LATENCY + BURST_AMOUNT - 8'd1)
        begin
            counter_next <= 8'd0;
        end
        else
        begin
            counter_next <= counter + 8'd1;
        end
        
        if(saved_rd)
        begin
            rd_data_valid_next <= 1'd1;
            rd_data_next <= mem[addr];
        end
        else
        begin
            rd_data_valid_next <= 1'd0;
            rd_data_next <= 32'd0;
        end
        
        if (saved_wr)
        begin
            mem_op_addr_next <= mem_op_addr + 32'd1;
            wr_data_next <= wr_data;
        end
        else
        begin
            mem_op_addr_next <= addr;
            wr_data_next <= mem[mem_op_addr];
        end
        
        saved_rd_next <= saved_rd;
        saved_wr_next <= saved_wr;
    end
    else if (counter > LATENCY && counter < LATENCY + BURST_AMOUNT)
    begin
        counter_next <= counter + 8'd1;
        rd_data_valid_next <= 1'd1;
        rd_data_next <= mem[addr + counter - LATENCY];
        mem_op_addr_next <= mem_op_addr + 32'd1;
        wr_data_next <= wr_data;
        
        saved_rd_next <= saved_rd;
        saved_wr_next <= saved_wr;
    end
    else if (counter == LATENCY + BURST_AMOUNT)
    begin
        counter_next <= 8'd0;
        rd_data_valid_next <= 1'd0;
        rd_data_next <= 32'd0;
        mem_op_addr_next <= 32'd0;
        wr_data_next <= mem[mem_op_addr];
        
        saved_rd_next <= saved_rd;
        saved_wr_next <= saved_wr;
    end
    else
    begin
        counter_next <= 8'd0;
        rd_data_valid_next <= 1'd0;
        rd_data_next <= 32'd0;
        mem_op_addr_next <= 32'd0;
        wr_data_next <= mem[mem_op_addr];
        
        saved_rd_next <= saved_rd;
        saved_wr_next <= saved_wr;
    end
end


endmodule

// Little Endian Memory, LSB is in the smaller address in memory
module Memory (clk, rst, mem_ctrl, funct3, addr, freeze_cpu, mem_wr_data, mem_rd_data, from_mem_ready, to_mem_rd, to_mem_wr, to_mem_wr_data, from_mem_rd_data);
input clk, rst;
input [31:0] addr;
output freeze_cpu;
input [31:0] mem_wr_data;
output reg [31:0] mem_rd_data;
input [6:0] mem_ctrl;
input [2:0] funct3;
input from_mem_ready;
output reg to_mem_rd, to_mem_wr;
output reg [31:0] to_mem_wr_data;
input [31:0] from_mem_rd_data;

reg [6:0] saved_mem_ctrl;
reg [2:0] saved_funct3;
reg [6:0] saved_mem_ctrl_next;
reg [2:0] saved_funct3_next;


reg [7:0] cache_data [4095:0];
reg [19:0] cache_tag [127:0];
reg [127:0] cache_valid;
reg [7:0] data_next;
reg [19:0] tag_next;
reg [127:0]valid_next;

wire [4:0] block_offset =   addr[4:0];
wire [6:0] block_index =    addr[11:5];
wire [19:0] requested_tag = addr[31:12];

always @ (posedge clk)
begin
    cache_valid <= valid_next;
end
always @ (*)
begin
    if (rst)
    begin
        valid_next <= 128'd0;
    end
    else
    begin
        valid_next <= cache_valid;
    end
end
always @ (*)
begin
    if (cache_tag[block_index] == requested_tag && cache_valid[block_index])
    begin
        // cache hit
        mem_rd_data = cache_data[{block_index, block_offset}];
    end
    else
    begin
        // cache miss
        
    end
end

assign freeze_cpu = ~from_mem_ready;
//reg [7:0] mem[63:0];
always @ (posedge clk)
begin
    if (saved_mem_ctrl == 7'b0000011) // LOAD (Load to Register) Spec. PDF-Page 42 )
    begin                
        if (funct3 == 3'b000) // LB (Load Byte)
        begin
            mem_rd_data <= {{24{from_mem_rd_data[7]}}, from_mem_rd_data[7:0]};
        end
        else if (funct3 == 3'b001) // LH (Load Half Word)
        begin
            mem_rd_data <= {{16{from_mem_rd_data[15]}}, from_mem_rd_data[15:0]};
        end
        else if (funct3 == 3'b010) // LW (Load Word)
        begin
            mem_rd_data <= from_mem_rd_data;
        end
        else if (funct3 == 3'b100) // LBU (Load Byte Unsigned)
        begin
            mem_rd_data <= {24'b0, from_mem_rd_data[7:0]};
        end
        else if (funct3 == 3'b101) // LHU (Load Half Word Unsigned)
        begin
            mem_rd_data <= {16'b0, from_mem_rd_data[15:0]};
        end
    end
    else
    begin
        // just pass data along for other instructions
        // They need to write back to register
        mem_rd_data <= mem_wr_data; 
    end
    
    saved_mem_ctrl <= saved_mem_ctrl_next;
    saved_funct3 <= saved_funct3_next;
end

always @ (*)
begin
    if (freeze_cpu)
    begin
        saved_mem_ctrl_next <= saved_mem_ctrl;
        saved_funct3_next <= saved_funct3;
    end
    else
    begin
        saved_mem_ctrl_next <= mem_ctrl;
        saved_funct3_next <= funct3;
    end
end

always @ (*)
begin
    // Write		
    if (mem_ctrl == 7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
    begin
        to_mem_rd <= 1'd0;
        to_mem_wr <= 1'd1;
    end
    // Read
    else if (mem_ctrl == 7'b0000011) // LOAD (Load to Register) Spec. PDF-Page 42 )
    begin
        to_mem_rd <= 1'd1;
        to_mem_wr <= 1'd0;
    end
    else
    begin
        to_mem_rd <= 1'd0;
        to_mem_wr <= 1'd0;
    end
end


always @ (*)
begin
    // Write		
    if (mem_ctrl == 7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
    begin
        if (funct3 == 3'b000) // SB (Store Byte)
        begin
            to_mem_wr_data = mem_wr_data;
        end
        else if (funct3 == 3'b001) // SH (Store Half Word)
        begin
            to_mem_wr_data = mem_wr_data;
        end
        else if (funct3 == 3'b010) // SW (Store Word)
        begin
            to_mem_wr_data = mem_wr_data;
        end
    end
    
end


endmodule












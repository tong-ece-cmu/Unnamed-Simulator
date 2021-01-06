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
//    $readmemh("BranchStallTaken.mem", imem); // Register 2 <- 0x06
    
end


endmodule


// Little Endian Memory, LSB is in the smaller address in memory
module Memory (clk, mem_ctrl, funct3, addr, mem_wr_data, mem_rd_data, wr_data);
input clk;
input [31:0] addr;
input [31:0] mem_wr_data;
input [31:0] wr_data;
output reg [31:0] mem_rd_data;
input [6:0] mem_ctrl;
input [2:0] funct3;

reg [7:0] mem[63:0];

always @ (posedge clk)
begin
    // Write		
    if (mem_ctrl == 7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
    begin
        if (funct3 == 3'b000) // SB (Store Byte)
        begin
            mem[addr] = mem_wr_data[7:0];
        end
        else if (funct3 == 3'b001) // SH (Store Half Word)
        begin
            mem[addr] = mem_wr_data[7:0];
            mem[addr+1] = mem_wr_data[15:8];
        end
        else if (funct3 == 3'b010) // SW (Store Word)
        begin
            mem[addr] = mem_wr_data[7:0];
            mem[addr+1] = mem_wr_data[15:8];
            mem[addr+2] = mem_wr_data[23:16];
            mem[addr+3] = mem_wr_data[31:24];
        end
    end
    
    // Read
    else if (mem_ctrl == 7'b0000011) // LOAD (Load to Register) Spec. PDF-Page 42 )
    begin                
        if (funct3 == 3'b000) // LB (Load Byte)
        begin
            mem_rd_data <= {{24{mem[addr][7]}}, mem[addr][7:0]};
        end
        else if (funct3 == 3'b001) // LH (Load Half Word)
        begin
            mem_rd_data <= {{16{mem[addr+1][7]}}, mem[addr+1][7:0], mem[addr][7:0]};
        end
        else if (funct3 == 3'b010) // LW (Load Word)
        begin
            mem_rd_data <= {mem[addr+3][7:0], mem[addr+2][7:0], mem[addr+1][7:0], mem[addr][7:0]};
        end
        else if (funct3 == 3'b100) // LBU (Load Byte Unsigned)
        begin
            mem_rd_data <= {24'b0, mem[addr][7:0]};
        end
        else if (funct3 == 3'b101) // LHU (Load Half Word Unsigned)
        begin
            mem_rd_data <= {16'b0, mem[addr+1][7:0], mem[addr][7:0]};
        end
    end
    
    else 
    begin
        // just pass data along for other instructions
        // They need to write back to register
        mem_rd_data <= mem_wr_data; 
    
    end
    
end


endmodule












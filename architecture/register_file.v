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

module RegisterFile (clk, addr1, addr2, rd1, rd2, wr1, wr2, wr_data, rd_data1, rd_data2);
input clk;
input [4:0] addr1;
input [4:0] addr2;
input rd1;
input rd2;
input wr1;
input wr2;
input [31:0] wr_data;
output reg [31:0] rd_data1;
output reg [31:0] rd_data2;

reg [31:0] registers[31:0];

always @ (posedge clk)
begin
	if (wr1 && wr2)
		// Write
		registers[addr1] <= wr_data;
	else
	begin
		// Read
		if (rd1)
			rd_data1 <= registers[addr1];
		if (rd2)
			rd_data2 <= registers[addr2];
	end
end

endmodule

// Little Endian Memory, LSB is in the smaller address in memory
module Memory (clk, dp_ctrl, funct3, addr, mem_wr_data, mem_rd_data);
input clk;
input [31:0] addr;
input [31:0] mem_wr_data;
output reg [31:0] mem_rd_data;
input [6:0] dp_ctrl;
input [2:0] funct3;

reg [7:0] mem[63:0];

always @ (posedge clk)
begin
    // Write		
    if (dp_ctrl == 7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
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
    else if (dp_ctrl == 7'b0000011) // LOAD (Load to Register) Spec. PDF-Page 42 )
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
	end


endmodule












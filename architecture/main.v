`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/26/2020 06:10:18 PM
// Design Name: 
// Module Name: main
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


module main(clk, inst, in_bus, out_bus);
input clk;
input [31:0] inst;
input [31:0] in_bus;
output [31:0] out_bus;

wire [31:0] rd_data1, rd_data2, wr_data;
wire [5:0] dp_ctrl;
wire [3:0] addr1, addr2;
wire rd1, rd2, wr1, wr2;

// Instantiation of the modules
Control control_module(.clk(clk), .addr1(addr1), .addr2(addr2), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), .dp_ctrl(dp_ctrl), .inst(inst));
Datapath datapath_module(.clk(clk), .dp_ctrl(dp_ctrl), .wr_data(wr_data), .rd_data1(rd_data1), .rd_data2(rd_data2), .in_bus(in_bus), .out_bus(out_bus));
RegisterFile register_module(.clk(clk), .addr1(addr1), .addr2(addr2), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), .wr_data(wr_data), .rd_data1(rd_data1), .rd_data2(rd_data2));

endmodule

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

module Datapath (clk, dp_ctrl, wr_data, rd_data1, rd_data2, immediate, in_bus, out_bus);
input clk;
input [6:0] dp_ctrl;
output reg [31:0] wr_data;
input [31:0] rd_data1;
input [31:0] rd_data2;
input [19:0] immediate;
input [31:0] in_bus;
output reg [31:0] out_bus;

always @ (posedge clk)
begin
	// Default assignments for more efficient synthesis
	out_bus <= out_bus;
	wr_data <= wr_data;
	
	// Choose which datapath operation based on opcode
	if (dp_ctrl == 7'b0000001)
		// Add
		wr_data <= rd_data1 + rd_data2;
	else if (dp_ctrl == 7'b0010000)
		// Load
		wr_data <= in_bus;
	// TODO: Add cases for remaining instructions
	else if (dp_ctrl == 7'b0000010)
	    // R_SHIFT
	    wr_data <= rd_data1 >> 1;
	else if (dp_ctrl == 7'b0000100)
	    // L_SHIFT
	    wr_data <= rd_data1 << 1;
	else if (dp_ctrl == 7'b0001000)
	    // AND_LSB
	    wr_data <= {32{rd_data1[0]}} & rd_data2;
	else if (dp_ctrl == 7'b0100000)
	    // STORE
	    out_bus <= rd_data1;
	    
	    
	    // -------------------------------------- RISC-V --------------------------------------
	    
	else if (dp_ctrl == 7'b0110111) // LUI (Load Upper Immediate) Spec. PDF-Page 37 )
	    wr_data <= {immediate, 12'b0};
end

endmodule

module Control (clk, addr1, addr2, rd1, rd2, wr1, wr2, dp_ctrl, immediate, inst);
input clk;
input [31:0] inst;
output reg [4:0] addr1;		
output reg [4:0] addr2;
output reg rd1;
output reg rd2;
output reg wr1;
output reg wr2;
output reg [6:0] dp_ctrl;
output reg [19:0] immediate;

reg [1:0] cycle;
reg [31:0] saved_inst;
reg [1:0] state, next_state;
parameter [1:0]s0=2'b00,s1=2'b01,s2=2'b11,s3=2'b10; // Use Gray coding for states for more efficient synthesis

// FSM Control Logic
// Keeps track of which phase we are in (decode, load, datapath, writeback)
always @ (posedge clk)
begin
	if(inst[6:0] == 7'b0000000)
		state = s0;
	else
		state = next_state;
end

// FSM
always @ (posedge clk)
begin
	case (state)

	s0:	// Cycle 1 -- Decode
		begin
			dp_ctrl <= 0;
			wr1 <= 0;
			wr2 <= 0;
			addr1 <= inst[7:4];
			addr2 <= inst[3:0];
			rd1 <= 0;
			rd2 <= 0;
			saved_inst <= inst; // Instruction input may not be valid in future clock cycles. So, we save the instruction in an internal register.
			next_state = s0;
			case (inst[6:0])
				// Set the control signals for the next phase
				7'b0000000: // NOP
					begin
						rd1 <= 0;
						rd2 <= 0;
						next_state = s0;
					end
				7'b0000001: // ANDLSB
					begin
						rd1 <= 1;
						rd2 <= 1;
						next_state = s1;
					end
				7'b0000010: // Add
					begin
						rd1 <= 1;
						rd2 <= 1;
						next_state = s1;
					end
				7'b0000100: // Right shift
					begin
						rd1 <= 1;
						rd2 <= 0;
						next_state = s1;
					end
				7'b0000101: // Left shift
					begin
						rd1 <= 1;
						rd2 <= 0;
						next_state = s1;
					end
				7'b0001000: // Load
					begin
						rd1 <= 0;
						rd2 <= 0;
						addr1 <= inst[11:8];
						next_state = s1;
					end
				7'b0001001: // Store
					begin
						rd1 <= 1;
						rd2 <= 0;
						next_state = s1;
					end
				
				// -------------------------------------- RISC-V --------------------------------------
				
				7'b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37 
					begin
						rd1 <= 0;
						rd2 <= 0;
						next_state = s1;
					end
			endcase
		end

	s1 :	// Cycle 2 -- fetch operands from register file
		begin
			// TODO:: Add control logic
//			dp_ctrl <= 0;
//			wr1 <= 0;
//			wr2 <= 0;
//			addr1 <= inst[7:4];
//			addr2 <= inst[3:0];
//			rd1 <= 0;
//			rd2 <= 0;
//			saved_inst <= inst; // Instruction input may not be valid in future clock cycles. So, we save the instruction in an internal register.
//			next_state = s0;
            dp_ctrl  <= saved_inst[6:0];
			case (saved_inst[6:0])
				// Set the control signals for the next phase
				// NOP should have never reached this state. It should kept at s0
//				4'b0000: // NOP
//					begin
//						rd1 <= 0;
//						rd2 <= 0;
//						next_state = s0;
//					end
				7'b0000001: // ANDLSB
					begin
						dp_ctrl <= 6'b001000;
//						next_state = s2;
					end
				7'b0000010: // Add
					begin
						dp_ctrl <= 6'b000001;
//						next_state = s2;
					end
				7'b0000100: // Right shift
					begin
						dp_ctrl <= 6'b000010;
//						next_state = s2;
					end
				7'b0000101: // Left shift
					begin
						dp_ctrl <= 6'b000100;
//						next_state = s2;
					end
				7'b0001000: // Load
					begin
						dp_ctrl <= 6'b010000;
//						addr1 <= inst[11:8];
//						next_state = s2;
					end
				7'b0001001: // Store
					begin
						dp_ctrl <= 6'b100000;
//						next_state = s2;
					end
				
				// -------------------------------------- RISC-V --------------------------------------
				
				7'b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37 
					begin
						immediate <= saved_inst[31:12];
					end
				
			endcase
			next_state = s2;
		end

	s2 :	// Cycle 3 -- perform datapath operation
		begin
			dp_ctrl <= dp_ctrl; // -------------------------------------- pick up here
			rd1 <= 0;
			rd2 <= 0;
			addr1 <= saved_inst[11:8];
			addr2 <= saved_inst[11:8];
			wr1 <= 0;
			wr2 <= 0;
			case (saved_inst[15:12])
				7'b0000000: // NOP
				begin
					wr1 <= 0;
					wr2 <= 0;
				end
				7'b0000001: // ANDLSB
				begin
					wr1 <= 1;
					wr2 <= 1;
				end
				// TODO: Add cases for remaining instructions
				7'b0000010: // Add
                begin
					wr1 <= 1;
					wr2 <= 1;
                end
				7'b0000100: // Right shift
                begin
					wr1 <= 1;
					wr2 <= 1;
                end
				7'b0000101: // Left shift
                begin
					wr1 <= 1;
					wr2 <= 1;
                end
				7'b0001000: // Load
                begin
					wr1 <= 1;
					wr2 <= 1;
                end
				7'b0001001: // Store
                begin
				    wr1 <= 0;
					wr2 <= 0;		
                end
			endcase
			next_state = s3;
		end

	s3 :	// Cycle 4 -- write back
		begin
			rd1 <= 0;
			rd2 <= 0;
			wr1 <= 0;
			wr2 <= 0;
			next_state = s0;
		end
	endcase
end

endmodule




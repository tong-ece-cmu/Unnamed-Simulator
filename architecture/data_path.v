`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2021 02:34:02 PM
// Design Name: 
// Module Name: data_path
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


module Datapath (clk, dp_ctrl, wr_data, wr_pc, PC, rd_data1, rd_data2, immediate, in_bus, out_bus, funct3, mem_addr);
input clk;
input [6:0] dp_ctrl;
output reg [31:0] wr_data;
output reg [31:0] wr_pc;
input [31:0] PC;
input [31:0] rd_data1;
input [31:0] rd_data2;
input [19:0] immediate;
input [31:0] in_bus;
output reg [31:0] out_bus;
input [2:0] funct3;
output reg [31:0] mem_addr;

always @ (posedge clk)
begin
	// Default assignments for more efficient synthesis
	out_bus <= out_bus;
	wr_data <= wr_data;
	
	// Choose which datapath operation based on opcode
	
	    // -------------------------------------- RISC-V --------------------------------------
	    
	if (dp_ctrl == 7'b0110111) // LUI (Load Upper Immediate) Spec. PDF-Page 37 )
	    wr_data <= {immediate, 12'b0};
	else if (dp_ctrl == 7'b0010111) // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
	begin
	    wr_data <= {immediate, 12'b0} + PC;
	end
	else if (dp_ctrl == 7'b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
	begin
	    wr_data <= 32'd4 + PC;
	    wr_pc <= {{11{immediate[19]}}, immediate, 1'b0} + PC;
	end
	else if (dp_ctrl == 7'b1100111) // JALR (Jump And Link Register) Spec. PDF-Page 39 )
	begin
	    wr_data <= 32'd4 + PC;
	    wr_pc <= {{20{immediate[11]}}, immediate[11:1], 1'b0} + rd_data1; // it needs LSB to be zero
	end
	
	else if (dp_ctrl == 7'b1100011) // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
	begin
	    if (funct3 == 3'b000) // BEQ (Branch Equal)
	    begin
	        if (rd_data1 == rd_data2)
	        begin wr_pc <= {{19{immediate[11]}}, immediate[11:0], 1'b0} + PC; end
	        else
	        begin wr_pc <= PC + 32'd4; end
	    end
	    else if (funct3 == 3'b001) // BNE (Branch Not Equal)
	    begin
	        if (rd_data1 != rd_data2)
	        begin wr_pc <= {{19{immediate[11]}}, immediate[11:0], 1'b0} + PC; end
	        else
	        begin wr_pc <= PC + 32'd4; end
	    end
	    else if (funct3 == 3'b100) // BLT (Branch Less Than)
	    begin
	        if ($signed(rd_data1) < $signed(rd_data2))
	        begin wr_pc <= {{19{immediate[11]}}, immediate[11:0], 1'b0} + PC; end
	        else
	        begin wr_pc <= PC + 32'd4; end
	    end
	    else if (funct3 == 3'b101) // BGT (Branch Greater Than)
	    begin
	        if ($signed(rd_data1) >= $signed(rd_data2))
	        begin wr_pc <= {{19{immediate[11]}}, immediate[11:0], 1'b0} + PC; end
	        else
	        begin wr_pc <= PC + 32'd4; end
	    end
	    else if (funct3 == 3'b110) // BLTU (Branch Less Than Unsigned)
	    begin
	        if (rd_data1 < rd_data2)
	        begin wr_pc <= {{19{immediate[11]}}, immediate[11:0], 1'b0} + PC; end
	        else
	        begin wr_pc <= PC + 32'd4; end
	    end
	    else if (funct3 == 3'b111) // BGTU (Branch Greater Than Unsigned)
	    begin
	        if (rd_data1 >= rd_data2)
	        begin wr_pc <= {{19{immediate[11]}}, immediate[11:0], 1'b0} + PC; end
	        else
	        begin wr_pc <= PC + 32'd4; end
	    end
	end
	
	else if (dp_ctrl == 7'b0000011) // LOAD (Load to Register) Spec. PDF-Page 42 )
	begin
	    mem_addr <= {{20{immediate[11]}}, immediate[11:0]} + rd_data1;
	    
//	    if (funct3 == 3'b000) // LB (Load Byte)
//	    begin
//	        wr_data <= {{24{in_bus[7]}}, in_bus[7:0]};
//	    end
//	    else if (funct3 == 3'b001) // LH (Load Half Word)
//	    begin
//	        wr_data <= {{16{in_bus[15]}}, in_bus[15:0]};
//	    end
//	    else if (funct3 == 3'b010) // LW (Load Word)
//	    begin
//	        wr_data <= in_bus;
//	    end
//	    else if (funct3 == 3'b100) // LBU (Load Byte Unsigned)
//	    begin
//	        wr_data <= {24'b0, in_bus[7:0]};
//	    end
//	    else if (funct3 == 3'b101) // LHU (Load Half Word Unsigned)
//	    begin
//	        wr_data <= {16'b0, in_bus[15:0]};
//	    end
	end
	
	else if (dp_ctrl == 7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
    begin
        mem_addr <= {{20{immediate[11]}}, immediate[11:0]} + rd_data1;
        
//        if (funct3 == 3'b000) // SB (Store Byte)
//	    begin
//	        out_bus <= {24'b0, rd_data2[7:0]};
//	    end
//	    else if (funct3 == 3'b001) // SH (Store Half Word)
//	    begin
//	        out_bus <= {16'b0, rd_data2[15:0]};
//	    end
//	    else if (funct3 == 3'b010) // SW (Store Word)
//	    begin
//	        out_bus <= rd_data2;
//	    end
    end
    
    else if (dp_ctrl == 7'b0010011) // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
    begin
        if (funct3 == 3'b000) // ADDI (Add Immediate)
	    begin
	       wr_data <= rd_data1 + {{20{immediate[11]}}, immediate[11:0]};
	    end
	    else if (funct3 == 3'b010) // SLTI (Set Less Than Immediate)
	    begin
	       wr_data <= $signed(rd_data1) < $signed({{20{immediate[11]}}, immediate[11:0]}) ? 32'b1 : 32'b0;
	    end
	    else if (funct3 == 3'b011) // SLTIU (Set Less Than Immediate Unsigned)
	    begin
	       wr_data <= rd_data1 < {{20{immediate[11]}}, immediate[11:0]} ? 32'b1 : 32'b0;
	    end
	    else if (funct3 == 3'b100) // XORI (XOR Immediate)
	    begin
	       wr_data <= {{20{immediate[11]}}, immediate[11:0]} ^ rd_data1;
	    end
	    else if (funct3 == 3'b110) // ORI (OR Immediate)
	    begin
	       wr_data <= {{20{immediate[11]}}, immediate[11:0]} | rd_data1;
	    end
	    else if (funct3 == 3'b111) // ANDI (AND Immediate)
	    begin
	       wr_data <= {{20{immediate[11]}}, immediate[11:0]} & rd_data1;
	    end
	    else if (funct3 == 3'b001) // SLLI (Shift Left Logic Immediate)
	    begin
	       wr_data <= rd_data1 << immediate[4:0];
	    end
	    else if (funct3 == 3'b101) 
	    begin
	       if (immediate[10] == 0) // SRLI (Shift Right Logic Immediate)
	       begin
	           wr_data <= rd_data1 >> immediate[4:0];
	       end
	       else // SRAI (Shift Right Arithmatic Immediate)
	       begin 
	           wr_data <= $signed(rd_data1) >>> immediate[4:0];
	       end
	    end
    end
    
    else if (dp_ctrl == 7'b0110011) // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
    begin
        if (funct3 == 3'b000) 
	    begin
	       if (immediate[5] == 0) // ADD (Addition)
	       begin
	           wr_data <= rd_data1 + rd_data2;
	       end
	       else // SUB (Subtraction)
	       begin 
	           wr_data <= rd_data1 - rd_data2;
	       end
	    end
	    
	    
	    else if (funct3 == 3'b001) // SLL (Shift Left Logic)
	    begin
	       wr_data <= rd_data1 << rd_data2[4:0];
	    end
	    else if (funct3 == 3'b010) // SLT (Set Less Than)
	    begin
	       wr_data <= $signed(rd_data1) < $signed(rd_data2) ? 32'b1 : 32'b0;
	    end
	    else if (funct3 == 3'b011) // SLTU (Set Less Than Unsigned)
	    begin
	       wr_data <= rd_data1 < rd_data2 ? 32'b1 : 32'b0;
	    end
	    else if (funct3 == 3'b100) // XOR (XOR)
	    begin
	       wr_data <= rd_data1 ^ rd_data2;
	    end
	    
	    
	    else if (funct3 == 3'b101) 
	    begin
	       if (immediate[5] == 0) // SRL (Shift Right Logic)
	       begin
	           wr_data <= rd_data1 >> rd_data2[4:0];
	       end
	       else // SRA (Shift Right Arithmatic)
	       begin 
	           wr_data <= $signed(rd_data1) >>> rd_data2[4:0];
	       end
	    end
	    
	    else if (funct3 == 3'b110) // OR (OR)
	    begin
	       wr_data <= rd_data1 | rd_data2;
	    end
	    else if (funct3 == 3'b111) // AND (AND)
	    begin
	       wr_data <= rd_data1 & rd_data2;
	    end
	    
    end
end

endmodule

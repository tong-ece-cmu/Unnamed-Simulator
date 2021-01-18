`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/18/2021 04:35:32 PM
// Design Name: 
// Module Name: execute
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


module Execute (
input clk,
input [31:0] PC,
input [31:0] exe_inst,
input exe_rs1_forward,
input [31:0] rd_data1,
input [31:0] rd_data2,
output reg [31:0] exe_result,
output reg [31:0] mem_inst

);
logic [31:0] exe_result_next;
wire [31:0] inst = exe_inst;
wire [6:0] opcode = inst[6:0];
wire [2:0] funct3 = inst[14:12];
wire [6:0] funct7 = inst[31:25];
wire [31:0] imm_I = {20'b0, inst[31:20]};
wire [31:0] imm_I_sign_extended = {{20{inst[31]}}, inst[31:20]};
wire [11:0] imm_S = {inst[31:25], inst[11:7]};
wire [12:0] imm_B = {inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
wire [31:0] imm_U = {inst[31:12], 12'b0};
wire [20:0] imm_J = {inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
wire [31:0] PC_next = PC+4;
wire [4:0] shamt = inst[24:20];
wire right_shift_type = inst[30];

wire [31:0] rs1_data = exe_rs1_forward ? exe_result : rd_data1;


always_comb
begin
	if (opcode == 7'b0110111) // LUI (Load Upper Immediate) Spec. PDF-Page 37 )
	    exe_result_next <= imm_U;
	else if (opcode == 7'b0010111) // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
	    exe_result_next <= imm_U + PC;
	else if (opcode == 7'b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
	    exe_result_next <= PC_next;
//	    wr_pc <= {{11{immediate[19]}}, immediate, 1'b0} + PC;
	else if (opcode == 7'b1100111) // JALR (Jump And Link Register) Spec. PDF-Page 39 )
	    exe_result_next <= PC_next;
//	    wr_pc <= {{20{immediate[11]}}, immediate[11:1], 1'b0} + rs1_data; // it needs LSB to be zero
	
	else if (opcode == 7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
        exe_result_next <= rd_data2;
        
    if (opcode == 7'b0010011) // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
    begin
        if (funct3 == 3'b000) // ADDI (Add Immediate)
	       exe_result_next = rs1_data + imm_I_sign_extended;
	    else if (funct3 == 3'b010) // SLTI (Set Less Than Immediate)
	       exe_result_next <= $signed(rs1_data) < $signed(imm_I_sign_extended) ? 32'b1 : 32'b0;
	    else if (funct3 == 3'b011) // SLTIU (Set Less Than Immediate Unsigned)
	       exe_result_next <= rs1_data < imm_I_sign_extended ? 32'b1 : 32'b0;
	    else if (funct3 == 3'b100) // XORI (XOR Immediate)
	       exe_result_next <= imm_I_sign_extended ^ rs1_data;
	    else if (funct3 == 3'b110) // ORI (OR Immediate)
	       exe_result_next <= imm_I_sign_extended | rs1_data;
	    else if (funct3 == 3'b111) // ANDI (AND Immediate)
	       exe_result_next <= imm_I_sign_extended & rs1_data;
	    else if (funct3 == 3'b001) // SLLI (Shift Left Logic Immediate)
	       exe_result_next <= rs1_data << shamt;
	    else if (funct3 == 3'b101) 
	    begin
	       if (right_shift_type == 0) // SRLI (Shift Right Logic Immediate)
	           exe_result_next <= rs1_data >> shamt;
	       else // SRAI (Shift Right Arithmatic Immediate)
	           exe_result_next <= $signed(rs1_data) >>> shamt;
	    end
    end
    
    else if (opcode == 7'b0110011) // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
    begin
        if (funct3 == 3'b000) 
	    begin
	       if (right_shift_type == 0) // ADD (Addition)
	           exe_result_next <= rs1_data + rd_data2;
	       else // SUB (Subtraction)
	           exe_result_next <= rs1_data - rd_data2;
	    end
	    
	    
	    else if (funct3 == 3'b001) // SLL (Shift Left Logic)
	       exe_result_next <= rs1_data << rd_data2[4:0];
	    else if (funct3 == 3'b010) // SLT (Set Less Than)
	       exe_result_next <= $signed(rs1_data) < $signed(rd_data2) ? 32'b1 : 32'b0;
	    else if (funct3 == 3'b011) // SLTU (Set Less Than Unsigned)
	       exe_result_next <= rs1_data < rd_data2 ? 32'b1 : 32'b0;
	    else if (funct3 == 3'b100) // XOR (XOR)
	       exe_result_next <= rs1_data ^ rd_data2;
	    
	    else if (funct3 == 3'b101) 
	    begin
	       if (right_shift_type == 0) // SRL (Shift Right Logic)
	           exe_result_next <= rs1_data >> rd_data2[4:0];
	       else // SRA (Shift Right Arithmatic)
	           exe_result_next <= $signed(rs1_data) >>> rd_data2[4:0];
	    end
	    
	    else if (funct3 == 3'b110) // OR (OR)
	       exe_result_next <= rs1_data | rd_data2;
	    else if (funct3 == 3'b111) // AND (AND)
	       exe_result_next <= rs1_data & rd_data2;	    
    end
end

always_ff @(posedge clk) begin
    
    exe_result <= exe_result_next;
    mem_inst <= exe_inst;
end

endmodule : Execute

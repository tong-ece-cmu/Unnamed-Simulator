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


module main(clk, rst, inst, in_bus, out_bus, mem_addr);
input clk;
input rst;
input [31:0] inst;
input [31:0] in_bus;
output [31:0] out_bus;
output [31:0] mem_addr;

wire [31:0] rd_data1, rd_data2, wr_data, wr_pc, PC;
wire [19:0] immediate;
wire [2:0] funct3;
wire [6:0] dp_ctrl;
wire [4:0] addr1, addr2;
wire rd1, rd2, wr1, wr2;

// Instantiation of the modules
Control control_module(.clk(clk), .rst(rst), .addr1(addr1), .addr2(addr2), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), 
                        .dp_ctrl(dp_ctrl), .immediate(immediate), .inst(inst), .PC(PC), .wr_pc(wr_pc), .funct3(funct3));
                        
Datapath datapath_module(.clk(clk), .dp_ctrl(dp_ctrl), .wr_data(wr_data), .wr_pc(wr_pc), .PC(PC), .rd_data1(rd_data1), .rd_data2(rd_data2), 
                            .immediate(immediate), .in_bus(in_bus), .out_bus(out_bus), .funct3(funct3), .mem_addr(mem_addr));
                            
RegisterFile register_module(.clk(clk), .addr1(addr1), .addr2(addr2), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), .wr_data(wr_data), 
                                .rd_data1(rd_data1), .rd_data2(rd_data2));

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
	if (dp_ctrl == 7'b0000001)
		// Add
		wr_data <= rd_data1 + rd_data2;
	else if (dp_ctrl == 7'b0000010)
	    // R_SHIFT
	    wr_data <= rd_data1 >> 1;
	else if (dp_ctrl == 7'b0000100)
	    // L_SHIFT
	    wr_data <= rd_data1 << 1;
	else if (dp_ctrl == 7'b0001000)
	    // AND_LSB
	    wr_data <= {32{rd_data1[0]}} & rd_data2;
	
	    
	    
	    // -------------------------------------- RISC-V --------------------------------------
	    
	else if (dp_ctrl == 7'b0110111) // LUI (Load Upper Immediate) Spec. PDF-Page 37 )
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
	    
	    if (funct3 == 3'b000) // LB (Load Byte)
	    begin
	        wr_data <= {{24{in_bus[7]}}, in_bus[7:0]};
	    end
	    if (funct3 == 3'b001) // LH (Load Half Word)
	    begin
	        wr_data <= {{16{in_bus[15]}}, in_bus[15:0]};
	    end
	    if (funct3 == 3'b010) // LW (Load Word)
	    begin
	        wr_data <= in_bus;
	    end
	    if (funct3 == 3'b100) // LBU (Load Byte Unsigned)
	    begin
	        wr_data <= {24'b0, in_bus[7:0]};
	    end
	    if (funct3 == 3'b101) // LHU (Load Half Word Unsigned)
	    begin
	        wr_data <= {16'b0, in_bus[15:0]};
	    end
	end
	
	else if (dp_ctrl == 7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
    begin
        mem_addr <= {{20{immediate[11]}}, immediate[11:0]} + rd_data1;
        
        if (funct3 == 3'b000) // SB (Store Byte)
	    begin
	        out_bus <= {24'b0, rd_data2[7:0]};
	    end
	    if (funct3 == 3'b001) // SH (Store Half Word)
	    begin
	        out_bus <= {16'b0, rd_data2[15:0]};
	    end
	    if (funct3 == 3'b010) // SW (Store Word)
	    begin
	        out_bus <= rd_data2;
	    end
    end
end

endmodule

module Control (clk, rst, addr1, addr2, rd1, rd2, wr1, wr2, dp_ctrl, immediate, inst, PC, wr_pc, funct3);
input clk;
input rst;
input [31:0] inst;
output reg [4:0] addr1;		
output reg [4:0] addr2;
output reg rd1;
output reg rd2;
output reg wr1;
output reg wr2;
output reg [6:0] dp_ctrl;
output reg [19:0] immediate;
output reg [31:0] PC;
input [31:0] wr_pc;
output reg [2:0] funct3;

reg [1:0] cycle;
reg [31:0] saved_inst;
reg [1:0] state, next_state;
parameter [1:0]s0=2'b00,s1=2'b01,s2=2'b11,s3=2'b10; // Use Gray coding for states for more efficient synthesis

// FSM
always @ (posedge clk)
begin
    if(rst) begin
        PC <= 32'b0;
        state <= s0;
    end
    else begin
       
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
//                next_state = s0;
                state <= s1;
                case (inst[6:0])
                    // Set the control signals for the next phase
                    7'b0000000: // NOP
                        begin
                            rd1 <= 0;
                            rd2 <= 0;
//                            next_state = s1;
                        end
                    7'b0000001: // ANDLSB
                        begin
                            rd1 <= 1;
                            rd2 <= 1;
//                            next_state = s1;
                        end
                    7'b0000010: // Add
                        begin
                            rd1 <= 1;
                            rd2 <= 1;
//                            next_state = s1;
                        end
                    7'b0000100: // Right shift
                        begin
                            rd1 <= 1;
                            rd2 <= 0;
//                            next_state = s1;
                        end
                    7'b0000101: // Left shift
                        begin
                            rd1 <= 1;
                            rd2 <= 0;
//                            next_state = s1;
                        end
                    
                    
                    // -------------------------------------- RISC-V --------------------------------------
                    
                    7'b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                        begin
                            rd1 <= 0;
                            rd2 <= 0;
//                            next_state = s1;
                        end
                    7'b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                        begin
                            rd1 <= 0;
                            rd2 <= 0;
                        end
                    7'b1101111: // JAL (Jump And Link) Spec. PDF-Page 39 )
                        begin
                            rd1 <= 0;
                            rd2 <= 0;
                        end
                    7'b1100111: // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                        begin
                            rd1 <= 1;
                            rd2 <= 0;
                            addr1 <= inst[19:15];
                        end
                    7'b1100011: // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                        begin
                            rd1 <= 1;
                            rd2 <= 1;
                            addr1 <= inst[19:15];
                            addr2 <= inst[24:20];
                        end
                    7'b0000011: // LOAD (Load to Register) Spec. PDF-Page 42 )
                        begin
                            rd1 <= 1;
                            rd2 <= 0;
                            addr1 <= inst[19:15];
                        end
                    7'b0100011: // STORE (Store to Memory) Spec. PDF-Page 42 )
                        begin
                            rd1 <= 1;
                            rd2 <= 1;
                            addr1 <= inst[19:15];
                            addr2 <= inst[24:20];
                        end
                endcase
            end
    
        s1 :	// Cycle 2 -- fetch operands from register file
            begin
                
                dp_ctrl  <= saved_inst[6:0];
                state <= s2;
                case (saved_inst[6:0])
                    // Set the control signals for the next phase
                    7'b0000000: // NOP
                        begin
                            dp_ctrl <= 6'b000000;
                        end
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
                    
                    
                    // -------------------------------------- RISC-V --------------------------------------
                    
                    7'b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                        begin
                            immediate <= saved_inst[31:12];
                        end
                    7'b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                        begin
                            immediate <= saved_inst[31:12];
                        end
                    7'b1101111: // JAL (Jump And Link) Spec. PDF-Page 39 )
                        begin
                            immediate <= {saved_inst[31], saved_inst[19:12], saved_inst[20], saved_inst[30:21]};
                        end
                    7'b1100111: // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                        begin
                            immediate <= {8'd0, saved_inst[31:20]};
                        end
                    7'b1100011: // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                        begin
                            immediate <= {8'b0, saved_inst[31], saved_inst[7], saved_inst[30:25], saved_inst[11:8]};
                            funct3 <= saved_inst[14:12];
                        end
                    7'b0000011: // LOAD (Load to Register) Spec. PDF-Page 42 )
                        begin
                            immediate <= {8'd0, saved_inst[31:20]};
                            funct3 <= saved_inst[14:12];
                        end
                    7'b0100011: // STORE (Store to Memory) Spec. PDF-Page 42 )
                        begin
                            immediate <= {8'd0, saved_inst[31:25], saved_inst[11:7]};
                            funct3 <= saved_inst[14:12];
                        end
                    
                endcase
                
            end
    
        s2 :	// Cycle 3 -- perform datapath operation
            begin
                dp_ctrl <= dp_ctrl;
                rd1 <= 0;
                rd2 <= 0;
                addr1 <= saved_inst[11:8];
                addr2 <= saved_inst[11:8];
                wr1 <= 0;
                wr2 <= 0;
                state <= s3;
                case (saved_inst[6:0])
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
                    
                    
                    
                    // -------------------------------------- RISC-V --------------------------------------
                    
                    7'b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                    begin
                        wr1 <= 1;
                        wr2 <= 1;	
                        addr1 <= saved_inst[11:7];
                        addr2 <= saved_inst[11:7];
                    end
                    7'b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                    begin
                        wr1 <= 1;
                        wr2 <= 1;	
                        addr1 <= saved_inst[11:7];
                        addr2 <= saved_inst[11:7];
                    end
                    7'b1101111: // JAL (Jump And Link) Spec. PDF-Page 39 )
                    begin
                        wr1 <= 1;
                        wr2 <= 1;	
                        addr1 <= saved_inst[11:7];
                        addr2 <= saved_inst[11:7];
                    end
                    7'b1100111: // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                    begin
                        wr1 <= 1;
                        wr2 <= 1;
                        addr1 <= saved_inst[11:7];
                        addr2 <= saved_inst[11:7];
                    end
                    7'b1100011: // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                    begin
                        wr1 <= 0;
                        wr2 <= 0;
                    end
                    7'b0000011: // LOAD (Load to Register) Spec. PDF-Page 42 )
                    begin
                        wr1 <= 1;
                        wr2 <= 1;
                        addr1 <= saved_inst[11:7];
                        addr2 <= saved_inst[11:7];
                    end
                    7'b0100011: // STORE (Store to Memory) Spec. PDF-Page 42 )
                    begin
                        wr1 <= 0;
                        wr2 <= 0;
                    end
                    
                endcase
                
            end
    
        s3 :	// Cycle 4 -- write back
            begin
                rd1 <= 0;
                rd2 <= 0;
                wr1 <= 0;
                wr2 <= 0;
                state <= s0;
                case (inst[6:0])
                    // -------------------------------------- RISC-V --------------------------------------
                    
                    7'b1101111: // JAL (Jump And Link) Spec. PDF-Page 39 )
                    begin
                        PC <= wr_pc;
                    end
                    7'b1100111: // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                    begin
                        PC <= wr_pc;
                    end
                    7'b1100011: // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                    begin
                        PC <= wr_pc;
                    end
                    default:
                    begin
                        PC <= PC + 32'd4;
                    end
                endcase
            end
        endcase
	end
end

endmodule




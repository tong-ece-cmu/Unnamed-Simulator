`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/03/2021 02:36:57 PM
// Design Name: 
// Module Name: control
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

reg [31:0] saved_inst;
reg [2:0] state, next_state;
parameter [2:0]s0=3'b000,s1=3'b001,s2=3'b010,s3=3'b011,s4=3'b100;

// FSM
always @ (posedge clk)
begin
    if(rst) begin
        PC <= 32'b0;
        state <= s0;
    end
    else begin
       
        case (state)
    
        s0:	// Cycle 1 -- Decode / Start Reading Register File at Rising Clock edge
            begin
                dp_ctrl <= 0;
                wr1 <= 0;
                wr2 <= 0;
                addr1 <= inst[7:4];
                addr2 <= inst[3:0];
                rd1 <= 0;
                rd2 <= 0;
                saved_inst <= inst; // Instruction input may not be valid in future clock cycles. So, we save the instruction in an internal register.
                state <= s1;
                case (inst[6:0])
                    
                    // -------------------------------------- RISC-V --------------------------------------
                    
                    7'b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                        begin
                            rd1 <= 0;
                            rd2 <= 0;
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
                    7'b0010011: // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                        begin
                            rd1 <= 1;
                            rd2 <= 0;
                            addr1 <= inst[19:15];
                        end
                    7'b0110011: // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                        begin
                            rd1 <= 1;
                            rd2 <= 1;
                            addr1 <= inst[19:15];
                            addr2 <= inst[24:20];
                        end
                endcase
            end
    
        s1 :	// Cycle 2 -- fetch operands from register file completed, clocked in immediate, datapath start propagating
            begin
                
                dp_ctrl  <= saved_inst[6:0];
                state <= s2;
                case (saved_inst[6:0])
                    // Set the control signals for the next phase
                  
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
                    7'b0010011: // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                        begin
                            immediate <= {8'd0, saved_inst[31:20]};
                            funct3 <= saved_inst[14:12];
                        end
                    7'b0110011: // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                        begin
                            immediate <= {13'd0, saved_inst[31:25]};
                            funct3 <= saved_inst[14:12];
                        end
                    
                endcase
                
            end
        
        s2:     // Cycle 3 -- datapath operation completed, if need memory access, start at this rising clock edge. Memory address calculation
                //              completed at the previous clock cycle, in datapath.
            begin
                dp_ctrl  <= saved_inst[6:0];
                funct3 <= saved_inst[14:12];
                state <= s3;
                
            end
        
        s3 :	// Cycle 4 -- write back to register start at this clock edge
            begin
                dp_ctrl <= dp_ctrl;
                rd1 <= 0;
                rd2 <= 0;
                addr1 <= saved_inst[11:8];
                addr2 <= saved_inst[11:8];
                wr1 <= 0;
                wr2 <= 0;
                state <= s4;
                case (saved_inst[6:0])
                    
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
                    7'b0010011: // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                    begin
                        wr1 <= 1;
                        wr2 <= 1;
                        addr1 <= saved_inst[11:7];
                        addr2 <= saved_inst[11:7];
                    end
                    7'b0110011: // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                    begin
                        wr1 <= 1;
                        wr2 <= 1;
                        addr1 <= saved_inst[11:7];
                        addr2 <= saved_inst[11:7];
                    end
                    
                endcase
                
            end
    
        s4 :	// Cycle 5 -- Next Instruction Fetch
            begin
                rd1 <= 0;
                rd2 <= 0;
                wr1 <= 0;
                wr2 <= 0;
                state <= s0;
                case (saved_inst[6:0])
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

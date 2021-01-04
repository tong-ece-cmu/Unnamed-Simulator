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

module ProgramCounter(clk, rst, wr_pc_valid, wr_pc, PC);
input clk;
input rst;
input wr_pc_valid;
input [31:0] wr_pc;
output reg [31:0] PC;

wire next_pc = PC + 32'd4;

always @ (posedge clk)
begin
    if (wr_pc_valid) begin
        PC <= wr_pc;
    end
    else begin
        PC <= next_pc;
    end
end


endmodule



module Control (clk, rst, addr1, addr2, addr3, rd1, rd2, wr1, wr2, dp_ctrl, immediate, funct3, mem_ctrl, mem_funct3, inst, PC, wr_pc);
input clk;
input rst;
input [31:0] inst;
output reg [4:0] addr1;		
output reg [4:0] addr2;
output reg [4:0] addr3;
output reg rd1;
output reg rd2;
output reg wr1;
output reg wr2;
output reg [6:0] dp_ctrl;
output reg [19:0] immediate;
output reg [31:0] PC;
input [31:0] wr_pc;
output reg [2:0] funct3;
output reg [6:0] mem_ctrl;
output reg [2:0] mem_funct3;

parameter [31:0] NOP = 32'b0;
reg [31:0] saved_inst[4:0], saved_pc[4:0];
wire next_saved_inst0, next_saved_inst1, next_saved_inst2, next_saved_inst3, next_saved_inst4;
wire next_saved_pc0, next_saved_pc1, next_saved_pc2, next_saved_pc3, next_saved_pc4;

wire [31:0] next_inst;
/*
rise    reset low, PC unknown, instruction unknown
fall    reset high, next PC - 0, next instruction - NOP, next counter - 0

rise    reset high, PC - 0, instruction - NOP, instruction memory start fetching at 0, next pc - 4
fall    

rise    reset low, PC = 4, next pc - 8, instruction memory fetch result going register, instruction memory start fetching again
fall    reset low

rise    
fall    
*/


assign next_saved_inst0 = rst ? NOP : next_inst;
assign next_saved_inst1 = rst ? NOP : saved_inst[0];
assign next_saved_inst2 = rst ? NOP : saved_inst[1];
assign next_saved_inst3 = rst ? NOP : saved_inst[2];
assign next_saved_inst4 = rst ? NOP : saved_inst[3];

assign next_saved_pc0 = rst ? 32'b0 : PC;
assign next_saved_pc1 = rst ? 32'b0 : saved_pc[0];
assign next_saved_pc2 = rst ? 32'b0 : saved_pc[1];
assign next_saved_pc3 = rst ? 32'b0 : saved_pc[2];
assign next_saved_pc4 = rst ? 32'b0 : saved_pc[3];

reg [2:0] state, next_state;
parameter [2:0]s0=3'b000,s1=3'b001,s2=3'b010,s3=3'b011,s4=3'b100;


always @ (posedge clk)
begin
    
    saved_inst[0] <= next_saved_inst0;
    saved_inst[1] <= next_saved_inst1;
    saved_inst[2] <= next_saved_inst2;
    saved_inst[3] <= next_saved_inst3;
    saved_inst[4] <= next_saved_inst4;
    
    saved_pc[0] <= next_saved_pc0;
    saved_pc[1] <= next_saved_pc1;
    saved_pc[2] <= next_saved_pc2;
    saved_pc[3] <= next_saved_pc3;
    saved_pc[4] <= next_saved_pc4;

end



// ############################## Stage 0 -- Instruction Fetch  ##############################
// Start setting up pc signal for instruction memory start at the Rising Clock edge
// At the next Rising edge, this will finish decoding, and instruction memory start reading
reg [2:0] counter;
wire [2:0] next_counter;
wire [31:0] next_pc;

wire not_normal =(  (saved_inst[0][6:0] == 7'b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
                ||  (saved_inst[0][6:0] == 7'b1100111) // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                ||  (saved_inst[0][6:0] == 7'b1100011) // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                );
                
wire is_normal = ~not_normal;

assign next_counter =   rst ? (3'b000) : 
                        (counter == 3'b000) ? (is_normal ? 3'b000 : counter + 3'b001) : 
                        (counter == 3'b001) ? (counter + 3'b001) : 
                        (counter == 3'b010) ? (counter + 3'b001) : 
                        (counter == 3'b011) ? (counter + 3'b001) : 
                        (counter == 3'b100) ? (counter + 3'b001) : 
                        (counter == 3'b101) ? (3'b0) : (3'b0);
                        
assign next_pc =    (next_counter == 3'b000) ? (PC + 32'd4) :
                    (next_counter == 3'b001) ? PC :
                    (next_counter == 3'b010) ? PC :
                    (next_counter == 3'b011) ? PC : 
                    (next_counter == 3'b100) ? wr_pc :
                    (PC + 32'd4);



assign next_inst =    (next_counter == 3'b000) ? inst :
                    (next_counter == 3'b001) ? NOP :
                    (next_counter == 3'b010) ? NOP :
                    (next_counter == 3'b011) ? NOP : 
                    (next_counter == 3'b100) ? NOP :
                    (next_counter == 3'b101) ? inst :
                    inst;

/*
rise    instruction going in IF, counter is zero
fall    

rise    instruction going in ID, counter == 1
fall    

rise    instruction going in EXE, register file start read, counter == 2
fall

rise    instruction going in MEM, datapath start execute, counter == 3
fall

rise    instruction going in WB, MEM start working, exe result going in register, counter == 4
fall

rise    instruction get discarded, MEM result going in register, WB start working, counter == 5
fall

*/

/*
two choices - normal instruction / pc modifier instruction
if normal
    go +=4
else -- the pc modifiers
    wait 3-4 cycle
    stop imcrement pc
    insert nop in the instruction chain

wire is_normal: ~(JAL && JALR && BRANCH)

reg first;
wire next_first = is_normal; // if current instuction is normal, next one will be first modifier
// if it's not normal, start the counter
wire next_counter = (~is_normal) && first ? 0 : counter + 1;

state 0
    if normal
        pc += 4
        instruction = next
        go to state 0
    else 
        pc = pc
        instruction = nop
        go to state 1

state 1
    go to state 2
    instruction = nop
    pc = pc
state 2
    pc = wr+pc
    
*/

always @ (posedge clk)
begin

    PC <= next_pc;

end




// ############################## Stage 1 -- Register File Read  ##############################
// Start setting up control signal for Register File start at the Rising Clock edge
// At the next Rising edge, this will finish decoding, and Register File start reading

wire next_rd1, next_rd2;
wire [4:0] next_addr1, next_addr2;
assign next_addr1 = saved_inst[0][19:15];
assign next_addr2 = saved_inst[0][24:20];

assign next_rd1 =   //                      7'b0110111 // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                    //                      7'b0010111 // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                    //                      7'b1101111 // JAL (Jump And Link) Spec. PDF-Page 39 )
                    (saved_inst[0][6:0] ==  7'b1100111) // JALR (Jump And Link Register) Spec. PDF-Page 39 
                ||  (saved_inst[0][6:0] ==  7'b1100011) // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                ||  (saved_inst[0][6:0] ==  7'b0000011) // LOAD (Load to Register) Spec. PDF-Page 42 )
                ||  (saved_inst[0][6:0] ==  7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
                ||  (saved_inst[0][6:0] ==  7'b0010011) // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (saved_inst[0][6:0] ==  7'b0110011) // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                ;

assign next_rd2 =   //                      7'b0110111 // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                    //                      7'b0010111 // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                    //                      7'b1101111 // JAL (Jump And Link) Spec. PDF-Page 39 )
                    //                      7'b1100111 // JALR (Jump And Link Register) Spec. PDF-Page 39 
                    (saved_inst[0][6:0] ==  7'b1100011) // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                    //                      7'b0000011 // LOAD (Load to Register) Spec. PDF-Page 42 )
                ||  (saved_inst[0][6:0] ==  7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
                    //                      7'b0010011 // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (saved_inst[0][6:0] ==  7'b0110011) // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                ;
                 
always @ (posedge clk)
begin
    addr1 <= next_addr1;
    addr2 <= next_addr2;
    rd1 <= next_rd1;
    rd2 <= next_rd2;
end




// ############################## Stage 2 -- Datapath Execute  ##############################
// Receive the instruction from the previous stage, while register file is reading
// Start setting up control signal for Datapath starting at the Rising Clock edge
// At the next Rising edge, this will finish decoding, and datapath start propagating

wire [6:0] next_dp_ctrl;
wire [19:0] next_immediate;
wire [2:0] next_funct3;
assign next_funct3 = saved_inst[1][14:12];
assign next_dp_ctrl = saved_inst[1][6:0];

// Note:
// assign variableName = (boolean expression here) ? (if boolean expression is true, do something here) : (if boolean expression is false, do something here);

                        // LUI (Load Upper Immediate) Spec. PDF-Page 37 
assign next_immediate = (saved_inst[1][6:0] == 7'b0110111) ? saved_inst[1][31:12] : 
                        // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                        (saved_inst[1][6:0] == 7'b0010111) ? saved_inst[1][31:12] : 
                        // JAL (Jump And Link) Spec. PDF-Page 39 )
                        (saved_inst[1][6:0] == 7'b1101111) ? {saved_inst[1][31], saved_inst[1][19:12], saved_inst[1][20], saved_inst[1][30:21]} : 
                        // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                        (saved_inst[1][6:0] == 7'b1100111) ? {8'd0, saved_inst[1][31:20]} : 
                        // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                        (saved_inst[1][6:0] == 7'b1100011) ? {8'b0, saved_inst[1][31], saved_inst[1][7], saved_inst[1][30:25], saved_inst[1][11:8]} : 
                        // LOAD (Load to Register) Spec. PDF-Page 42 )
                        (saved_inst[1][6:0] == 7'b0000011) ? {8'd0, saved_inst[1][31:20]} : 
                        // STORE (Store to Memory) Spec. PDF-Page 42 )
                        (saved_inst[1][6:0] == 7'b0100011) ? {8'd0, saved_inst[1][31:25], saved_inst[1][11:7]} : 
                        // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                        (saved_inst[1][6:0] == 7'b0010011) ? {8'd0, saved_inst[1][31:20]} : 
                        // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                        (saved_inst[1][6:0] == 7'b0110011) ? {13'd0, saved_inst[1][31:25]} : 
                        // Everything else, unimplemented opcodes
                        20'b0;
                        

always @ (posedge clk)
begin
    
    dp_ctrl <= next_dp_ctrl;
    immediate <= next_immediate;
    funct3 <= next_funct3;
    
end




// ############################## Stage 3 -- Memory Operation  ##############################
// Receive the instruction from the previous stage, while datapath is propagating
// Start setting up control signal for memory module starting at the Rising Clock edge
// At the next Rising edge, this will finish decoding, datapath finish computing address, and memory start working

wire [6:0] next_mem_ctrl;
wire [2:0] next_mem_funct3;
assign next_mem_ctrl = saved_inst[2][6:0];
assign next_mem_funct3 = saved_inst[2][14:12];

always @(posedge clk)
begin

    mem_ctrl <= next_mem_ctrl;
    mem_funct3 <= next_mem_funct3;

end




// ############################## Stage 4 -- Write Back  ##############################
// Receive the instruction from the previous stage, while memory is working
// Start setting up control signal for register file write starting at the Rising Clock edge
// At the next Rising edge, this will finish decoding, memory finish operation, and register file start writing

wire next_wr1, next_wr2;
wire [4:0] next_addr3;

assign next_addr3 = saved_inst[3][11:7];
assign next_wr1 = next_wr2;
assign next_wr2 =   (saved_inst[3][6:0] ==  7'b0110111) // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                ||  (saved_inst[3][6:0] ==  7'b0010111) // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                ||  (saved_inst[3][6:0] ==  7'b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
                ||  (saved_inst[3][6:0] ==  7'b1100111) // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                //                          7'b1100011: // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                ||  (saved_inst[3][6:0] ==  7'b0000011) // LOAD (Load to Register) Spec. PDF-Page 42 )
                //                          7'b0100011: // STORE (Store to Memory) Spec. PDF-Page 42 )
                ||  (saved_inst[3][6:0] ==  7'b0010011) // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (saved_inst[3][6:0] ==  7'b0110011) // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                
                ;
 
 always @(posedge clk)
 begin
 
    wr1 <= next_wr1;
    wr2 <= next_wr2;
    addr3 <= next_addr3;
 
 end
 
 
 
 

// FSM
always @ (posedge clk)
begin
    if(rst) begin
        state <= s0;
    end
    else begin
       
        case (state)
    
        s0:	    // Cycle 1 -- Decode / Start Reading Register File at Rising Clock edge
            begin
                dp_ctrl <= 0;
                wr1 <= 0;
                wr2 <= 0;
                addr1 <= inst[7:4];
                addr2 <= inst[3:0];
                wr_pc_valid <= 1'b0;
                saved_pc <= PC;
                saved_inst <= inst; // Instruction input valid in future clock cycles due to pipeline. So, we save the instruction in an internal register.
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
                    default:
                        begin
                            rd1 <= 0;
                            rd2 <= 0;
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
                        wr_pc_valid <= 1'b1;
                    end
                    7'b1100111: // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                    begin
                        wr_pc_valid <= 1'b1;
                    end
                    7'b1100011: // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                    begin
                        wr_pc_valid <= 1'b1;
                    end
                    default:
                    begin
                        wr_pc_valid <= 1'b0;
                    end
                endcase
            end
        endcase
	end
end

endmodule

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


module Control (clk, rst, addr1, addr2, addr3, rd1, rd2, wr1, wr2, dp_ctrl, immediate, funct3, mem_ctrl, mem_funct3, 
                inst, PC, dp_pc, wr_pc, forward_ctrl1, forward_ctrl2, branch_taken);
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
output reg [31:0] PC, dp_pc;
input [31:0] wr_pc;
output reg [2:0] funct3;
output reg [6:0] mem_ctrl;
output reg [2:0] mem_funct3;

output reg [1:0] forward_ctrl1, forward_ctrl2;
input branch_taken;

wire [1:0] forward_ctrl1_next, forward_ctrl2_next;

parameter [31:0] NOP = 32'h00000013; // ADDI x0, x0, 0
reg [31:0] saved_inst[4:0], saved_pc[4:0];
wire [31:0] next_saved_inst0, next_saved_inst1, next_saved_inst2, next_saved_inst3, next_saved_inst4;
wire [31:0] next_saved_pc0, next_saved_pc1, next_saved_pc2, next_saved_pc3, next_saved_pc4;

wire [31:0] next_inst;
wire [31:0] next_pc;
wire pipeline_flush;
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
assign next_saved_inst1 = rst ? NOP : (pipeline_flush ? NOP : saved_inst[0]);
assign next_saved_inst2 = rst ? NOP : (pipeline_flush ? NOP : saved_inst[1]);
assign next_saved_inst3 = rst ? NOP : (pipeline_flush ? NOP : saved_inst[2]);
assign next_saved_inst4 = rst ? NOP : (pipeline_flush ? NOP : saved_inst[3]);

assign next_saved_pc0 = rst ? 32'b0 : PC;
assign next_saved_pc1 = rst ? 32'b0 : saved_pc[0];
assign next_saved_pc2 = rst ? 32'b0 : saved_pc[1];
assign next_saved_pc3 = rst ? 32'b0 : saved_pc[2];
assign next_saved_pc4 = rst ? 32'b0 : saved_pc[3];



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

/*

if in one insturction rs1 or rs2 uses rd in another instuction
    insert stall

*/
always @(posedge clk)
begin

    forward_ctrl1 <= forward_ctrl1_next;
    forward_ctrl2 <= forward_ctrl2_next;

end

wire raw_1step = saved_inst[2][19:15] != 5'b0 && saved_inst[2][19:15] == saved_inst[3][11:7];
wire raw_2step = saved_inst[2][19:15] != 5'b0 && saved_inst[2][19:15] == saved_inst[4][11:7];
assign forward_ctrl1_next = rst ? 2'b00 : 
                            raw_1step ? 2'b01 : 
                            raw_2step ? 2'b10 : 2'b00;


wire raw_1step_rs2 = saved_inst[2][24:20] != 5'b0 && saved_inst[2][24:20] == saved_inst[3][11:7];
wire raw_2step_rs2 = saved_inst[2][24:20] != 5'b0 && saved_inst[2][24:20] == saved_inst[4][11:7];
assign forward_ctrl2_next = rst ? 2'b00 : 
                            raw_1step_rs2 ? 2'b01 : 
                            raw_2step_rs2 ? 2'b10 : 2'b00;
// ############################## Stage 0 -- Instruction Fetch  ##############################
// Start setting up pc signal for instruction memory start at the Rising Clock edge
// At the next Rising edge, normally this will finish decoding, and instruction memory start reading
// If there is a PC modifier, like branch, the FSM will start and stall the pipeline by inserting NOP. 
/*
rise    instruction going in IF, counter is zero, goes to one when meet PC modifying instructions
fall    

rise    instruction going in ID, counter == 1
fall    

rise    instruction going in EXE, register file start read, counter == 2
fall

rise    instruction going in MEM, datapath start execute, counter == 3
fall

rise    instruction going in WB, instruction MEM start working, exe result going in register, counter == 4
fall

rise    instruction get discarded, instruction MEM result going in register, WB start working, counter == 5
fall

*/
reg [3:0] counter;
wire [3:0] next_counter;



wire need_rs1 =     //                  7'b0110111 // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                    //                  7'b0010111 // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                    //                  7'b1101111 // JAL (Jump And Link) Spec. PDF-Page 39 )
                    (inst[6:0] ==  7'b1100111)  // JALR (Jump And Link Register) Spec. PDF-Page 39 
                ||  (inst[6:0] ==  7'b1100011)  // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                ||  (inst[6:0] ==  7'b0000011)  // LOAD (Load to Register) Spec. PDF-Page 42 )
                ||  (inst[6:0] ==  7'b0100011)  // STORE (Store to Memory) Spec. PDF-Page 42 )
                ||  (inst[6:0] ==  7'b0010011)  // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (inst[6:0] ==  7'b0110011)  // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                ;

wire need_rs2 =     //                  7'b0110111 // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                    //                  7'b0010111 // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                    //                  7'b1101111 // JAL (Jump And Link) Spec. PDF-Page 39 )
                    //                  7'b1100111 // JALR (Jump And Link Register) Spec. PDF-Page 39 
                    (inst[6:0] ==  7'b1100011) // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                    //                  7'b0000011 // LOAD (Load to Register) Spec. PDF-Page 42 )
                ||  (inst[6:0] ==  7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
                    //                  7'b0010011 // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (inst[6:0] ==  7'b0110011) // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                ;

wire rs1_rd_same = need_rs1 && inst[19:15] == saved_inst[0][11:7];
wire rs2_rd_same = need_rs2 && inst[24:20] == saved_inst[0][11:7];

// The current instruction is load, next instruction need to use load result, insert a nop
wire load_stall = (rs1_rd_same || rs2_rd_same) && (saved_inst[0][6:0] ==  7'b0000011); // LOAD (Load to Register) Spec. PDF-Page 42 )


reg [1:0] branch_prediction_fsm;
reg [1:0] branch_prediction_fsm_next;
wire is_branch = next_counter == 4'b1011;

wire branch_predict_taken = branch_prediction_fsm == 2'b11 || branch_prediction_fsm == 2'b10;

always @ (posedge clk)
begin
    branch_prediction_fsm <= branch_prediction_fsm_next;
end
always @ (*)
begin
    if (rst)
    begin
        branch_prediction_fsm_next <= 2'b00;
    end
    else if(branch_prediction_fsm == 2'b00)
    begin
        branch_prediction_fsm_next <= is_branch ? (branch_taken ? 2'b01 : 2'b00) : 
                                                    2'b00;
    end
    else if(branch_prediction_fsm == 2'b01)
    begin
        branch_prediction_fsm_next <= is_branch ? (branch_taken ? 2'b11 : 2'b00) : 
                                                    2'b01;
    end
    else if(branch_prediction_fsm == 2'b10)
    begin
        branch_prediction_fsm_next <= is_branch ? (branch_taken ? 2'b11 : 2'b00) : 
                                                    2'b10;
    end
    else if(branch_prediction_fsm == 2'b11)
    begin
        branch_prediction_fsm_next <= is_branch ? (branch_taken ? 2'b11 : 2'b10) : 
                                                    2'b11;
    end
    else
    begin
        branch_prediction_fsm_next <= 2'b00;
    end

end


// for JAL and BRANCH we can get new pc from instruction, that's how we predict it
reg [31:0] predict_pc;
always @ (*)

    begin
    if (inst[6:0] == 7'b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
    begin
        predict_pc <= {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0} + PC;
    end
    else if (inst[6:0] == 7'b1100011) // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
    begin
        if (branch_predict_taken) 
        begin
            predict_pc <= {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0} + PC;
        end
        else 
        begin
            predict_pc <= PC + 32'd4;
        end
    end
    else
    begin
        predict_pc <= 32'b0;
    end
end

wire use_predict_pc =   (inst[6:0] == 7'b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
                    ||  (inst[6:0] == 7'b1100011) // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                    ;

// can't use predication here, have to read register value
wire not_normal =(saved_inst[0][6:0] == 7'b1100111); // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                
wire is_normal = ~not_normal;

assign next_counter =   rst ? (4'b0000) :
                        (counter == 4'b0000) ? (load_stall ? counter + 4'b0001 : (not_normal ? 4'b0010 : (use_predict_pc ? 4'b0111 : 4'b0000))) : 
                        (counter == 4'b0001) ? 4'b0000 : 
                        (counter == 4'b0010) ? (counter + 4'b0001) :
                        (counter == 4'b0011) ? (counter + 4'b0001) :
                        (counter == 4'b0100) ? (counter + 4'b0001) :
                        (counter == 4'b0101) ? (counter + 4'b0001) :
                        (counter == 4'b0110) ? (4'b0000) :
                        (counter == 4'b0111) ? (counter + 4'b0001) :
                        (counter == 4'b1000) ? (counter + 4'b0001) : 
                        (counter == 4'b1001) ? (counter + 4'b0001) :
                        (counter == 4'b1010) ? (counter + 4'b0001) :
                        (counter == 4'b1011) ? (4'b0000) : (4'b0000);

assign next_pc =    rst ? (32'b0) : 
                    (next_counter == 4'b0000) ? (PC + 32'd4) :
                    (next_counter == 4'b0001) ? PC : 
                    (next_counter == 4'b0010) ? PC :
                    (next_counter == 4'b0011) ? PC :
                    (next_counter == 4'b0100) ? PC :
                    (next_counter == 4'b0101) ? wr_pc : 
                    (next_counter == 4'b0111) ? predict_pc : 
                    (next_counter == 4'b1000) ? (PC + 32'd4) : 
                    (next_counter == 4'b1001) ? (PC + 32'd4) : 
                    (next_counter == 4'b1010) ? (PC + 32'd4) : 
                    (next_counter == 4'b1011) ? (branch_taken != branch_predict_taken ? wr_pc : PC + 32'd4) : 
                    (PC + 32'd4);
                    
assign next_inst =  (next_counter == 4'b0000) ? inst :
                    (next_counter == 4'b0001) ? NOP : 
                    (next_counter == 4'b0010) ? NOP : 
                    (next_counter == 4'b0011) ? NOP : 
                    (next_counter == 4'b0100) ? NOP : 
                    (next_counter == 4'b0101) ? NOP : // wait longer than PC, Instruction fetch takes a while
                    (next_counter == 4'b0110) ? inst : 
                    (next_counter == 4'b0111) ? inst : 
                    (next_counter == 4'b1000) ? inst : 
                    (next_counter == 4'b1001) ? inst : 
                    (next_counter == 4'b1010) ? inst : 
                    (next_counter == 4'b1011) ? (branch_taken != branch_predict_taken ? NOP : inst) :
                    (next_counter == 4'b1100) ? inst : inst; 

assign pipeline_flush = next_counter == 4'b1011 && branch_taken != branch_predict_taken;

//assign next_counter =   rst ? (3'b000) : 
//                        (counter == 3'b000) ? (is_normal ? 3'b000 : counter + 3'b001) : 
//                        (counter == 3'b001) ? (counter + 3'b001) : 
//                        (counter == 3'b010) ? (counter + 3'b001) : 
//                        (counter == 3'b011) ? (counter + 3'b001) : 
//                        (counter == 3'b100) ? (counter + 3'b001) : 
//                        (counter == 3'b101) ? (3'b0) : (3'b0);
                        
//assign next_pc =    rst ? (32'b0) : 
//                    (next_counter == 3'b000) ? (PC + 32'd4) :
//                    (next_counter == 3'b001) ? PC :
//                    (next_counter == 3'b010) ? PC :
//                    (next_counter == 3'b011) ? PC : 
//                    (next_counter == 3'b100) ? wr_pc :
//                    (PC + 32'd4);



//assign next_inst =  (next_counter == 3'b000) ? inst :
//                    (next_counter == 3'b001) ? NOP :
//                    (next_counter == 3'b010) ? NOP :
//                    (next_counter == 3'b011) ? NOP : 
//                    (next_counter == 3'b100) ? NOP :
//                    (next_counter == 3'b101) ? inst : // wait longer than PC, Instruction fetch takes a while
//                    inst;

always @ (posedge clk)
begin

    counter <= next_counter;
    PC <= next_pc;

end





// ############################## Stage 1 -- Register File Read  ##############################
// Start setting up control signal for Register File start at the Rising Clock edge
// At the next Rising edge, this will finish decoding, and Register File start reading

wire next_rd1, next_rd2;
wire [4:0] next_addr1, next_addr2;
assign next_addr1 = saved_inst[1][19:15];
assign next_addr2 = saved_inst[1][24:20];

assign next_rd1 =   //                      7'b0110111 // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                    //                      7'b0010111 // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                    //                      7'b1101111 // JAL (Jump And Link) Spec. PDF-Page 39 )
                    (saved_inst[1][6:0] ==  7'b1100111) // JALR (Jump And Link Register) Spec. PDF-Page 39 
                ||  (saved_inst[1][6:0] ==  7'b1100011) // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                ||  (saved_inst[1][6:0] ==  7'b0000011) // LOAD (Load to Register) Spec. PDF-Page 42 )
                ||  (saved_inst[1][6:0] ==  7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
                ||  (saved_inst[1][6:0] ==  7'b0010011) // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (saved_inst[1][6:0] ==  7'b0110011) // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                ;

assign next_rd2 =   //                      7'b0110111 // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                    //                      7'b0010111 // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                    //                      7'b1101111 // JAL (Jump And Link) Spec. PDF-Page 39 )
                    //                      7'b1100111 // JALR (Jump And Link Register) Spec. PDF-Page 39 
                    (saved_inst[1][6:0] ==  7'b1100011) // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                    //                      7'b0000011 // LOAD (Load to Register) Spec. PDF-Page 42 )
                ||  (saved_inst[1][6:0] ==  7'b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
                    //                      7'b0010011 // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (saved_inst[1][6:0] ==  7'b0110011) // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
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
assign next_funct3 = saved_inst[2][14:12];
assign next_dp_ctrl = saved_inst[2][6:0];

// Note:
// assign variableName = (boolean expression here) ? (if boolean expression is true, do something here) : (if boolean expression is false, do something here);

                        // LUI (Load Upper Immediate) Spec. PDF-Page 37 
assign next_immediate = (saved_inst[2][6:0] == 7'b0110111) ? saved_inst[2][31:12] : 
                        // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                        (saved_inst[2][6:0] == 7'b0010111) ? saved_inst[2][31:12] : 
                        // JAL (Jump And Link) Spec. PDF-Page 39 )
                        (saved_inst[2][6:0] == 7'b1101111) ? {saved_inst[2][31], saved_inst[2][19:12], saved_inst[2][20], saved_inst[2][30:21]} : 
                        // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                        (saved_inst[2][6:0] == 7'b1100111) ? {8'd0, saved_inst[2][31:20]} : 
                        // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                        (saved_inst[2][6:0] == 7'b1100011) ? {8'b0, saved_inst[2][31], saved_inst[2][7], saved_inst[2][30:25], saved_inst[2][11:8]} : 
                        // LOAD (Load to Register) Spec. PDF-Page 42 )
                        (saved_inst[2][6:0] == 7'b0000011) ? {8'd0, saved_inst[2][31:20]} : 
                        // STORE (Store to Memory) Spec. PDF-Page 42 )
                        (saved_inst[2][6:0] == 7'b0100011) ? {8'd0, saved_inst[2][31:25], saved_inst[2][11:7]} : 
                        // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                        (saved_inst[2][6:0] == 7'b0010011) ? {8'd0, saved_inst[2][31:20]} : 
                        // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                        (saved_inst[2][6:0] == 7'b0110011) ? {13'd0, saved_inst[2][31:25]} : 
                        // Everything else, unimplemented opcodes
                        20'b0;
                        

always @ (posedge clk)
begin
    
    dp_ctrl <= next_dp_ctrl;
    immediate <= next_immediate;
    funct3 <= next_funct3;
    dp_pc <= saved_pc[2];
end




// ############################## Stage 3 -- Memory Operation  ##############################
// Receive the instruction from the previous stage, while datapath is propagating
// Start setting up control signal for memory module starting at the Rising Clock edge
// At the next Rising edge, this will finish decoding, datapath finish computing address, and memory start working

wire [6:0] next_mem_ctrl;
wire [2:0] next_mem_funct3;
assign next_mem_ctrl = saved_inst[3][6:0];
assign next_mem_funct3 = saved_inst[3][14:12];

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

assign next_addr3 = saved_inst[4][11:7];
assign next_wr1 = next_wr2;
assign next_wr2 =   (saved_inst[4][6:0] ==  7'b0110111) // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                ||  (saved_inst[4][6:0] ==  7'b0010111) // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                ||  (saved_inst[4][6:0] ==  7'b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
                ||  (saved_inst[4][6:0] ==  7'b1100111) // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                //                          7'b1100011: // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                ||  (saved_inst[4][6:0] ==  7'b0000011) // LOAD (Load to Register) Spec. PDF-Page 42 )
                //                          7'b0100011: // STORE (Store to Memory) Spec. PDF-Page 42 )
                ||  (saved_inst[4][6:0] ==  7'b0010011) // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (saved_inst[4][6:0] ==  7'b0110011) // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                
                ;
 
 always @(posedge clk)
 begin
 
    wr1 <= next_wr1;
    wr2 <= next_wr2;
    addr3 <= next_addr3;
 
 end

endmodule

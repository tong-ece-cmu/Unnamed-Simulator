`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/18/2021 09:34:17 AM
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


module main(
    );
    reg clk, rst;
    always #5 clk = ~clk;  // Create clock with period=10
    
    // Register File
    wire [4:0] addr1, addr2, addr3;
    wire rd1, rd2, wr1;
    wire [31:0] wr_data, rd_data1, rd_data2;
    // Execute Datapath
    wire [31:0] exe_inst, exe_result;
    wire exe_rs1_forward;
    // Data Memory
    wire [31:0] mem_result, mem_inst;
    // Write Back
    wire [31:0] write_back_inst;
    
    
    wire[31:0] inst, PC;
    
    InstructionMemory instruction_memory_module(.*);
    RegisterFile register_module(.*);
    InstructionDecode instruction_decode_module(.*);
    Execute execute_module(.*);
    Data_Memory data_memory_module(.*);
    Write_Back_Control write_back_control_module(.*);
    
    initial
    begin
        clk <= 0;
        rst <= 1;
        #10 rst <= 0;
        
        #2560 $finish;            // Quit the simulation
    end
    
endmodule : main

// ----------------------------------------------------------------------------------------
module Write_Back_Control (
input clk,
input [31:0] mem_result,
input [31:0] write_back_inst,
output reg wr1,
output reg [4:0] addr3,
output reg [31:0] wr_data
);

wire [31:0] inst = write_back_inst;
wire need_rd =      (inst[6:0] ==   7'b0110111) // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                ||  (inst[6:0] ==   7'b0010111) // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                ||  (inst[6:0] ==   7'b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
                ||  (inst[6:0] ==   7'b1100111)  // JALR (Jump And Link Register) Spec. PDF-Page 39 
                // ||  (inst[6:0] ==   7'b1100011)  // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                ||  (inst[6:0] ==   7'b0000011)  // LOAD (Load to Register) Spec. PDF-Page 42 )
                // ||  (inst[6:0] ==  7'b0100011)  // STORE (Store to Memory) Spec. PDF-Page 42 )
                ||  (inst[6:0] ==   7'b0010011)  // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (inst[6:0] ==   7'b0110011)  // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                ;
assign wr1 = need_rd;
assign addr3 = inst[11:7];
assign wr_data = mem_result;


endmodule : Write_Back_Control


// ----------------------------------------------------------------------------------------
module InstructionDecode (
input clk,
input rst,
input [31:0] inst,
output reg [31:0] PC,
output rd1,
output rd2,
output [4:0] addr1,
output [4:0] addr2,
output reg [31:0] exe_inst,
output reg exe_rs1_forward
);

logic[31:0] PC_next;

assign addr1 = inst[19:15];
assign addr2 = inst[24:20];

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


wire next_inst_need_rd = (exe_inst[6:0] ==   7'b0110111) // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                ||  (exe_inst[6:0] ==   7'b0010111) // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                ||  (exe_inst[6:0] ==   7'b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
                ||  (exe_inst[6:0] ==   7'b1100111)  // JALR (Jump And Link Register) Spec. PDF-Page 39 
                // ||  (exe_inst[6:0] ==   7'b1100011)  // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                ||  (exe_inst[6:0] ==   7'b0000011)  // LOAD (Load to Register) Spec. PDF-Page 42 )
                // ||  (exe_inst[6:0] ==  7'b0100011)  // STORE (Store to Memory) Spec. PDF-Page 42 )
                ||  (exe_inst[6:0] ==   7'b0010011)  // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (exe_inst[6:0] ==   7'b0110011)  // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                ;

assign rd1 = need_rs1;
assign rd2 = need_rs2;

wire [4:0] next_inst_rd_addr = exe_inst[11:7];
wire rs1_forward_next = (addr1 != 0) && next_inst_need_rd && need_rs1 
                        && (addr1 == next_inst_rd_addr);


always_comb begin
    if (rst)    PC_next = 0;
    else        PC_next = PC + 4;
end

always_ff @(posedge clk) begin
    PC <= PC_next;
    exe_inst <= inst;
    exe_rs1_forward <= rs1_forward_next;
end

endmodule : InstructionDecode

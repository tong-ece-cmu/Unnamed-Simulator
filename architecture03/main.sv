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
    wire [1:0] exe_rs1_forward, exe_rs2_forward;
    // Cache
    wire [31:0] mem_result, mem_inst, mem_addr;
    wire freeze_cpu;
    // Write Back
    wire [31:0] write_back_inst;
    
    // DRAM
    wire dram_ready;
    wire [31:0] dram_result;
    wire [1:0] dram_signal;
    wire [31:0] dram_addr;
    wire [31:0] dram_write_data;
    
    wire[31:0] inst, PC;
    
    InstructionMemory instruction_memory_module(.*);
    RegisterFile register_module(.*);
    InstructionDecode instruction_decode_module(.*);
    Execute execute_module(.*);
    Cache cache_module(.*);
    Write_Back_Control write_back_control_module(.*);
    
    DRAM dram_module(.*);
//    Data_Memory data_memory_module(.*);
    
    initial
    begin
        
        clk <= 0;
        rst <= 1;
        #10 rst <= 0;
        
        `include "verification.vh"
        #`SIMULATION_FINISH_TIME $finish;            // Quit the simulation
        
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
input freeze_cpu,
input [31:0] mem_inst,
output reg [31:0] PC,
output rd1,
output rd2,
output [4:0] addr1,
output [4:0] addr2,
output reg [31:0] exe_inst,
output reg [1:0] exe_rs1_forward,
output reg [1:0] exe_rs2_forward
);

logic[31:0] PC_next;
logic[31:0] exe_inst_next;
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

wire next_next_inst_need_rd = (mem_inst[6:0] ==   7'b0110111) // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                ||  (mem_inst[6:0] ==   7'b0010111) // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                ||  (mem_inst[6:0] ==   7'b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
                ||  (mem_inst[6:0] ==   7'b1100111)  // JALR (Jump And Link Register) Spec. PDF-Page 39 
                // ||  (mem_inst[6:0] ==   7'b1100011)  // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                ||  (mem_inst[6:0] ==   7'b0000011)  // LOAD (Load to Register) Spec. PDF-Page 42 )
                // ||  (mem_inst[6:0] ==  7'b0100011)  // STORE (Store to Memory) Spec. PDF-Page 42 )
                ||  (mem_inst[6:0] ==   7'b0010011)  // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                ||  (mem_inst[6:0] ==   7'b0110011)  // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                ;

assign rd1 = !freeze_cpu && need_rs1;
assign rd2 = !freeze_cpu && need_rs2;

wire [4:0] next_inst_rd_addr = exe_inst[11:7];
wire [4:0] next_next_inst_rd_addr = mem_inst[11:7];
logic [1:0] rs1_forward_next;
logic [1:0] rs2_forward_next;

always_comb begin
    if (freeze_cpu)
        rs1_forward_next = exe_rs1_forward;
    else if ((addr1 != 0) && next_inst_need_rd && need_rs1 && (addr1 == next_inst_rd_addr))
        rs1_forward_next = 1;
    else if ((addr1 != 0) && next_next_inst_need_rd && need_rs1 && (addr1 == next_next_inst_rd_addr))
        rs1_forward_next = 2;
    else
        rs1_forward_next = 0;
end

always_comb begin
    if (freeze_cpu)
        rs2_forward_next = exe_rs2_forward;
    else if ((addr2 != 0) && next_inst_need_rd && need_rs2 && (addr2 == next_inst_rd_addr))
        rs2_forward_next = 1;
    else if ((addr2 != 0) && next_next_inst_need_rd && need_rs2 && (addr2 == next_next_inst_rd_addr))
        rs2_forward_next = 2;
    else
        rs2_forward_next = 0;
end

always_comb begin
    if (rst)                PC_next = 0;
    else if (freeze_cpu)    PC_next = PC;
    else                    PC_next = PC + 4;
end

always_comb begin
    if (rst)        exe_inst_next = 32'h00000013;
    else if (freeze_cpu) exe_inst_next = exe_inst;
    else            exe_inst_next = inst;
end

always_ff @(posedge clk) begin
    PC <= PC_next;
    exe_inst <= exe_inst_next;
    exe_rs1_forward <= rs1_forward_next;
    exe_rs2_forward <= rs2_forward_next;
end

endmodule : InstructionDecode

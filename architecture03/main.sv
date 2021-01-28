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
module main_verification(
input wire clk,
input [15:0] clk_counter
);
    wire clk_ss;
    initial begin
        #10 $display("from test module");
    end
    
    assert property (                                  
        @(posedge clk)       // sampling event
            clk |-> ##20 clk                             // expression to check
        )
        else                                        // (optional) error message
            $error("%m bad clock");
    
    covergroup clkcover @ (posedge clk);
        coverpoint clk_counter;
    endgroup

endmodule


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
    wire [7:0] dram_result;
    wire [1:0] dram_signal;
    wire [31:0] dram_addr_rd;
    wire [31:0] dram_addr_wr;
    wire [7:0] dram_write_data;
    
    wire[31:0] inst, PC;
    
    InstructionMemory instruction_memory_module(.*);
    RegisterFile register_module(.*);
    InstructionDecode instruction_decode_module(.*);
    Execute execute_module(.*);
    Cache cache_module(.*);
    Write_Back_Control write_back_control_module(.*);
    
    DRAM dram_module(.*);
//    Data_Memory data_memory_module(.*);
    bind RegisterFile main_verification assert_bind_ip_instance(.*);

    integer i=0;
    initial
    begin
	if($test$plusargs("ss"))
            $display("yes");
        clk <= 0;
        rst <= 1;
        #10 rst <= 0;

        `include "verification.svh"
        #`SIMULATION_FINISH_TIME $stop;            // $finish to Quit the simulation
        
        
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

logic [31:0] inst_for_rf;
logic[31:0] PC_next;
logic[31:0] exe_inst_next;

wire exe_is_load = (exe_inst[6:0] ==   7'b0000011);  // LOAD (Load to Register) Spec. PDF-Page 42 )

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

wire [4:0] next_inst_rd_addr = exe_inst[11:7];
wire [4:0] next_next_inst_rd_addr = mem_inst[11:7];
logic [1:0] rs1_forward_next;
logic [1:0] rs2_forward_next;

wire [4:0] addr1_inst = inst[19:15];
wire [4:0] addr2_inst = inst[24:20];
wire need_rs1_n0 = need_rs1 && (addr1_inst != 0);
wire need_rs2_n0 = need_rs2 && (addr2_inst != 0);

wire is_rs1_one_step_raw = need_rs1_n0 && next_inst_need_rd && (addr1_inst == next_inst_rd_addr);
wire is_rs2_one_step_raw = need_rs2_n0 && next_inst_need_rd && (addr2_inst == next_inst_rd_addr);
wire is_rs1_two_step_raw = need_rs1_n0 && next_next_inst_need_rd && (addr1_inst == next_next_inst_rd_addr);
wire is_rs2_two_step_raw = need_rs2_n0 && next_next_inst_need_rd && (addr2_inst == next_next_inst_rd_addr);

reg [7:0] counter;
logic [7:0] counter_next;

assign rd1 = counter_next == 1 || (!freeze_cpu && need_rs1);
assign rd2 = !freeze_cpu && need_rs2;

assign addr1 = counter_next == 1 ? 0 : addr1_inst; // NOP for read after load need to read r0
assign addr2 = counter_next == 1 ? 0 : addr2_inst; // NOP for read after load need to read r0

always_comb begin
    if (rst)    counter_next = 0;
    else if (freeze_cpu) begin
        counter_next = counter;
    end
    else if (counter == 0) begin
        if ((is_rs1_one_step_raw || is_rs2_one_step_raw) && exe_is_load) begin
            counter_next = 1;
        end
        else begin
            counter_next = 0;
        end
    end
    else if (counter == 1) begin
        counter_next = 0;
    end
    else begin
        counter_next = 0;
    end
end


always_comb begin
    if (freeze_cpu)
        rs1_forward_next = exe_rs1_forward;
    else if (counter_next == 1)
        rs1_forward_next = 0; // forward for NOP is none
    else if (is_rs1_one_step_raw)
        rs1_forward_next = 1;
    else if (is_rs1_two_step_raw)
        rs1_forward_next = 2;
    else
        rs1_forward_next = 0;
end

always_comb begin
    if (freeze_cpu)
        rs2_forward_next = exe_rs2_forward;
    else if (counter_next == 1)
        rs2_forward_next = 0; // forward for NOP is none
    else if (is_rs2_one_step_raw)
        rs2_forward_next = 1;
    else if (is_rs2_two_step_raw)
        rs2_forward_next = 2;
    else
        rs2_forward_next = 0;
end


always_comb begin
    if (rst)                PC_next = 0;
    else if (freeze_cpu)    PC_next = PC;
    else if (counter_next == 1) PC_next = PC; // NOP for read after load
    else                    PC_next = PC + 4;
end

always_comb begin
    if (rst)        exe_inst_next = 32'h00000013;
    else if (freeze_cpu) exe_inst_next = exe_inst;
    else if (counter_next == 1) exe_inst_next = 32'h00000013; // NOP for read after load
    else            exe_inst_next = inst;
end

always_ff @(posedge clk) begin
    PC <= PC_next;
    exe_inst <= exe_inst_next;
    exe_rs1_forward <= rs1_forward_next;
    exe_rs2_forward <= rs2_forward_next;
    counter <= counter_next;
end

endmodule : InstructionDecode

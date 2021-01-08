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

module main(clk, rst);
input clk;
input rst;
wire [31:0] inst;
wire [31:0] mem_addr;

wire [1:0] forward_ctrl1, forward_ctrl2;
wire [31:0] rd_data1, rd_data2, wr_data, wr_pc, PC, wr_data_from_mem, dp_pc;
wire [19:0] immediate;
wire [2:0] funct3, mem_funct3;
wire [6:0] dp_ctrl, mem_ctrl;
wire [4:0] addr1, addr2, addr3;
wire rd1, rd2, wr1, wr2, branch_taken;
wire freeze_cpu, from_mem_ready, to_mem_rd, to_mem_wr;
wire [31:0] to_mem_wr_data;
wire [31:0] new_mem_rd_data;

// Instantiation of the modules

Control control_module(.clk(clk), .rst(rst), .addr1(addr1), .addr2(addr2), .addr3(addr3), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), .freeze_cpu(freeze_cpu),
                        .dp_ctrl(dp_ctrl), .immediate(immediate), .funct3(funct3), .mem_ctrl(mem_ctrl), .mem_funct3(mem_funct3), .inst(inst), .PC(PC), .wr_pc(wr_pc), 
                        .forward_ctrl1(forward_ctrl1), .forward_ctrl2(forward_ctrl2), .dp_pc(dp_pc), .branch_taken(branch_taken));
                        
Datapath datapath_module(.clk(clk), .dp_ctrl(dp_ctrl), .wr_data(wr_data), .wr_pc(wr_pc), .PC(dp_pc), .rd_data1_input(rd_data1), .rd_data2_input(rd_data2), 
                            .forward_ctrl1(forward_ctrl1), .forward_ctrl2(forward_ctrl2), .immediate(immediate), .funct3(funct3), .mem_addr(mem_addr),
                            .mem_forward(wr_data_from_mem), .branch_taken(branch_taken));
                            
RegisterFile register_module(.clk(clk), .addr1(addr1), .addr2(addr2), .addr3(addr3), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), .wr_data(wr_data_from_mem), 
                                .rd_data1(rd_data1), .rd_data2(rd_data2));

Memory memory_module (.clk(clk), .rst(rst), .mem_ctrl(mem_ctrl), .funct3(mem_funct3), .addr(mem_addr), .freeze_cpu(freeze_cpu), .mem_rd_data(wr_data_from_mem), 
                    .mem_wr_data(wr_data), .from_mem_ready(from_mem_ready), .to_mem_rd(to_mem_rd), .to_mem_wr(to_mem_wr), .to_mem_wr_data(to_mem_wr_data),
                    .from_mem_rd_data(new_mem_rd_data));
                    
InstructionMemory instruction_memory_module (.clk(clk), .PC(PC), .inst(inst));

//wire new_mem_rd = 1'b0;
//wire new_mem_wr;
//wire [31:0] new_mem_wr_data;
wire new_mem_rd_valid;
//wire write_ready;
Mem new_memory_module (.clk(clk), .rst(rst), .rd(to_mem_rd), .wr(to_mem_wr), .addr(mem_addr), .wr_data(to_mem_wr_data), .mem_ready(from_mem_ready), 
                        .rd_data(new_mem_rd_data), .rd_data_valid(new_mem_rd_valid));

//Mem_user new_memory_user_module (.clk(clk), .rst(rst), .wr(new_mem_wr), .wr_data(new_mem_wr_data), .wr_ready(write_ready));
endmodule






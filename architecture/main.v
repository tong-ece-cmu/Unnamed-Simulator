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
wire [31:0] rd_data1, rd_data2, wr_data, wr_pc, PC, wr_data_from_mem;
wire [19:0] immediate;
wire [2:0] funct3, mem_funct3;
wire [6:0] dp_ctrl, mem_ctrl;
wire [4:0] addr1, addr2, addr3;
wire rd1, rd2, wr1, wr2;

// Instantiation of the modules

Control control_module(.clk(clk), .rst(rst), .addr1(addr1), .addr2(addr2), .addr3(addr3), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), 
                        .dp_ctrl(dp_ctrl), .immediate(immediate), .funct3(funct3), .mem_ctrl(mem_ctrl), .mem_funct3(mem_funct3), .inst(inst), .PC(PC), .wr_pc(wr_pc), 
                        .forward_ctrl1(forward_ctrl1), .forward_ctrl2(forward_ctrl2));
                        
Datapath datapath_module(.clk(clk), .dp_ctrl(dp_ctrl), .wr_data(wr_data), .wr_pc(wr_pc), .PC(PC), .rd_data1_input(rd_data1), .rd_data2_input(rd_data2), 
                            .forward_ctrl1(forward_ctrl1), .forward_ctrl2(forward_ctrl2), .immediate(immediate), .funct3(funct3), .mem_addr(mem_addr),
                            .mem_forward(wr_data_from_mem));
                            
RegisterFile register_module(.clk(clk), .addr1(addr1), .addr2(addr2), .addr3(addr3), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), .wr_data(wr_data_from_mem), 
                                .rd_data1(rd_data1), .rd_data2(rd_data2));

Memory memory_module (.clk(clk), .mem_ctrl(mem_ctrl), .funct3(mem_funct3), .addr(mem_addr), .mem_rd_data(wr_data_from_mem), .mem_wr_data(wr_data));

InstructionMemory instruction_memory_module (.clk(clk), .PC(PC), .inst(inst));


endmodule






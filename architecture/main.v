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

Memory memory_module (.clk(clk), .dp_ctrl(dp_ctrl), .funct3(funct3), .addr(mem_addr), .mem_rd_data(in_bus), .mem_wr_data(out_bus));

endmodule






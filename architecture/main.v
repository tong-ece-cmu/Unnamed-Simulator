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

/* python code
for i in range(5):
    print('addr1_{ii}, addr2_{ii}, rd1_{ii}, rd2_{ii}, wr1_{ii}, wr2_{ii}, dp_crtl_{ii}, immediate_{ii},'.format(ii=i))
    
*/

/* python code
for i in range(5):
    print('''input [31:0] addr1_{ii}, addr2_{ii};
input rd1_{ii}, rd2_{ii}, wr1_{ii}, wr2_{ii};
input [6:0] dp_crtl_{ii};
input [19:0] immediate_{ii};
input [2:0] funct3_{ii};
'''.format(ii=i))

*/


module main_control(clk, rst_main, rst0, rst1, rst2, rst3, rst4,
                    addr1_main, addr2_main, addr3_main, rd1_main, rd2_main, wr1_main, wr2_main, dp_crtl_main, mem_dp_ctrl, immediate_main, funct3_main, mem_funct3, PC_main,
                    addr1_0, addr2_0, rd1_0, rd2_0, wr1_0, wr2_0, dp_crtl_0, immediate_0, funct3_0,
                    addr1_1, addr2_1, rd1_1, rd2_1, wr1_1, wr2_1, dp_crtl_1, immediate_1, funct3_1,
                    addr1_2, addr2_2, rd1_2, rd2_2, wr1_2, wr2_2, dp_crtl_2, immediate_2, funct3_2,
                    addr1_3, addr2_3, rd1_3, rd2_3, wr1_3, wr2_3, dp_crtl_3, immediate_3, funct3_3,
                    addr1_4, addr2_4, rd1_4, rd2_4, wr1_4, wr2_4, dp_crtl_4, immediate_4, funct3_4);
input clk;
input rst_main;
output reg rst0, rst1, rst2, rst3, rst4;

output reg [31:0] addr1_main, addr2_main, addr3_main, PC_main;
output reg rd1_main, rd2_main, wr1_main, wr2_main;
output reg [6:0] dp_crtl_main, mem_dp_ctrl;
output reg [2:0] funct3_main, mem_funct3;
output reg [19:0] immediate_main;

input [31:0] addr1_0, addr2_0;
input rd1_0, rd2_0, wr1_0, wr2_0;
input [6:0] dp_crtl_0;
input [19:0] immediate_0;
input [2:0] funct3_0;

input [31:0] addr1_1, addr2_1;
input rd1_1, rd2_1, wr1_1, wr2_1;
input [6:0] dp_crtl_1;
input [19:0] immediate_1;
input [2:0] funct3_1;

input [31:0] addr1_2, addr2_2;
input rd1_2, rd2_2, wr1_2, wr2_2;
input [6:0] dp_crtl_2;
input [19:0] immediate_2;
input [2:0] funct3_2;

input [31:0] addr1_3, addr2_3;
input rd1_3, rd2_3, wr1_3, wr2_3;
input [6:0] dp_crtl_3;
input [19:0] immediate_3;
input [2:0] funct3_3;

input [31:0] addr1_4, addr2_4;
input rd1_4, rd2_4, wr1_4, wr2_4;
input [6:0] dp_crtl_4;
input [19:0] immediate_4;
input [2:0] funct3_4;

reg [2:0] counter;
always @ (posedge clk)
begin
    if(rst_main) begin
        counter <= 3'b000;
        
    end
    else begin
        counter <= counter + 1'b1;
    end
end

always @ (*)
begin
    case (counter)
        3'b000:
        begin
            rst0 <= 1'b1;
            rst1 <= 1'b1;
            rst2 <= 1'b1;
            rst3 <= 1'b1;
            rst4 <= 1'b1;
        end
        3'b001:
        begin
            rst0 <= 1'b0;
            addr1_main <= addr1_0;
            addr2_main <= addr2_0;
            rd1_main <= rd1_0;
            rd2_main <= rd2_0;
            
            
            dp_crtl_main <= dp_crtl_1;
            funct3_main <= funct3_1;
            
            
            mem_dp_ctrl <= dp_crtl_2;
            mem_funct3 <= funct3_2;
            
            
            addr3_main <= addr1_3;
            wr1_main <= wr1_3;
            wr2_main <= wr2_3;
            
            
            
        end
        default:
        begin
            
        end
    
    endcase
        
    
end


endmodule

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
wire [4:0] addr1, addr2, addr3;
wire rd1, rd2, wr1, wr2;

// Instantiation of the modules



Control control_module0(.clk(clk), .rst(rst), .addr1(addr1), .addr2(addr2), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), 
                        .dp_ctrl(dp_ctrl), .immediate(immediate), .inst(inst), .PC(PC), .wr_pc(wr_pc), .funct3(funct3));

Control control_module1(.clk(clk), .rst(rst), .addr1(addr1), .addr2(addr2), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), 
                        .dp_ctrl(dp_ctrl), .immediate(immediate), .inst(inst), .PC(PC), .wr_pc(wr_pc), .funct3(funct3));
                        
Control control_module2(.clk(clk), .rst(rst), .addr1(addr1), .addr2(addr2), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), 
                        .dp_ctrl(dp_ctrl), .immediate(immediate), .inst(inst), .PC(PC), .wr_pc(wr_pc), .funct3(funct3));
                        
Control control_module3(.clk(clk), .rst(rst), .addr1(addr1), .addr2(addr2), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), 
                        .dp_ctrl(dp_ctrl), .immediate(immediate), .inst(inst), .PC(PC), .wr_pc(wr_pc), .funct3(funct3));
                        
Control control_module4(.clk(clk), .rst(rst), .addr1(addr1), .addr2(addr2), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), 
                        .dp_ctrl(dp_ctrl), .immediate(immediate), .inst(inst), .PC(PC), .wr_pc(wr_pc), .funct3(funct3));
                        


Datapath datapath_module(.clk(clk), .dp_ctrl(dp_ctrl), .wr_data(wr_data), .wr_pc(wr_pc), .PC(PC), .rd_data1(rd_data1), .rd_data2(rd_data2), 
                            .immediate(immediate), .in_bus(in_bus), .out_bus(out_bus), .funct3(funct3), .mem_addr(mem_addr));
                            
RegisterFile register_module(.clk(clk), .addr1(addr1), .addr2(addr2), .addr3(addr3), .rd1(rd1), .rd2(rd2), .wr1(wr1), .wr2(wr2), .wr_data(wr_data), 
                                .rd_data1(rd_data1), .rd_data2(rd_data2));

Memory memory_module (.clk(clk), .dp_ctrl(dp_ctrl), .funct3(funct3), .addr(mem_addr), .mem_rd_data(in_bus), .mem_wr_data(out_bus));

endmodule






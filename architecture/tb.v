`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/26/2020 06:12:14 PM
// Design Name: 
// Module Name: tb
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


module tb(

    );
    reg clk=0;
	always #5 clk = ~clk;  // Create clock with period=10

//    reg [15:0] inst;
    reg [15:0] in_bus;
    wire [15:0] out_bus;
    
    reg [15:0] rd_data1, rd_data2;
    wire [15:0] wr_data;
    reg [5:0] dp_ctrl;
//    wire [3:0] addr1, addr2;
//    wire rd1, rd2, wr1, wr2;

	// A testbench
	initial begin
	    // ADD
//		#10 dp_ctrl <= 6'b000001; rd_data1 <= 16'd20; rd_data2 <= 16'd20; in_bus <= 16'd12;
		
//		#10 dp_ctrl <= 6'b000001; rd_data1 <= 16'd12; rd_data2 <= 16'd20; in_bus <= 16'd12;
		
//		#10 dp_ctrl <= 6'b000001; rd_data1 <= 16'd35; rd_data2 <= 16'd20; in_bus <= 16'd12;
        
        // R_SHIFT
//        #10 dp_ctrl <= 6'b000010; rd_data1 <= 16'd20; rd_data2 <= 16'd21; in_bus <= 16'd12;
        
//        #10 dp_ctrl <= 6'b000010; rd_data1 <= 16'd11; rd_data2 <= 16'd31; in_bus <= 16'd12;
        
//        #10 dp_ctrl <= 6'b000010; rd_data1 <= 16'd81; rd_data2 <= 16'd6; in_bus <= 16'd12;
        
		// AND_LSB
		#10 dp_ctrl <= 6'b001000; rd_data1 <= 16'd81; rd_data2 <= 16'd6; in_bus <= 16'd12;
		
		#10 dp_ctrl <= 6'b001000; rd_data1 <= 16'd13; rd_data2 <= 16'd92; in_bus <= 16'd12;
		
		#10 dp_ctrl <= 6'b001000; rd_data1 <= 16'd58; rd_data2 <= 16'd56; in_bus <= 16'd12;
		
		
		#50 $finish;            // Quit the simulation
	end
    Datapath datapath_module(.clk(clk), .dp_ctrl(dp_ctrl), .wr_data(wr_data), .rd_data1(rd_data1), .rd_data2(rd_data2), .in_bus(in_bus), .out_bus(out_bus));
    
endmodule

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
    
    reg rst=1;
    
	// A testbench
	initial begin
        #10 rst <= 1'b0;
		
		#2560 $finish;            // Quit the simulation
	end
	main main_cpu_module(.clk(clk), .rst(rst));
    
endmodule

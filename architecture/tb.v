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
    reg [31:0] inst;
    reg [31:0] in_bus;
    wire [31:0] out_bus;
    wire [31:0] mem_addr;
//    reg [31:0] inst_memory [0:512];
    
    
	// A testbench
	initial begin
//	   $readmemh("inst1.mem", inst_memory);
    
        // main
        #10 inst <= 32'h00000000; in_bus <= 32'd58; rst <= 1'b0; 
        #10; #10; #10;
        
        #10 inst <= {20'h1234A, 5'b00001, 7'b0110111}; in_bus <= 32'd58; // LUI (Load Upper Immediate) Spec. PDF-Page 37 )
        #10; #10; #10;
        
        #10 inst <= {20'h00800, 5'b00001, 7'b1101111}; in_bus <= 32'd58; // JAL (Jump And Link) Spec. PDF-Page 39 )
        #10; #10; #10;
        
        #10 inst <= {20'hffdff, 5'b00001, 7'b1101111}; in_bus <= 32'd58; // JAL (Jump And Link) Spec. PDF-Page 39 )
        #10; #10; #10;
        
        #10 inst <= {20'h00800, 5'b00001, 7'b1101111}; in_bus <= 32'd58; // JAL (Jump And Link) Spec. PDF-Page 39 )
        #10; #10; #10;
        
        #10 inst <= {12'h008, 5'b00001, 3'b000, 5'b00010, 7'b1100111}; in_bus <= 32'd58; // JALR (Jump And Link Register) Spec. PDF-Page 39 )
        #10; #10; #10;
        
        #10 inst <= {20'h22222, 5'b00001, 7'b0010111}; in_bus <= 32'd58; // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
        #10; #10; #10;
		
		#50 $finish;            // Quit the simulation
	end
	    
    main main_cpu_module(.clk(clk), .rst(rst), .inst(inst), .in_bus(in_bus), .out_bus(out_bus), .mem_addr(mem_addr));
    
endmodule

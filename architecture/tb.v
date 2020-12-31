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
    reg [31:0] inst_memory [0:512];
    
    
	// A testbench
	initial begin
	   $readmemh("inst1.mem", inst_memory);
	    // ADD
//		#10 dp_ctrl <= 6'b000001; rd_data1 <= 16'd20; rd_data2 <= 16'd20; in_bus <= 16'd12;
		
//		#10 dp_ctrl <= 6'b000001; rd_data1 <= 16'd12; rd_data2 <= 16'd20; in_bus <= 16'd12;
		
//		#10 dp_ctrl <= 6'b000001; rd_data1 <= 16'd35; rd_data2 <= 16'd20; in_bus <= 16'd12;
        
        // R_SHIFT
//        #10 dp_ctrl <= 6'b000010; rd_data1 <= 16'd20; rd_data2 <= 16'd21; in_bus <= 16'd12;
        
//        #10 dp_ctrl <= 6'b000010; rd_data1 <= 16'd11; rd_data2 <= 16'd31; in_bus <= 16'd12;
        
//        #10 dp_ctrl <= 6'b000010; rd_data1 <= 16'd81; rd_data2 <= 16'd6; in_bus <= 16'd12;
        
		// AND_LSB
//		#10 dp_ctrl <= 7'b0001000; rd_data1 <= 16'd81; rd_data2 <= 16'd6; in_bus <= 16'd12;
		
//		#10 dp_ctrl <= 7'b0001000; rd_data1 <= 16'd13; rd_data2 <= 16'd92; in_bus <= 16'd12;
		
//		#10 dp_ctrl <= 7'b0001000; rd_data1 <= 16'd58; rd_data2 <= 16'd56; in_bus <= 16'd12;
    
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
        
        #10 inst <= {20'h22222, 5'b00001, 7'b0010111}; in_bus <= 32'd58; // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
        #10; #10; #10;
		
		#50 $finish;            // Quit the simulation
	end
//    Datapath datapath_module(.clk(clk), .dp_ctrl(dp_ctrl), .wr_data(wr_data), .rd_data1(rd_data1), .rd_data2(rd_data2), .in_bus(in_bus), .out_bus(out_bus));
    
    main main_cpu_module(.clk(clk), .rst(rst), .inst(inst), .in_bus(in_bus), .out_bus(out_bus));
endmodule

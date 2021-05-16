
/* 
 * Module `RegisterFile`
 * 
 * addr3 is the address for write data
 */

module RegisterFile (
input clk,
input [4:0] addr1,
input [4:0] addr2,
input [4:0] addr3,
input rd1,
input rd2,
input wr1,
input [31:0] wr_data,
output reg [31:0] rd_data1,
output reg [31:0] rd_data2
);

reg [31:0] registers[31:0];
logic [31:0] next_rd_data1, next_rd_data2, next_wr_data;

always_comb begin
    if (addr1 == 0)             next_rd_data1 = 0; // read register zero return zero
    else if (addr1 == addr3)    next_rd_data1 = wr_data; // read and write at the same time, return written value
    else                        next_rd_data1 = registers[addr1]; // normal register read
    
    if (addr2 == 0)             next_rd_data2 = 0;
    else if (addr2 == addr3)    next_rd_data2 = wr_data;
    else                        next_rd_data2 = registers[addr1];
    
    if (addr3 == 0)             next_wr_data = 0;
    else                        next_wr_data = wr_data;
end


always_ff @ (posedge clk) begin
    // Single Write Port
	if (wr1) registers[addr3] <= next_wr_data;
	
    // Dual Read Port
    if (rd1) rd_data1 <= next_rd_data1;
    if (rd2) rd_data2 <= next_rd_data2;
	
end

endmodule : RegisterFile
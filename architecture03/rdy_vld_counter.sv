/* 
 * Module `rdy_vld_counter`
 * 
 * It uses the ready valid interface and it's a 
 * counter. At the sampling edge while valid is 
 * high, it starts counting. After reaching the 
 * desired count, it will raise reached signal. 
 * That is, from valid high to reached high will 
 * totally includes desired amount of clock period. 
 * 
 * For example, if the desired amount is one, then 
 * the reached signal will be high at the next rising  
 * edge.
 */

module rdy_vld_counter(
    input clk,
    input rst,
    input [7:0] counter_until_this,
    input counter_vld,
    output counter_reached,
    output [7:0] counter_counter
    // output counter_rdy
);

reg [7:0] target;
logic [7:0] next_target;

reg [7:0] counter;
logic [7:0] next_counter;
assign counter_reached = target == counter;// && !counter_vld;
// assign counter_rdy = next_target <= next_counter;

always_comb begin : nextTargetBlock
    if (rst || counter_reached) begin
        // next_target = 0;
        next_counter = 0;
    end
    else begin
        // next_target = target;
        next_counter = counter + 1;
    end

    if (rst) begin
        next_target = 0;
    end
    else if (counter_reached) begin
        if (counter_vld) begin
            next_target = counter_until_this;
        end
        else begin
            next_target = 0;
        end
    end
    else begin
        next_target = target;
    end
    // else if (counter_vld) begin
        // next_target = counter_until_this;
        // next_counter = 1;
    // end
    // else begin
    //     // next_target = target;
    //     next_counter = counter;
    // end
end

always_ff @( posedge clk ) begin : counterBlock
    target <= next_target;
    counter <= next_counter;
end


endmodule : rdy_vld_counter




module rdy_vld_counter_tb();

reg clk = 0;
reg rst = 0;
reg [7:0] counter_until_this = 0;
reg counter_vld = 0;
wire counter_reached, counter_rdy;

always begin
	#5 clk = ~clk;
end

rdy_vld_counter rdyVldCounter(.*);

initial begin
    #5;
    #10 rst <= 1;
    #10 rst <= 0;

    #10 counter_until_this <= 0; counter_vld <= 1;
    #10 counter_vld <= 0;
    #10;

    #10 counter_until_this <= 1; counter_vld <= 1;
    #10 counter_vld <= 0;
    #20;

    #10 counter_until_this <= 3; counter_vld <= 1;
    #10 counter_vld <= 0;
    #50;
    
    #10 counter_until_this <= 5; counter_vld <= 1;
    #10 counter_vld <= 0;
    #80;

    #10 counter_until_this <= 3; counter_vld <= 1;
    #10 counter_until_this <= 5; counter_vld <= 1;
    #10 counter_vld <= 0;
    #80;

    #10 $stop;
end

endmodule : rdy_vld_counter_tb
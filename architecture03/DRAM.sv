
/* 
 * Module `rdy_vld_dram`
 * 
 * It uses the ready valid interface and it's a 
 * dram. It has a input signal for read or write.
 * It has ready signal for getting data from cache. 
 * It has valid signal for sending data to cache. 
 * It has address input for reading or writing. 
 * It has data output for sending data to cache. 
 * It has data input for receiving data from cache. 
 */

module DRAM #(
parameter DATA_WIDTH=8,
parameter BLOCK_SIZE = 32
)
(
input clk,
input rst,
input dram_is_rd,
input [31:0] dram_op_address,

output dram_rdy,
input cache_vld,
input [DATA_WIDTH-1:0] dram_store,

input cache_rdy,
output dram_vld,
output logic [DATA_WIDTH-1:0] dram_load
);
// localparam BLOCK_SIZE = 32;
//parameter LATENCY = 20;
parameter LATENCY = 4;
reg [DATA_WIDTH-1:0] dmem [63:0];

reg _is_rd;
reg [31:0] _address;


logic [7:0] counter_until_this;
logic counter_vld;
wire counter_reached;
wire [7:0] counter_counter;
// wire counter_rdy;
    // input [7:0] until_this,
    // input vld,
    // output reached,
    // output rdy
rdy_vld_counter rdyVldCounter(.*);

reg [7:0] state;
logic [7:0] next_state;

always_comb begin : loadStoreHandling

    counter_until_this = 0;
    counter_vld = 0;
    next_state = state;
    
    if (rst) begin
        next_state = 0;
    end
    else if (state == 0) begin
        if (cache_vld) begin
            counter_until_this = LATENCY - 1;
            counter_vld = 1;
            next_state = 1;
        end
        // else begin
        //     counter_until_this = 0;
        //     counter_vld = 0;
        //     next_state = state;
        // end
    end
    else if (state == 1) begin
        if (counter_reached == 1) begin
            counter_until_this = BLOCK_SIZE;
            counter_vld = 1;
            next_state = 2;
        end
        // else begin
        //     counter_until_this = 0;
        //     counter_vld = 0;
        //     next_state = state;
        // end
    end
    else if (state == 2) begin
        if (counter_reached == 1) begin
            counter_until_this = 0;
            counter_vld = 0;
            next_state = 0;
        end
        else begin
            if (_is_rd) begin
                dram_load = dmem[_address + counter_counter];
            end
            counter_until_this = 0;
            counter_vld = 0;
            next_state = state;
        end
    end
    // else begin
    //     next_state = 0;
    // end
end

always_ff @( posedge clk ) begin : loadStoreSequential
    state <= next_state;
    if (state == 0 && cache_vld) begin
        _is_rd <= dram_is_rd;
        _address <= dram_op_address;
    end

    if (state == 2 && !_is_rd) begin
        dmem[_address + counter_counter] <= dram_store;
    end
end

// reg [7:0] delay_counter;
// logic [7:0] delay_counter_next;

// wire is_read_write = dram_signal == SIG_READ || dram_signal == SIG_WRITE;
// wire dram_busy = is_read_write && delay_counter >= 0 && delay_counter < LATENCY;
// assign dram_ready = !dram_busy;

// logic [DATA_WIDTH-1:0] dram_write_next;


/*


// ------------------------ DRAM write ------------------------ 
always_comb begin
    if (delay_counter == LATENCY && dram_signal == SIG_WRITE)
        dram_write_next = dram_write_data;
    else if (delay_counter > LATENCY && delay_counter < LATENCY + BLOCK_SIZE && dram_signal == SIG_WRITE)
        dram_write_next = dram_write_data;
    else
        dram_write_next = dmem[dram_addr_wr];
end

// ------------------------ DRAM read ------------------------ 
always_comb begin
    if (delay_counter == LATENCY && dram_signal == SIG_READ)
        dram_result = dmem[dram_addr_rd];
    else if (delay_counter > LATENCY && delay_counter < LATENCY + BLOCK_SIZE && dram_signal == SIG_READ)
        dram_result = dmem[dram_addr_rd];
    else
        dram_result = 0;
end

always_comb begin
    if (rst) begin
        delay_counter_next = 0;
    end
    else if (delay_counter == 0) begin
        if (dram_signal == SIG_READ || dram_signal == SIG_WRITE) begin
            delay_counter_next = 1;
        end
        else begin
            delay_counter_next = 0;
        end
    end
    else if (delay_counter > 0 && delay_counter < LATENCY) begin
        delay_counter_next = delay_counter + 1;
    end
    else if (delay_counter == LATENCY) begin
         delay_counter_next = delay_counter + 1;
    end
    else if (delay_counter > LATENCY && delay_counter < LATENCY + BLOCK_SIZE) begin
         delay_counter_next = delay_counter + 1;
    end
    else if (delay_counter == LATENCY + BLOCK_SIZE) begin
         delay_counter_next = 0;
    end
    else begin
        delay_counter_next = delay_counter;
    end
end

always_ff @(posedge clk) begin
    delay_counter <= delay_counter_next;
    dmem[dram_addr_wr] <= dram_write_next;
end
*/


endmodule : DRAM
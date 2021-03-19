# Arch#3 Notes

This is Architecture #3 development notes.

This architecture model will focus on the memory hierarchy. Double core, pipelined processor.

# Breif Cycle Outline

At first clock edge, instruction becomes available.

In the period after, decode immediate, check whether we need to read register file, and read register file.

At the second clock edge, operands and immediates are available.

In the period after, execute result.

At the third clock edge, results are available.

In the period after, read memory if needed. 

At the fourth clock edge. Memory read results ready. Or the execution result if no memory read.

In the period after, write results to register file.

# Memory 

Currently after the third clock edge. The data memory module will give signal to freeze the cpu. So the fourth clock edge won't come until the data memory unfreeze the cpu. We want to put a cache inbetween data memory and the rest of the CPU. 

So after the third clock edge, the cache needs to freeze the CPU. In this period, we need to check the cache block to see whether it's valid. We need to check whether the tag of the block matches the requested address. If both are true, we have a hit, use the cache data. Unfreeze the cpu. 

If it's a miss, tell the memory module to go from idle to start working. So the state machine in data memory will move to working state at the next cycle.

For load, the memory result will become available at clock edge. It will be a wire going straight from data memory module, pass cache, and arrive at CPU. It is unrealistic to have data from DRAM to be immediately available in one CPU clock cycle, from off-chip to on-chip. But we don't need it to be right now, we can model the delay of it using the state machine LATENCY parameter. We can use that single LATENCY parameter to encapsulate all the details of the memory controller and DRAM. 

There is a bug in data forwarding. For instruction(maybe addi) immediately following the load. Load will be available at the fourth clock edge while the instruction addi wants to complete at the third clock edge. So while we are processing the addi which needs the load result, the load instruction has not finished yet. We have to put a NOP in there.

We can check it in the Decoding stage, just after the first clock edge. If the current instruction need something in next instruction rd. And next instruction is Load. Pause and put a NOP in there. 

We are going to skip this for now and fix it by manually adding a NOP in the machine code. We will implement the hardware to handle it later.

We got a problem. The simulator is not doing what I think it should be doing. There are combinational logic in always_comb statement, they are suppose to change the exe_result_next to 0x40. But it didn't. 

My stuff runs fine in ModelSim. I guess it's time to jump ship to ModelSim. Xilinx Vivado supported me well enough through the past years, rest in peace. Hopefully I won't be coming back crying about how hard and frustrating ModelSim is.

So we have a problem with the cache. Right now, the cache is transparent. It pass the Store to the DRAM and then pass the Load to the DRAM. The part where the cache saves the result of the store is missing. 

Now the cache actually saves the data from DRAM and execution unit. And the current cycle count is 18.

Right now, the cache only save one word from DRAM, we want to fetch the whole block, which is 8 words or 32 bytes. We will need a state machine. The DRAM need to support burst mode, transfer one block at a time. 

The delay_counter in DRAM needs to handle more states. While it's in those transfer states, transfer data.

The combinational logic for dram_write_next needs to change. dram_write_data from the cache module will continously feed in data of the block. And dram_addr is an input from cache, so it will be controlled by the cache. 

Currently, the cache just assign the exe_result to the dram_write_data. We need to write the data from data cache. So we need a counter. When we received a load/store instruction, switch counter from idle(0) to working(1). Wait while DRAM not ready, if DRAM ready, start shifting addresses and record or write data. After block transfer completed, present the data to the CPU. 

DRAM do read and write bases on the SIG_READ and SIG_WRITE from cache. Need to keep those signal stable throughout the DRAM access.

DRAM changes are simple, make sure counter has more states, and make sure DRAM continously accepting data in those new states. And DRAM will have ready signal high during the data transfer. Also changed the data width to 8. So each read from DRAM will only return one byte.

The cache will wait while dram_ready is low. After dram_ready is high, the counter will transition to next state at the next clock edge.

Now, the Cache module has a counter, the counter will move to working state if there is a cache miss on load or store. If there isn't, the memory result will take the cache data and move on. The counter will move to state 2 when there DRAM is ready. Then the cache will write the data block to dram, or read data block from dram depends on the opcode. After the block operation is finished, the memory result will take the appropriate data bytes on read, the cache treat DRAM as Little Endian.

# Cache Write Strategy

There are a few cases we need to think about. When we have a LOAD instruction and cache hit. When we have a LOAD instruction and cache miss. When we have a Store instruction and cache hit. When we have a Store instruction and cache miss.

PLAN A
- When we have a LOAD instruction and cache hit. We just read from the cache.

- When we have a LOAD instruction and cache miss. Write old cache data if valid, tell the DRAM to read. Store DRAM data and present the data to CPU.

- When we have a Store instruction and cache hit. We just put the data in cache.

- When we have a Store instruction and cache miss. Write old cache data if valid, tell the DRAM to read data. Stroe DRAM data in cache and overwrite it.

PLAN B
- When we have a LOAD instruction and cache hit. We just read from the cache.

- When we have a LOAD instruction and cache miss. Tell the DRAM to read. Store DRAM data and present the data to CPU.

- When we have a Store instruction and cache hit. We write the whole block with new data to DRAM.

- When we have a Store instruction and cache miss. Tell the DRAM to read data. Stroe DRAM data in cache and write block with new data back to DRAM.

So PLAN A is 0, 2, 0, 2 and PLAN B is 0, 1, 1, 2. The number indicates the DRAM access time. PLAN B is optimized for reading while PLAN A is equal share in delay. It's possible to devise a PLAN that optimize for writing, but that would require a lot more change in hardware structure.

We will run with PLAN A for now.

The complexity of the cache module just increased... 

We need another state machine. Initially idle at state 0, if cache hit, we are fine, the combinational logic will handle it. If cache miss, if block valid, write the old data, after it finishes, read the new data block.

Our counter in the cache is actually half way there, we just need to add some more states. Right now, the cache module has state machine that signal the DRAM to write, wait for the latency to finish, and shoveling data to DRAM. We need more states that then tell the DRAM to read new data.

If we have a cache miss. If valid is true, we start from the beginning, if valid is false, we can skip the write part. If valid is true, going to working state(state 1). In there, we write the original data to DRAM. Then we load new data from DRAM.

Rough outline of cache is done. Now start debugging. AAAAAANNNNNDDDDD, first test case passssssssssssssed.

We need to find a way to initialize all valid bit to zero. And since we are using ModelSim now, let's try assert.

Ok, we can just declare Valid bits as one 128bit register not as memory. We can reset it by assigning zero. To get one bit high, we can use some bit manipulation to flip that bit:

```valid_next = valid | (1 << index_field);``` 
# Read after Load RAW

For the special case of RAW hazard, where there is a read after load. We need to insert NOP. We first check whether there is actually a RAW hazard for both RS1 and RS2, then we check if there is a load instruction been executed. If it is, we need to insert NOP(By the way, this is a lot of combination logic, we may need to have five stages after all). We also need a state machine, a counter. At the idling stage, we check for RAW hazard and generate the forwarding signals. If there is a RAW for load, we insert NOP and generate zero for the forwarding signals. We also need to handle the register file read signal generation. The read and address is from the instruction. We can change the instruction in the beginning, so we don't need to handle the rest. We also need to handle the PC, if we are inserting NOP, then PC needs to keep its original value. 

What if we get a freeze CPU? We want to PC to stay the same, exe_inst to stay the same, and forwarding signal to stay the same. In each stage of the counter, we can put a if statement to check freeze cpu, if freeze_cpu, we don't change state and keep the output value the same. 

Change of plan, the counter will go to one when there is a one step raw for LOAD. And the existing logic will take that as input and do their thing. So we can keep all the existing code without rewriting the whole thing. 

Everything works beautifully.


# Branching

Ok, branching. 

First of, what PC modifying instruction do we have? Branching instruction and jump instruction.

The result of those PC modification will be ready after the execute stage. So we have decode stage and execute stage. After execute stage, which is the third clock edge, we have our new PC ready.


So, the easiest design is to have stall when meeting a branching code. Unpause CPU when the branching code has been resolved.

The better design is to have branch take one path, and if predict wrong, roll back all changes. Take one path, we need to record that we are doing this, so we can roll back later. At the execute stage, before the third clock edge, we need to compare execute result with our prediction. If predication incorrect, flush the decoded instruction. Clock in NOP for the first flip-flop and execute state input flip-flop. 

Currently the Instruction memory is super simplified. At the clock edge when PC is clocked in, the instruction is immediately fetched. So everything is assumed to be happending at the clock edge, both PC ready and instruction fetch.

So after first clock edge, if it's a branch instruction. Then state machine next state is 1. Next PC is the predicted PC. At second clock edge, start executing branch. Near the end of the period, if branch result match with predication, next state is 0. Else, execute stage clock in NOP, next PC is the new PC.

Another state machine for the branch instruction one after another. If it's a branch instruction and first state machine is busy, if we didn't get a flush, do the same thing.

We need to consider if there are consequetive branch instructions.

The test vector would just be an assembly if statement. We will run through it and see if it produce the correct result. This is already been done, we have the test vectors from the previous architecture.

Right now, we are missing things for execute stage. We are missing the entire branch instruction execute, and write pc wires. Write PC wire will get calculated during the execute stage. The result will get clocked in into the decoder PC register in the next clock edge.

There are some logic in the decoder that's related to PC. We have reset, freeze_cpu and counter next. Reset is straight forward. Freeze cpu is for pausing the CPU for cache memory access. Counter next is for inserting NOP for read after load. 

We are really just having performance benefit of one clock cycle when doing prediction. The reading register file takes one cycle, then we have the next PC sorted out. Oh well, let's do it for completenss sake. 

So instead of having to calculate PC in decoder, we will always take value from the execute stage. And execute stage will always output +4 PC. It will output correct PC value if there is a branch or jump instruction.

We are missing the whole block that generate the newPC output. So this block will have if statements to check whether its a branch insturction(all its sub instruction BEQ, BNEQ, etc), or jump. And in the if statement, assign new appropriate PC. That new PC will be type logic, not wire or reg. Need to check ISA specification on the detail of branch and jump instruction. They may also want to store address in register file. Then we can also reference things from previous architecture. 

``` SystemVerilog
wire pc_offset = inst[15:32] // check the offset field in instruction
localparam true = 1'b1, false = 1'b0;
localparam NOP = 32'h0011010; // check the NOP instruction in RISC-V
wire predict = true;
wire [31:0] predict_PC = (predict == true) ? PC + pc_offset : PC + 4;
reg [31:0] predict_PC_saved;
wire is_branch = inst[6:0] == 7'b1011101;

wire pc_caculated; // coming from execute unit

logic [31:0] next_PC;

reg [7:0] state;
logic [7:0] next_state;
logic wrong_predication = (state == 1) && (pc_caculated != predict_PC_saved);

// ---------- below need some merging with existing code -----------
always_comb begin
    if (wrong_predication) begin
        next_inst_to_exe = NOP;
    end
    else begin
        next_inst_to_exe = inst;
    end
end
// ---------- above need some merging with existing code -----------

always_comb begin
    if (state == 0) begin
        if (is_branch) begin
            next_state = 1;
            next_PC = predict_PC;
        end
        else begin
            next_state = state;
            next_PC = PC + 4;
        end
    end
    else if (state == 1) begin
        next_state = 0;
        if (pc_caculated == predict_PC_saved) begin
            next_PC = PC + 4;
        end
        else begin
            next_PC = pc_caculated;
        end
    end
    else begin
        next_state = state;
        next_PC = PC + 4;
    end

end

always_ff @(posedge clk) begin
    predict_PC_saved <= predict_PC;
    state <= next_state;
    PC <= next_PC;

end


```

# Instruction Fetch stage

Maybe we should add a instruction fetch stage. It will fetch instruction from memory, just like the data memory stage. The program will reside near the top of the address space while heap is near the bottom of the address space. By top, I mean the address number is bigger. And they can even share the same cache.

# Do scripts

Do script is used for automated compiling and running simulation. I can pass in parameter to simulator. And in the system verilog code, I can create a module that will test on the parameter and run different test cases specified by the parameter. The module that test the parameter need to reside in the register file module or instruction memory module. Otherwise, readmem won't work.

Can we use bind to insert a module into register file? Yes, we can use bind to insert module into other module. But we can't use assertion. Assertion is not supported in the student edition of ModelSim. Covergroup is also not supported, it outright stops the simulation. Randomize is also not supported. We can use python to generate random test instructions. Need an ISA simulator first and cross checking with the Cornell one first.

Direct Programming Interface seems to be a possible path. We can can c function from system verilog and let the c function to handle the function coverage.

Or we can just write some system verilog code that will keep track of it. Using counter and such.

We can put verification code in completely separate files now, that's fantastic. Let's do that first, then we can do some magic to get some coverage.  

Actually, we can't initialize things in the separate file. For example, we can't initialize the instruction memory in verification file. We don't seem to have write access using bind. 

That means we can only put register file verification code in separate file. And the new counter code for coverage. Or, how about we just put the instruction memory module in verification file all together. 

We need to use $test$plusargs to automate the process of running different test cases, which means, we will not use macros to setup the test cases. We will move the instruction memory to verification module, since there isn't much in there anyway. But we will create test module which is binded to register file to check results, and count cycles. 

We are going to write a Python script which will generate random tests and it will generate test ground truth. And it will parse log file output from simulation to get coverage detail. We can create a counter with string parameter. We are going to create a counter and tell it what to keep track off. And it will printout the details in the end. Then python will parse it and write a report.



# System Verilog Class

Here is the syntax for it: https://www.chipverify.com/systemverilog/systemverilog-class

Ok, we hope to generate test cases and check architecture using the class construct. So we don't need to go through python and tcl scripts. 

To generate test cases is kind complicated. Assembler is ok, but compiler is much more complicated. Maybe we can just write an assembler and generate random scripts of assembly code and run that. So we are not having an actual usable, or existing program. The random scripts actually should be better. As it will exercise chip that human programmer will never do. 

The checker part is easier. It's just an ISA simulator. It's quite similar to the ALU or datapath. But it doesn't have all the control signals. It's purely sequential code. Operate assembly instructions line by line. 

It's interesting to think about. The only difference between our C++ like ISA simulator and System verilog architecture is the degree of parallism. We can do ISA simulator style in System Verilog, but it will be slow, low throughput. As we are waiting for decoding, read register file, datapath execute, memory access and write back all for one instruction. 

We can tolerate the low parallism of ISA simulator, as the primary goal of it is to be correct. 

We first need to generate random assembly code, then we write the checker for it.

Let's first do one or three assembly instruction. Generate random ordering of them, random amount of them, each having random arguments.

Then create a checker. Each instruction should just be a function, or a case in a big switch statement. 


# side notes #5
check the class feature of system verilog, we can implement the assembler and checker in there.

# side notes #4

I found something on PCIe : https://www.cl.cam.ac.uk/~djm202/pdf/specifications/pcie/PCI_Express_Base_Rev_2.0_20Dec06a.pdf

PCIe is kind complex and hard protocol, also USB. It will need a lot of time. There are some simplier protocol like AXI.

# side notes #3

electromagnetic field solver is instersting. Maybe use cuda to accelerate it. Some interesting Cuda Application: https://www.nvidia.com/en-us/gpu-accelerated-applications/

Maybe use DirectX instead, it has more support, and more tools available from Microsoft. Trying to build on existing tools without knowledge from the previous tool developer is going to be harder than starting from scratch.

Cuda seems to be good too... But I don't have Nvidia card, so we will stick with directx for now.


# Side notes #2

Try system verilog coverage function. As a start, we can put coverage on the instructions. So we can see how much instructions are covered. Then we can put coverage on register file and DRAM to see how much regions of memory or register file is covered. Those are not very insteresting. As they can be acheived with the assertion. More interesting case would be coverage for all the hiden wires in the module. State machine states coverage. Make sure to exercise every part of the design. Use illegal bin in coverage to make sure no invalid signals. Coverage seems to need interface and class language construct.

Assertion binding, from online document, this is the way to separate assertion and verification code from the design code.

# Off the side notes #1
Try ModelSim PE SE, it has assertion support, supposedly better than Vivado simulator.

https://www.mentor.com/company/higher_ed/modelsim-student-edition

temporal logic assertions

jaspergold formal verification
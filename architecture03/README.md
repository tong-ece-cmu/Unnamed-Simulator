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

# Do scripts

Do script is used for automated compiling and running simulation. I can pass in parameter to simulator. And in the system verilog code, I can create a module that will test on the parameter and run different test cases specified by the parameter. The module that test the parameter need to reside in the register file module or instruction memory module. Otherwise, readmem won't work.

Can we use bind to insert a module into register file? Yes, we can use bind to insert module into other module. But we can't use assertion. Assertion is not supported in the student edition of ModelSim. Covergroup is also not supported, it outright stops the simulation.

Direct Programming Interface seems to be a possible path. We can can c function from system verilog and let the c function to handle the function coverage.

Or we can just write some system verilog code that will keep track of it. Using counter and such. 


# side notes #4

I found something on PCIe : https://www.cl.cam.ac.uk/~djm202/pdf/specifications/pcie/PCI_Express_Base_Rev_2.0_20Dec06a.pdf

# side notes #3

electromagnetic field solver is instersting. Maybe use cuda to accelerate it. Some interesting Cuda Application: https://www.nvidia.com/en-us/gpu-accelerated-applications/


# Side notes #2

Try system verilog coverage function. As a start, we can put coverage on the instructions. So we can see how much instructions are covered. Then we can put coverage on register file and DRAM to see how much regions of memory or register file is covered. Those are not very insteresting. As they can be acheived with the assertion. More interesting case would be coverage for all the hiden wires in the module. State machine states coverage. Make sure to exercise every part of the design. Use illegal bin in coverage to make sure no invalid signals. Coverage seems to need interface and class language construct.

Assertion binding, from online document, this is the way to separate assertion and verification code from the design code.

# Off the side notes #1
Try ModelSim PE SE, it has assertion support, supposedly better than Vivado simulator.

https://www.mentor.com/company/higher_ed/modelsim-student-edition

temporal logic assertions

jaspergold formal verification
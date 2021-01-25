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



# Off the side notes
Try ModelSim PE SE, it has assertion support, supposedly better than Vivado simulator.

https://www.mentor.com/company/higher_ed/modelsim-student-edition

temporal logic assertions

jaspergold formal verification
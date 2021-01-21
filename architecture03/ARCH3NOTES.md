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

# Off the side notes
Try ModelSim PE SE, it has assertion support, supposedly better than Vivado simulator.

https://www.mentor.com/company/higher_ed/modelsim-student-edition

temporal logic assertions

jaspergold formal verification
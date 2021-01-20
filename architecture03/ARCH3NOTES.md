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

# Off the side notes
Try ModelSim PE SE, it has assertion support, supposedly better than Vivado simulator.

https://www.mentor.com/company/higher_ed/modelsim-student-edition

temporal logic assertions

jaspergold formal verification
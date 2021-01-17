# Architecture No.2

This the design note for architecture #2

This will use issue out of order architecture with researvation stations.

Will have multiple function units.

Not supporting multiplier right now.

## The first set of Flip-flops stores the instruction

There are instructions coming in. At the positive edge, the flip-flops clocks in the next instruction. After the flip flop stores the instruction, the instruction signal start propagating through the combinational logic.

If it's an Add function unit function and Add function unit reservation station is free, then place this instruction into the reservation station.

A big And gate to check whether all reservation entries are valid, if they are, tell the instruction register to not clock in the next instruction.

Ready the opcode for the reservation station flip-flop. Each reservation station entry will have a valid bit to signal it stores a valid entry that will be executed in the future. If entry0 is not valid, store next in entry0, else if entry1 is not valid, store next in entry1, else if ...

DeMultiplexer has selection bits that choose which output will gets the input. The one didn't get the input will see high impedence.

The chain of if statement will be an unbalanced-tree of demutiplexers. The instruction opcode will travel through the wire of those demutiplexers and finally reaches the input of the flip-flops of the desired reservation entry. Or reach nothing if station is full.

The register file will have flip-flops(marker) that will keep track which register will be written in the near future, beacause it's the write back target of one of the instructions in the reservation station. We use our destination operand to get a one to the approporate field of the marker, to mark it so future instruction will see it. And there is a multiplexer in the end to present marker original content, if we can't get a reservation station entry. The marker will store the reservation station entry ID. We will have five entry for add unit, five entry for load and store unit, so that's 10 IDs needed. We will use ID 0 as unmarked. And ID 1-10 as valid entry ID. ID will be 4 bit.

We will also present our future reservation station entry number to the marker flip-flop input, to get clocked in at the next positive clock edge. If entry0 is not valid, present ID of entry0, else if entry1 is not valid, present ID of entry1, else if ... . And there is a multiplexer in the end, if reservation station is full, present the marker original conent, as we wait for reservation station to free up entries.

If our source operands is marked in marker. We will get its reservation station entry ID to our reservation station operand entry. We will select the proper mark in marker using our source operand field in the instruction and a multiplexer. We will select the proper entry ID using source operand and multiplexer. If marked, present this ID to our reservation station entry. 

We will record this mark and unmarked info in our reservation station entry using Flip-flops. If marked, present a one, if unmarked, present a zero. We will also store the info about where our source operand value will come from. If marked, we will store the ID of which reservation station entry will produce our operand. If unmarked, we will store the register value.

We use source operand field to select which register, if unmarked, will start reading and present the value to our reservation station entry to be clocked in at the next clock edge.

## The second set of flip-flops, reservation station info, register file marker

One of the reservation station invalid entry will get populated. It will store mark/unmarked bit(we need to wait for other function unit or directly read from register). It will store where source operand will come, reservation entry ID if marked, real register value from register file if unmarked. It will also store the opcode from instruction. 

The register file marker will get update on its value, about our destination register and our reservation entry ID. Now start the next set of combinational logic.

<!-- The reservation station flip-flop clocks in the reservation. The flip-flops need the operands of the instruction. It also needs the opcode for choosing the proper execution. It needs the valid bits for the two operand to see whether they are available. Whether I will be busy in the next cycle. -->

One reservation entry is ready if both operands are unmarked. 

If the entry0 is ready, start working on it using its opcode field and the operand values in the reservation station, else if the entry1 is ready, start working on it using its opcode field and the operand values in the reservation station, else if ... . The result of the calculation will be presented to set of flip-flops, which will record it at the next edge of the clock. 


Load and store unit is the same. Some entries may not be ready due to operand not been calculated. Load early or late doesn't matter, all interested reservation station entry all are listening for its boardcast.

For the load and store unit there is a flip-flop to signal when the data is ready. The valid bit will clock in at the same time as the data, and the ID field. Arithmatic unit doesn't need it as all instruction is one clock cycle.

If reservation entry is not ready, some operands are marked. We need hardware to handle signal from common data bus and receive its data. If common data bus boardcast a reservation entry ID that matches with our operand source. Present its signal to our operand field and get it clocked in at the next clock edge. The common data bus will have a ID bus and a data bus. The ID bus will propagate reservation entry ID, the data bus will propagate its data value. If our source operand entry is marked and entry ID bus value matches with our source operand ID, then present the data bus to our source operand flip-flop to get clocked in. Else, don't change the source operand field. Also, if source operand entry is marked and common data bus matches with our ID, present zero to our mark, else don't change reservation station entry marker value.

Register file will also check the common data bus. If the common data bus ID matches with one of the marker ID and that one is valid mark, then remove valid mark and write common data bus value to register file. If the current issuing instruction need it, present it.

## The third set of flip-flops, function unit execution result

Result of function unit are stored into flip-flops. Load and Store unit data valid flip-flop is set.

If load and store unit has data, and there is a valid entry ID, boardcast it on common data bus. Else if arithmatic unit has data, and there is a valid entry ID, boardcast it on common data bus. Any thing above zero is a valid entry ID. 

There are mutliple function unit that tries to use the common data bus. If the result wasn't able to boardcast this cycle. We need hold on to it and wait for the next cycle. The function result will need to keep its value. The reservation station entry been executed need to keep its value.

We will have a wire going to exe combinational logic block and issue combinational logic block to tell them the result wasn't broadcasted. 


# System C Implementation Issues

System C syntax is complicated with hard to find documentation. Right now, I'm working on the first set and second set of flip-flops and the combinational logic inbetween. There suppose to be three modules, Instruction fetch unit that gives instruction(The first set of flip-flops), Reservation Station that takes in instructions(The second set of flip-flops), and Register file(Supply data to reservation station, using instruction). 

The combinational logic should ask the register file to read data out and send it to reservation station to get clocked in. This transfer of data back and forth all happens in one cycle. We can have four module, IF, RF, Reservation Station, Combinational logic. And have combinational logic wait on negative edge of the clock and other wait on positive edge of the clock. Combinational logic suppose to have the whole clock cycle to process it, but it's systemc, so we can change it a little bit. We just need the simulation to run correctly to some degree.

There are so many wires and signals, 32 register file data line, and ID tags. We can use sc_vector < sc_in \<unsigned\> > to create a vector input or output. Nice.

A few minutes later ...

Surprise! The vector syntax doesn't work. I'm pretty sure I need to initialize the vector somewhere. But I don't know how. The VCD file format doesn't look too complicated. 
\
\
Plan B.
We can use python to generate those vector declarations. For reservation station, we need 6 wires for each entry, rs1, rs2, entry valid, rs1_mark, rs2_mark, and instruction. We have 5 entry so far, so that's 30 wires. We are modeling the flip-flop in this module, so we need seperate wire for flip-flop input and output. So that's a grand total of 60 wires. 

So the flip-flop will have a big block of code that will just do (private_entry = sc_in) and (sc_out = sc_in) for each wire. 

Let me summary, there are three blocks of code that we need to generate. The declaration block, and assignment blcok for the reservation flip-flop module, combinational logic input declaration. The declaration block should have 60 lines. The assignment block should have 60 lines, 6 wire per entry, 5 entry, 2 assignments per entry. And combinational logic input declaration should have 60 lines. 

There are more, in the main module, we need to connect those two modules together. We need to create the connection wires, 60 lines. Each module need to connect to the wire, two module with 60 line each, 120 lines.

Register file is another beast. 32 registers, each will have next and output, so that's 64 lines. And there is the ID field for each register, with input and output, 64 lines.

I'm going to ask around online. While waiting for an answer, I'm going to do some planning on the cache structure and assembler.

Someone give this guy a medal, he helped me figure out the vector syntax.
https://stackoverflow.com/users/5942006/systemcpro

https://stackoverflow.com/questions/35425052/how-to-initialize-a-systemc-port-name-which-is-an-array/35535730#35535730



All the combinational logic has to be in one module and the flip-flops in their seperated module. If we seperate the combinational logic into different modules and coalesse them with the flip-flops modules, then the order of simulator event will be a problem. At the clock edge, the simulator call the flip-flops module coroutines and some combinational logic will process the output using the old value of the other flip-flops.

The instruction fetch unit will take one cycle to fetch instruction. Meaning, there is a 32-bit flip-flop that will record the next PC value, and it will take a cycle to fetch the instruction. So the instruction pointed by the pc will appear on the wire on the next clock edge. If we don't do this, we record the PC at the clock edge and after the clock edge, the correct instruction just appeared on the wire. That's not normal, natural, or correct.

I used a circular buffer to implement it. It's possible to use a small variable to easily implement this latency, but we need to think about the future. In the future, we may want to model an Instruction Cache, and there will be a lot more latency that can't be modeled using small variable.


The second block of combinational logic. They need to find one entry to execute.


When pressing reset, while reset is high, the rising clock edge should get zero on PC and NOP. After the reset is low, next rising clock edge should get PC incremented, and still get NOP. Then at the next clock edge, PC increment again and the instruction should be the previous PC fetch.


For each register, it needs to check common data bus. 
read 0, march ID
If on register 0, clear ID marker, if needed by other instruction, present 0.

Else if the common data bus ID matches and valid, it will clear ID marker and write new value from common data bus. If it's needed by other instruction for read. Present the new value. If it's needed by other instruction for write, overwrite ID marker and keep its value. 

Else if the common data bus ID doesn't match or not valid, keep its marker value and register value. If it's needed by other instruction for read, if marked, present ID, if not marked, present register value. If needed for write, overwrite ID marker and keep its value.

We got a problem. The events of the simulator are triggered sequentially. So when I put different combinational logic in different module and have all of them change on negative edge of clock, the behavior is wrong. There are 3 blocks of combinational logic and they are inter-dependent. The first block will generate some signals that's needed by the second block, the second block will generate something needed by the third block. And the third block will loop-back, generating something needed by the first block. They are realistic and can be implemented by the transistor and wire. But it's not obvious how to get the simulator to do it. The issuing stage will need to read the common data bus values and fetch operand from register files.

There is something called next_trigger and SC_METHOD. This sounds like a good place to put in combinational logic. 
https://forums.accellera.org/topic/6004-sc_method-and-next_trigger-diagnostics/

But next_trigger will complicate things. If we marked an register for destination. Then a common data bus signal comes in and overwrite that destination with data. Just because the event scheduler called the common data bus signal late. We then lost our mark on the destination and mess up all the insturction after it.

It's better to have all combinational logic in one module.




So, we have a big pile of code. Goal of the day to debug the code and pass as many test cases as possible. 

1. The instructions from instruction fetch unit are all correct.                            CHECK.
2. At 2ns, First Reservation station entry get proper instruction.  CHECK.
3. At 2ns, First Reservation station entry get proper valid bit.    CHECK.
4. At 2ns, First Reservation station entry get proper rs1 operand.  CHECK.
5. At 2ns, First Reservation station entry get proper rs1 marker.   CHECK.
6. At 2ns, First Reservation station entry get proper rs2 operand and marker.   CHECK.
7. At 3ns, First entry get executed with proper ID and result.   CHECK.
8. At 4ns, First entry get write back to register. CHECK.
9. At 3ns, Second Reservation station entry get proper instruction. CHECK.
10. At 3ns, second entry get proper valid bit, rs1, rs2 operand and marker. CHECK.
11. At 4ns, second entry finished executing, recorded with proper ID(2) and result(3). CHECK.
12. At 5ns, second entry finish writing back to register(write 3 to register 1). BAD.

Actually, we are good. The register is now waiting for the result of the first entry again. Because first entry just got its next instruction and it's going to overwrite the second entry destination register. The reservation station of the first entry recorded the data on the common data bus.

13. At 4ns, First entry get the third instruction. CHECK.
14. At 4ns, First entry get proper valid bit, rs1, rs2 operand(2 and 0) and rs1, rs2 marker(1, 0). BAD.

We don't need rs2 but our operand is still marked. It may halt the execution later. FIXED.

15. At 5ns, First entry, third instruction finished executing, recorded with proper ID(1) and result(4). BAD.

It didn't happen. Something is wrong. Actually, it's good. We are waiting on reservation station entry 2. And it just finished at 4ns and finished write back at 5ns. So right now, our operands are all unmarked.

16. At 6ns, First entry, third instruction finished executing, recorded with proper ID(1) and result(4). CHECK.
17. At 7ns, First entry, third instruction write back to proper reservation station entry(second entry). CHECK.

18. At 5ns, Second entry get the forth instruction. CHECK.
19. At 5ns, Second entry get proper valid bit, rs1, rs2 operand(1 and 0) and rs1, rs2 marker(1, 0). CHECK.
20. At 7ns, Second entry get result from first entry. rs1(4) and unmarked. CHECK.
21. At 8ns, Second entry forth instruction finished executing, recorded with proper ID(2) and result(6). BAD.

Somehow the fifth instruction is executed before the forth instruction. At 4ns, the second entry finish executing the second instruction. At 5ns, function unit result didn't change, still holding second entry result, because first entry just got its data from common data bus. At 5ns, second entry got the forth instruction and told the register1 to wait on its data. But also at 5ns, the fifth instruction is issued and it needs register1. It sees register1 is waiting on second entry and common data bus is boardcasting second entry result, then everything is wrong. The fifth instruction mistakenly took the old value of the second entry. We need to clear function unit result when it's idling. 

The result is still wrong. It's giving the first entry result, the first entry is on NOP, so result is zero. And the valid bit for the second entry is turned off. Found it, the issue logic assumed all valid entry will be executed, but in reality, only one entry will be executed. That's the reason the valid bit for second entry is off, even though it wasn't been executed.

So at 8ns, the NOP in first entry gets executed first. In this architecture, the instructions in reservation station are executed base on their entry number. Lower entry number gets executed first. So this is expected. FIXED.

22. At 9ns, Second entry forth instruction finished executing, recorded with proper ID(2) and result(6). CHECK.
23. At 10ns, Second entry forth instruction write back to proper reservation station entry(third entry). CHECK.

24. At 6ns, Third entry get the fifth instruction. CHECK.
25. At 6ns, Third entry get proper valid bit, rs1, rs2 operand(2 and 0) and rs1, rs2 marker(1, 0). CHECK.
26. At 10ns, Third entry get executed value from second entry. rs1(6). CHECK.
27. At 11ns, Third entry fifth instruction finished executing, recorded with proper ID(3) and result(7). BAD.

The function unit is permanently occupied with NOP in the first and the second entry. We can use some special NOP to force the NOP to wait on the last instruction. Or we can implement a some hardware to execute entries in first in first out order. Implement some hardware is the better choice here.

We need know which entry to execute next. We can have a shift register, or a normal block of memory with looping index. Either way, we need some flip-flops to hold the history. Every cycle, we remove one instruction from the reservation station, and write-in a new instruction from the instruction fetch unit. Think of an array, there is a pointer points to the start of the FIFO and a pointer points to the end of the FIFO. To add, we write to the end of the FIFO and increment the end pointer. To remove, we read the start of the FIFO and increment the start pointer.

Or we can have a shift register with end pointer. We write at the end and increment end pointer. We read at index zero and shift all memory and decrement end pointer. We will do this.

Add five set of flip-flops, FIFO, maybe in the reservation station module. Add a set of flip-flops to record index. Each time an entry been populated with instruction, store entry number in FIFO at index and increment index. Actually, each cycle, we will execute one instruction and populate one instruction. Shift and write at the same time is difficult.

Start over. We will have five set of flip-flops, FIFO. And two sets of flip-flops to record start and end index of FIFO. This won't work. We are actually not taking the start of the FIFO every time. Sometimes, we will take things in the middle. 

Start over. Each entry will have a priority counter. Zero means lowest priority. Five means the highest priority. Each cycle, we will take the highest priority entry. Initially, the highest priority is zero. We put in one instruction, it will have priority one and the highest priority is one. We put in another instruction, it will have priotiry one and all other instructions get their priority incremented. And the highest priority increment as well. If we remove one instruction, all instruction that has lower priority get incremented. 


if we are executing
    put new entry in end pointer - 1
    end point stay
else
    put new entry in end pointer
    end pointer increment

if reset
    clear fifo
    last = 0

if entry[fifo[0]] valid and ready
    execute
    shift last four register
    fifo[0] = last == 1 ? new : fifo[1]
    fifo[1] = last == 2 ? new : fifo[2]
    fifo[2] = last == 3 ? new : fifo[3]
    fifo[3] = last == 4 ? new : fifo[4]
else if entry[fifo[1]] valid ready
    execute
    shift last three register
    fifo[1] = last == 2 ? new : fifo[2]
    fifo[2] = last == 3 ? new : fifo[3]
    fifo[3] = last == 4 ? new : fifo[4]
else if entry[fifo[2]] valid ready
    execute
    shift last two register
    fifo[2] = last == 3 ? new : fifo[3]
    fifo[3] = last == 4 ? new : fifo[4]
else if entry[fifo[3]] valid ready
    execute
    shift last one register
    fifo[3] = last == 4 ? new : fifo[4]
else if entry[fifo[4]] valid ready
    execute
    fifo[4] = new
else
    none executed
    if last == 5
        pause
    else
        fifo[last] = new
        last ++

This is so complicated. How about we just change the order of checking instructions. So right now, start from entry0 to entry4, we check each to see whether it's valid and ready. If it is, we will execute it. This creates the problem if entry0 and entry1 are always valid and ready, we will stuck on executing those and never had a chance to execute other entry. The previous approach is to find which entry is the oldest entry and execute that first, it's complicated. In software, we need a priority heap, in hardware, it's non-trivial. Do we really need to do this to solve our problem? Our problem is execution stuck in entry0 and entry1. We will change the order we check those entries. Check 0-4, then 1-4-0, then 2-4-1, then 3-4-2, then 4-0-3, then 0-4.

WOW, it worked. This is exciting. I think this scheme is synthesisable in hardware. We have an input and we want some output, not sure how will the combinational logic look like, but the hardware should be able to implement it. The next thing is to implement the load and store unit.

# LOAD and Store Unit

So the first set of Flip-flops store the instruction. After the rising clock edge, those flip-flops stores the instruction that needs to go in an reservation station at the next clock edge.

Previously, we are just putting it into one of the ADD unit reservation station entries. We also read register file while at it. 

Now, we need to account for the load and store unit. If it's an load or store instruction. We still need to read register file, this will probably take one cycle. Then we need to calculate the address, another cycle. Then we put it in the load and store buffer, which is fifo, another cycle. 

The memory unit will have some sort of input. An address, read data, and write data. Also a valid bit, since memory will not give result in one clock cycle and it's not very predictable. The memory will have an array to store the data. There will be sets of flip-flops that stores the address, the write data, read signal, and write signal. At the positive clock edge, those things become available. We don't know what's actually going on in memory, we just want to model the delay. So there will be a state machine. If there read or write is high, start the delay, else stay in idle state. And record the address and write data. At the end of the delay, there will be a set of flip-flops to store the read data, and data valid bit. Can you pipeline a memory? Probably can, but we are not going to do it here.

So the memory unit will have flip-flops for receiving the read result from register. Next cycle, the result will be calculated and put into fifo buffer. Next cycle, the fifo buffer will present one instruction to the memory unit.

The memory unit will start the state machine if it detects a read or write, move away from the idle state at the next clock edge. Wait until it start loading data. It will start reading or writing to the data array. At the last clock edge, it read or write the last byte of data, and put the valid bit to high, to signal read complete or write complete. 

The load and store unit will have two sets of flip-flops. One for storing read result from register file. One for storing the memory address execution results. The second set will actually have five entries, so it can store five load and store instructions that's going to be executed when memory module is available. To make it simple, we are going to say we can accomandate five instructions. So that's five new ID for register file and reservation station to keep track of. 

Actually, it's possible that our source operands aren't available at the issue stage. But read and write out of order is not that trivial. We will leave it for now.

We need a shift register to implement the fifo. We need an ID generator to issue ID to the register file marker. The calculation of memory address needs to wait until its source operand is valid, or broadcasted on CDB. 

If there is a load and store. Check whether we have space in fifo. If there are space, get an ID, send that ID to register file. Read register file and send it to flip-flop. We will have a counter that keeps track of the end of fifo. If that is five, then we are full, else we have space. While reading the operand, increment the counter.

Next clock cycle if we have the operand ready, then we calculate the address and present it to the fifo. If not ready, we check the CDB, if that shows the data we needed, calculate. Else, if CDB only provide one operand, save it, else wait for next cycle. Put the busy flag while we are waiting. Can't take load or store instruction right now. 

Next clock cycle, if execution result is valid, put it in the fifo, at index counter - 1. 


Present the adress and data to the memory unit. At the clock edge, if counter is zero, do nothing, else if counter is one, check if counter is greater than zero. Then start reading the memory stored in index zero of the fifo. 

Next cycle, put the result in the result flip-flop, along with the valid bit. The CDB will handle it from there. Then shift the fifo for the next instruction. 


# Load an Store Unit Implementation Notes
Currently, the Add unit is taking all the instructions, that includes the load and store instruction. That's not right. The instructions are issued in the issue_combinational module. If the instuction is not a load or store instruction, put it in one of the instruction unit. 

Don't worry about delay for now. Assume the memory will get the data at the next clock edge. Make sure everything else is working, CDB, register file read and write.
































# Off the side idea
How about self-reconfigurable cache. Use LUT to control passgate which controls the wire for the cache address decoder. We can shift the tag field, index, and block offset field around. And change the configuration of the cache on the fly. Before each reconfiguration, we need to flush the cache, because the old address system is gone. We can monitor the cache access to change configuration on the fly. If we have 4kB cache, we monitor the recent 4kB access pattern. If they are all the same, then modify our cache configuration to optimize cache access. Keep track of which address bit changes the most, then put those into the block offset field.





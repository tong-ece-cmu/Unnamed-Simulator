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
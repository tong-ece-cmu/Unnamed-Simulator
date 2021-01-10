This the design note for architecture #2

This will use issue out of order architecture with researvation stations.

Will have multiple function units.

## The first set of Flip-flops stores the instruction

There are instructions coming in. At the positive edge, the flip-flops clocks in the next instruction. After the flip flop stores the instruction, the instruction signal start propagating through the combinational logic.

If it's an Add function unit function and Add function unit reservation station is free, then place this instruction into the reservation station.

A big And gate to check whether all reservation entries are valid, if they are, tell the instruction register to not clock in the next instruction.

Ready the opcode for the reservation station flip-flop. Each reservation station entry will have a valid bit to signal it stores a valid entry that will be executed in the future. If entry0 is not valid, store next in entry0, else if entry1 is not valid, store next in entry1, else if ...

DeMultiplexer has selection bits that choose which output will gets the input. The one didn't get the input will see high impedence.

The chain of if statement will be an unbalanced-tree of demutiplexers. The instruction opcode will travel through the wire of those demutiplexers and finally reaches the input of the flip-flops of the desired reservation entry. Or reach nothing if station is full.

The register file will have flip-flops(marker) that will keep track which register will be written in the near future, beacause it's the write back target of one of the instructions in the reservation station. We use our destination operand to get a one to the approporate field of the marker, to mark it so future instruction will see it. And there is a multiplexer in the end to present marker original content, if we can't get a reservation station entry.

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

If load and store unit has data, valid bit is set, boardcast it on common data bus. Else if arithmatic unit has data, valid bit is set, boardcast it on common data bus. The common data bus should have a valid bit to signal its data is valid. 
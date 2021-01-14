// UnnamedSystemC1.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <systemc.h>
#include <string>

class register_file : sc_module
{
private:
    unsigned REGISTER_COUNT = 32;
public:

    sc_vector < sc_out<unsigned> >  markerID_reg;
    sc_vector < sc_in<unsigned> >   markerID_next;

    sc_vector < sc_out<unsigned> >  registers_reg;
    sc_vector < sc_in<unsigned> >   registers_next;

    sc_in_clk 			clk;

    //Constructor
    SC_CTOR(register_file) : markerID_reg("markerID_reg", REGISTER_COUNT), markerID_next("markerID_next", REGISTER_COUNT), 
        registers_reg("registers_reg", REGISTER_COUNT), registers_next("registers_next", REGISTER_COUNT)
    {
        SC_CTHREAD(entry, clk.pos());
    }

    // Process functionality in member function below
    void entry() {
        //unsigned address1;
        //unsigned address2;

        while (true) {
            wait();
            for (unsigned i = 0; i < REGISTER_COUNT; i++)
            {
                markerID_reg[i].write(markerID_next[i]);
                registers_reg[i].write(registers_next[i]);
            }
        }
    
    }
};


//class data_path : sc_module
//{
//public:
//    sc_in<unsigned>  		dp_ctrl;  	// data path control signal
//    sc_out<unsigned> 		wr_data;  	// write to register file
//    sc_out<unsigned> 		wr_pc;  	// write to program counter
//
//    sc_in<unsigned> 		PC;  	    // program counter from control unit
//
//    sc_in<unsigned> 		rd_data1;  	// register file data input from read port 1
//    sc_in<unsigned> 		rd_data2;  	// register file data input from read port 2
//    sc_in<unsigned> 		immediate;  // immediate from control unit
//    sc_in<unsigned> 		in_bus;  	// receive data from outside, DRAM, etc
//    sc_out<unsigned> 		out_bus;  	// transmit data to outside, DRAM, etc
//
//    sc_in_clk 			clk;
//
//    //Constructor
//    SC_CTOR(data_path) {
//        SC_CTHREAD(entry, clk.pos());
//    }
//
//    // Process functionality in member function below
//    void entry() {
//
//        while (true) {
//            wait();
//
//            switch (dp_ctrl.read())
//            {
//            case 0b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37 )
//                wr_data.write(immediate.read() << 12);
//                break;
//            case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
//                wr_data.write((immediate.read() << 12) + PC.read());
//                wr_pc.write((immediate.read() << 12) + PC.read());
//                break;
//            default:
//                break;
//            }
//
//        }
//
//    }
//};
//
//class control : sc_module
//{
//public:
//    sc_in<bool>             rst;            // reset
//    sc_in<unsigned> 		inst;  	        // instruction for cpu
//
//    sc_out<unsigned>  		addr1;  		// address1 for register file port 1
//    sc_out<unsigned>  		addr2;  		// address1 for register file port 2
//    sc_out<bool>  			rd1;    		// register file read port 1 enable
//    sc_out<bool>  			rd2;    		// register file read port 2 enable
//    sc_out<bool>  			wr1;    		// register file write port 1 enable
//    sc_out<bool>  			wr2;    		// register file write port 2 enable
//
//    sc_out<unsigned>  		dp_ctrl;  	    // generate data path control signal
//    sc_out<unsigned> 		immediate;      // generate immediate from instruction to datapath
//    sc_out<unsigned> 		PC;  	        // keep track of program counter
//    sc_in<unsigned> 		wr_pc;  	    // calculated new program counter from datapath
//
//    sc_in_clk 			clk;
//
//
//    // Parameter
//    unsigned pc;
//    unsigned saved_inst;	 			    // Saved instruction
//    unsigned state;	 			            // control unit state
//    static const unsigned s0 = 0b00;
//    static const unsigned s1 = 0b01;
//    static const unsigned s2 = 0b11;
//    static const unsigned s3 = 0b10;        // Use Gray coding for states for more efficient synthesis
//
//
//    //Constructor
//    SC_CTOR(control) {
//        SC_CTHREAD(entry, clk.pos());
//        pc = 0;
//        saved_inst = 0;
//        state = s0;
//    }
//
//    // Process functionality in member function below
//    void entry() {
//
//        while (true) {
//            wait();
//
//            if (rst.read())
//            {
//                PC.write(0x00000000);
//                pc = 0;
//                state = s0;
//            }
//            else
//            {
//                
//                switch (state)
//                {
//                case s0:    // Cycle 1 -- Decode
//                    dp_ctrl.write(0x0);
//                    wr1.write(false);
//                    wr2.write(false);
//                    saved_inst = inst.read();
//                    state = s1;
//
//                    switch (inst.read() & 0x7f) 
//                    {
//                    case 0b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37
//                        rd1.write(false);
//                        rd2.write(false);
//                        break;
//                    case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
//                        rd1.write(false);
//                        rd2.write(false);
//                        break;
//                    default:
//                        rd1.write(false);
//                        rd2.write(false);
//                        break;
//                    }
//
//                    break;
//                case s1:    // Cycle 2 -- fetch operands from register file
//                    dp_ctrl.write(saved_inst & 0x7f);
//                    state = s2;
//
//                    switch (saved_inst & 0x7f)
//                    {
//                    case 0b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37
//                        immediate.write(saved_inst >> 12);
//                        break;
//                    case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
//                        immediate.write(saved_inst >> 12);
//                        break;
//                    default:
//                        break;
//                    }
//                    break;
//                case s2:    // Cycle 3 -- perform datapath operation
//                    rd1.write(false);
//                    rd2.write(false);
//                    state = s3;
//
//                    switch (saved_inst & 0x7f)
//                    {
//                    case 0b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37
//                        wr1.write(true);
//                        wr2.write(true);
//                        addr1.write((saved_inst >> 7) & 0x1f);
//                        addr2.write((saved_inst >> 7) & 0x1f);
//                        break;
//                    case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
//                        wr1.write(true);
//                        wr2.write(true);
//                        addr1.write((saved_inst >> 7) & 0x1f);
//                        addr2.write((saved_inst >> 7) & 0x1f);
//                        break;
//                    default:
//                        wr1.write(false);
//                        wr2.write(false);
//                        break;
//                    }
//                    break;
//                case s3:    // Cycle 4 -- write back
//                    rd1.write(false);
//                    rd2.write(false);
//                    wr1.write(false);
//                    wr2.write(false);
//                    state = s0;
//
//                    switch (saved_inst & 0x7f)
//                    {
//                    case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
//                        pc = wr_pc.read();
//                        PC.write(pc);
//                        break;
//                    default:
//                        pc++;
//                        PC.write(pc);
//                        break;
//                    }
//                    break;
//                default:
//                    break;
//                }
//            }
//        }
//
//    }
//};
//
//class test_bench : sc_module
//{
//public:
//    sc_out<bool>  			rst;    	// reset
//    sc_out<unsigned> 		inst;  	    // generate instruction for cpu
//    sc_out<unsigned> 		in_bus;  	// generate input for cpu
//    sc_in<unsigned> 		out_bus;    // receive output from cpu
//
//    sc_in_clk 			clk;
//    
//    bool        stopped;
//
//    //Constructor
//    SC_CTOR(test_bench) {
//        SC_CTHREAD(entry, clk.neg());
//        stopped = false;
//    }
//
//    // Process functionality in member function below
//    void entry() {
//
//        while (true) {
//            wait();
//            inst.write(0x00000000);
//            in_bus.write(58);
//            rst.write(true);
//
//            wait();
//            inst.write((0x1234A << 12) | (1 << 7) | 0b0110111);
//            in_bus.write(58);
//            rst.write(false);
//            wait(3);
//
//            inst.write((0xBEEF0 << 12) | (1 << 7) | 0b0110111);
//            in_bus.write(58);
//            rst.write(false);
//            wait(3);
//
//            inst.write((0x22222 << 12) | (1 << 7) | 0b0010111);
//            in_bus.write(58);
//            rst.write(false);
//            wait(3);
//            
//            wait(16);
//            stopped = true;
//            sc_stop();
//
//        }
//
//    }
//};


class new_control : sc_module
{
private:
    /*unsigned pc;*/
    unsigned LATENCY = 1;
    unsigned NOP = 0x00000013;
    std::vector<unsigned> instructions;
    std::vector<unsigned> *pc_delay_loop; // circular buffer
    unsigned pc_index;

public:
    sc_in<bool>  		rst;    	// reset
    sc_out<unsigned> 	inst;  	    // instruction output
    sc_in_clk 			clk;

    sc_in<unsigned>     pc_next;
    sc_out<unsigned>    pc_reg;
    //Constructor
    SC_CTOR(new_control){
        SC_CTHREAD(entry, clk.pos());

        pc_delay_loop = new std::vector<unsigned>(LATENCY, 0);
        pc_index = 0;
        //cout << "size " << pc_delay_loop->size() << endl;
        //cout << "content " << pc_delay_loop->at(0) << " " << pc_delay_loop->at(1) << endl;

        /*pc = 0;*/
        instructions = {
            0x00300093,
            0x00108093,
            0x00208093,
            0x00108093
        };
    }

    // Process functionality in member function below
    void entry() {

        while (true) {
            wait();
            
            unsigned new_pc = pc_next.read();
            //if (new_pc >= instructions.size())
            //{
            //    new_pc = instructions.size() - 1;
            //}


            pc_reg.write(new_pc);

            unsigned end_of_buffer = (pc_index + pc_delay_loop->size() - 1) % pc_delay_loop->size();
            unsigned start_of_buffer = pc_index;

            unsigned end_of_buffer_value = (*pc_delay_loop)[end_of_buffer];
            unsigned start_of_buffer_value = (*pc_delay_loop)[start_of_buffer];

            if (rst.read() == 1)
            {
                inst.write(NOP);
            }
            else if (end_of_buffer_value >= instructions.size())
            {
                inst.write(NOP);
            }
            else
            {
                inst.write(instructions[end_of_buffer_value]);
            }

            (*pc_delay_loop)[end_of_buffer] = new_pc;
            pc_index = end_of_buffer;

            // cout << end_of_buffer << " " << end_of_buffer_value << " " << instructions[end_of_buffer_value] << endl;
            
        }
    }
};


class issue_combinational : sc_module
{
private:
    unsigned ENTRY_COUNT = 5;
    unsigned REGISTER_COUNT = 32;
public:
    sc_in<unsigned> 		inst;  	    // instruction input
    sc_in_clk 			clk;
    sc_in<bool>         reset;

    sc_out<unsigned>    if_pc_next;
    sc_in<unsigned>     if_pc_reg;

    sc_vector < sc_in<unsigned> > entry_valid_reg; // zero is invalid, one is valid
    sc_vector < sc_in<unsigned> > entry_rs1_mark_reg; // zero is unmarked, one is marked
    sc_vector < sc_in<unsigned> > entry_rs2_mark_reg; // zero is unmarked, one is marked
    sc_vector < sc_in<unsigned> > entry_rs1_reg; // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_in<unsigned> > entry_rs2_reg; // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_in<unsigned> > entry_inst_reg; // saved instruction

    sc_vector < sc_out<unsigned> > entry_valid_next; // zero is invalid, one is valid
    sc_vector < sc_out<unsigned> > entry_rs1_mark_next; // zero is unmarked, one is marked
    sc_vector < sc_out<unsigned> > entry_rs2_mark_next; // zero is unmarked, one is marked
    sc_vector < sc_out<unsigned> > entry_rs1_next; // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_out<unsigned> > entry_rs2_next; // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_out<unsigned> > entry_inst_next; // saved instruction

    sc_vector < sc_in<unsigned> >  rf_markerID_reg;
    sc_vector < sc_out<unsigned> >   rf_markerID_next;

    sc_vector < sc_in<unsigned> >  rf_registers_reg;
    sc_vector < sc_out<unsigned> >   rf_registers_next;

    sc_in<unsigned> cdb_result_broadcasted;
    sc_in<unsigned> cdb_com_data;
    sc_in<unsigned> cdb_com_ID;

    sc_vector < sc_in<unsigned> > issue_fifo_reg;
    sc_vector < sc_out<unsigned> > issue_fifo_next;

    sc_in<unsigned> issue_fifo_last_reg;
    sc_out<unsigned> issue_fifo_last_next;

    //Constructor
    SC_CTOR(issue_combinational) : entry_valid_reg("entry_valid_reg", ENTRY_COUNT), entry_rs1_mark_reg("entry_rs1_mark_reg", ENTRY_COUNT),
        entry_rs2_mark_reg("entry_rs2_mark_reg", ENTRY_COUNT), entry_rs1_reg("entry_rs1_reg", ENTRY_COUNT), entry_rs2_reg("entry_rs2_reg", ENTRY_COUNT),
        entry_inst_reg("entry_inst_reg", ENTRY_COUNT),

        entry_valid_next("entry_valid_next", ENTRY_COUNT), entry_rs1_mark_next("entry_rs1_mark_next", ENTRY_COUNT),
        entry_rs2_mark_next("entry_rs2_mark_next", ENTRY_COUNT), entry_rs1_next("entry_rs1_next", ENTRY_COUNT), entry_rs2_next("entry_rs2_next", ENTRY_COUNT),
        entry_inst_next("entry_inst_next", ENTRY_COUNT),

        rf_markerID_reg("rf_markerID_reg", REGISTER_COUNT), rf_markerID_next("rf_markerID_next", REGISTER_COUNT),
        rf_registers_reg("rf_registers_reg", REGISTER_COUNT), rf_registers_next("rf_registers_next", REGISTER_COUNT)
    {
        //SC_CTHREAD(entry, clk.neg());
        SC_METHOD(entry)
        sensitive << clk.neg() << cdb_result_broadcasted << cdb_com_data << cdb_com_ID;
    }

    // Process functionality in member function below
    void entry() {
        //while (true) {
            //wait();
            //next_trigger();
            if (reset.read() == 1)
            {
                for (unsigned i = 0; i < ENTRY_COUNT; i++)
                {
                    entry_rs1_mark_next[i].write(entry_rs1_mark_reg[i].read());
                    entry_rs2_mark_next[i].write(entry_rs2_mark_reg[i].read());

                    entry_rs1_next[i].write(entry_rs1_reg[i].read());
                    entry_rs2_next[i].write(entry_rs2_reg[i].read());

                    entry_valid_next[i].write(0);
                    entry_inst_next[i].write(entry_inst_reg[i]);

                    issue_fifo_next[i].write(0);
                }

                for (unsigned i = 0; i < REGISTER_COUNT; i++)
                {
                    rf_markerID_next[i].write(0);
                    rf_registers_next[i].write(rf_registers_reg[i].read());
                }

                if_pc_next.write(0);


                issue_fifo_last_next.write(0);
                //continue;
                return;
            }


            unsigned instv = inst.read();
            unsigned rd = instv >> 7 & 0x1F;
            unsigned rs1 = instv >> 15 & 0x1F;
            unsigned rs2 = instv >> 20 & 0x1F;
            unsigned opcode = instv & 0x7F;

            bool need_rs1 = //                  7'b0110111 // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                            //                  7'b0010111 // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                            //                  7'b1101111 // JAL (Jump And Link) Spec. PDF-Page 39 )
                            (opcode == 0b1100111)  // JALR (Jump And Link Register) Spec. PDF-Page 39 
                        ||  (opcode == 0b1100011)  // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                        ||  (opcode == 0b0000011)  // LOAD (Load to Register) Spec. PDF-Page 42 )
                        ||  (opcode == 0b0100011)  // STORE (Store to Memory) Spec. PDF-Page 42 )
                        ||  (opcode == 0b0010011)  // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                        ||  (opcode == 0b0110011)  // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                        ;

            bool need_rs2 = //                  7'b0110111 // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                            //                  7'b0010111 // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                            //                  7'b1101111 // JAL (Jump And Link) Spec. PDF-Page 39 )
                            //                  7'b1100111 // JALR (Jump And Link Register) Spec. PDF-Page 39 
                            (opcode == 0b1100011) // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                            //                  7'b0000011 // LOAD (Load to Register) Spec. PDF-Page 42 )
                        ||  (opcode == 0b0100011) // STORE (Store to Memory) Spec. PDF-Page 42 )
                            //                  7'b0010011 // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                        ||  (opcode == 0b0110011) // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                        ;

            bool need_rd =  (opcode == 0b0110111) // LUI (Load Upper Immediate) Spec. PDF-Page 37 
                        ||  (opcode == 0b0010111) // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                        ||  (opcode == 0b1101111) // JAL (Jump And Link) Spec. PDF-Page 39 )
                        ||  (opcode == 0b1100111)  // JALR (Jump And Link Register) Spec. PDF-Page 39 
                        //||  (opcode == 0b1100011)  // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
                        ||  (opcode == 0b0000011)  // LOAD (Load to Register) Spec. PDF-Page 42 )
                        //||  (opcode == 0b0100011)  // STORE (Store to Memory) Spec. PDF-Page 42 )
                        ||  (opcode == 0b0010011)  // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                        ||  (opcode == 0b0110011)  // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                        ;


            unsigned reserved_id = 0;
            for (unsigned i = 0; i < ENTRY_COUNT; i++)
            {
                if (entry_valid_reg[i].read() == 0 && reserved_id == 0)
                {
                    // find an open spot for next instruction
                    reserved_id = i + 1;
                    break;
                }
            }
            // It's possible we can't find an open spot, let's wait and see whether any spot will be executed and get freed

            unsigned executed_id = 0;
            if (entry_valid_reg[issue_fifo_reg[0].read()].read() == 1 && entry_rs1_mark_reg[issue_fifo_reg[0].read()].read() == 0
                && entry_rs2_mark_reg[issue_fifo_reg[0].read()].read() == 0)
            {
                executed_id = issue_fifo_reg[0].read();
                if (reserved_id == 0)
                {
                    reserved_id = executed_id;
                }
                    //shift last four register
                issue_fifo_next[0].write(issue_fifo_last_reg.read() == 1 ? reserved_id : issue_fifo_reg[1].read());// = last == 1 ? new : fifo[1]
                issue_fifo_next[1].write(issue_fifo_last_reg.read() == 2 ? reserved_id : issue_fifo_reg[2].read());
                issue_fifo_next[2].write(issue_fifo_last_reg.read() == 3 ? reserved_id : issue_fifo_reg[3].read());
                issue_fifo_next[3].write(issue_fifo_last_reg.read() == 4 ? reserved_id : issue_fifo_reg[4].read());
                    //fifo[1] = last == 2 ? new : fifo[2]
                    //fifo[2] = last == 3 ? new : fifo[3]
                    //fifo[3] = last == 4 ? new : fifo[4]
            }
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
                    last++




            unsigned reserved_id = 0;
            unsigned executed_id = 0;
            for (unsigned i = 0; i < ENTRY_COUNT; i++)
            {
                if (entry_valid_reg[i].read() == 0 && reserved_id == 0)
                {
                    // this spot is open and we are actually looking for a spot
                    // we will use this spot and start filling info next

                    // those will come from register file logic
                    //entry_rs1_mark_next[i].write(check register mark status, check opcode whether rs1 is needed);
                    //entry_rs2_mark_next[i].write(check register mark status, check opcode whether rs2 is needed);

                    //entry_rs1_next[i].write(get entry ID from register if latest value not available, or get saved value);
                    //entry_rs2_next[i].write(get entry ID from register if latest value not available, or get saved value);

                    entry_valid_next[i].write(1);
                    entry_inst_next[i].write(instv);
                    
                    reserved_id = 1 + i;
                }
                else if (entry_valid_reg[i].read() == 1 && entry_rs1_mark_reg[i].read() == 0
                    && entry_rs2_mark_reg[i].read() == 0 && cdb_result_broadcasted.read() == 1
                    && executed_id == 0)
                {
                    // this will be executed
                    entry_rs1_mark_next[i].write(entry_rs1_mark_reg[i].read());
                    entry_rs2_mark_next[i].write(entry_rs2_mark_reg[i].read());

                    entry_rs1_next[i].write(entry_rs1_reg[i].read());
                    entry_rs2_next[i].write(entry_rs2_reg[i].read());

                    entry_valid_next[i].write(0);
                    entry_inst_next[i].write(entry_inst_reg[i].read());

                    executed_id = 1 + i;
                }
                else
                {
                    // rest of the entry, check common data bus for boardcast, and keep value
                    if (entry_valid_reg[i].read() == 1)
                    {
                        if (entry_rs1_mark_reg[i].read() == 1 && entry_rs1_reg[i].read() == cdb_com_ID.read())
                        {
                            // we are listening for boardcast and boardcast data is what we are waiting for
                            // record the data
                            entry_rs1_mark_next[i].write(0);
                            entry_rs1_next[i].write(cdb_com_data.read());
                        }
                        if (entry_rs2_mark_reg[i].read() == 1 && entry_rs2_reg[i].read() == cdb_com_ID.read())
                        {
                            // we are listening for boardcast and boardcast data is what we are waiting for
                            // record the data
                            entry_rs2_mark_next[i].write(0);
                            entry_rs2_next[i].write(cdb_com_data.read());
                        }
                    }
                    else
                    {
                        entry_rs1_mark_next[i].write(entry_rs1_mark_reg[i].read());
                        entry_rs2_mark_next[i].write(entry_rs2_mark_reg[i].read());

                        entry_rs1_next[i].write(entry_rs1_reg[i].read());
                        entry_rs2_next[i].write(entry_rs2_reg[i].read());

                        entry_valid_next[i].write(entry_valid_reg[i].read());
                        entry_inst_next[i].write(entry_inst_reg[i].read());
                    }

                }
            }

            if (reserved_id == 0)
            {
                // we didn't get a spot, pause instruction
                if_pc_next.write(if_pc_reg.read());
            }
            else
            {
                if_pc_next.write(if_pc_reg.read() + 1);
            }

            //for (unsigned i = 0; i < REGISTER_COUNT; i++)
            //{
            //    // get common data bus value
            //    if (rf_markerID_reg[i].read() != 0 && rf_markerID_reg[i].read() == cdb_com_ID.read())
            //    {
            //        rf_markerID_next[i].write(0);
            //        rf_registers_next[i].write(cdb_com_data.read());
            //    }
            //}


            for (unsigned i = 0; i < REGISTER_COUNT; i++)
            {

                if (i == 0)
                {
                    rf_markerID_next[i].write(0);
                    rf_registers_next[i].write(0);

                    if (rs1 == i && need_rs1)
                    {
                        entry_rs1_mark_next[reserved_id - 1].write(0);
                        entry_rs1_next[reserved_id - 1].write(0);
                    }
                    if (rs2 == i && need_rs2)
                    {
                        entry_rs2_mark_next[reserved_id - 1].write(0);
                        entry_rs2_next[reserved_id - 1].write(0);
                    }
                    if (rd == i && need_rd)
                    {
                        // wirte to register zero have no effect
                    }
                }
                else if (rf_markerID_reg[i].read() != 0 && rf_markerID_reg[i].read() == cdb_com_ID.read())
                {
                    // This register is waiting on data and Common data bus is boardcasting the data we are insterested in
                    if (rs1 == i && need_rs1)
                    {
                        entry_rs1_mark_next[reserved_id - 1].write(0);
                        entry_rs1_next[reserved_id - 1].write(cdb_com_data.read());
                    }
                    if (rs2 == i && need_rs2)
                    {
                        entry_rs2_mark_next[reserved_id - 1].write(0);
                        entry_rs2_next[reserved_id - 1].write(cdb_com_data.read());
                    }
                    if (rd == i && need_rd)
                    {
                        // This register destination will be written by our instruction at this entry
                        rf_markerID_next[i].write(reserved_id);
                        rf_registers_next[i].write(cdb_com_data.read());
                    }
                    else
                    {
                        rf_markerID_next[i].write(0);
                        rf_registers_next[i].write(cdb_com_data.read());
                    }
                }
                else
                {
                    // Common data bus is not boardcasting the data for this register right now
                    if (rs1 == i && need_rs1)
                    {
                        if (rf_markerID_reg[i].read() != 0)
                        {
                            // we need to wait for other reservation station to finish
                            entry_rs1_mark_next[reserved_id - 1].write(1);
                            entry_rs1_next[reserved_id - 1].write(rf_markerID_reg[i].read());
                        }
                        else
                        {
                            entry_rs1_mark_next[reserved_id - 1].write(0);
                            entry_rs1_next[reserved_id - 1].write(rf_registers_reg[i].read());
                        }
                    }
                    if (rs2 == i && need_rs2)
                    {
                        if (rf_markerID_reg[i].read() != 0)
                        {
                            // we need to wait for other reservation station to finish
                            entry_rs2_mark_next[reserved_id - 1].write(1);
                            entry_rs2_next[reserved_id - 1].write(rf_markerID_reg[i].read());
                        }
                        else
                        {
                            entry_rs2_mark_next[reserved_id - 1].write(0);
                            entry_rs2_next[reserved_id - 1].write(rf_registers_reg[i].read());
                        }
                    }
                    if (rd == i && need_rd)
                    {
                        // This register destination will be written by our instruction at this entry
                        rf_markerID_next[i].write(reserved_id);
                        rf_registers_next[i].write(rf_registers_reg[i].read());
                    }
                    else
                    {
                        rf_markerID_next[i].write(rf_markerID_reg[i].read());
                        rf_registers_next[i].write(rf_registers_reg[i].read());
                    }
                }

            //    if (rf_markerID_reg[i].read() != 0 && rf_markerID_reg[i].read() == cdb_com_ID.read())
            //    {

            //        // common data bus ID match, we have new data


            //        if (reserved_id != 0 && (rs1 == i || rs2 == i || rd == i))
            //        {
            //            // We reserve a spot for us, let's get in and start registering info
            //            if (rs1 == i)
            //            {
            //                if (rs1 == 0)
            //                {
            //                    entry_rs1_mark_next[reserved_id - 1].write(0);
            //                    entry_rs1_next[reserved_id - 1].write(0);
            //                }
            //                else if (rf_markerID_reg[i].read() != 0)
            //                {
            //                    // we need to wait for other reservation station to finish
            //                    entry_rs1_mark_next[reserved_id - 1].write(1);
            //                    entry_rs1_next[reserved_id - 1].write(rf_markerID_reg[i].read());
            //                }
            //                else
            //                {
            //                    entry_rs1_mark_next[reserved_id - 1].write(0);
            //                    entry_rs1_next[reserved_id - 1].write(rf_registers_reg[i].read());
            //                }
            //            }

            //            if (rs2 == i)
            //            {
            //                if (rs2 == 0)
            //                {
            //                    entry_rs2_mark_next[reserved_id - 1].write(0);
            //                    entry_rs2_next[reserved_id - 1].write(0);
            //                }
            //                else if (rf_markerID_reg[i].read() != 0)
            //                {
            //                    // we need to wait for other reservation station to finish
            //                    entry_rs2_mark_next[reserved_id - 1].write(1);
            //                    entry_rs2_next[reserved_id - 1].write(rf_markerID_reg[i].read());
            //                }
            //                else
            //                {
            //                    entry_rs2_mark_next[reserved_id - 1].write(0);
            //                    entry_rs2_next[reserved_id - 1].write(rf_registers_reg[i].read());
            //                }
            //            }

            //            if (rd == i && rd != 0)
            //            {
            //                // This register destination will be written by our instruction at this entry
            //                rf_markerID_next[i].write(reserved_id);
            //                rf_registers_next[i].write(rf_registers_reg[i].read());
            //            }
            //        }
            //    }


            //    if (reserved_id != 0 && (rs1 == i || rs2 == i || rd == i))
            //    {
            //        // We reserve a spot for us, let's get in and start registering info
            //        if (rs1 == i)
            //        {
            //            if (rs1 == 0)
            //            {
            //                entry_rs1_mark_next[reserved_id - 1].write(0);
            //                entry_rs1_next[reserved_id - 1].write(0);
            //            }
            //            else if (rf_markerID_reg[i].read() != 0)
            //            {
            //                // we need to wait for other reservation station to finish
            //                entry_rs1_mark_next[reserved_id - 1].write(1);
            //                entry_rs1_next[reserved_id - 1].write(rf_markerID_reg[i].read());
            //            }
            //            else
            //            {
            //                entry_rs1_mark_next[reserved_id - 1].write(0);
            //                entry_rs1_next[reserved_id - 1].write(rf_registers_reg[i].read());
            //            }
            //        }

            //        if (rs2 == i)
            //        {
            //            if (rs2 == 0) 
            //            {
            //                entry_rs2_mark_next[reserved_id - 1].write(0);
            //                entry_rs2_next[reserved_id - 1].write(0);
            //            }
            //            else if (rf_markerID_reg[i].read() != 0)
            //            {
            //                // we need to wait for other reservation station to finish
            //                entry_rs2_mark_next[reserved_id - 1].write(1);
            //                entry_rs2_next[reserved_id - 1].write(rf_markerID_reg[i].read());
            //            }
            //            else
            //            {
            //                entry_rs2_mark_next[reserved_id - 1].write(0);
            //                entry_rs2_next[reserved_id - 1].write(rf_registers_reg[i].read());
            //            }
            //        }

            //        if (rd == i && rd != 0)
            //        {
            //            // This register destination will be written by our instruction at this entry
            //            rf_markerID_next[i].write(reserved_id);
            //            rf_registers_next[i].write(rf_registers_reg[i].read());
            //        }
            //    }
            //    else
            //    {
            //        // All full, keep their original value
            //        rf_markerID_next[i].write(rf_markerID_reg[i].read());
            //        rf_registers_next[i].write(rf_registers_reg[i].read());
            //        
            //    }
            //}


        }
        
    }
};

class reservation_station : sc_module
{
private:
    unsigned ENTRY_COUNT = 5;
    std::vector<unsigned> entry_valid; // zero is invalid, one is valid
    std::vector<unsigned> entry_rs1_mark; // zero is unmarked, one is marked
    std::vector<unsigned> entry_rs2_mark; // zero is unmarked, one is marked
    std::vector<unsigned> entry_rs1; // real reigster value if unmarked, reservation entry ID if marked
    std::vector<unsigned> entry_rs2; // real reigster value if unmarked, reservation entry ID if marked
    std::vector<unsigned> entry_inst; // saved instruction
public:
    //sc_in<bool>  			rst;    	// reset
    //sc_out<unsigned> 		inst;  	    // instruction output
    sc_in_clk 			clk;

    sc_vector < sc_out<unsigned> > entry_valid_reg; // zero is invalid, one is valid
    sc_vector < sc_out<unsigned> > entry_rs1_mark_reg; // zero is unmarked, one is marked
    sc_vector < sc_out<unsigned> > entry_rs2_mark_reg; // zero is unmarked, one is marked
    sc_vector < sc_out<unsigned> > entry_rs1_reg; // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_out<unsigned> > entry_rs2_reg; // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_out<unsigned> > entry_inst_reg; // saved instruction

    sc_vector < sc_in<unsigned> > entry_valid_next; // zero is invalid, one is valid
    sc_vector < sc_in<unsigned> > entry_rs1_mark_next; // zero is unmarked, one is marked
    sc_vector < sc_in<unsigned> > entry_rs2_mark_next; // zero is unmarked, one is marked
    sc_vector < sc_in<unsigned> > entry_rs1_next; // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_in<unsigned> > entry_rs2_next; // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_in<unsigned> > entry_inst_next; // saved instruction

    sc_vector < sc_out<unsigned> > fifo_reg;
    sc_vector < sc_in<unsigned> > fifo_next;
    //Constructor
    SC_CTOR(reservation_station) : entry_valid_reg("entry_valid_reg", ENTRY_COUNT), entry_rs1_mark_reg("entry_rs1_mark_reg", ENTRY_COUNT),
        entry_rs2_mark_reg("entry_rs2_mark_reg", ENTRY_COUNT), entry_rs1_reg("entry_rs1_reg", ENTRY_COUNT), entry_rs2_reg("entry_rs2_reg", ENTRY_COUNT), 
        entry_inst_reg("entry_inst_reg", ENTRY_COUNT),

        entry_valid_next("entry_valid_next", ENTRY_COUNT), entry_rs1_mark_next("entry_rs1_mark_next", ENTRY_COUNT),
        entry_rs2_mark_next("entry_rs2_mark_next", ENTRY_COUNT), entry_rs1_next("entry_rs1_next", ENTRY_COUNT), entry_rs2_next("entry_rs2_next", ENTRY_COUNT),
        entry_inst_next("entry_inst_next", ENTRY_COUNT),

        fifo_reg("fifo_reg", ENTRY_COUNT), fifo_next("fifo_next", ENTRY_COUNT)
    {
        SC_CTHREAD(entry, clk.pos());

        entry_valid     = std::vector<unsigned>(ENTRY_COUNT, 0);
        entry_rs1_mark  = std::vector<unsigned>(ENTRY_COUNT, 0);
        entry_rs2_mark  = std::vector<unsigned>(ENTRY_COUNT, 0);
        entry_rs1       = std::vector<unsigned>(ENTRY_COUNT, 0);
        entry_rs2       = std::vector<unsigned>(ENTRY_COUNT, 0);
        entry_inst      = std::vector<unsigned>(ENTRY_COUNT, 0);
    }

    // Process functionality in member function below
    void entry() {
        while (true)
        {
            wait();
            for (unsigned i = 0; i < ENTRY_COUNT; i++)
            {
                entry_valid[i] = entry_valid_next[i].read();
                entry_valid_reg[i].write(entry_valid_next[i].read());

                entry_rs1_mark[i] = entry_rs1_mark_next[i].read();
                entry_rs1_mark_reg[i].write(entry_rs1_mark_next[i].read());

                entry_rs2_mark[i] = entry_rs2_mark_next[i].read();
                entry_rs2_mark_reg[i].write(entry_rs2_mark_next[i].read());

                entry_rs1[i] = entry_rs1_next[i].read();
                entry_rs1_reg[i].write(entry_rs1_next[i].read());

                entry_rs2[i] = entry_rs2_next[i].read();
                entry_rs2_reg[i].write(entry_rs2_next[i].read());

                entry_inst[i] = entry_inst_next[i].read();
                entry_inst_reg[i].write(entry_inst_next[i].read());

                fifo_reg[i].write(fifo_next[i].read());
            }
        }
    }
};

class exe_combinational : sc_module
{
private:
    unsigned ENTRY_COUNT = 5;
public:
    sc_in<bool>  		rst;    	// reset
    sc_in_clk 			clk;
    sc_in<unsigned>     func_result_reg;
    sc_out<unsigned>    func_result_next;
    sc_in<unsigned>     func_result_ID_reg;
    sc_out<unsigned>    func_result_ID_next;

    sc_in<unsigned>     if_pc_reg;
    sc_out<unsigned>    pc_calculated;

    sc_vector < sc_in<unsigned> > entry_valid_reg; // zero is invalid, one is valid
    sc_vector < sc_in<unsigned> > entry_rs1_mark_reg; // zero is unmarked, one is marked
    sc_vector < sc_in<unsigned> > entry_rs2_mark_reg; // zero is unmarked, one is marked
    sc_vector < sc_in<unsigned> > entry_rs1_reg; // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_in<unsigned> > entry_rs2_reg; // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_in<unsigned> > entry_inst_reg; // saved instruction

    sc_in<unsigned> result_broadcasted;

    

    
    //Constructor
    SC_CTOR(exe_combinational) : entry_valid_reg("entry_valid_reg", ENTRY_COUNT), entry_rs1_mark_reg("entry_rs1_mark_reg", ENTRY_COUNT),
        entry_rs2_mark_reg("entry_rs2_mark_reg", ENTRY_COUNT), entry_rs1_reg("entry_rs1_reg", ENTRY_COUNT), entry_rs2_reg("entry_rs2_reg", ENTRY_COUNT),
        entry_inst_reg("entry_inst_reg", ENTRY_COUNT)
    {
        SC_CTHREAD(entry, clk.neg());

    }
    signed get_s_imm_J(unsigned instv) 
    {
        unsigned imm19_12 = instv >> 12 & 0xFF;
        unsigned imm11 = instv >> 20 & 0x1;
        unsigned imm10_1 = instv >> 21 & 0x3FF;
        unsigned imm20 = instv >> 31 & 0x1;
        unsigned imm_J = imm20 << 20 | imm19_12 << 12 | imm11 << 11 | imm10_1 << 1;

        imm_J = imm_J | (imm_J & 0x100000 ? 0xFFF00000 : 0);

        signed int s_imm = (signed int)imm_J;
        return s_imm;
    }

    signed get_s_imm_B(unsigned instv)
    {
        unsigned imm11 = instv >> 7 & 0x1;
        unsigned imm4_1 = instv >> 8 & 0xF;
        unsigned imm10_5 = instv >> 25 & 0x3F;
        unsigned imm12 = instv >> 31 & 0x1;
        unsigned imm_B = imm12 << 12 | imm11 << 11 | imm10_5 << 5 | imm4_1 << 1;
        imm_B = imm_B | (imm_B & 0x1000 ? 0xFFFFF000 : 0);

        signed int s_imm = (signed int)imm_B;
        return s_imm;
    }
    // Process functionality in member function below
    void entry()
    {
        while (true)
        {
            wait();
            if (rst.read() == 1)
            {
                func_result_ID_next.write(0);
                func_result_next.write(0);
                continue;
            }

            if (result_broadcasted.read() == 0)
            {
                func_result_ID_next.write(func_result_ID_reg.read());
                func_result_next.write(func_result_reg.read());
                continue;
            }

            unsigned selected_entry_id = 0;
            for (unsigned i = 0; i < ENTRY_COUNT; i++)
            {
                if (entry_valid_reg[i].read() == 1 && entry_rs1_mark_reg[i].read() == 0
                    && entry_rs2_mark_reg[i].read() == 0)
                {
                    // we are going to execute on this entry
                    selected_entry_id = i+1;
                    break;
                }
            }

            if (selected_entry_id == 0)
            {
                // no entry is ready
                // clear result, prevent other issuing instruction to see the old value
                func_result_ID_next.write(0);
                func_result_next.write(0);
                continue;
            }
            
            func_result_ID_next.write(selected_entry_id);
            selected_entry_id -= 1;

            unsigned instv =    entry_inst_reg[selected_entry_id].read();
            unsigned opcode =   instv & 0x7F;
            unsigned rd =       instv >> 7 & 0x1F;
            unsigned rs1 =      entry_rs1_reg[selected_entry_id].read();
            unsigned rs2 =      entry_rs2_reg[selected_entry_id].read();
            unsigned funct3 =   instv >> 12 & 0x7;
            unsigned funct7 =   instv >> 25 & 0x7F;
            unsigned imm_I =    instv >> 20 & 0xFFF;
            signed int s_imm_I = (signed int)(imm_I | (imm_I & 0x800 ? 0xFFFFF000 : 0));
            unsigned imm_U =    instv & 0xFFFFF000;
            signed int s_imm_B = get_s_imm_B(instv);

            switch (opcode)
            {
            case 0b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37 )
                func_result_next.write(imm_U);
                break;
            case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                func_result_next.write(imm_U + if_pc_reg.read());
                pc_calculated.write(imm_U + if_pc_reg.read());
                break;
            case 0b1101111: // JAL (Jump And Link) Spec. PDF-Page 39 )
            
                func_result_next.write(if_pc_reg.read() + 4);

                /*unsigned imm19_12 = instv >> 12 & 0xFF;
                unsigned imm11 = instv >> 20 & 0x1;
                unsigned imm10_1 = instv >> 21 & 0x3FF;
                unsigned imm20 = instv >> 31 & 0x1;
                unsigned imm_J = imm20 << 20 | imm19_12 << 12 | imm11 << 11 | imm10_1 << 1;

                imm_J = imm_J | (imm_J & 0x100000 ? 0xFFF00000 : 0);

                signed int s_imm = (signed int)imm_J;*/


                pc_calculated.write(if_pc_reg.read() + get_s_imm_J(instv));
                break; 
            case 0b1100111: // JALR (Jump And Link Register) Spec. PDF-Page 39 )
                func_result_next.write(if_pc_reg.read() + 4);
                pc_calculated.write(rs1 + s_imm_I);
                break;
            case 0b1100011: // BRANCH (Comparasion and Branch) Spec. PDF-Page 40 )
            
                /*unsigned imm11 = instv >> 7 & 0x1;
                unsigned imm4_1 = instv >> 8 & 0xF;
                unsigned imm10_5 = instv >> 25 & 0x3F;
                unsigned imm12 = instv >> 31 & 0x1;
                unsigned imm_B = imm12 << 12 | imm11 << 11 | imm10_5 << 5 | imm4_1 << 1;
                imm_B = imm_B | (imm_B & 0x1000 ? 0xFFFFF000 : 0);

                signed int s_imm = (signed int)imm_B;*/
                switch (funct3)
                {
                case 0b000: // BEQ (Branch Equal)
                    if (rs1 == rs2) {
                        pc_calculated.write(if_pc_reg.read() + s_imm_B);
                    }
                    else {
                        pc_calculated.write(if_pc_reg.read() + 4);
                    }
                    break;
                case 0b001: // BNE (Branch Not Equal)
                    if (rs1 != rs2) {
                        pc_calculated.write(if_pc_reg.read() + s_imm_B);
                    }
                    else {
                        pc_calculated.write(if_pc_reg.read() + 4);
                    }
                    break;
                case 0b100: // BLT (Branch Less Than)
                    if ((signed)rs1 < (signed)rs2) {
                        pc_calculated.write(if_pc_reg.read() + s_imm_B);
                    }
                    else {
                        pc_calculated.write(if_pc_reg.read() + 4);
                    }
                    break;
                case 0b101: // BGT (Branch Greater Than)
                    if ((signed)rs1 >= (signed)rs2) {
                        pc_calculated.write(if_pc_reg.read() + s_imm_B);
                    }
                    else {
                        pc_calculated.write(if_pc_reg.read() + 4);
                    }
                    break;
                case 0b110: // BLTU (Branch Less Than Unsigned)
                    if (rs1 < rs2) {
                        pc_calculated.write(if_pc_reg.read() + s_imm_B);
                    }
                    else {
                        pc_calculated.write(if_pc_reg.read() + 4);
                    }
                    break;
                case 0b111: // BGTU (Branch Greater Than Unsigned)
                    if (rs1 >= rs2) {
                        pc_calculated.write(if_pc_reg.read() + s_imm_B);
                    }
                    else {
                        pc_calculated.write(if_pc_reg.read() + 4);
                    }
                    break;
                
                default:
                    cout << "************* BAD FUNCT3 *************" << endl;
                    break;
                }
            case 0b0010011: // OP_IMM (Integer Register-Immediate Instructions) Spec. PDF-Page 36 )
                switch (funct3)
                {
                case 0b000: // ADDI (Add Immediate)
                    func_result_next.write(rs1 + s_imm_I);
                    break;
                case 0b010: // SLTI (Set Less Than Immediate)
                    func_result_next.write((signed)rs1 < (signed)s_imm_I ? 1 : 0);
                    break;
                case 0b011: // SLTIU (Set Less Than Immediate Unsigned)
                    func_result_next.write(rs1 < imm_I ? 1 : 0);
                    break;
                case 0b100: // XORI (XOR Immediate)
                    func_result_next.write(rs1 ^ s_imm_I);
                    break;
                case 0b110: // ORI (OR Immediate)
                    func_result_next.write(rs1 | s_imm_I);
                    break;
                case 0b111: // ANDI (AND Immediate)
                    func_result_next.write(rs1 & s_imm_I);
                    break;
                case 0b001: // SLLI (Shift Left Logic Immediate)
                    func_result_next.write(rs1 << (s_imm_I & 0x1F));
                    break;
                case 0b101: 
                    if ((s_imm_I & 0x400) == 0) // SRLI (Shift Right Logic Immediate)
                    {
                        func_result_next.write(rs1 >> (imm_I & 0x1F));
                    }
                    else // SRAI (Shift Right Arithmatic Immediate)
                    {
                        func_result_next.write((signed)rs1 >> (s_imm_I & 0x1F));
                    }
                    break;
                default:
                    cout << "************* BAD FUNCT3 *************" << endl;
                    break;
                }
                break;
            case 0b0110011: // OP (Integer Register-Register Instructions) Spec. PDF-Page 37 )
                switch (funct3)
                {
                case 0b000:
                    if ((s_imm_I & 0x2F) == 0) // ADD (Addition)
                    {
                        func_result_next.write(rs1 + rs2);
                    }
                    else // SUB (Subtraction)
                    {
                        func_result_next.write(rs1 - rs2);
                    }
                    break;
                case 0b001: // SLL (Shift Left Logic)
                    func_result_next.write(rs1 << (rs2 & 0x1F));
                    break;
                case 0b010: // SLT (Set Less Than)
                    func_result_next.write((signed)rs1 < (signed)rs2 ? 1 : 0);
                    break;
                case 0b011: // SLTU (Set Less Than Unsigned)
                    func_result_next.write(rs1 < rs2 ? 1 : 0);
                    break;
                case 0b100: // XOR (XOR)
                    func_result_next.write(rs1 ^ rs2);
                    break;
                case 0b101: 
                    if ((s_imm_I & 0x2F) == 0) // SRL (Shift Right Logic)
                    {
                        func_result_next.write(rs1 >> (rs2 & 0x1F));
                    }
                    else // SRA (Shift Right Arithmatic)
                    {
                        func_result_next.write((signed)rs1 >> ((signed)rs2 & 0x1F));
                    }
                    break;
                case 0b110: // OR (OR)
                    func_result_next.write(rs1 | rs2);
                    break;
                case 0b111: // AND (AND)
                    func_result_next.write(rs1 & rs2);
                    break;
                default:
                    cout << "************* BAD FUNCT3 *************" << endl;
                    break;
                }
                break;
            default:
                cout << "************* BAD OPCODE *************" << endl;
                break;
            }

        }

    }
};

class function_result : sc_module
{
private:

public:
    sc_in<bool>  			rst;    	// reset
    sc_in_clk 			clk;
    sc_out<unsigned> result_reg;
    sc_in<unsigned> result_next;

    sc_out<unsigned> result_ID_reg;
    sc_in<unsigned> result_ID_next;
    //sc_vector < sc_out<unsigned> > entry_valid_reg; // zero is invalid, one is valid
    //Constructor
    SC_CTOR(function_result) {
        SC_CTHREAD(entry, clk.pos());

    }

    // Process functionality in member function below
    void entry() {
        while (true)
        {
            wait();
            result_reg.write(result_next.read());
            result_ID_reg.write(result_ID_next.read());
        }

    }
};

class common_data_bus_combinational : sc_module
{
private:

public:
    sc_in<bool>  			rst;    	// reset
    sc_in_clk 			clk;

    sc_in<unsigned> result_reg;
    sc_in<unsigned> result_ID_reg;
    sc_out<unsigned> result_broadcasted;

    sc_out<unsigned> com_data;
    sc_out<unsigned> com_ID;


    //Constructor
    SC_CTOR(common_data_bus_combinational) {
        SC_CTHREAD(entry, clk.neg());

    }

    // Process functionality in member function below
    void entry() {
        while (true)
        {
            wait();
            if (result_ID_reg.read() != 0)
            {
                com_data.write(result_reg.read());
                com_ID.write(result_ID_reg.read());
                result_broadcasted.write(1);
            }
            // add else if for other function unit
            else
            {
                com_data.write(0);
                com_ID.write(0);
                result_broadcasted.write(1);
            }
        }

    }
};

class your_module : sc_module 
{
private:

public:
    sc_in<bool>  			rst;    	// reset
    sc_out<unsigned> 		inst;  	    // instruction output
    sc_in_clk 			clk;

    //Constructor
    SC_CTOR(your_module) {
        SC_CTHREAD(entry, clk.pos());

    }

    // Process functionality in member function below
    void entry() {
        while (true)
        {
            wait();

        }
    
    }
};

int sc_main(int, char* []) {

    // ************************ Register File ***********************************
    unsigned REGISTER_COUNT = 32;
    sc_vector < sc_signal<unsigned> >  RFwire_markerID_reg("rf_markerID_reg", REGISTER_COUNT);
    sc_vector < sc_signal<unsigned> >  RFwire_markerID_next("rf_markerID_next", REGISTER_COUNT);

    sc_vector < sc_signal<unsigned> >  RFwire_registers_reg("rf_registers_reg", REGISTER_COUNT);
    sc_vector < sc_signal<unsigned> >  RFwire_registers_next("rf_registers_next", REGISTER_COUNT);


    // ************************ Data Path ***********************************
    //sc_signal<unsigned>  		dp_dp_ctrl("DP_CTRL");  	// data path control signal
    //sc_signal<unsigned> 		dp_wr_pc("DP_WRITE_PC");  	// data path write to program counter
    //sc_signal<unsigned> 		dp_in_bus("DP_INPUT_BUS");  	// data path receive data from outside, DRAM, etc
    //sc_signal<unsigned> 		dp_out_bus("DP_OUTPUT_BUS");  	// data path transmit data to outside, DRAM, etc
    sc_signal<unsigned> func_result_reg("func_result_reg");
    sc_signal<unsigned> func_result_next("func_result_next");

    sc_signal<unsigned> func_result_ID_reg("func_result_ID_reg");
    sc_signal<unsigned> func_result_ID_next("func_result_ID_next");
    sc_signal<unsigned>    func_pc_calculated("func_pc_calculated");

    //// ************************ Control ***********************************
    sc_signal<bool>             rst("RESET");            // reset
    //sc_signal<unsigned> 		ctrl_inst("CTRL_INSTRUCTION");  	        // instruction for cpu
    //sc_signal<unsigned> 		ctrl_immediate("CTRL_IMMEDIATE");      // generate immediate from instruction to datapath
    //sc_signal<unsigned> 		ctrl_PC("CTRL_PROGRAM_COUNTER");  	        // keep track of program counter

    //// ************************ Common Data Bus ***********************************
    sc_signal<unsigned> cdb_result_broadcasted;

    sc_signal<unsigned> cdb_com_data;
    sc_signal<unsigned> cdb_com_ID;

    sc_clock clk("Clock", 1, SC_NS, 0.5, 0.0, SC_NS); // 1ns period, 0.5 duty cycle, start at 0ns

    register_file RF("REGISTER_FILE_BLOCK");
    RF.markerID_reg(RFwire_markerID_reg);
    RF.markerID_next(RFwire_markerID_next);
    RF.registers_reg(RFwire_registers_reg);
    RF.registers_next(RFwire_registers_next);
    RF.clk(clk);

    // ------------------------------------------------ New Architecture Below --------------------------------------

    sc_signal<unsigned> 	new_control_inst("CTRL_INST");  	    // instruction output
    sc_signal<unsigned>     pc_next("pc_next");
    sc_signal<unsigned>     pc_reg("pc_reg");

    unsigned ENTRY_COUNT = 5;
    sc_vector < sc_signal<unsigned> > issue_entry_valid_reg("ISSUE_ENTRY_VALID_REG", ENTRY_COUNT); // zero is invalid, one is valid
    sc_vector < sc_signal<unsigned> > issue_entry_rs1_mark_reg("ISSUE_ENTRY_RS1_MARK_REG", ENTRY_COUNT); // zero is unmarked, one is marked
    sc_vector < sc_signal<unsigned> > issue_entry_rs2_mark_reg("ISSUE_ENTRY_RS2_MARK_REG", ENTRY_COUNT); // zero is unmarked, one is marked
    sc_vector < sc_signal<unsigned> > issue_entry_rs1_reg("ISSUE_ENTRY_RS1_REG", ENTRY_COUNT); // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_signal<unsigned> > issue_entry_rs2_reg("ISSUE_ENTRY_RS2_REG", ENTRY_COUNT); // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_signal<unsigned> > issue_entry_inst_reg("ISSUE_ENTRY_INST_REG", ENTRY_COUNT); // saved instruction

    sc_vector < sc_signal<unsigned> > issue_entry_valid_next("ISSUE_ENTRY_VALID_NEXT", ENTRY_COUNT); // zero is invalid, one is valid
    sc_vector < sc_signal<unsigned> > issue_entry_rs1_mark_next("ISSUE_ENTRY_RS1_MARK_NEXT", ENTRY_COUNT); // zero is unmarked, one is marked
    sc_vector < sc_signal<unsigned> > issue_entry_rs2_mark_next("ISSUE_ENTRY_RS2_MARK_NEXT", ENTRY_COUNT); // zero is unmarked, one is marked
    sc_vector < sc_signal<unsigned> > issue_entry_rs1_next("ISSUE_ENTRY_RS1_NEXT", ENTRY_COUNT); // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_signal<unsigned> > issue_entry_rs2_next("ISSUE_ENTRY_RS2_NEXT", ENTRY_COUNT); // real reigster value if unmarked, reservation entry ID if marked
    sc_vector < sc_signal<unsigned> > issue_entry_inst_next("ISSUE_ENTRY_INST_NEXT", ENTRY_COUNT); // saved instruction

    sc_vector < sc_signal<unsigned> > issue_fifo_reg("issue_fifo_reg", ENTRY_COUNT);
    sc_vector < sc_signal<unsigned> > issue_fifo_next("issue_fifo_next", ENTRY_COUNT);

    new_control NCTRL("NEW_CONTROL");
    NCTRL.inst(new_control_inst);
    NCTRL.rst(rst);
    NCTRL.clk(clk);
    NCTRL.pc_next(pc_next);
    NCTRL.pc_reg(pc_reg);

    reservation_station RS("RESERVATION_STATION");
    RS.clk(clk);
    RS.entry_valid_reg(issue_entry_valid_reg); // zero is invalid, one is valid
    RS.entry_rs1_mark_reg(issue_entry_rs1_mark_reg); // zero is unmarked, one is marked
    RS.entry_rs2_mark_reg(issue_entry_rs2_mark_reg); // zero is unmarked, one is marked
    RS.entry_rs1_reg(issue_entry_rs1_reg); // real reigster value if unmarked, reservation entry ID if marked
    RS.entry_rs2_reg(issue_entry_rs2_reg); // real reigster value if unmarked, reservation entry ID if marked
    RS.entry_inst_reg(issue_entry_inst_reg); // saved instruction

    RS.entry_valid_next(issue_entry_valid_next); // zero is invalid, one is valid
    RS.entry_rs1_mark_next(issue_entry_rs1_mark_next); // zero is unmarked, one is marked
    RS.entry_rs2_mark_next(issue_entry_rs2_mark_next); // zero is unmarked, one is marked
    RS.entry_rs1_next(issue_entry_rs1_next); // real reigster value if unmarked, reservation entry ID if marked
    RS.entry_rs2_next(issue_entry_rs2_next); // real reigster value if unmarked, reservation entry ID if marked
    RS.entry_inst_next(issue_entry_inst_next); // saved instruction

    RS.fifo_reg(issue_fifo_reg);
    RS.fifo_next(issue_fifo_next);

    issue_combinational ISSUE_COM("ISSUE_COMBINATIONAL_LOGIC");
    ISSUE_COM.clk(clk);
    ISSUE_COM.reset(rst);
    ISSUE_COM.inst(new_control_inst);
    ISSUE_COM.if_pc_next(pc_next);
    ISSUE_COM.if_pc_reg(pc_reg);
    ISSUE_COM.entry_valid_reg(issue_entry_valid_reg); // zero is invalid, one is valid
    ISSUE_COM.entry_rs1_mark_reg(issue_entry_rs1_mark_reg); // zero is unmarked, one is marked
    ISSUE_COM.entry_rs2_mark_reg(issue_entry_rs2_mark_reg); // zero is unmarked, one is marked
    ISSUE_COM.entry_rs1_reg(issue_entry_rs1_reg); // real reigster value if unmarked, reservation entry ID if marked
    ISSUE_COM.entry_rs2_reg(issue_entry_rs2_reg); // real reigster value if unmarked, reservation entry ID if marked
    ISSUE_COM.entry_inst_reg(issue_entry_inst_reg); // saved instruction

    ISSUE_COM.entry_valid_next(issue_entry_valid_next); // zero is invalid, one is valid
    ISSUE_COM.entry_rs1_mark_next(issue_entry_rs1_mark_next); // zero is unmarked, one is marked
    ISSUE_COM.entry_rs2_mark_next(issue_entry_rs2_mark_next); // zero is unmarked, one is marked
    ISSUE_COM.entry_rs1_next(issue_entry_rs1_next); // real reigster value if unmarked, reservation entry ID if marked
    ISSUE_COM.entry_rs2_next(issue_entry_rs2_next); // real reigster value if unmarked, reservation entry ID if marked
    ISSUE_COM.entry_inst_next(issue_entry_inst_next); // saved instruction

    ISSUE_COM.rf_markerID_reg(RFwire_markerID_reg);
    ISSUE_COM.rf_markerID_next(RFwire_markerID_next);
    ISSUE_COM.rf_registers_reg(RFwire_registers_reg);
    ISSUE_COM.rf_registers_next(RFwire_registers_next);

    ISSUE_COM.cdb_result_broadcasted(cdb_result_broadcasted);
    ISSUE_COM.cdb_com_data(cdb_com_data);
    ISSUE_COM.cdb_com_ID(cdb_com_ID);

    function_result FR("FUNCTION_RESULTS");
    FR.rst(rst);    	// reset
    FR.clk(clk);
    FR.result_reg(func_result_reg);
    FR.result_next(func_result_next);

    FR.result_ID_reg(func_result_ID_reg);
    FR.result_ID_next(func_result_ID_next);

    exe_combinational EXE_COM("EXECUTE_COMBINATIONAL_LOGIC");
    EXE_COM.rst(rst);    	// reset
    EXE_COM.clk(clk);
    EXE_COM.func_result_reg(func_result_reg);
    EXE_COM.func_result_next(func_result_next);
    EXE_COM.func_result_ID_reg(func_result_ID_reg);
    EXE_COM.func_result_ID_next(func_result_ID_next);

    EXE_COM.if_pc_reg(pc_reg);
    EXE_COM.pc_calculated(func_pc_calculated);

    EXE_COM.entry_valid_reg(issue_entry_valid_reg); // zero is invalid, one is valid
    EXE_COM.entry_rs1_mark_reg(issue_entry_rs1_mark_reg); // zero is unmarked, one is marked
    EXE_COM.entry_rs2_mark_reg(issue_entry_rs2_mark_reg); // zero is unmarked, one is marked
    EXE_COM.entry_rs1_reg(issue_entry_rs1_reg); // real reigster value if unmarked, reservation entry ID if marked
    EXE_COM.entry_rs2_reg(issue_entry_rs2_reg); // real reigster value if unmarked, reservation entry ID if marked
    EXE_COM.entry_inst_reg(issue_entry_inst_reg); // saved instruction

    EXE_COM.result_broadcasted(cdb_result_broadcasted);


    common_data_bus_combinational CDB_COM("COMMON_DATA_BUS_LOGIC");
    CDB_COM.rst(rst);    	// reset
    CDB_COM.clk(clk);

    CDB_COM.result_reg(func_result_reg);
    CDB_COM.result_ID_reg(func_result_ID_reg);
    CDB_COM.result_broadcasted(cdb_result_broadcasted);

    CDB_COM.com_data(cdb_com_data);
    CDB_COM.com_ID(cdb_com_ID);


    sc_trace_file* Tf;
    Tf = sc_create_vcd_trace_file("traces");
    sc_trace(Tf, clk, "clk");
    sc_trace(Tf, rst, "rst");
    sc_trace(Tf, NCTRL.inst, "nctrl_inst");
    sc_trace(Tf, pc_next, "nctrl_pc_next");
    sc_trace(Tf, pc_reg, "nctrl_pc_reg");

    sc_trace(Tf, func_result_reg, "func_result_reg");
    sc_trace(Tf, func_result_next, "func_result_next");
    sc_trace(Tf, func_result_ID_reg, "func_result_ID_reg");
    sc_trace(Tf, func_result_ID_next, "func_result_ID_next");
    sc_trace(Tf, func_pc_calculated, "func_pc_calculated");

    sc_trace(Tf, cdb_result_broadcasted, "cdb_result_broadcasted");
    sc_trace(Tf, cdb_com_data, "cdb_com_data");
    sc_trace(Tf, cdb_com_ID, "cdb_com_ID");

    for (unsigned i = 0; i < REGISTER_COUNT; i++)
    {
        sc_trace(Tf, RFwire_markerID_reg[i], "RFwire_markerID" + std::to_string(i) + "_reg");
        sc_trace(Tf, RFwire_markerID_next[i], "RFwire_markerID" + std::to_string(i) + "_next");
        sc_trace(Tf, RFwire_registers_reg[i], "RFwire_registers" + std::to_string(i) + "_reg");
        sc_trace(Tf, RFwire_registers_next[i], "RFwire_registers" + std::to_string(i) + "_next");
    }

    for (unsigned i = 0; i < ENTRY_COUNT; i++)
    {
        sc_trace(Tf, issue_entry_valid_reg[i], "issue_entry" + std::to_string(i) + "_valid_reg");
        sc_trace(Tf, issue_entry_rs1_mark_reg[i], "issue_entry" + std::to_string(i) + "_rs1_mark_reg");
        sc_trace(Tf, issue_entry_rs2_mark_reg[i], "issue_entry" + std::to_string(i) + "_rs2_mark_reg");
        sc_trace(Tf, issue_entry_rs1_reg[i], "issue_entry" + std::to_string(i) + "_rs1_reg");
        sc_trace(Tf, issue_entry_rs2_reg[i], "issue_entry" + std::to_string(i) + "_rs2_reg");
        sc_trace(Tf, issue_entry_inst_reg[i], "issue_entry" + std::to_string(i) + "_inst_reg");

        sc_trace(Tf, issue_entry_valid_next[i], "issue_entry" + std::to_string(i) + "_valid_next");
        sc_trace(Tf, issue_entry_rs1_mark_next[i], "issue_entry" + std::to_string(i) + "_rs1_mark_next");
        sc_trace(Tf, issue_entry_rs2_mark_next[i], "issue_entry" + std::to_string(i) + "_rs2_mark_next");
        sc_trace(Tf, issue_entry_rs1_next[i], "issue_entry" + std::to_string(i) + "_rs1_next");
        sc_trace(Tf, issue_entry_rs2_next[i], "issue_entry" + std::to_string(i) + "_rs2_next");
        sc_trace(Tf, issue_entry_inst_next[i], "issue_entry" + std::to_string(i) + "_inst_next");

        sc_trace(Tf, issue_fifo_reg[i], "issue_fifo" + std::to_string(i) + "_reg");
        sc_trace(Tf, issue_fifo_next[i], "issue_fifo" + std::to_string(i) + "_next");
    }
    
    rst.write(1);
    sc_start(1.5, SC_NS);
    rst.write(0);
    sc_start(20, SC_NS);

    sc_close_vcd_trace_file(Tf);

    return 0;
}

SC_MODULE(M) {

    static const int SIZE = 4;

    typedef sc_uint<16> DataType;
    typedef sc_in<DataType> PortType;
    typedef sc_vector<PortType> PortVectorType;

    //PortVectorType port_vec;
    sc_vector<sc_out<sc_uint<16>>> port_vec;
    sc_in_clk clk;
    SC_CTOR(M) : port_vec("my_port", SIZE) {
        SC_CTHREAD(entry, clk.pos());
        for (int i = 0; i < SIZE; ++i)
            cout << port_vec[i].basename() << '\n';
    }

    void entry() {
        while (true) {
            wait();
            (port_vec)[0].write(2);
            (port_vec)[1].write(4);
            (port_vec)[2].write(8);
            (port_vec)[3].write(10);
        }
    
    }
};

int sc_main22(int, char**) {
    M my_module("m");
    sc_clock clk("Clock", 1, SC_NS, 0.5, 0.0, SC_NS); // 1ns period, 0.5 duty cycle, start at 0ns
    sc_vector<sc_signal<sc_uint<16>>> port_vec_wire("wiree", 4);

    my_module.clk(clk);
    my_module.port_vec(port_vec_wire);

    sc_start(100, SC_PS);

    return 0;
}

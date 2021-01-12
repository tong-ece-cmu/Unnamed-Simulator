// UnnamedSystemC1.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <systemc.h>
#include <string>

class register_file : sc_module
{
public:
    sc_in<unsigned>  		addr1;  		// physical address1
    sc_in<unsigned>  		addr2;  		// physical address2
    sc_in<bool>  			rd1;    		// read enable 1
    sc_in<bool>  			rd2;    		// read enable 2
    sc_in<bool>  			wr1;    		// write enable 1
    sc_in<bool>  			wr2;    		// write enable 2

    sc_in<unsigned> 		wr_data;  	// register file data input
    sc_out<unsigned> 		rd_data1;  	// register file data output read port 1
    sc_out<unsigned> 		rd_data2;  	// register file data output read port 2

    sc_in_clk 			clk;

    // Parameter
    unsigned* registers;	 			// Register File content
    

    //Constructor
    SC_CTOR(register_file) {
        SC_CTHREAD(entry, clk.pos());

        registers = new unsigned[32];
    }

    // Process functionality in member function below
    void entry() {
        unsigned address1;
        unsigned address2;

        while (true) {
            do { wait(); } while (!(rd1 == true || rd2 == true || wr1 == true || wr2 == true));

            address1 = addr1.read();
            address2 = addr2.read();

            if (wr1 == true && wr2 == true)
            {
                // Write operation
                if (!(address1 == address2))
                {
                    printf("** ERROR ** REGISTER FILE: Two write ports addresses are different, write failed\n");
                }

                //wait();
                registers[address1] = wr_data.read();

            }
            else if (wr1 == false && wr2 == false)
            {
                if (rd1 == true)
                {
                    // Read port 1 operation
                    //wait();
                    rd_data1.write(registers[address1]);

                }

                if (rd2 == true)
                {
                    // Read port 1 operation
                    //wait();
                    rd_data2.write(registers[address2]);
                }
            }
            else
            {
                printf("** ALERT ** REGISTER FILE: Two write ports have conflicting behavior\n");
            }
        }
    
    }
};


class data_path : sc_module
{
public:
    sc_in<unsigned>  		dp_ctrl;  	// data path control signal
    sc_out<unsigned> 		wr_data;  	// write to register file
    sc_out<unsigned> 		wr_pc;  	// write to program counter

    sc_in<unsigned> 		PC;  	    // program counter from control unit

    sc_in<unsigned> 		rd_data1;  	// register file data input from read port 1
    sc_in<unsigned> 		rd_data2;  	// register file data input from read port 2
    sc_in<unsigned> 		immediate;  // immediate from control unit
    sc_in<unsigned> 		in_bus;  	// receive data from outside, DRAM, etc
    sc_out<unsigned> 		out_bus;  	// transmit data to outside, DRAM, etc

    sc_in_clk 			clk;

    //Constructor
    SC_CTOR(data_path) {
        SC_CTHREAD(entry, clk.pos());
    }

    // Process functionality in member function below
    void entry() {

        while (true) {
            wait();

            switch (dp_ctrl.read())
            {
            case 0b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37 )
                wr_data.write(immediate.read() << 12);
                break;
            case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                wr_data.write((immediate.read() << 12) + PC.read());
                wr_pc.write((immediate.read() << 12) + PC.read());
                break;
            default:
                break;
            }

        }

    }
};

class control : sc_module
{
public:
    sc_in<bool>             rst;            // reset
    sc_in<unsigned> 		inst;  	        // instruction for cpu

    sc_out<unsigned>  		addr1;  		// address1 for register file port 1
    sc_out<unsigned>  		addr2;  		// address1 for register file port 2
    sc_out<bool>  			rd1;    		// register file read port 1 enable
    sc_out<bool>  			rd2;    		// register file read port 2 enable
    sc_out<bool>  			wr1;    		// register file write port 1 enable
    sc_out<bool>  			wr2;    		// register file write port 2 enable

    sc_out<unsigned>  		dp_ctrl;  	    // generate data path control signal
    sc_out<unsigned> 		immediate;      // generate immediate from instruction to datapath
    sc_out<unsigned> 		PC;  	        // keep track of program counter
    sc_in<unsigned> 		wr_pc;  	    // calculated new program counter from datapath

    sc_in_clk 			clk;


    // Parameter
    unsigned pc;
    unsigned saved_inst;	 			    // Saved instruction
    unsigned state;	 			            // control unit state
    static const unsigned s0 = 0b00;
    static const unsigned s1 = 0b01;
    static const unsigned s2 = 0b11;
    static const unsigned s3 = 0b10;        // Use Gray coding for states for more efficient synthesis


    //Constructor
    SC_CTOR(control) {
        SC_CTHREAD(entry, clk.pos());
        pc = 0;
        saved_inst = 0;
        state = s0;
    }

    // Process functionality in member function below
    void entry() {

        while (true) {
            wait();

            if (rst.read())
            {
                PC.write(0x00000000);
                pc = 0;
                state = s0;
            }
            else
            {
                
                switch (state)
                {
                case s0:    // Cycle 1 -- Decode
                    dp_ctrl.write(0x0);
                    wr1.write(false);
                    wr2.write(false);
                    saved_inst = inst.read();
                    state = s1;

                    switch (inst.read() & 0x7f) 
                    {
                    case 0b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37
                        rd1.write(false);
                        rd2.write(false);
                        break;
                    case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                        rd1.write(false);
                        rd2.write(false);
                        break;
                    default:
                        rd1.write(false);
                        rd2.write(false);
                        break;
                    }

                    break;
                case s1:    // Cycle 2 -- fetch operands from register file
                    dp_ctrl.write(saved_inst & 0x7f);
                    state = s2;

                    switch (saved_inst & 0x7f)
                    {
                    case 0b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37
                        immediate.write(saved_inst >> 12);
                        break;
                    case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                        immediate.write(saved_inst >> 12);
                        break;
                    default:
                        break;
                    }
                    break;
                case s2:    // Cycle 3 -- perform datapath operation
                    rd1.write(false);
                    rd2.write(false);
                    state = s3;

                    switch (saved_inst & 0x7f)
                    {
                    case 0b0110111: // LUI (Load Upper Immediate) Spec. PDF-Page 37
                        wr1.write(true);
                        wr2.write(true);
                        addr1.write((saved_inst >> 7) & 0x1f);
                        addr2.write((saved_inst >> 7) & 0x1f);
                        break;
                    case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                        wr1.write(true);
                        wr2.write(true);
                        addr1.write((saved_inst >> 7) & 0x1f);
                        addr2.write((saved_inst >> 7) & 0x1f);
                        break;
                    default:
                        wr1.write(false);
                        wr2.write(false);
                        break;
                    }
                    break;
                case s3:    // Cycle 4 -- write back
                    rd1.write(false);
                    rd2.write(false);
                    wr1.write(false);
                    wr2.write(false);
                    state = s0;

                    switch (saved_inst & 0x7f)
                    {
                    case 0b0010111: // AUIPC (Add Upper Immediate to PC) Spec. PDF-Page 37 )
                        pc = wr_pc.read();
                        PC.write(pc);
                        break;
                    default:
                        pc++;
                        PC.write(pc);
                        break;
                    }
                    break;
                default:
                    break;
                }
            }
        }

    }
};

class test_bench : sc_module
{
public:
    sc_out<bool>  			rst;    	// reset
    sc_out<unsigned> 		inst;  	    // generate instruction for cpu
    sc_out<unsigned> 		in_bus;  	// generate input for cpu
    sc_in<unsigned> 		out_bus;    // receive output from cpu

    sc_in_clk 			clk;
    
    bool        stopped;

    //Constructor
    SC_CTOR(test_bench) {
        SC_CTHREAD(entry, clk.neg());
        stopped = false;
    }

    // Process functionality in member function below
    void entry() {

        while (true) {
            wait();
            inst.write(0x00000000);
            in_bus.write(58);
            rst.write(true);

            wait();
            inst.write((0x1234A << 12) | (1 << 7) | 0b0110111);
            in_bus.write(58);
            rst.write(false);
            wait(3);

            inst.write((0xBEEF0 << 12) | (1 << 7) | 0b0110111);
            in_bus.write(58);
            rst.write(false);
            wait(3);

            inst.write((0x22222 << 12) | (1 << 7) | 0b0010111);
            in_bus.write(58);
            rst.write(false);
            wait(3);
            
            wait(16);
            stopped = true;
            sc_stop();

        }

    }
};


class new_control : sc_module
{
private:
    unsigned pc;
    std::vector<unsigned> instructions;

public:
    sc_in<bool>  			rst;    	// reset
    sc_out<unsigned> 		inst;  	    // instruction output
    sc_in_clk 			clk;
    sc_vector < sc_out< unsigned > > e_valid;
    sc_vector < sc_out< unsigned > > e_valid2;
    //Constructor
    SC_CTOR(new_control) : e_valid("my_port", 4),e_valid2("port2", 4){
        SC_CTHREAD(entry, clk.pos());

        //sc_vector<sc_out< unsigned >> ee_valid("vector_name", 4);
        //e_valid = &ee_valid;

        pc = 0;
        instructions = {
            0x00100093,
            0x00108663,
            0x00208093,
            0x0080006F,
            0x00408093,
            0x00108093,
            0x00000013
        };
    }

    // Process functionality in member function below
    void entry() {

        while (true) {
            wait();
            (e_valid)[0].write(2);
            (e_valid)[1].write(4);
            (e_valid)[2].write(8);
            (e_valid)[3].write(10);
            (e_valid2)[0].write(2);
            (e_valid2)[1].write(4);
            (e_valid2)[2].write(8);
            (e_valid2)[3].write(10);
            if (rst.read())
            {
                pc = 0;
            }
            else
            {
                if (instructions.size() - 1 > pc)
                {
                    pc++;
                }
            }

            inst.write(instructions[pc]);
        }
    }
};


class issue_combinational : sc_module
{
private:
    unsigned ENTRY_COUNT = 5;
public:
    sc_in<unsigned> 		inst;  	    // instruction input
    sc_in_clk 			clk;

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

    //Constructor
    SC_CTOR(issue_combinational) : entry_valid_reg("entry_valid_reg", ENTRY_COUNT), entry_rs1_mark_reg("entry_rs1_mark_reg", ENTRY_COUNT),
        entry_rs2_mark_reg("entry_rs2_mark_reg", ENTRY_COUNT), entry_rs1_reg("entry_rs1_reg", ENTRY_COUNT), entry_rs2_reg("entry_rs2_reg", ENTRY_COUNT),
        entry_inst_reg("entry_inst_reg", ENTRY_COUNT),

        entry_valid_next("entry_valid_next", ENTRY_COUNT), entry_rs1_mark_next("entry_rs1_mark_next", ENTRY_COUNT),
        entry_rs2_mark_next("entry_rs2_mark_next", ENTRY_COUNT), entry_rs1_next("entry_rs1_next", ENTRY_COUNT), entry_rs2_next("entry_rs2_next", ENTRY_COUNT),
        entry_inst_next("entry_inst_next", ENTRY_COUNT)
    {
        SC_CTHREAD(entry, clk.neg());

    }

    // Process functionality in member function below
    void entry() {
        while (true) {
            wait();
            unsigned instv = inst.read();
            unsigned rd = instv >> 7 & 0x1F;
            unsigned rs1 = instv >> 15 & 0x1F;
            unsigned rs2 = instv >> 20 & 0x1F;

            for (unsigned i = 0; i < ENTRY_COUNT; i++)
            {
                if (entry_valid_reg[i].read() == 0)
                {
                    entry_rs1_next[i].write(rs1);
                    entry_rs2_next[i].write(rs2);
                    entry_valid_next[i].write(1);
                    entry_inst_next[i].write(instv);

                    break;
                }
            }
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

    //Constructor
    SC_CTOR(reservation_station) : entry_valid_reg("entry_valid_reg", ENTRY_COUNT), entry_rs1_mark_reg("entry_rs1_mark_reg", ENTRY_COUNT),
        entry_rs2_mark_reg("entry_rs2_mark_reg", ENTRY_COUNT), entry_rs1_reg("entry_rs1_reg", ENTRY_COUNT), entry_rs2_reg("entry_rs2_reg", ENTRY_COUNT), 
        entry_inst_reg("entry_inst_reg", ENTRY_COUNT),

        entry_valid_next("entry_valid_next", ENTRY_COUNT), entry_rs1_mark_next("entry_rs1_mark_next", ENTRY_COUNT),
        entry_rs2_mark_next("entry_rs2_mark_next", ENTRY_COUNT), entry_rs1_next("entry_rs1_next", ENTRY_COUNT), entry_rs2_next("entry_rs2_next", ENTRY_COUNT),
        entry_inst_next("entry_inst_next", ENTRY_COUNT) 
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
            cout << "here1" << endl;
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
        
    
    }
};

int sc_main(int, char* []) {

    // ************************ Register File ***********************************
    sc_signal<unsigned>  		rf_addr1("RF_ADDR1");  		// physical address1
    sc_signal<unsigned>  		rf_addr2("RF_ADDR2");  		// physical address2
    sc_signal<bool>  			rf_rd1("RF_READ1");    		// read enable 1
    sc_signal<bool>  			rf_rd2("RF_READ2");    		// read enable 2
    sc_signal<bool>  			rf_wr1("RF_WRITE1");    		// write enable 1
    sc_signal<bool>  			rf_wr2("RF_WRITE2");    		// write enable 2

    sc_signal<unsigned> 		rf_wr_data("RF_WR_DATA1");  	// register file data input
    sc_signal<unsigned> 		rf_rd_data1("RF_RD_DATA1");  	// register file data output read port 1
    sc_signal<unsigned> 		rf_rd_data2("RF_RD_DATA2");  	// register file data output read port 2

    // ************************ Data Path ***********************************
    sc_signal<unsigned>  		dp_dp_ctrl("DP_CTRL");  	// data path control signal
    sc_signal<unsigned> 		dp_wr_pc("DP_WRITE_PC");  	// data path write to program counter
    sc_signal<unsigned> 		dp_in_bus("DP_INPUT_BUS");  	// data path receive data from outside, DRAM, etc
    sc_signal<unsigned> 		dp_out_bus("DP_OUTPUT_BUS");  	// data path transmit data to outside, DRAM, etc

    // ************************ Control ***********************************
    sc_signal<bool>             ctrl_rst("CTRL_RESET");            // reset
    sc_signal<unsigned> 		ctrl_inst("CTRL_INSTRUCTION");  	        // instruction for cpu
    sc_signal<unsigned> 		ctrl_immediate("CTRL_IMMEDIATE");      // generate immediate from instruction to datapath
    sc_signal<unsigned> 		ctrl_PC("CTRL_PROGRAM_COUNTER");  	        // keep track of program counter


    sc_clock clk("Clock", 1, SC_NS, 0.5, 0.0, SC_NS); // 1ns period, 0.5 duty cycle, start at 0ns

    register_file RF("REGISTER_FILE_BLOCK");
    RF.addr1(rf_addr1);  		// physical address1
    RF.addr2(rf_addr2);  		// physical address2
    RF.rd1(rf_rd1);    		// read enable 1
    RF.rd2(rf_rd2);    		// read enable 2
    RF.wr1(rf_wr1);    		// write enable 1
    RF.wr2(rf_wr2);    		// write enable 2
    RF.wr_data(rf_wr_data);  	// register file data input
    RF.rd_data1(rf_rd_data1);  	// register file data output read port 1
    RF.rd_data2(rf_rd_data2);  	// register file data output read port 2
    RF.clk(clk);

    data_path DP("DATA_PATH_BLOCK");
    DP.dp_ctrl(dp_dp_ctrl);  	// data path control signal
    DP.wr_data(rf_wr_data);  	// write to register file
    DP.wr_pc(dp_wr_pc);  	    // write to program counter
    DP.PC(ctrl_PC);  	        // program counter from control unit
    DP.rd_data1(rf_rd_data1);  	// register file data input from read port 1
    DP.rd_data2(rf_rd_data2);  	// register file data input from read port 2
    DP.immediate(ctrl_immediate);             // immediate from control unit
    DP.in_bus(dp_in_bus);  	    // receive data from outside, DRAM, etc
    DP.out_bus(dp_out_bus);  	// transmit data to outside, DRAM, etc
    DP.clk(clk);

    control CTRL("CONTROL_BLOCK");
    CTRL.rst(ctrl_rst);         // reset
    CTRL.inst(ctrl_inst);  	    // instruction for cpu
    CTRL.addr1(rf_addr1);  		// address1 for register file port 1
    CTRL.addr2(rf_addr2);  		// address1 for register file port 2
    CTRL.rd1(rf_rd1);    		// register file read port 1 enable
    CTRL.rd2(rf_rd2);    		// register file read port 2 enable
    CTRL.wr1(rf_wr1);    		// register file write port 1 enable
    CTRL.wr2(rf_wr2);    		// register file write port 2 enable
    CTRL.dp_ctrl(dp_dp_ctrl);  	// generate data path control signal
    CTRL.immediate(ctrl_immediate);      // generate immediate from instruction to datapath
    CTRL.PC(ctrl_PC);  	        // keep track of program counter
    CTRL.wr_pc(dp_wr_pc);  	    // calculated new program counter from datapath
    CTRL.clk(clk);

    test_bench TB("TEST_BENCH");
    TB.rst(ctrl_rst);    	    // reset
    TB.inst(ctrl_inst);  	    // generate instruction for cpu
    TB.in_bus(dp_in_bus);  	    // generate input for cpu
    TB.out_bus(dp_out_bus);     // receive output from cpu
    TB.clk(clk);

    cout << "Register1 " << std::hex << RF.registers[1] << endl;

    // ------------------------------------------------ New Architecture Below --------------------------------------

    sc_signal<unsigned> 		new_control_inst("CTRL_INST");  	    // instruction output
    sc_vector<sc_signal<unsigned>> new_control_vv("CTRL_vector", 4);
    sc_vector<sc_signal<unsigned>> new_control_vv2("CTRL_vector2", 4);

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

    new_control NCTRL("NEW_CONTROL");
    NCTRL.inst(new_control_inst);
    NCTRL.e_valid(new_control_vv);
    NCTRL.e_valid2(new_control_vv2);
    NCTRL.rst(ctrl_rst);
    NCTRL.clk(clk);

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

    issue_combinational ISSUE_COM("ISSUE_COMBINATIONAL_LOGIC");
    ISSUE_COM.clk(clk);
    ISSUE_COM.inst(new_control_inst);
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

    sc_trace_file* Tf;
    Tf = sc_create_vcd_trace_file("traces");
    //((vcd_trace_file*)Tf)->sc_set_vcd_time_unit(-9);
    sc_trace(Tf, clk, "clk");
    sc_trace(Tf, TB.rst, "rst");
    sc_trace(Tf, NCTRL.inst, "nctrl_inst");

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
    }
    
    //sc_trace(Tf, clk, "clk");
   /* sc_trace(Tf, TB.inst, "inst");
    sc_trace(Tf, CTRL.saved_inst, "saved_inst");
    sc_trace(Tf, TB.rst, "rst");
    sc_trace(Tf, TB.in_bus, "S2");
    sc_trace(Tf, CTRL.dp_ctrl, "S3");
    
    sc_trace(Tf, (NCTRL.e_valid)[0], "nctrl_vvv0");
    sc_trace(Tf, (NCTRL.e_valid)[1], "nctrl_vvv1");
    sc_trace(Tf, (NCTRL.e_valid)[2], "nctrl_vvv2");
    sc_trace(Tf, (NCTRL.e_valid)[3], "nctrl_vvv3");
    sc_trace(Tf, (NCTRL.e_valid2)[0], "nctrl_v2v0");
    sc_trace(Tf, (NCTRL.e_valid2)[1], "nctrl_v2v1");
    sc_trace(Tf, (NCTRL.e_valid2)[2], "nctrl_v2v2");
    sc_trace(Tf, (NCTRL.e_valid2)[3], "nctrl_v2v3");*/

    
    unsigned old_PC = 0;
    int inst_tb = 0;
    int i = 0;
    while(false)
    {
        if (TB.stopped == true) // cause error if call sc_start after sc_stop being called in TB
        {
            break;
        }

        sc_start(250, SC_PS);
        cout << std::dec << (i+1)*250 << "ps";
        cout << ((i + 1) * 250 % 1000 == 250 ? " --- posedge outcome" : "") << endl;
        cout << "Clock: " << clk.read() << endl;
        cout << "Instruction: " << std::hex << TB.inst.read() << endl;
        cout << "Instruction Saved: " << std::hex << CTRL.saved_inst << endl;
        cout << "Reset: " << TB.rst.read() << endl;
        cout << "In_bus: " << std::hex << TB.in_bus.read() << endl;
        cout << "dp_ctrl: " << std::hex << CTRL.dp_ctrl.read() << endl;
        cout << "PC: " << std::hex << CTRL.PC.read() << endl;
        cout << "ctrl_state: " << CTRL.state << endl;
        cout << "ctrl_immediate: " << std::hex << CTRL.immediate.read() << endl;
        cout << "wr_data: " << std::hex << RF.wr_data.read() << endl;
        cout << "Register1 " << std::hex << RF.registers[1] << endl;
        cout << endl;

        if ((i + 1) * 250 % 1000 == 250)
        {
            // PC changed at this posedge, meaning one insturction finished, let's check result
            if (CTRL.PC.read() != old_PC)
            {
                cout << "check instruction outcome!!!!!!!!!!!!!!!!!!!!!!!!!!!!" << endl << endl;

                switch (inst_tb)
                {
                case 0:
                    if (!(RF.registers[1] == 0x1234A000))
                    {
                        cout << "Verification Failed" << endl;
                        sc_stop();
                    } 
                    break;
                case 1:
                    if (!(RF.registers[1] == 0xBEEF0000))
                    {
                        cout << "Verification Failed" << endl;
                        sc_stop();
                    }
                    break;
                case 2:
                    if (!( (RF.registers[1] == (0x22222000 + old_PC)) && CTRL.PC.read() == (0x22222000 + old_PC) ))
                    {
                        cout << "Verification Failed" << endl;
                        sc_stop();
                    }
                    break;
                default:
                    break;
                }
                inst_tb++;
            }
        }
        old_PC = CTRL.PC.read();
        i++;
    }

    
    cout << "Register1 " << std::hex << RF.registers[1] << endl;

    cout << "Verification Successed" << endl;


    

    sc_start(10, SC_NS);  // run forever
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

// UnnamedSystemC1.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <systemc.h>

class write_if : virtual public sc_interface
{
public:
    virtual void write(char) = 0;
    virtual void reset() = 0;
};

class read_if : virtual public sc_interface
{
public:
    virtual void read(char&) = 0;
    virtual int num_available() = 0;
};

class fifo : public sc_channel, public write_if, public read_if
{
public:
    fifo(sc_module_name name) : sc_channel(name), num_elements(0), first(0) {}

    void write(char c) {
        if (num_elements == max)
            wait(read_event);

        data[(first + num_elements) % max] = c;
        ++num_elements;
        write_event.notify();
    }

    void read(char& c) {
        if (num_elements == 0)
            wait(write_event);

        c = data[first];
        --num_elements;
        first = (first + 1) % max;
        read_event.notify();
    }

    void reset() { num_elements = first = 0; }

    int num_available() { return num_elements; }

private:
    enum e { max = 10 };
    char data[max];
    int num_elements, first;
    sc_event write_event, read_event;
};

class producer : public sc_module
{
public:
    sc_port<write_if> out;

    SC_HAS_PROCESS(producer);

    producer(sc_module_name name) : sc_module(name)
    {
        SC_THREAD(main);
    }

    void main()
    {
        const char* str =
            "Visit www.accellera.org and see what SystemC can do for you today!\n";

        while (*str)
            out->write(*str++);

        sc_stop();
    }
};

class consumer : public sc_module
{
public:
    sc_port<read_if> in;

    SC_HAS_PROCESS(consumer);

    consumer(sc_module_name name) : sc_module(name)
    {
        SC_THREAD(main);
    }

    void main()
    {
        char c;
        cout << endl << endl;

        while (true) {
            in->read(c);
            cout << c << flush;

            if (in->num_available() == 1)
                cout << "<1>" << flush;
            if (in->num_available() == 9)
                cout << "<9>" << flush;
        }
    }
};


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

                wait();
                registers[address1] = wr_data.read();

            }
            else if (wr1 == false && wr2 == false)
            {
                if (rd1 == true)
                {
                    // Read port 1 operation
                    wait();
                    rd_data1.write(registers[address1]);

                }

                if (rd2 == true)
                {
                    // Read port 1 operation
                    wait();
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


class top : public sc_module
{
public:
    fifo* fifo_inst;
    producer* prod_inst;
    consumer* cons_inst;

    top(sc_module_name name) : sc_module(name)
    {
        fifo_inst = new fifo("Fifo1");

        prod_inst = new producer("Producer1");
        prod_inst->out(*fifo_inst);

        cons_inst = new consumer("Consumer1");
        cons_inst->in(*fifo_inst);
    }
};

int sc_main(int, char* []) {
    sc_signal<unsigned>  		rf_addr1("RF_ADDR1");  		// physical address1
    sc_signal<unsigned>  		rf_addr2("RF_ADDR2");  		// physical address2
    sc_signal<bool>  			rf_rd1("RF_READ1");    		// read enable 1
    sc_signal<bool>  			rf_rd2("RF_READ2");    		// read enable 2
    sc_signal<bool>  			rf_wr1("RF_WRITE1");    		// write enable 1
    sc_signal<bool>  			rf_wr2("RF_WRITE2");    		// write enable 2

    sc_signal<unsigned> 		rf_wr_data("RF_WR_DATA1");  	// register file data input
    sc_signal<unsigned> 		rf_rd_data1("RF_RD_DATA1");  	// register file data output read port 1
    sc_signal<unsigned> 		rf_rd_data2("RF_RD_DATA2");  	// register file data output read port 2


    sc_clock clk("Clock", 1, SC_NS, 0.5, 0.0, SC_NS);

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



    top top1("Top1");
    sc_start();
    return 0;
}

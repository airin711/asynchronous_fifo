`default_nettype wire
`timescale 1 ns / 1 ns   
    
  module test();

    parameter R_CLK_INTERVAL = 0;
    parameter W_CLK_INTERVAL = 0;
    parameter R_CLK_CYCLE_TIME = 70;
    parameter W_CLK_CYCLE_TIME = 50;
    parameter INIT_INTERVAL = 350;
    parameter SIM_CYCLE = 10000;
//    parameter SIM_TIME = INIT_INTERVAL + SIM_CYCLE * R_CLK_CYCLE_TIME * 2;
    parameter SIM_TIME = 10000000;


    reg         R_CLK;
    reg         W_CLK;
    reg         RST_N;
    reg [31:0]  R_CLK_CYCLE;
    reg [31:0]  W_CLK_CYCLE;
    wire [31:0] counter1, counter2;
    wire [63:0] sum1, sum2;
    wire        done1, done2;

    initial begin
        R_CLK = 0;
        #(R_CLK_INTERVAL);
        R_CLK = 1;
        forever #(R_CLK_CYCLE_TIME) R_CLK = ~R_CLK;
    end

    initial begin
        W_CLK = 0;
        #(W_CLK_INTERVAL);
        W_CLK = 1;
        forever #(W_CLK_CYCLE_TIME) W_CLK = ~W_CLK;
    end


    always @(posedge R_CLK)
      R_CLK_CYCLE <= (!RST_N) ? 0 : R_CLK_CYCLE + 1;

    always @(posedge W_CLK) 
      W_CLK_CYCLE <= (!RST_N) ? 0 : W_CLK_CYCLE + 1;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, afifo_test);
    end

    initial begin
        RST_N = 0;
        #INIT_INTERVAL;
        RST_N = 1;
    end
    
    initial begin
        #SIM_TIME;
        $finish;
    end



    afifo_test afifo_test(W_CLK, R_CLK, RST_N, counter1, counter2, sum1, sum2, done1, done2);


    always @(posedge R_CLK) begin
        if(!afifo_test.read_side2.done) begin
	        $display("rdata: %x, deq: %b, empty: %b, counter: %d, sum: %d", 
		             afifo_test.read_side2.read_data,
		             afifo_test.read_side2.deq,
		             afifo_test.read_side2.empty,
		             afifo_test.read_side2.counter,
		             afifo_test.read_side2.sum
                     );
	        $display("wdata: %x, enq: %b, full: %b, done: %b",        
		             afifo_test.write_side1.write_data,
		             afifo_test.write_side1.enq,
		             afifo_test.write_side1.full,
                     afifo_test.write_side1.done
                     );

        end
    end

/*
    always @(posedge W_CLK) begin
        if(!afifo_test.read_side1.done) begin
	        $display("rdata: %x, deq: %b, empty: %b, counter: %d, sum: %d", 
		             afifo_test.read_side1.read_data,
		             afifo_test.read_side1.deq,
		             afifo_test.read_side1.empty,
		             afifo_test.read_side1.counter,
		             afifo_test.read_side1.sum
                     );

	        $display("wdata: %x, enq: %b, full: %b, done: %b", 
		             afifo_test.write_side1.write_data,
		             afifo_test.write_side1.enq,
		             afifo_test.write_side1.full,
                     afifo_test.write_side1.done
                     );

        end
    end
*/
endmodule // test


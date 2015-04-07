`default_nettype none
module afifo_test (
                   input wire 	  f_clk,
                   input wire 	  l_clk,
                   input wire 	  rst_n,
                   output wire [31:0]    counter1,
                   output wire [31:0]    counter2,
                   output wire [63:0]    sum1,
                   output wire [63:0]    sum2,
                   output wire           done1,
                   output wire           done2
                   );

    wire [63:0]     data_in1, data_in2;
    wire [63:0]     data_out1, data_out2;
    wire            deq1, enq1;
    wire            deq2, enq2;
    wire            full1, empty1;
    wire            full2, empty2;

    AFIFO #(.DATA_WIDTH(64), .AFIFO_SIZE(4))
    AFIFO1(
           .RCLK(f_clk),
           .WCLK(l_clk),
           .RST_X(rst_n),
           .enq(enq1),
           .deq(deq1),
           .data_in(data_in1),
           .data_out(data_out1),
           .empty(empty1),
           .full(full1)
	 	   );
    
    read_side read_side1(f_clk, rst_n, data_out1, empty1, deq1, counter1, sum1, done1);

    write_side write_side1(l_clk, rst_n, data_in1, full1, enq1);

    AFIFO #(.DATA_WIDTH(64), .AFIFO_SIZE(4))
    AFIFO2(
           .RCLK(l_clk),
           .WCLK(f_clk),
           .RST_X(rst_n),
           .enq(enq2),
           .deq(deq2),
           .data_in(data_in2),
           .data_out(data_out2),
           .empty(empty2),
           .full(full2)
	 	   );
    
    read_side read_side2(l_clk, rst_n, data_out2, empty2, deq2, counter2, sum2, done2);

    write_side write_side2(f_clk, rst_n, data_in2, full2, enq2);

endmodule   


module write_side (
                   input  wire         CLK, RST_N,
                   output reg  [63:0]  write_data,
                   input  wire         full,
                   output reg          enq
                   );

    reg done;

    always @ (posedge CLK) begin
        if(!RST_N) {enq, write_data, done} <= 0;
        else begin
            if(!done && !full) begin
                enq      <= 1;
                write_data <=  write_data + 1;
                if(write_data == 64'd99999)   done <= 1;
            end else begin
                enq      <= 0;
                if(enq) begin
                    write_data <= write_data - 1;
                    done   <= 0;
                end
            end
        end
    end
endmodule // write_side

module read_side (
                  input   wire          CLK, RST_N,
                  input   wire  [63:0]  read_data,
                  input   wire          empty,
                  output  wire          deq,
                  output  reg   [31:0]  counter,
                  output  reg   [63:0]  sum,
                  output  reg           done
                  );

    reg deq_reg;
    assign deq = deq_reg && !done;

    always @ (posedge CLK) begin
        if(!RST_N) deq_reg <= 0;
        else begin
            if(!empty && !done) begin
                deq_reg <= 1;
            end else begin
                deq_reg  <= 0;
			end
        end
    end
    always @(posedge CLK) begin
        if(!RST_N) {counter, sum, done} <= 0;
        else if(deq && !empty) begin
            counter <= counter + 1;
            sum <= sum + read_data;
            if(counter == 64'd99999) begin
                done <= 1;
            end
        end
    end
endmodule // read_side


`include "../rtl/system.v"
`default_nettype none

module main(CLK_IN, RST_X_IN, LED, TXD);
    input       CLK_IN;
    input       RST_X_IN;

	output reg [15:0] LED;
    output            TXD;
    

    wire    CLK1;
	wire    CLK2;
	wire    RST_X;
    wire [31:0] counter1;
    wire [31:0] counter2;
    wire [63:0] sum1;
    wire [63:0] sum2;
    wire        done1;
    wire        done2;
    reg         Tx_WE;
    reg  [31:0] Tx_data;
    wire        uart_ready;
    reg  [3:0]  uart_state;    
    

    //instances
    GEN gen(.CLK_IN(CLK_IN),
            .RST_X_I(~RST_X_IN),
            .CLK_O1(CLK1),
			   .CLK_O2(CLK2),
            .RST_X_O(RST_X));
            

    afifo_test afifo_test(.f_clk(CLK1),
                          .l_clk(CLK2),
                          .rst_n(RST_X),
                          .counter1(counter1),
                          .counter2(counter2),
                          .sum1(sum1),
                          .sum2(sum2),
                          .done1(done1),
                          .done2(done2)
                          );

    LCDC LCDC(.CLK(CLK1), 
              .RST_X(RST_X), 
              .DATA(Tx_data), 
              .WE(Tx_WE), 
              .TXD(TXD), 
              .READY(uart_ready)
              );


    always @(posedge CLK1 or negedge RST_X) begin
        if(!RST_X) begin
            {uart_state, Tx_data, Tx_WE} <= 0;
        end else if(done1 && done2) begin
            case(uart_state)
                0: begin
                    Tx_data <= sum1[63:32];
                    Tx_WE   <= 1;
                    uart_state <= 1;
                end
                1: begin
                    if(uart_ready) begin
                        Tx_data <= sum1[31:0];
                        Tx_WE   <= 1;
                        uart_state <= 2;
                    end
                end
                2: begin
                    if(uart_ready) begin
                        Tx_data <= counter1;
                        Tx_WE   <= 1;
                        uart_state <= 3;
                    end
                end
                3: begin
                    if(uart_ready) begin
                        Tx_data <= sum2[63:32];
                        Tx_WE   <= 1;
                        uart_state <= 4;
                    end
                end 
                4: begin
                    if(uart_ready) begin
                        Tx_data <= sum2[31:0];
                        Tx_WE   <= 1;
                        uart_state <= 5;
                    end
                end
                5: begin
                    if(uart_ready) begin
                        Tx_data <= counter2;
                        Tx_WE   <= 1;
                        uart_state <= 6;
                    end
                end
                6: begin
					 if(uart_ready) begin
                    Tx_WE   <= 0;
						  end
                end
            endcase // case (uart_state)
        end
    end

	reg [23:0] CLK1_count;
    reg [23:0] CLK2_count;
	always @(posedge CLK1 or negedge RST_X) begin
        if(~RST_X) begin
			LED[14:0]    <= 0;
		end else begin
            CLK1_count <= CLK1_count + 1;
			LED[0] <= RST_X;
            LED[1] <= done1;
            LED[2] <= done2;
            LED[3] <= uart_ready;
            LED[4] <= Tx_WE;
				LED[7:5]  <= uart_state[2:0];
            LED[13:8] <= 0;
            LED[14] <= CLK1_count[23];
		end
	end

    always @(posedge CLK2 or negedge RST_X) begin
        if(!RST_X) LED[15] <= 0;
        else begin
            CLK2_count <= CLK2_count + 1;
            LED[15]    <= CLK2_count[23];
        end
    end


endmodule


/***************************************************************************************/

//`define LCDC_WAIT 40 //default
`define LCDC_WAIT 100*(`DCM_CLKFX_MULTIPLY)/(`DCM_CLKFX_DIVIDE)
/***************************************************************************************/
module LCDC(CLK, RST_X, DATA, WE, TXD, READY);
	input        CLK, RST_X;
	input [31:0] DATA;
	input        WE;
	output reg   TXD;
	output reg   READY;
	
	reg [89:0]   cmd;
	reg [11:0]   waitnum;
	reg [6:0]    cnt;
	reg [31:0]   D;
	
	wire [7:0] d0 = (D[3:0]<10)   ? 8'd48 + D[3:0]   : 8'd87 + D[3:0];
	wire [7:0] d1 = (D[7:4]<10)   ? 8'd48 + D[7:4]   : 8'd87 + D[7:4];
	wire [7:0] d2 = (D[11:8]<10)  ? 8'd48 + D[11:8]  : 8'd87 + D[11:8];
	wire [7:0] d3 = (D[15:12]<10) ? 8'd48 + D[15:12] : 8'd87 + D[15:12];
	wire [7:0] d4 = (D[19:16]<10) ? 8'd48 + D[19:16] : 8'd87 + D[19:16];
	wire [7:0] d5 = (D[23:20]<10) ? 8'd48 + D[23:20] : 8'd87 + D[23:20];
	wire [7:0] d6 = (D[27:24]<10) ? 8'd48 + D[27:24] : 8'd87 + D[27:24];
	wire [7:0] d7 = (D[31:28]<10) ? 8'd48 + D[31:28] : 8'd87 + D[31:28];
	
	wire [89:0] value = {8'h20, 2'b01, // add space
	                     d0, 2'b01, d1, 2'b01, d2, 2'b01, d3, 2'b01,
	                     d4, 2'b01, d5, 2'b01, d6, 2'b01, d7, 2'b01};
	
	always @ (negedge RST_X or posedge CLK) begin
	    if(!RST_X) begin
	        TXD       <= 1;
	        READY     <= 1;
	        cmd       <= ~(90'b0);
	        waitnum   <= 0;
	        cnt       <= 0;
	    end else if( READY ) begin
	        TXD       <= 1;
	        waitnum   <= 0;
	        if( WE )begin
	            READY <= 0;
	            D     <= DATA;
	            cnt   <= 93;
	            $write("EOUT: %08x\n", DATA);
	        end
	    end else if(cnt==93) begin
	        cnt <= cnt - 1;
	        cmd <= value;
	    end else if( waitnum >= `LCDC_WAIT ) begin
	        TXD       <= cmd[0];
	        READY     <= (cnt == 1);
	        cmd       <= {1'b1, cmd[89:1]};
	        waitnum   <= 1;
	        cnt       <= cnt - 1;
	    end else begin
	        waitnum   <= waitnum + 1;
	    end
	end
endmodule // LCDC


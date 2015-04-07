`default_nettype none
`timescale 1ns/1ps

module AFIFO
  #(parameter      DATA_WIDTH  = 32,
                   AFIFO_SIZE  = 8)
    
    (input  wire                  RCLK, WCLK, RST_X,
     input  wire                  enq, deq,
     input  wire [DATA_WIDTH-1:0] data_in,
     output wire [DATA_WIDTH-1:0] data_out,
     output wire                  empty,
     output wire                  full
     );

    /////Internal connections & variables//////
    reg   [DATA_WIDTH-1:0]             mem[(2**AFIFO_SIZE)-1:0];
    reg   [AFIFO_SIZE:0]               R_bin, W_bin;
    reg   [AFIFO_SIZE:0]               Wp, Rp;
    reg   [AFIFO_SIZE:0]               Wp_rclk, Rp_wclk;
    reg   [AFIFO_SIZE:0]               Next_Wp, Next_Rp;
    reg   [AFIFO_SIZE:0]               preWp, preRp;
    reg                                error1, error2;

    assign data_out     = (Rp[AFIFO_SIZE]) ? mem[{!Rp[AFIFO_SIZE-1], Rp[AFIFO_SIZE-2:0]}] 
                                             :mem[Rp[AFIFO_SIZE-1:0]];
    assign empty  = (Wp_rclk == Rp);
    assign full   = (Wp == {~Rp_wclk[AFIFO_SIZE:AFIFO_SIZE-1], Rp_wclk[AFIFO_SIZE-2:0]});

    ////double flopping////
    always @(posedge RCLK) begin
        if(!RST_X) Wp_rclk <= 0;
        else Wp_rclk <= Wp;
    end

    always @(posedge WCLK) begin
        if(!RST_X) Rp_wclk <= 0;
        else Rp_wclk <= Rp;
    end

    ////write////
    always @ (posedge WCLK) begin
        if(!RST_X) begin
            {preWp,Wp}   <= 0;
            Next_Wp      <= 1;
            W_bin        <= 2;
        end else begin 
            if(enq && !full) begin
                if(Wp[AFIFO_SIZE]) mem[{!Wp[AFIFO_SIZE-1], Wp[AFIFO_SIZE-2:0]}] <= data_in;
                else mem[Wp[AFIFO_SIZE-1:0]] <= data_in;
                preWp   <= Wp;
                Wp      <= Next_Wp;
                Next_Wp <= (W_bin ^ {1'b0, (W_bin >> 1'b1)});
                W_bin   <= W_bin + 1;
            end else begin
                preWp   <= preWp;
                Wp      <= Wp;
                Next_Wp <= Next_Wp;
                W_bin   <= W_bin;
            end
        end
    end

    ////read////
    always @(posedge RCLK) begin
        if(!RST_X) begin
            {preRp,Rp}   <= 0;
            Next_Rp      <= 1;
            R_bin        <= 2;
        end else begin
            if(deq && !empty) begin
                preRp   <= Rp;
                Rp      <= Next_Rp;
                Next_Rp <= (R_bin ^ {1'b0, (R_bin >> 1'b1)});
                R_bin   <= R_bin + 1;
            end else begin
                preRp   <= preRp;
                Rp      <= Rp;
                Next_Rp <= Next_Rp;
                R_bin   <= R_bin;
            end
        end
    end
     
endmodule

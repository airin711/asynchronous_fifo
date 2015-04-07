`define DCM_CLKIN_PERIOD 10.000
`define DCM_CLKFX_MULTIPLY 8
`define DCM_CLKFX_DIVIDE   10
`define DCM_CLKIN_PERIOD2 10.000
`define DCM_CLKFX_MULTIPLY2 16
`define DCM_CLKFX_DIVIDE2   10

`default_nettype none

module CLKGEN1(CLK_IN, CLK_OUT, LOCKED);
    input  CLK_IN;
    output CLK_OUT, LOCKED;

    wire   CLK_IBUF, CLK_OBUF, CLK0, CLK0_OUT;

    BUFG   fbuf (.I(CLK0), .O(CLK0_OUT));    //feedback buffer
    BUFG   obuf (.I(CLK_OBUF), .O(CLK_OUT)); //output buffer

    assign CLK_IBUF = CLK_IN;
    DCM_SP dcm  (.CLKIN(CLK_IBUF), .CLKFX(CLK_OBUF), .CLK0(CLK0), .CLKFB(CLK0_OUT), 
                 .LOCKED(LOCKED), .RST(1'b0), .DSSEN(1'b0), .PSCLK(1'b0), 
                 .PSEN(1'b0), .PSINCDEC(1'b0));
    defparam dcm.CLKIN_PERIOD   = `DCM_CLKIN_PERIOD;
    defparam dcm.CLKFX_MULTIPLY = `DCM_CLKFX_MULTIPLY;
    defparam dcm.CLKFX_DIVIDE   = `DCM_CLKFX_DIVIDE;
endmodule

module CLKGEN2(CLK_IN, CLK_OUT, LOCKED);
    input  CLK_IN;
    output CLK_OUT, LOCKED;

    wire   CLK_IBUF, CLK_OBUF, CLK0, CLK0_OUT;

    BUFG   fbuf (.I(CLK0), .O(CLK0_OUT));    //feedback buffer
    BUFG   obuf (.I(CLK_OBUF), .O(CLK_OUT)); //output buffer

    assign CLK_IBUF = CLK_IN;
    DCM_SP dcm  (.CLKIN(CLK_IBUF), .CLKFX(CLK_OBUF), .CLK0(CLK0), .CLKFB(CLK0_OUT), 
                 .LOCKED(LOCKED), .RST(1'b0), .DSSEN(1'b0), .PSCLK(1'b0), 
                 .PSEN(1'b0), .PSINCDEC(1'b0));
    defparam dcm.CLKIN_PERIOD   = `DCM_CLKIN_PERIOD2;
    defparam dcm.CLKFX_MULTIPLY = `DCM_CLKFX_MULTIPLY2;
    defparam dcm.CLKFX_DIVIDE   = `DCM_CLKFX_DIVIDE2;
endmodule

module RSTGEN(CLK, RST_X_I, RST_X_O);
    input  CLK, RST_X_I;
    output RST_X_O;

    reg [7:0] cnt;
    assign RST_X_O = cnt[7];

    always @(posedge CLK or negedge RST_X_I) begin
        if      (!RST_X_I) cnt <= 0;
        else if (~RST_X_O) cnt <= (cnt + 1'b1);
    end
endmodule

module GEN(CLK_IN, RST_X_I, CLK_O1, CLK_O2, RST_X_O);
    input  CLK_IN, RST_X_I;
    output CLK_O1, CLK_O2, RST_X_O;
    
    wire LOCKED1;
	wire LOCKED2;
    wire clk_t;

    IBUFG ibuf (.I(CLK_IN), .O(clk_t));
    CLKGEN1 clkgen1(clk_t, CLK_O1, LOCKED1);
    CLKGEN2 clkgen2(clk_t, CLK_O2, LOCKED2);	
    RSTGEN rstgen(CLK_O1, (RST_X_I & LOCKED1 & LOCKED2), RST_X_O);
endmodule

`default_nettype none
`timescale 1ps / 1ps

module clk_wiz_ypcb (
    input  wire clk_in1,
    input  wire reset,
    output wire locked,
    output wire controller_clk,
    output wire ddr3_clk,
    output wire ddr3_clk_n,
    output wire ref_clk,
    output wire ddr3_clk_90
);
    wire clkfbout;
    wire controller_clk_unbuf;
    wire ddr3_clk_unbuf;
    wire ddr3_clk_n_unbuf;
    wire ref_clk_unbuf;
    wire ddr3_clk_90_unbuf;

    PLLE2_ADV #(
        .BANDWIDTH("OPTIMIZED"),
        .COMPENSATION("INTERNAL"),
        .STARTUP_WAIT("FALSE"),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT(4),
        .CLKFBOUT_PHASE(0.000),
        .CLKOUT0_DIVIDE(8),
        .CLKOUT0_PHASE(0.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT1_DIVIDE(2),
        .CLKOUT1_PHASE(0.000),
        .CLKOUT1_DUTY_CYCLE(0.500),
        .CLKOUT2_DIVIDE(4),
        .CLKOUT2_PHASE(0.000),
        .CLKOUT2_DUTY_CYCLE(0.500),
        .CLKOUT3_DIVIDE(2),
        .CLKOUT3_PHASE(135.000),
        .CLKOUT3_DUTY_CYCLE(0.500),
        .CLKOUT4_DIVIDE(2),
        .CLKOUT4_PHASE(180.000),
        .CLKOUT4_DUTY_CYCLE(0.500),
        .CLKIN1_PERIOD(5.000)
    ) pll_inst (
        .CLKFBOUT(clkfbout),
        .CLKOUT0(controller_clk_unbuf),
        .CLKOUT1(ddr3_clk_unbuf),
        .CLKOUT2(ref_clk_unbuf),
        .CLKOUT3(ddr3_clk_90_unbuf),
        .CLKOUT4(ddr3_clk_n_unbuf),
        .CLKFBIN(clkfbout),
        .CLKIN1(clk_in1),
        .LOCKED(locked),
        .RST(reset)
    );

    BUFG controller_clk_buf (.O(controller_clk), .I(controller_clk_unbuf));
    BUFG ddr3_clk_buf       (.O(ddr3_clk),       .I(ddr3_clk_unbuf));
    BUFG ddr3_clk_n_buf     (.O(ddr3_clk_n),     .I(ddr3_clk_n_unbuf));
    BUFG ref_clk_buf        (.O(ref_clk),        .I(ref_clk_unbuf));
    BUFG ddr3_clk_90_buf    (.O(ddr3_clk_90),    .I(ddr3_clk_90_unbuf));
endmodule

`default_nettype wire

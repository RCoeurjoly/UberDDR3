`timescale 1ps / 1ps
`default_nettype none

module clk_wiz (
    input wire clk_in1,
    output wire clk_out1,
    output wire clk_out2,
    output wire clk_out3,
    output wire clk_out4,
    input wire reset,
    output wire locked
);
    wire clkfbout;
    wire clk0;
    wire clk1;
    wire clk2;
    wire clk3;

    PLLE2_ADV #(
        .BANDWIDTH("OPTIMIZED"),
        .COMPENSATION("INTERNAL"),
        .STARTUP_WAIT("FALSE"),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT(20),
        .CLKFBOUT_PHASE(0.000),
        .CLKOUT0_DIVIDE(8),
        .CLKOUT0_PHASE(0.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT1_DIVIDE(2),
        .CLKOUT1_PHASE(0.000),
        .CLKOUT1_DUTY_CYCLE(0.500),
        .CLKOUT2_DIVIDE(5),
        .CLKOUT2_PHASE(0.000),
        .CLKOUT2_DUTY_CYCLE(0.500),
        .CLKOUT3_DIVIDE(2),
        .CLKOUT3_PHASE(90.000),
        .CLKOUT3_DUTY_CYCLE(0.500),
        .CLKIN1_PERIOD(20.000)
    ) pll (
        .CLKFBOUT(clkfbout),
        .CLKOUT0(clk0),
        .CLKOUT1(clk1),
        .CLKOUT2(clk2),
        .CLKOUT3(clk3),
        .CLKFBIN(clkfbout),
        .CLKIN1(clk_in1),
        .LOCKED(locked),
        .RST(reset)
    );

    BUFG controller_buf (.O(clk_out1), .I(clk0));
    BUFG ddr3_buf       (.O(clk_out2), .I(clk1));
    BUFG ref_buf        (.O(clk_out3), .I(clk2));
    BUFG ddr3_90_buf    (.O(clk_out4), .I(clk3));
endmodule

`default_nettype wire

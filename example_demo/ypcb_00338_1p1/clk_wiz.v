`timescale 1ps/1ps

`ifndef UBERDDR3_YPCB_PLL_FB_MULT
`define UBERDDR3_YPCB_PLL_FB_MULT 20
`endif

`ifndef UBERDDR3_YPCB_PLL_CLKOUT0_DIVIDE
`define UBERDDR3_YPCB_PLL_CLKOUT0_DIVIDE 12
`endif

`ifndef UBERDDR3_YPCB_PLL_CLKOUT1_DIVIDE
`define UBERDDR3_YPCB_PLL_CLKOUT1_DIVIDE 3
`endif

`ifndef UBERDDR3_YPCB_PLL_CLKOUT2_DIVIDE
`define UBERDDR3_YPCB_PLL_CLKOUT2_DIVIDE 5
`endif

`ifndef UBERDDR3_YPCB_PLL_CLKOUT3_DIVIDE
`define UBERDDR3_YPCB_PLL_CLKOUT3_DIVIDE 3
`endif

module clk_wiz
 (
  input wire         clk_in1,
  output wire        clk_out1,
  output wire        clk_out2,
  output wire        clk_out3,
  output wire        clk_out4,
  input wire         reset,
  output wire        locked
 );
  wire        clk_out1_clk_wiz_0;
  wire        clk_out2_clk_wiz_0;
  wire        clk_out3_clk_wiz_0;
  wire        clk_out4_clk_wiz_0;


  wire clkfbout;

  PLLE2_ADV
  #(.BANDWIDTH            ("OPTIMIZED"),
    .COMPENSATION         ("INTERNAL"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (1),
    .CLKFBOUT_MULT        (`UBERDDR3_YPCB_PLL_FB_MULT),
    .CLKFBOUT_PHASE       (0.000),
    .CLKOUT0_DIVIDE       (`UBERDDR3_YPCB_PLL_CLKOUT0_DIVIDE),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT1_DIVIDE       (`UBERDDR3_YPCB_PLL_CLKOUT1_DIVIDE),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT2_DIVIDE       (`UBERDDR3_YPCB_PLL_CLKOUT2_DIVIDE),
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    .CLKOUT3_DIVIDE       (`UBERDDR3_YPCB_PLL_CLKOUT3_DIVIDE),
    .CLKOUT3_PHASE        (90.000),
    .CLKOUT3_DUTY_CYCLE   (0.500),
    .CLKIN1_PERIOD        (20.000) // 50 MHz input
  )
  plle2_adv_inst
   (
    .CLKFBOUT            (clkfbout),
    .CLKOUT0             (clk_out1_clk_wiz_0),
    .CLKOUT1             (clk_out2_clk_wiz_0),
    .CLKOUT2             (clk_out3_clk_wiz_0),
    .CLKOUT3             (clk_out4_clk_wiz_0),
    .CLKFBIN             (clkfbout),
	.CLKIN1              (clk_in1),
    .LOCKED              (locked),
    .RST                 (reset)
  );
  BUFG clkout1_buf
   (.O   (clk_out1),
    .I   (clk_out1_clk_wiz_0));
  BUFG clkout2_buf
   (.O   (clk_out2),
    .I   (clk_out2_clk_wiz_0));
  BUFG clkout3_buf
   (.O   (clk_out3),
    .I   (clk_out3_clk_wiz_0));
  BUFG clkout4_buf
   (.O   (clk_out4),
    .I   (clk_out4_clk_wiz_0));
endmodule

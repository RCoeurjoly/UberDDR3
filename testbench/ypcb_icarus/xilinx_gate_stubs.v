`timescale 1ps / 1ps
`default_nettype none

// Minimal Icarus-compatible behavioral stubs for Yosys/OpenXC7 gate-level
// experiments. These are not timing-accurate vendor simulation models.

module PLLE2_ADV #(
    parameter BANDWIDTH = "OPTIMIZED",
    parameter CLKFBOUT_MULT = 5,
    parameter CLKFBOUT_PHASE = 0,
    parameter CLKIN1_PERIOD = 0,
    parameter CLKOUT0_DIVIDE = 1,
    parameter CLKOUT0_DUTY_CYCLE = 0,
    parameter CLKOUT0_PHASE = 0,
    parameter CLKOUT1_DIVIDE = 1,
    parameter CLKOUT1_DUTY_CYCLE = 0,
    parameter CLKOUT1_PHASE = 0,
    parameter CLKOUT2_DIVIDE = 1,
    parameter CLKOUT2_DUTY_CYCLE = 0,
    parameter CLKOUT2_PHASE = 0,
    parameter CLKOUT3_DIVIDE = 1,
    parameter CLKOUT3_DUTY_CYCLE = 0,
    parameter CLKOUT3_PHASE = 0,
    parameter COMPENSATION = "INTERNAL",
    parameter DIVCLK_DIVIDE = 1,
    parameter STARTUP_WAIT = "FALSE"
) (
    input wire CLKFBIN,
    output wire CLKFBOUT,
    input wire CLKIN1,
    output wire CLKOUT0,
    output wire CLKOUT1,
    output wire CLKOUT2,
    output wire CLKOUT3,
    output wire CLKOUT4,
    output wire CLKOUT5,
    output wire LOCKED,
    input wire RST
);
    assign CLKFBOUT = CLKFBIN;
    assign CLKOUT0 = CLKIN1;
    assign CLKOUT1 = CLKIN1;
    assign CLKOUT2 = CLKIN1;
    assign CLKOUT3 = CLKIN1;
    assign CLKOUT4 = CLKIN1;
    assign CLKOUT5 = CLKIN1;
    assign LOCKED = !RST;
endmodule

module IDELAYCTRL #(
    parameter SIM_DEVICE = "7SERIES"
) (
    output wire RDY,
    input wire REFCLK,
    input wire RST
);
    assign RDY = !RST;
    wire unused = REFCLK;
endmodule

module IDELAYE2 #(
    parameter CINVCTRL_SEL = "FALSE",
    parameter DELAY_SRC = "IDATAIN",
    parameter HIGH_PERFORMANCE_MODE = "FALSE",
    parameter IDELAY_TYPE = "FIXED",
    parameter IDELAY_VALUE = 0,
    parameter PIPE_SEL = "FALSE",
    parameter REFCLK_FREQUENCY = 200.0,
    parameter SIGNAL_PATTERN = "DATA"
) (
    input wire C,
    input wire CE,
    input wire CINVCTRL,
    input wire [4:0] CNTVALUEIN,
    output wire [4:0] CNTVALUEOUT,
    input wire DATAIN,
    output wire DATAOUT,
    input wire IDATAIN,
    input wire INC,
    input wire LD,
    input wire LDPIPEEN,
    input wire REGRST
);
    assign DATAOUT = (DELAY_SRC == "DATAIN") ? DATAIN : IDATAIN;
    assign CNTVALUEOUT = CNTVALUEIN;
    wire unused = C ^ CE ^ CINVCTRL ^ INC ^ LD ^ LDPIPEEN ^ REGRST;
endmodule

module ISERDESE2 #(
    parameter DATA_RATE = "DDR",
    parameter DATA_WIDTH = 4,
    parameter INIT_Q1 = 1'b0,
    parameter INIT_Q2 = 1'b0,
    parameter INIT_Q3 = 1'b0,
    parameter INIT_Q4 = 1'b0,
    parameter INTERFACE_TYPE = "NETWORKING",
    parameter IOBDELAY = "NONE",
    parameter NUM_CE = 1,
    parameter OFB_USED = "FALSE",
    parameter SERDES_MODE = "MASTER",
    parameter SRVAL_Q1 = 1'b0,
    parameter SRVAL_Q2 = 1'b0,
    parameter SRVAL_Q3 = 1'b0,
    parameter SRVAL_Q4 = 1'b0
) (
    input wire BITSLIP,
    input wire CE1,
    input wire CE2,
    input wire CLK,
    input wire CLKB,
    input wire CLKDIV,
    input wire D,
    input wire DDLY,
    input wire OFB,
    output reg O,
    output reg Q1,
    output reg Q2,
    output reg Q3,
    output reg Q4,
    output reg Q5,
    output reg Q6,
    output reg Q7,
    output reg Q8,
    input wire RST,
    input wire SHIFTIN1,
    input wire SHIFTIN2,
    output wire SHIFTOUT1,
    output wire SHIFTOUT2
);
    assign SHIFTOUT1 = 1'b0;
    assign SHIFTOUT2 = 1'b0;
    always @(posedge CLKDIV or posedge RST) begin
        if (RST) begin
            O <= 1'b0;
            Q1 <= INIT_Q1;
            Q2 <= INIT_Q2;
            Q3 <= INIT_Q3;
            Q4 <= INIT_Q4;
            Q5 <= 1'b0;
            Q6 <= 1'b0;
            Q7 <= 1'b0;
            Q8 <= 1'b0;
        end else begin
            O <= D;
            Q1 <= DDLY;
            Q2 <= DDLY;
            Q3 <= DDLY;
            Q4 <= DDLY;
            Q5 <= DDLY;
            Q6 <= DDLY;
            Q7 <= DDLY;
            Q8 <= DDLY;
        end
    end
    wire unused = BITSLIP ^ CE1 ^ CE2 ^ CLK ^ CLKB ^ OFB ^ SHIFTIN1 ^ SHIFTIN2;
endmodule

module OSERDESE2 #(
    parameter DATA_RATE_OQ = "DDR",
    parameter DATA_RATE_TQ = "BUF",
    parameter DATA_WIDTH = 4,
    parameter INIT_OQ = 1'b0,
    parameter SERDES_MODE = "MASTER",
    parameter SRVAL_OQ = 1'b0,
    parameter TBYTE_CTL = "FALSE",
    parameter TBYTE_SRC = "FALSE",
    parameter TRISTATE_WIDTH = 1
) (
    input wire CLK,
    input wire CLKDIV,
    input wire D1,
    input wire D2,
    input wire D3,
    input wire D4,
    input wire D5,
    input wire D6,
    input wire D7,
    input wire D8,
    input wire OCE,
    output reg OFB,
    output reg OQ,
    input wire RST,
    input wire SHIFTIN1,
    input wire SHIFTIN2,
    output wire SHIFTOUT1,
    output wire SHIFTOUT2,
    input wire T1,
    input wire T2,
    input wire T3,
    input wire T4,
    input wire TBYTEIN,
    output wire TBYTEOUT,
    input wire TCE,
    output reg TFB,
    output reg TQ
);
    assign SHIFTOUT1 = 1'b0;
    assign SHIFTOUT2 = 1'b0;
    assign TBYTEOUT = 1'b0;
    always @(posedge CLKDIV or posedge RST) begin
        if (RST) begin
            OQ <= INIT_OQ;
            OFB <= INIT_OQ;
            TQ <= 1'b1;
            TFB <= 1'b1;
        end else begin
            OQ <= D1;
            OFB <= D1;
            TQ <= T1;
            TFB <= T1;
        end
    end
    wire unused = CLK ^ D2 ^ D3 ^ D4 ^ D5 ^ D6 ^ D7 ^ D8 ^ OCE ^ SHIFTIN1 ^ SHIFTIN2 ^ T2 ^ T3 ^ T4 ^ TBYTEIN ^ TCE;
endmodule

module IOBUFDS #(
    parameter IBUF_LOW_PWR = "TRUE",
    parameter IOSTANDARD = "DEFAULT",
    parameter SLEW = "SLOW"
) (
    input wire I,
    inout wire IO,
    inout wire IOB,
    output wire O,
    input wire T
);
    assign IO = T ? 1'bz : I;
    assign IOB = T ? 1'bz : !I;
    assign O = IO;
endmodule

module OBUFDS #(
    parameter IOSTANDARD = "DEFAULT",
    parameter SLEW = "SLOW"
) (
    input wire I,
    output wire O,
    output wire OB
);
    assign O = I;
    assign OB = !I;
endmodule

`default_nettype wire

// Minimal simulation model for the 7-series USER BSCAN primitive. The gate-level
// DDR/BIST simulation does not drive JTAG, so keep the USER chain inactive.
module BSCANE2 #(
    parameter integer JTAG_CHAIN = 1
) (
    output wire CAPTURE,
    output wire DRCK,
    output wire RESET,
    output wire RUNTEST,
    output wire SEL,
    output wire SHIFT,
    output wire TCK,
    output wire TDI,
    input  wire TDO,
    output wire TMS,
    output wire UPDATE
);
    assign CAPTURE = 1'b0;
    assign DRCK = 1'b0;
    assign RESET = 1'b0;
    assign RUNTEST = 1'b0;
    assign SEL = 1'b0;
    assign SHIFT = 1'b0;
    assign TCK = 1'b0;
    assign TDI = 1'b0;
    assign TMS = 1'b0;
    assign UPDATE = 1'b0;
endmodule

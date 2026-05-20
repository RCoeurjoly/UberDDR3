`default_nettype none

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_CLOCKED
`define YPCB_PHASER_DIAG_CONN(sig) sig
`else
`define YPCB_PHASER_DIAG_CONN(sig)
`endif


`ifdef YPCB_PHASER_BYTE_LANE_DIAG_FIFO
`define YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO
`define YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO
`define YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_ENABLE_PORTS
`define YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO_ENABLE_PORTS
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_FIFO_IDLE
`define YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_ENABLE_PORTS
`define YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO_ENABLE_PORTS
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_FIFO_FULL_PORTS
`define YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_CLKRST_PORTS
`define YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO_CLKRST_PORTS
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_SYSTEST_CONNECTED
`define YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO
`define YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_ENABLE_PORTS
`define YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_CLKRST_PORTS
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_CLKRST_PORTS
`define YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_RDCLK_PORT
`define YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_WRCLK_PORT
`define YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_RESET_PORT
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO_CLKRST_PORTS
`define YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO_RDCLK_PORT
`define YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO_WRCLK_PORT
`define YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO_RESET_PORT
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO
`ifndef YPCB_PHASER_BYTE_LANE_DIAG_ANY_FIFO
`define YPCB_PHASER_BYTE_LANE_DIAG_ANY_FIFO
`endif
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO
`ifndef YPCB_PHASER_BYTE_LANE_DIAG_ANY_FIFO
`define YPCB_PHASER_BYTE_LANE_DIAG_ANY_FIFO
`endif
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_SYSTEST_PARAMS
`define YPCB_PHASER_DIAG_PHYCTL_BURST_MODE "TRUE"
`define YPCB_PHASER_DIAG_CLKOUT_DIV 2
`define YPCB_PHASER_DIAG_OUTPUT_CLK_SRC "DELAYED_REF"
`define YPCB_PHASER_DIAG_IN_FINE_DELAY 33
`define YPCB_PHASER_DIAG_OUT_FINE_DELAY 60
`define YPCB_PHASER_DIAG_OUT_DATA_CTL_N "TRUE"
`define YPCB_PHASER_DIAG_OUT_OCLKDELAY_INV "TRUE"
`define YPCB_PHASER_DIAG_REFCLK_PERIOD 1.875
`define YPCB_PHASER_DIAG_MEMREFCLK_PERIOD 1.875
`define YPCB_PHASER_DIAG_IN_PHASEREFCLK_PERIOD 1.875
`define YPCB_PHASER_DIAG_OUT_PHASEREFCLK_PERIOD 1.000
`else
`define YPCB_PHASER_DIAG_PHYCTL_BURST_MODE "FALSE"
`define YPCB_PHASER_DIAG_CLKOUT_DIV 4
`define YPCB_PHASER_DIAG_OUTPUT_CLK_SRC "PHASE_REF"
`define YPCB_PHASER_DIAG_IN_FINE_DELAY 0
`define YPCB_PHASER_DIAG_OUT_FINE_DELAY 0
`define YPCB_PHASER_DIAG_OUT_DATA_CTL_N "FALSE"
`define YPCB_PHASER_DIAG_OUT_OCLKDELAY_INV "FALSE"
`define YPCB_PHASER_DIAG_REFCLK_PERIOD 0.000
`define YPCB_PHASER_DIAG_MEMREFCLK_PERIOD 5.000
`define YPCB_PHASER_DIAG_IN_PHASEREFCLK_PERIOD 5.000
`define YPCB_PHASER_DIAG_OUT_PHASEREFCLK_PERIOD 5.000
`endif

module ypcb_phaser_byte_lane_diag (
    input  wire       clk50,
    input  wire       rst_n,
    output wire [2:0] led
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_DDR3_LANE0
    ,
    input  wire [7:0] ddr3_dq,
    input  wire       ddr3_dqs_p,
    input  wire       ddr3_dqs_n
`endif
);
    localparam [31:0] READ_MAGIC = 32'h50485344; // "PHSD"
    `ifdef YPCB_PHASER_BYTE_LANE_DIAG_READBACK128
    localparam integer READ_PAYLOAD_BITS = 128;
`else
    localparam integer READ_PAYLOAD_BITS = 136;
`endif
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_CLOCKED
    localparam [7:0] READ_VERSION = 8'd4;
`else
    localparam [7:0] READ_VERSION = 8'd1;
`endif

    wire rst = ~rst_n;

    reg [25:0] heartbeat_q = 26'h0;
    always @(posedge clk50 or posedge rst) begin
        if (rst)
            heartbeat_q <= 26'h0;
        else
            heartbeat_q <= heartbeat_q + 1'b1;
    end

    wire inactive_low = rst & heartbeat_q[0];
    wire inactive_high = ~rst | heartbeat_q[0];

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_DDR3_LANE0
    wire ddr3_lane0_dqs;
    (* keep, dont_touch *)
    IBUFDS #(
        .IBUF_LOW_PWR("FALSE")
    ) ddr3_lane0_dqs_ibuf (
        .O(ddr3_lane0_dqs),
        .I(ddr3_dqs_p),
        .IB(ddr3_dqs_n)
    );

    reg [7:0] ddr3_dq_meta_q = 8'd0;
    reg [7:0] ddr3_dq_sync_q = 8'd0;
    reg [7:0] ddr3_dq_prev_q = 8'd0;
    reg [7:0] ddr3_dq_seen_high_q = 8'd0;
    reg [7:0] ddr3_dq_seen_low_q = 8'd0;
    reg [7:0] ddr3_dq_toggle_seen_q = 8'd0;
    reg ddr3_dqs_meta_q = 1'b0;
    reg ddr3_dqs_sync_q = 1'b0;
    reg ddr3_dqs_prev_q = 1'b0;
    reg ddr3_dqs_seen_high_q = 1'b0;
    reg ddr3_dqs_seen_low_q = 1'b0;
    reg ddr3_dqs_toggle_seen_q = 1'b0;

    always @(posedge clk50 or posedge rst) begin
        if (rst) begin
            ddr3_dq_meta_q <= 8'd0;
            ddr3_dq_sync_q <= 8'd0;
            ddr3_dq_prev_q <= 8'd0;
            ddr3_dq_seen_high_q <= 8'd0;
            ddr3_dq_seen_low_q <= 8'd0;
            ddr3_dq_toggle_seen_q <= 8'd0;
            ddr3_dqs_meta_q <= 1'b0;
            ddr3_dqs_sync_q <= 1'b0;
            ddr3_dqs_prev_q <= 1'b0;
            ddr3_dqs_seen_high_q <= 1'b0;
            ddr3_dqs_seen_low_q <= 1'b0;
            ddr3_dqs_toggle_seen_q <= 1'b0;
        end else begin
            ddr3_dq_meta_q <= ddr3_dq;
            ddr3_dq_sync_q <= ddr3_dq_meta_q;
            ddr3_dq_prev_q <= ddr3_dq_sync_q;
            ddr3_dq_seen_high_q <= ddr3_dq_seen_high_q | ddr3_dq_sync_q;
            ddr3_dq_seen_low_q <= ddr3_dq_seen_low_q | ~ddr3_dq_sync_q;
            ddr3_dq_toggle_seen_q <= ddr3_dq_toggle_seen_q | (ddr3_dq_sync_q ^ ddr3_dq_prev_q);

            ddr3_dqs_meta_q <= ddr3_lane0_dqs;
            ddr3_dqs_sync_q <= ddr3_dqs_meta_q;
            ddr3_dqs_prev_q <= ddr3_dqs_sync_q;
            ddr3_dqs_seen_high_q <= ddr3_dqs_seen_high_q | ddr3_dqs_sync_q;
            ddr3_dqs_seen_low_q <= ddr3_dqs_seen_low_q | ~ddr3_dqs_sync_q;
            ddr3_dqs_toggle_seen_q <= ddr3_dqs_toggle_seen_q | (ddr3_dqs_sync_q ^ ddr3_dqs_prev_q);
        end
    end

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_DDR3_DQS_ISERDES_IOLOGIC
    wire ddr3_lane0_dqs_idelay;
    wire [7:0] ddr3_lane0_dqs_iserdes_q;
    reg [7:0] ddr3_lane0_dqs_iserdes_meta_q = 8'd0;
    reg [7:0] ddr3_lane0_dqs_iserdes_sync_q = 8'd0;
    reg [7:0] ddr3_lane0_dqs_iserdes_prev_q = 8'd0;
    reg ddr3_lane0_dqs_iserdes_nonzero_seen_q = 1'b0;
    reg ddr3_lane0_dqs_iserdes_toggle_seen_q = 1'b0;

    (* keep, dont_touch, IODELAY_GROUP="DDR3-GROUP" *)
    IDELAYE2 #(
        .DELAY_SRC("IDATAIN"),
        .HIGH_PERFORMANCE_MODE("TRUE"),
        .IDELAY_TYPE("VAR_LOAD"),
        .IDELAY_VALUE(0),
        .PIPE_SEL("FALSE"),
        .REFCLK_FREQUENCY(200.0),
        .SIGNAL_PATTERN("CLOCK")
    ) ddr3_lane0_dqs_idelay_i (
        .CNTVALUEOUT(),
        .DATAOUT(ddr3_lane0_dqs_idelay),
        .C(clk50),
        .CE(1'b0),
        .CINVCTRL(1'b0),
        .CNTVALUEIN(5'd0),
        .DATAIN(1'b0),
        .IDATAIN(ddr3_lane0_dqs),
        .INC(1'b0),
        .LD(1'b0),
        .LDPIPEEN(1'b0),
        .REGRST(1'b0)
    );

    (* keep, dont_touch *)
    ISERDESE2 #(
        .DATA_RATE("DDR"),
        .DATA_WIDTH(8),
        .INIT_Q1(1'b0),
        .INIT_Q2(1'b0),
        .INIT_Q3(1'b0),
        .INIT_Q4(1'b0),
        .INTERFACE_TYPE("NETWORKING"),
        .IOBDELAY("IFD"),
        .NUM_CE(1),
        .OFB_USED("FALSE"),
        .SRVAL_Q1(1'b0),
        .SRVAL_Q2(1'b0),
        .SRVAL_Q3(1'b0),
        .SRVAL_Q4(1'b0)
    ) ddr3_lane0_dqs_iserdes_i (
        .O(),
        .Q1(ddr3_lane0_dqs_iserdes_q[7]),
        .Q2(ddr3_lane0_dqs_iserdes_q[6]),
        .Q3(ddr3_lane0_dqs_iserdes_q[5]),
        .Q4(ddr3_lane0_dqs_iserdes_q[4]),
        .Q5(ddr3_lane0_dqs_iserdes_q[3]),
        .Q6(ddr3_lane0_dqs_iserdes_q[2]),
        .Q7(ddr3_lane0_dqs_iserdes_q[1]),
        .Q8(ddr3_lane0_dqs_iserdes_q[0]),
        .SHIFTOUT1(),
        .SHIFTOUT2(),
        .BITSLIP(1'b0),
        .CE1(1'b1),
        .CE2(1'b1),
        .CLKDIVP(1'b0),
        .CLK(in_iclk),
        .CLKB(~in_iclk),
        .CLKDIV(in_iclkdiv),
        .OCLK(1'b0),
        .DYNCLKDIVSEL(1'b0),
        .DYNCLKSEL(1'b0),
        .D(1'b0),
        .DDLY(ddr3_lane0_dqs_idelay),
        .OFB(1'b0),
        .OCLKB(1'b0),
        .RST(in_iserdes_rst | rst),
        .SHIFTIN1(1'b0),
        .SHIFTIN2(1'b0)
    );

    always @(posedge clk50 or posedge rst) begin
        if (rst) begin
            ddr3_lane0_dqs_iserdes_meta_q <= 8'd0;
            ddr3_lane0_dqs_iserdes_sync_q <= 8'd0;
            ddr3_lane0_dqs_iserdes_prev_q <= 8'd0;
            ddr3_lane0_dqs_iserdes_nonzero_seen_q <= 1'b0;
            ddr3_lane0_dqs_iserdes_toggle_seen_q <= 1'b0;
        end else begin
            ddr3_lane0_dqs_iserdes_meta_q <= ddr3_lane0_dqs_iserdes_q;
            ddr3_lane0_dqs_iserdes_sync_q <= ddr3_lane0_dqs_iserdes_meta_q;
            ddr3_lane0_dqs_iserdes_prev_q <= ddr3_lane0_dqs_iserdes_sync_q;
            ddr3_lane0_dqs_iserdes_nonzero_seen_q <=
                ddr3_lane0_dqs_iserdes_nonzero_seen_q | (|ddr3_lane0_dqs_iserdes_sync_q);
            ddr3_lane0_dqs_iserdes_toggle_seen_q <=
                ddr3_lane0_dqs_iserdes_toggle_seen_q |
                (|(ddr3_lane0_dqs_iserdes_sync_q ^ ddr3_lane0_dqs_iserdes_prev_q));
        end
    end
`else
    wire ddr3_lane0_dqs_iserdes_nonzero_seen_q = 1'b0;
    wire ddr3_lane0_dqs_iserdes_toggle_seen_q = 1'b0;
`endif

    wire [3:0] ddr3_lane0_observed = {
        ddr3_dqs_toggle_seen_q,
        ddr3_dqs_seen_high_q & ddr3_dqs_seen_low_q,
        |ddr3_dq_toggle_seen_q,
        |ddr3_dq_seen_high_q & |ddr3_dq_seen_low_q
    };
`else
    wire [3:0] ddr3_lane0_observed = 4'd0;
    wire ddr3_lane0_dqs_iserdes_nonzero_seen_q = 1'b0;
    wire ddr3_lane0_dqs_iserdes_toggle_seen_q = 1'b0;
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_DDR3_DQS_PHASEREF
    wire phaser_in_phaserefclk = ddr3_lane0_dqs;
`else
    wire phaser_in_phaserefclk = 1'b0;
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_CLOCKED
    wire phaser_pll_fb;
    wire phaser_freq_refclk;
    wire phaser_sync_refclk;
    wire phaser_pll_locked;

    (* keep, dont_touch, PHASER_FREQ_BACKBONE_ACTIVE = 1 *)
    PLLE2_ADV #(
        .BANDWIDTH("OPTIMIZED"),
        .COMPENSATION("INTERNAL"),
        .STARTUP_WAIT("FALSE"),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT(16),
        .CLKFBOUT_PHASE(0.000),
        .CLKOUT0_DIVIDE(2),
        .CLKOUT0_PHASE(0.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT1_DIVIDE(2),
        .CLKOUT1_PHASE(0.000),
        .CLKOUT1_DUTY_CYCLE(0.500),
        .CLKIN1_PERIOD(20.000)
    ) phaser_pll_i (
        .CLKFBOUT(phaser_pll_fb),
        .CLKOUT0(phaser_freq_refclk),
        .CLKOUT1(phaser_sync_refclk),
        .CLKFBIN(phaser_pll_fb),
        .CLKIN1(clk50),
        .CLKINSEL(1'b1),
        .LOCKED(phaser_pll_locked),
        .PWRDWN(1'b0),
        .RST(rst)
    );
`endif

    wire phaser_ref_locked;
    (* keep, dont_touch, PHASER_CLOCKED_ORACLE_ROUTE = 1 *)
    PHASER_REF phaser_ref_i (
        .LOCKED(`YPCB_PHASER_DIAG_CONN(phaser_ref_locked)),
        .CLKIN(`YPCB_PHASER_DIAG_CONN(phaser_freq_refclk)),
        .PWRDWN(`YPCB_PHASER_DIAG_CONN(phaser_ref_pwrdwn)),
        .RST(`YPCB_PHASER_DIAG_CONN(phaser_ref_reset))
    );

    wire phyctl_ready;
    wire [1:0] phyctl_in_rank_a;
    wire [1:0] phyctl_in_rank_b;
    wire [1:0] phyctl_in_rank_c;
    wire [1:0] phyctl_in_rank_d;
    wire [1:0] phyctl_pc_enable_calib;
    wire [3:0] phyctl_aux_output;
    wire [3:0] phyctl_in_burst_pending;
    wire [3:0] phyctl_out_burst_pending;
    wire in_phase_locked;

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_CLOCKED
`include "ypcb_phaser_byte_lane_diag_sequence.vh"

    localparam integer SEQ_FLAG_PHASER_REF_PWRDWN = 0;
    localparam integer SEQ_FLAG_PHASER_REF_RST = 1;
    localparam integer SEQ_FLAG_PHYCTL_RESET = 2;
    localparam integer SEQ_FLAG_READCALIBENABLE = 3;
    localparam integer SEQ_FLAG_WRITECALIBENABLE = 4;
    localparam integer SEQ_FLAG_PHYCTLWRENABLE = 5;
    localparam integer SEQ_FLAG_LANE_RESET = 6;
    localparam integer SEQ_FLAG_RSTDQSFIND = 7;
    localparam integer SEQ_FLAG_SYNC_ENABLE = 8;

    reg [PHASER_SEQUENCE_STEP_BITS - 1:0] sequence_step_q = {PHASER_SEQUENCE_STEP_BITS{1'b0}};
    reg [15:0] sequence_elapsed_q = 16'd0;
    reg [15:0] sequence_advance_count_q = 16'd0;
    reg [31:0] sequence_last_phyctlwd_q = 32'd0;
    reg sequence_done_q = 1'b0;

    wire [8:0] sequence_flags = phaser_sequence_flags(sequence_step_q);
    wire [3:0] sequence_wait_flags = phaser_sequence_wait_flags(sequence_step_q);
    wire [15:0] sequence_hold_cycles = phaser_sequence_hold_cycles(sequence_step_q);
    wire [31:0] sequence_phyctlwd = phaser_sequence_phyctlwd(sequence_step_q);
    wire sequence_wait_satisfied =
        (~sequence_wait_flags[0] | phaser_pll_locked) &
        (~sequence_wait_flags[1] | phaser_ref_locked) &
        (~sequence_wait_flags[2] | in_phase_locked) &
        (~sequence_wait_flags[3] | phyctl_ready);
    wire sequence_dwell_satisfied = (sequence_elapsed_q + 16'd1) >= sequence_hold_cycles;
    wire sequence_is_final_step = sequence_step_q >= (PHASER_SEQUENCE_STEP_COUNT - 1);
    wire sequence_can_advance = ~sequence_done_q & sequence_wait_satisfied & sequence_dwell_satisfied;

    wire sequence_phaser_ref_pwrdwn = sequence_flags[SEQ_FLAG_PHASER_REF_PWRDWN];
    wire sequence_phaser_ref_rst = sequence_flags[SEQ_FLAG_PHASER_REF_RST];
    wire sequence_phyctl_reset = sequence_flags[SEQ_FLAG_PHYCTL_RESET];
    wire sequence_readcalibenable = sequence_flags[SEQ_FLAG_READCALIBENABLE];
    wire sequence_writecalibenable = sequence_flags[SEQ_FLAG_WRITECALIBENABLE];
    wire sequence_phyctlwrenable = sequence_flags[SEQ_FLAG_PHYCTLWRENABLE];
    wire sequence_lane_reset = sequence_flags[SEQ_FLAG_LANE_RESET];
    wire sequence_rstdqsfind = sequence_flags[SEQ_FLAG_RSTDQSFIND];
    wire sequence_sync_enable = sequence_flags[SEQ_FLAG_SYNC_ENABLE];

    wire [31:0] phyctl_wd_q = sequence_phyctlwd;
    wire phyctl_wr_enable_q = sequence_phyctlwrenable;
    wire phyctl_readcalibenable = sequence_readcalibenable;
    wire phyctl_writecalibenable = sequence_writecalibenable;
    wire phaser_ref_pwrdwn = 1'b0;
    wire phaser_ref_reset = rst;
    wire phyctl_reset = rst | sequence_phyctl_reset;
    wire lane_reset = rst | sequence_lane_reset;
    wire rstdqsfind = rst | sequence_rstdqsfind;
    wire phaser_syncin = phaser_sync_refclk;

    always @(posedge clk50 or posedge rst) begin
        if (rst) begin
            sequence_step_q <= {PHASER_SEQUENCE_STEP_BITS{1'b0}};
            sequence_elapsed_q <= 16'd0;
            sequence_advance_count_q <= 16'd0;
            sequence_last_phyctlwd_q <= 32'd0;
            sequence_done_q <= 1'b0;
        end else begin
            if (sequence_elapsed_q != 16'hffff)
                sequence_elapsed_q <= sequence_elapsed_q + 1'b1;

            if (sequence_phyctlwrenable && sequence_elapsed_q == 16'd0)
                sequence_last_phyctlwd_q <= sequence_phyctlwd;

            if (sequence_can_advance) begin
                sequence_advance_count_q <= sequence_advance_count_q + 1'b1;
                sequence_elapsed_q <= 16'd0;
                if (sequence_is_final_step)
                    sequence_done_q <= PHASER_SEQUENCE_FINAL_HOLD;
                else
                    sequence_step_q <= sequence_step_q + 1'b1;
            end
        end
    end
`else
    wire [31:0] phyctl_wd_q = 32'd0;
    wire phyctl_wr_enable_q = 1'b0;
    wire phyctl_readcalibenable = 1'b0;
    wire phyctl_writecalibenable = 1'b0;
    wire phaser_ref_pwrdwn = inactive_low;
    wire phaser_ref_reset = rst;
    wire phyctl_reset = rst;
    wire lane_reset = rst;
    wire rstdqsfind = rst;
`endif

    (* keep, dont_touch *)
    PHY_CONTROL #(
        .BURST_MODE(`YPCB_PHASER_DIAG_PHYCTL_BURST_MODE),
        .CLK_RATIO(4),
        .SYNC_MODE("FALSE")
    ) phy_control_i (
        .PHYCTLALMOSTFULL(),
        .PHYCTLEMPTY(),
        .PHYCTLFULL(),
        .PHYCTLREADY(`YPCB_PHASER_DIAG_CONN(phyctl_ready)),
        .INRANKA(`YPCB_PHASER_DIAG_CONN(phyctl_in_rank_a)),
        .INRANKB(`YPCB_PHASER_DIAG_CONN(phyctl_in_rank_b)),
        .INRANKC(`YPCB_PHASER_DIAG_CONN(phyctl_in_rank_c)),
        .INRANKD(`YPCB_PHASER_DIAG_CONN(phyctl_in_rank_d)),
        .PCENABLECALIB(`YPCB_PHASER_DIAG_CONN(phyctl_pc_enable_calib)),
        .AUXOUTPUT(`YPCB_PHASER_DIAG_CONN(phyctl_aux_output)),
        .INBURSTPENDING(`YPCB_PHASER_DIAG_CONN(phyctl_in_burst_pending)),
        .OUTBURSTPENDING(`YPCB_PHASER_DIAG_CONN(phyctl_out_burst_pending)),
        .MEMREFCLK(`YPCB_PHASER_DIAG_CONN(phaser_freq_refclk)),
        .PHYCLK(`YPCB_PHASER_DIAG_CONN(clk50)),
        .PHYCTLMSTREMPTY(),
        .PHYCTLWRENABLE(`YPCB_PHASER_DIAG_CONN(phyctl_wr_enable_q)),
        .PLLLOCK(`YPCB_PHASER_DIAG_CONN(phaser_pll_locked)),
        .READCALIBENABLE(`YPCB_PHASER_DIAG_CONN(phyctl_readcalibenable)),
        .REFDLLLOCK(`YPCB_PHASER_DIAG_CONN(phaser_ref_locked)),
        .RESET(`YPCB_PHASER_DIAG_CONN(phyctl_reset)),
        .SYNCIN(`YPCB_PHASER_DIAG_CONN(phaser_syncin)),
        .WRITECALIBENABLE(`YPCB_PHASER_DIAG_CONN(phyctl_writecalibenable)),
        .PHYCTLWD(`YPCB_PHASER_DIAG_CONN(phyctl_wd_q))
    );

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_GOLDEN_C0_GROUP2A
    wire [1:0] phyctl_in_rank_selected = phyctl_in_rank_a;
    wire phyctl_in_burst_pending_selected = phyctl_in_burst_pending[0];
    wire phyctl_out_burst_pending_selected = phyctl_out_burst_pending[0];
`elsif YPCB_PHASER_BYTE_LANE_DIAG_DDR3_DQS_PHASEREF
    wire [1:0] phyctl_in_rank_selected = phyctl_in_rank_b;
    wire phyctl_in_burst_pending_selected = phyctl_in_burst_pending[1];
    wire phyctl_out_burst_pending_selected = phyctl_out_burst_pending[1];
`else
    wire [1:0] phyctl_in_rank_selected = phyctl_in_rank_a;
    wire phyctl_in_burst_pending_selected = phyctl_in_burst_pending[0];
    wire phyctl_out_burst_pending_selected = phyctl_out_burst_pending[0];
`endif

    wire dqs_found;
    wire dqs_out_of_range;
    wire in_fine_overflow;
    wire in_iclk;
    wire in_iclkdiv;
    wire in_iserdes_rst;
    wire in_rclk;
    wire in_wrenable;
    wire [5:0] in_counter_read;

    (* keep, dont_touch *)
    PHASER_IN_PHY #(
        .CLKOUT_DIV(`YPCB_PHASER_DIAG_CLKOUT_DIV),
        .FINE_DELAY(`YPCB_PHASER_DIAG_IN_FINE_DELAY),
        .OUTPUT_CLK_SRC(`YPCB_PHASER_DIAG_OUTPUT_CLK_SRC),
        .REFCLK_PERIOD(`YPCB_PHASER_DIAG_REFCLK_PERIOD),
        .MEMREFCLK_PERIOD(`YPCB_PHASER_DIAG_MEMREFCLK_PERIOD),
        .PHASEREFCLK_PERIOD(`YPCB_PHASER_DIAG_IN_PHASEREFCLK_PERIOD)
    ) phaser_in_i (
        .DQSFOUND(`YPCB_PHASER_DIAG_CONN(dqs_found)),
        .DQSOUTOFRANGE(`YPCB_PHASER_DIAG_CONN(dqs_out_of_range)),
        .FINEOVERFLOW(`YPCB_PHASER_DIAG_CONN(in_fine_overflow)),
        .ICLK(`YPCB_PHASER_DIAG_CONN(in_iclk)),
        .ICLKDIV(`YPCB_PHASER_DIAG_CONN(in_iclkdiv)),
        .ISERDESRST(`YPCB_PHASER_DIAG_CONN(in_iserdes_rst)),
        .PHASELOCKED(`YPCB_PHASER_DIAG_CONN(in_phase_locked)),
        .RCLK(`YPCB_PHASER_DIAG_CONN(in_rclk)),
        .WRENABLE(`YPCB_PHASER_DIAG_CONN(in_wrenable)),
        .COUNTERREADVAL(`YPCB_PHASER_DIAG_CONN(in_counter_read)),
        .BURSTPENDINGPHY(`YPCB_PHASER_DIAG_CONN(phyctl_in_burst_pending_selected)),
        .COUNTERLOADEN(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .COUNTERREADEN(`YPCB_PHASER_DIAG_CONN(heartbeat_q[20])),
        .FINEENABLE(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .FINEINC(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .FREQREFCLK(`YPCB_PHASER_DIAG_CONN(phaser_freq_refclk)),
        .MEMREFCLK(`YPCB_PHASER_DIAG_CONN(phaser_freq_refclk)),
        .PHASEREFCLK(`YPCB_PHASER_DIAG_CONN(phaser_in_phaserefclk)),
        .RST(`YPCB_PHASER_DIAG_CONN(lane_reset)),
        .RSTDQSFIND(`YPCB_PHASER_DIAG_CONN(rstdqsfind)),
        .SYNCIN(`YPCB_PHASER_DIAG_CONN(phaser_syncin)),
        .SYSCLK(`YPCB_PHASER_DIAG_CONN(clk50)),
        .ENCALIBPHY(`YPCB_PHASER_DIAG_CONN(phyctl_pc_enable_calib)),
        .RANKSELPHY(`YPCB_PHASER_DIAG_CONN(phyctl_in_rank_selected)),
        .COUNTERLOADVAL(`YPCB_PHASER_DIAG_CONN(heartbeat_q[5:0]))
    );

    wire out_coarse_overflow;
    wire out_fine_overflow;
    wire out_oclk;
    wire out_oclk_delayed;
    wire out_oclkdiv;
    wire out_oserdes_rst;
    wire out_rd_enable;
    wire [1:0] out_cts_bus;
    wire [1:0] out_dqs_bus;
    wire [1:0] out_dts_bus;
    wire [8:0] out_counter_read;

    (* keep, dont_touch *)
    PHASER_OUT_PHY #(
        .CLKOUT_DIV(`YPCB_PHASER_DIAG_CLKOUT_DIV),
        .DATA_CTL_N(`YPCB_PHASER_DIAG_OUT_DATA_CTL_N),
        .FINE_DELAY(`YPCB_PHASER_DIAG_OUT_FINE_DELAY),
        .OCLKDELAY_INV(`YPCB_PHASER_DIAG_OUT_OCLKDELAY_INV),
        .OUTPUT_CLK_SRC(`YPCB_PHASER_DIAG_OUTPUT_CLK_SRC),
        .REFCLK_PERIOD(`YPCB_PHASER_DIAG_REFCLK_PERIOD),
        .MEMREFCLK_PERIOD(`YPCB_PHASER_DIAG_MEMREFCLK_PERIOD),
        .PHASEREFCLK_PERIOD(`YPCB_PHASER_DIAG_OUT_PHASEREFCLK_PERIOD)
    ) phaser_out_i (
        .COARSEOVERFLOW(`YPCB_PHASER_DIAG_CONN(out_coarse_overflow)),
        .FINEOVERFLOW(`YPCB_PHASER_DIAG_CONN(out_fine_overflow)),
        .OCLK(`YPCB_PHASER_DIAG_CONN(out_oclk)),
        .OCLKDELAYED(`YPCB_PHASER_DIAG_CONN(out_oclk_delayed)),
        .OCLKDIV(`YPCB_PHASER_DIAG_CONN(out_oclkdiv)),
        .OSERDESRST(`YPCB_PHASER_DIAG_CONN(out_oserdes_rst)),
        .RDENABLE(),
        .CTSBUS(`YPCB_PHASER_DIAG_CONN(out_cts_bus)),
        .DQSBUS(`YPCB_PHASER_DIAG_CONN(out_dqs_bus)),
        .DTSBUS(`YPCB_PHASER_DIAG_CONN(out_dts_bus)),
        .COUNTERREADVAL(`YPCB_PHASER_DIAG_CONN(out_counter_read)),
        .BURSTPENDINGPHY(`YPCB_PHASER_DIAG_CONN(phyctl_out_burst_pending_selected)),
        .COARSEENABLE(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .COARSEINC(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .COUNTERLOADEN(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .COUNTERREADEN(`YPCB_PHASER_DIAG_CONN(heartbeat_q[20])),
        .FINEENABLE(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .FINEINC(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .FREQREFCLK(`YPCB_PHASER_DIAG_CONN(phaser_freq_refclk)),
        .MEMREFCLK(`YPCB_PHASER_DIAG_CONN(phaser_freq_refclk)),
        .PHASEREFCLK(),
        .RST(`YPCB_PHASER_DIAG_CONN(lane_reset)),
        .SELFINEOCLKDELAY(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .SYNCIN(`YPCB_PHASER_DIAG_CONN(phaser_syncin)),
        .SYSCLK(`YPCB_PHASER_DIAG_CONN(clk50)),
        .ENCALIBPHY(`YPCB_PHASER_DIAG_CONN(phyctl_pc_enable_calib)),
        .COUNTERLOADVAL(`YPCB_PHASER_DIAG_CONN(heartbeat_q[8:0]))
    );

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_FIFO_IDLE
    wire in_fifo_rden = inactive_low;
    wire in_fifo_wren = inactive_low;
    wire out_fifo_rden = inactive_low;
    wire out_fifo_wren = inactive_low;
`else
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_SYSTEST_CONNECTED
    wire in_fifo_rden = 1'b1;
    wire in_fifo_wren = in_wrenable;
    wire out_fifo_rden = out_rd_enable;
    wire out_fifo_wren = heartbeat_q[17];
`else
    wire in_fifo_rden = heartbeat_q[18];
    wire in_fifo_wren = in_wrenable;
    wire out_fifo_rden = out_rd_enable;
    wire out_fifo_wren = heartbeat_q[17];
`endif
`endif

    wire in_fifo_rdclk = clk50;
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_SYSTEST_CONNECTED
    wire in_fifo_wrclk = in_iclkdiv;
`else
    wire in_fifo_wrclk = clk50;
`endif
    wire in_fifo_reset = lane_reset;

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO
    (* keep, dont_touch *)
    IN_FIFO in_fifo_i (
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_RDCLK_PORT
        .RDCLK(`YPCB_PHASER_DIAG_CONN(in_fifo_rdclk)),
`endif
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_WRCLK_PORT
        .WRCLK(`YPCB_PHASER_DIAG_CONN(in_fifo_wrclk)),
`endif
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_RESET_PORT
        .RESET(`YPCB_PHASER_DIAG_CONN(in_fifo_reset)),
`endif
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_FIFO_DATA_PORTS
        .D0(4'h0),
        .D1(4'h0),
        .D2(4'h0),
        .D3(4'h0),
        .D4(4'h0),
        .D5(8'h00),
        .D6(8'h00),
        .D7(4'h0),
        .D8(4'h0),
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_ENABLE_PORTS
        .D9(4'h0),
`else
        .D9(4'h0)
`endif
`endif
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_ENABLE_PORTS
        .RDEN(`YPCB_PHASER_DIAG_CONN(in_fifo_rden)),
        .WREN(`YPCB_PHASER_DIAG_CONN(in_fifo_wren))
`endif
    );
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO
    (* keep, dont_touch *)
    OUT_FIFO out_fifo_i (
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO_RDCLK_PORT
        .RDCLK(`YPCB_PHASER_DIAG_CONN(clk50)),
`endif
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO_WRCLK_PORT
        .WRCLK(`YPCB_PHASER_DIAG_CONN(clk50)),
`endif
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_OUT_FIFO_RESET_PORT
        .RESET(`YPCB_PHASER_DIAG_CONN(lane_reset)),
`endif
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_FIFO_DATA_PORTS
        .D0(8'h00),
        .D1(8'h00),
        .D2(8'h00),
        .D3(8'h00),
        .D4(8'h00),
        .D5(8'h00),
        .D6(8'h00),
        .D7(8'h00),
        .D8(8'h00),
        .D9(8'h00),
`endif
        .RDEN(`YPCB_PHASER_DIAG_CONN(out_fifo_rden)),
        .WREN(`YPCB_PHASER_DIAG_CONN(out_fifo_wren))
    );
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_CLOCKED
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_ANY_FIFO
    wire fifo_activity = heartbeat_q[24];
`else
    wire fifo_activity = 1'b0;
`endif
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO_SYSTEST_CONNECTED
    wire status_in_wrenable = 1'b0;
`else
    wire status_in_wrenable = in_wrenable;
`endif
    wire [31:0] status_word = {
        ddr3_lane0_observed,
        status_in_wrenable,
        out_rd_enable,
        dqs_out_of_range,
        dqs_found,
        out_fine_overflow,
        out_coarse_overflow,
        rstdqsfind,
        lane_reset,
        phaser_ref_pwrdwn,
        phaser_ref_reset,
        phyctl_reset,
        phyctl_writecalibenable,
        phyctl_readcalibenable,
        phyctl_wr_enable_q,
        sequence_sync_enable,
        sequence_wait_satisfied,
        sequence_done_q,
        1'b1,
        ddr3_lane0_dqs_iserdes_toggle_seen_q,
        ddr3_lane0_dqs_iserdes_nonzero_seen_q,
        1'b0,
        fifo_activity,
        heartbeat_q[25],
        rst_n,
        phyctl_ready,
        in_phase_locked,
        phaser_ref_locked,
        phaser_pll_locked
    };
    wire [127:0] read_payload128 = {
        sequence_last_phyctlwd_q[23:0],
        {{(16 - PHASER_SEQUENCE_STEP_BITS){1'b0}}, sequence_step_q},
        sequence_advance_count_q,
        status_word,
        READ_VERSION,
        READ_MAGIC
    };
    wire [READ_PAYLOAD_BITS - 1:0] read_payload = {
        {(READ_PAYLOAD_BITS - 128){1'b0}},
        read_payload128
    };

    assign led[0] = phaser_ref_locked;
    assign led[1] = in_phase_locked ^ sequence_done_q;
    assign led[2] = phyctl_ready ^ heartbeat_q[25];
`else
    wire [READ_PAYLOAD_BITS - 1:0] read_payload = {
        8'd0,
        30'd0,
        heartbeat_q,
        32'd0,
        READ_VERSION,
        READ_MAGIC
    };

    assign led[0] = heartbeat_q[23];
    assign led[1] = heartbeat_q[24];
    assign led[2] = heartbeat_q[25];
`endif

    ypcb_bscan_readback #(
        .WIDTH(READ_PAYLOAD_BITS),
        .JTAG_CHAIN(1)
    ) readback_port (
        .payload_i(read_payload)
    );
endmodule

`undef YPCB_PHASER_DIAG_CONN
`undef YPCB_PHASER_BYTE_LANE_DIAG_ANY_FIFO

`default_nettype wire

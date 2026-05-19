`default_nettype none

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_CLOCKED
`define YPCB_PHASER_DIAG_CONN(sig) sig
`else
`define YPCB_PHASER_DIAG_CONN(sig)
`endif

module ypcb_phaser_byte_lane_diag (
    input  wire       clk50,
    input  wire       rst_n,
    output wire [2:0] led
);
    localparam [31:0] READ_MAGIC = 32'h50485344; // "PHSD"
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
        .BURST_MODE("FALSE"),
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
        .CLKOUT_DIV(4),
        .OUTPUT_CLK_SRC("PHASE_REF"),
        .REFCLK_PERIOD(0.000),
        .MEMREFCLK_PERIOD(5.000),
        .PHASEREFCLK_PERIOD(5.000)
    ) phaser_in_i (
        .DQSFOUND(`YPCB_PHASER_DIAG_CONN(dqs_found)),
        .DQSOUTOFRANGE(`YPCB_PHASER_DIAG_CONN(dqs_out_of_range)),
        .FINEOVERFLOW(`YPCB_PHASER_DIAG_CONN(in_fine_overflow)),
        .ICLK(`YPCB_PHASER_DIAG_CONN(in_iclk)),
        .ICLKDIV(`YPCB_PHASER_DIAG_CONN(in_iclkdiv)),
        .ISERDESRST(`YPCB_PHASER_DIAG_CONN(in_iserdes_rst)),
        .PHASELOCKED(`YPCB_PHASER_DIAG_CONN(in_phase_locked)),
        .RCLK(`YPCB_PHASER_DIAG_CONN(in_rclk)),
        .WRENABLE(),
        .COUNTERREADVAL(`YPCB_PHASER_DIAG_CONN(in_counter_read)),
        .BURSTPENDINGPHY(`YPCB_PHASER_DIAG_CONN(phyctl_in_burst_pending[0])),
        .COUNTERLOADEN(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .COUNTERREADEN(`YPCB_PHASER_DIAG_CONN(heartbeat_q[20])),
        .FINEENABLE(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .FINEINC(`YPCB_PHASER_DIAG_CONN(inactive_low)),
        .FREQREFCLK(`YPCB_PHASER_DIAG_CONN(phaser_freq_refclk)),
        .MEMREFCLK(`YPCB_PHASER_DIAG_CONN(phaser_freq_refclk)),
        .PHASEREFCLK(),
        .RST(`YPCB_PHASER_DIAG_CONN(lane_reset)),
        .RSTDQSFIND(`YPCB_PHASER_DIAG_CONN(rstdqsfind)),
        .SYNCIN(`YPCB_PHASER_DIAG_CONN(phaser_syncin)),
        .SYSCLK(`YPCB_PHASER_DIAG_CONN(clk50)),
        .ENCALIBPHY(`YPCB_PHASER_DIAG_CONN(phyctl_pc_enable_calib)),
        .RANKSELPHY(`YPCB_PHASER_DIAG_CONN(phyctl_in_rank_a)),
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
        .CLKOUT_DIV(4),
        .OUTPUT_CLK_SRC("PHASE_REF"),
        .REFCLK_PERIOD(0.000),
        .MEMREFCLK_PERIOD(5.000),
        .PHASEREFCLK_PERIOD(5.000)
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
        .BURSTPENDINGPHY(`YPCB_PHASER_DIAG_CONN(phyctl_out_burst_pending[0])),
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

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_FIFO
    wire in_fifo_almost_empty;
    wire in_fifo_almost_full;
    wire in_fifo_empty;
    wire in_fifo_full;
    wire [7:0] in_fifo_q0;
    wire [7:0] in_fifo_q1;
    wire [7:0] in_fifo_q2;
    wire [7:0] in_fifo_q3;
    wire [7:0] in_fifo_q4;
    wire [7:0] in_fifo_q5;
    wire [7:0] in_fifo_q6;
    wire [7:0] in_fifo_q7;
    wire [7:0] in_fifo_q8;
    wire [7:0] in_fifo_q9;

    (* keep, dont_touch *)
    IN_FIFO in_fifo_i (
        .ALMOSTEMPTY(`YPCB_PHASER_DIAG_CONN(in_fifo_almost_empty)),
        .ALMOSTFULL(`YPCB_PHASER_DIAG_CONN(in_fifo_almost_full)),
        .EMPTY(`YPCB_PHASER_DIAG_CONN(in_fifo_empty)),
        .FULL(`YPCB_PHASER_DIAG_CONN(in_fifo_full)),
        .Q0(`YPCB_PHASER_DIAG_CONN(in_fifo_q0)),
        .Q1(`YPCB_PHASER_DIAG_CONN(in_fifo_q1)),
        .Q2(`YPCB_PHASER_DIAG_CONN(in_fifo_q2)),
        .Q3(`YPCB_PHASER_DIAG_CONN(in_fifo_q3)),
        .Q4(`YPCB_PHASER_DIAG_CONN(in_fifo_q4)),
        .Q5(`YPCB_PHASER_DIAG_CONN(in_fifo_q5)),
        .Q6(`YPCB_PHASER_DIAG_CONN(in_fifo_q6)),
        .Q7(`YPCB_PHASER_DIAG_CONN(in_fifo_q7)),
        .Q8(`YPCB_PHASER_DIAG_CONN(in_fifo_q8)),
        .Q9(`YPCB_PHASER_DIAG_CONN(in_fifo_q9)),
        .RDCLK(`YPCB_PHASER_DIAG_CONN(clk50)),
        .RDEN(`YPCB_PHASER_DIAG_CONN(heartbeat_q[18])),
        .RESET(`YPCB_PHASER_DIAG_CONN(rst)),
        .WRCLK(`YPCB_PHASER_DIAG_CONN(clk50)),
        .WREN(`YPCB_PHASER_DIAG_CONN(in_wrenable)),
        .D0(`YPCB_PHASER_DIAG_CONN(heartbeat_q[3:0])),
        .D1(`YPCB_PHASER_DIAG_CONN(heartbeat_q[7:4])),
        .D2(`YPCB_PHASER_DIAG_CONN(heartbeat_q[11:8])),
        .D3(`YPCB_PHASER_DIAG_CONN(heartbeat_q[15:12])),
        .D4(`YPCB_PHASER_DIAG_CONN(heartbeat_q[19:16])),
        .D7(`YPCB_PHASER_DIAG_CONN(heartbeat_q[22:19])),
        .D8(`YPCB_PHASER_DIAG_CONN(heartbeat_q[23:20])),
        .D9(`YPCB_PHASER_DIAG_CONN(heartbeat_q[24:21])),
        .D5(`YPCB_PHASER_DIAG_CONN(heartbeat_q[7:0])),
        .D6(`YPCB_PHASER_DIAG_CONN(heartbeat_q[15:8]))
    );

    wire out_fifo_almost_empty;
    wire out_fifo_almost_full;
    wire out_fifo_empty;
    wire out_fifo_full;
    wire [3:0] out_fifo_q0;
    wire [3:0] out_fifo_q1;
    wire [3:0] out_fifo_q2;
    wire [3:0] out_fifo_q3;
    wire [3:0] out_fifo_q4;
    wire [3:0] out_fifo_q7;
    wire [3:0] out_fifo_q8;
    wire [3:0] out_fifo_q9;
    wire [7:0] out_fifo_q5;
    wire [7:0] out_fifo_q6;

    (* keep, dont_touch *)
    OUT_FIFO out_fifo_i (
        .ALMOSTEMPTY(`YPCB_PHASER_DIAG_CONN(out_fifo_almost_empty)),
        .ALMOSTFULL(`YPCB_PHASER_DIAG_CONN(out_fifo_almost_full)),
        .EMPTY(`YPCB_PHASER_DIAG_CONN(out_fifo_empty)),
        .FULL(`YPCB_PHASER_DIAG_CONN(out_fifo_full)),
        .Q0(`YPCB_PHASER_DIAG_CONN(out_fifo_q0)),
        .Q1(`YPCB_PHASER_DIAG_CONN(out_fifo_q1)),
        .Q2(`YPCB_PHASER_DIAG_CONN(out_fifo_q2)),
        .Q3(`YPCB_PHASER_DIAG_CONN(out_fifo_q3)),
        .Q4(`YPCB_PHASER_DIAG_CONN(out_fifo_q4)),
        .Q7(`YPCB_PHASER_DIAG_CONN(out_fifo_q7)),
        .Q8(`YPCB_PHASER_DIAG_CONN(out_fifo_q8)),
        .Q9(`YPCB_PHASER_DIAG_CONN(out_fifo_q9)),
        .Q5(`YPCB_PHASER_DIAG_CONN(out_fifo_q5)),
        .Q6(`YPCB_PHASER_DIAG_CONN(out_fifo_q6)),
        .RDCLK(`YPCB_PHASER_DIAG_CONN(clk50)),
        .RDEN(`YPCB_PHASER_DIAG_CONN(out_rd_enable)),
        .RESET(`YPCB_PHASER_DIAG_CONN(rst)),
        .WRCLK(`YPCB_PHASER_DIAG_CONN(clk50)),
        .WREN(`YPCB_PHASER_DIAG_CONN(heartbeat_q[17])),
        .D0(`YPCB_PHASER_DIAG_CONN(heartbeat_q[7:0])),
        .D1(`YPCB_PHASER_DIAG_CONN(heartbeat_q[8:1])),
        .D2(`YPCB_PHASER_DIAG_CONN(heartbeat_q[9:2])),
        .D3(`YPCB_PHASER_DIAG_CONN(heartbeat_q[10:3])),
        .D4(`YPCB_PHASER_DIAG_CONN(heartbeat_q[11:4])),
        .D5(`YPCB_PHASER_DIAG_CONN(heartbeat_q[12:5])),
        .D6(`YPCB_PHASER_DIAG_CONN(heartbeat_q[13:6])),
        .D7(`YPCB_PHASER_DIAG_CONN(heartbeat_q[14:7])),
        .D8(`YPCB_PHASER_DIAG_CONN(heartbeat_q[15:8])),
        .D9(`YPCB_PHASER_DIAG_CONN(heartbeat_q[16:9]))
    );
`endif

`ifdef YPCB_PHASER_BYTE_LANE_DIAG_CLOCKED
`ifdef YPCB_PHASER_BYTE_LANE_DIAG_FIFO
    wire fifo_activity = in_fifo_empty ^ in_fifo_full ^ out_fifo_empty ^ out_fifo_full;
`else
    wire fifo_activity = 1'b0;
`endif
    wire [31:0] status_word = {
        4'd0,
        in_wrenable,
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
        1'b0,
        1'b0,
        1'b0,
        fifo_activity,
        heartbeat_q[25],
        rst_n,
        phyctl_ready,
        in_phase_locked,
        phaser_ref_locked,
        phaser_pll_locked
    };
    wire [127:0] read_payload = {
        sequence_last_phyctlwd_q,
        {{(16 - PHASER_SEQUENCE_STEP_BITS){1'b0}}, sequence_step_q},
        sequence_advance_count_q,
        status_word,
        READ_VERSION,
        READ_MAGIC
    };

    assign led[0] = phaser_ref_locked;
    assign led[1] = in_phase_locked ^ sequence_done_q;
    assign led[2] = phyctl_ready ^ heartbeat_q[25];
`else
    wire [127:0] read_payload = {
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
        .WIDTH(128),
        .JTAG_CHAIN(1)
    ) readback_port (
        .payload_i(read_payload)
    );
endmodule

`undef YPCB_PHASER_DIAG_CONN

`default_nettype wire

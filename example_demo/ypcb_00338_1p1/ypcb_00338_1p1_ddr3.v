`default_nettype none
`timescale 1ps / 1ps

module ypcb_00338_1p1_ddr3 (
    input  wire        clk50,
    input  wire        rst_n,

    output wire [0:0]  ddr3_ck_p,
    output wire [0:0]  ddr3_ck_n,
    output wire        ddr3_reset_n,
    output wire [0:0]  ddr3_cke,
    output wire [0:0]  ddr3_cs_n,
    output wire        ddr3_ras_n,
    output wire        ddr3_cas_n,
    output wire        ddr3_we_n,
    output wire [14:0] ddr3_addr,
    output wire [2:0]  ddr3_ba,
    inout  wire [63:0] ddr3_dq,
    inout  wire [7:0]  ddr3_dqs_p,
    inout  wire [7:0]  ddr3_dqs_n,
    output wire [0:0]  ddr3_odt,

    output wire [2:0]  led
);
    localparam integer BYTE_LANES = 2;
    localparam integer WB_ADDR_BITS = 15 + 10 + 3 - 3;
    localparam integer WB_DATA_BITS = 8 * BYTE_LANES * 8;
    localparam integer WB_SEL_BITS = WB_DATA_BITS / 8;

    wire controller_clk;
    wire ddr3_clk;
    wire ref_clk;
    wire ddr3_clk_90;
    wire clk_locked;
    wire calib_complete;
    wire [31:0] debug1;
    wire [63:0] debug8;
    wire [31:0] debug_calib_gate;
    wire [63:0] debug_startup;
    wire [31:0] debug_idelay;
    wire [63:0] debug_calib_abort;
    wire [127:0] debug_calib_fail_snapshot;
    wire debug_phy_sync_rst;
    wire [2:0] debug_phy_status;
    wire [7:0] debug_phy_startup;
    wire [5*8*BYTE_LANES-1:0] debug_idelay_data_cntvalueout;
    wire [5*BYTE_LANES-1:0] debug_idelay_dqs_cntvalueout;
    wire [63:0] bist_counts;
    wire [959:0] jtag_debug_payload;
    wire jtag_debug_selected;
    wire uart_tx_unused;
    wire [BYTE_LANES-1:0] ddr3_dm_unused;

    wire bist_done = calib_complete && (debug1[4:0] == 5'd23);

    assign led[0] = bist_done;
    assign led[1] = !bist_done;
    assign led[2] = clk_locked;

    clk_wiz clk_wiz_inst (
        .clk_in1(clk50),
        .clk_out1(controller_clk),
        .clk_out2(ddr3_clk),
        .clk_out3(ref_clk),
        .clk_out4(ddr3_clk_90),
        .reset(!rst_n),
        .locked(clk_locked)
    );

    ddr3_top #(
        .CONTROLLER_CLK_PERIOD(12_000),
        .DDR3_CLK_PERIOD(3_000),
        .ROW_BITS(15),
        .COL_BITS(10),
        .BA_BITS(3),
        .BYTE_LANES(BYTE_LANES),
        .AUX_WIDTH(4),
        .WB2_ADDR_BITS(32),
        .WB2_DATA_BITS(32),
        .DUAL_RANK_DIMM(0),
        .MICRON_SIM(0),
        .ODELAY_SUPPORTED(0),
        .SECOND_WISHBONE(0),
        .DLL_OFF(0),
        .WB_ERROR(0),
        .BIST_MODE(2'd2),
        .BIST_TEST_DATAMASK(1'b0),
        .ECC_ENABLE(0),
        .SPEED_BIN(1),
        .SDRAM_CAPACITY(4)
    ) ddr3_top_inst (
        .i_controller_clk(controller_clk),
        .i_ddr3_clk(ddr3_clk),
        .i_ref_clk(ref_clk),
        .i_ddr3_clk_90(ddr3_clk_90),
        .i_rst_n(rst_n && clk_locked),

        .i_wb_cyc(1'b1),
        .i_wb_stb(1'b0),
        .i_wb_we(1'b0),
        .i_wb_addr({WB_ADDR_BITS{1'b0}}),
        .i_wb_data({WB_DATA_BITS{1'b0}}),
        .i_wb_sel({WB_SEL_BITS{1'b1}}),
        .i_aux(4'b0),
        .o_wb_stall(),
        .o_wb_ack(),
        .o_wb_err(),
        .o_wb_data(),
        .o_aux(),

        .i_wb2_cyc(1'b0),
        .i_wb2_stb(1'b0),
        .i_wb2_we(1'b0),
        .i_wb2_addr(32'b0),
        .i_wb2_data(32'b0),
        .i_wb2_sel(4'b0),
        .o_wb2_stall(),
        .o_wb2_ack(),
        .o_wb2_data(),

        .o_ddr3_clk_p(ddr3_ck_p),
        .o_ddr3_clk_n(ddr3_ck_n),
        .o_ddr3_reset_n(ddr3_reset_n),
        .o_ddr3_cke(ddr3_cke),
        .o_ddr3_cs_n(ddr3_cs_n),
        .o_ddr3_ras_n(ddr3_ras_n),
        .o_ddr3_cas_n(ddr3_cas_n),
        .o_ddr3_we_n(ddr3_we_n),
        .o_ddr3_addr(ddr3_addr),
        .o_ddr3_ba_addr(ddr3_ba),
        .io_ddr3_dq(ddr3_dq[(8*BYTE_LANES)-1:0]),
        .io_ddr3_dqs(ddr3_dqs_p[BYTE_LANES-1:0]),
        .io_ddr3_dqs_n(ddr3_dqs_n[BYTE_LANES-1:0]),
        .o_ddr3_dm(ddr3_dm_unused),
        .o_ddr3_odt(ddr3_odt),
        .o_calib_complete(calib_complete),
        .o_debug1(debug1),
        .o_debug8(debug8),
        .o_debug_calib_gate(debug_calib_gate),
        .o_debug_startup(debug_startup),
        .o_debug_idelay(debug_idelay),
        .o_debug_calib_abort(debug_calib_abort),
        .o_debug_calib_fail_snapshot(debug_calib_fail_snapshot),
        .o_debug_phy_sync_rst(debug_phy_sync_rst),
        .o_debug_phy_status(debug_phy_status),
        .o_debug_phy_startup(debug_phy_startup),
        .o_debug_idelay_data_cntvalueout(debug_idelay_data_cntvalueout),
        .o_debug_idelay_dqs_cntvalueout(debug_idelay_dqs_cntvalueout),
        .o_bist_counts(bist_counts),
        .i_user_self_refresh(1'b0),
        .uart_tx(uart_tx_unused)
    );

    assign jtag_debug_payload = {
        debug_calib_fail_snapshot,
        320'd0,
        bist_counts,
        78'd0,
        debug_calib_abort,
        debug_idelay_data_cntvalueout,
        debug_idelay_dqs_cntvalueout,
        debug_phy_sync_rst,
        debug_phy_status,
        debug_phy_startup,
        debug_idelay,
        debug_calib_gate,
        debug_startup[63:24],
        8'h03,
        32'h33445244,
        debug1,
        debug_startup[23:0],
        calib_complete,
        bist_done,
        clk_locked,
        rst_n
    };

    jtag_debug_bscan #(
        .WIDTH(960),
        .JTAG_CHAIN(1)
    ) jtag_debug_bscan_inst (
        .debug_data(jtag_debug_payload),
        .selected(jtag_debug_selected)
    );

    wire unused_jtag_debug_selected = jtag_debug_selected;

endmodule

`default_nettype wire

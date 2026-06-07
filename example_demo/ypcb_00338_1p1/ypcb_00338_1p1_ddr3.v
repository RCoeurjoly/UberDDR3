`default_nettype none
`timescale 1ps / 1ps

`ifndef UBERDDR3_YPCB_BYTE_LANES
`define UBERDDR3_YPCB_BYTE_LANES 2
`endif

`ifndef UBERDDR3_YPCB_BIST_MODE
`define UBERDDR3_YPCB_BIST_MODE 2
`endif

`ifndef UBERDDR3_YPCB_CONTROLLER_CLK_PERIOD
`define UBERDDR3_YPCB_CONTROLLER_CLK_PERIOD 12_000
`endif

`ifndef UBERDDR3_YPCB_DDR3_CLK_PERIOD
`define UBERDDR3_YPCB_DDR3_CLK_PERIOD 3_000
`endif

`ifndef UBERDDR3_YPCB_ROW_BITS
`define UBERDDR3_YPCB_ROW_BITS 15
`endif

`ifndef UBERDDR3_YPCB_COL_BITS
`define UBERDDR3_YPCB_COL_BITS 10
`endif

`ifndef UBERDDR3_YPCB_BA_BITS
`define UBERDDR3_YPCB_BA_BITS 3
`endif

`ifndef UBERDDR3_YPCB_AUX_WIDTH
`define UBERDDR3_YPCB_AUX_WIDTH 4
`endif

`ifndef UBERDDR3_YPCB_WB2_ADDR_BITS
`define UBERDDR3_YPCB_WB2_ADDR_BITS 32
`endif

`ifndef UBERDDR3_YPCB_WB2_DATA_BITS
`define UBERDDR3_YPCB_WB2_DATA_BITS 32
`endif

`ifndef UBERDDR3_YPCB_MICRON_SIM
`define UBERDDR3_YPCB_MICRON_SIM 0
`endif

`ifndef UBERDDR3_YPCB_ODELAY_SUPPORTED
`define UBERDDR3_YPCB_ODELAY_SUPPORTED 0
`endif

`ifndef UBERDDR3_YPCB_SECOND_WISHBONE
`define UBERDDR3_YPCB_SECOND_WISHBONE 0
`endif

`ifndef UBERDDR3_YPCB_WB_ERROR
`define UBERDDR3_YPCB_WB_ERROR 0
`endif

`ifndef UBERDDR3_YPCB_BIST_TEST_DATAMASK
`define UBERDDR3_YPCB_BIST_TEST_DATAMASK 0
`endif

`ifndef UBERDDR3_YPCB_ECC_ENABLE
`define UBERDDR3_YPCB_ECC_ENABLE 0
`endif

`ifndef UBERDDR3_YPCB_DIC
`define UBERDDR3_YPCB_DIC 2'b00
`endif

`ifndef UBERDDR3_YPCB_RTT_NOM
`define UBERDDR3_YPCB_RTT_NOM 3'b011
`endif

`ifndef UBERDDR3_YPCB_SELF_REFRESH
`define UBERDDR3_YPCB_SELF_REFRESH 2'b00
`endif

`ifndef UBERDDR3_YPCB_SPEED_BIN
`define UBERDDR3_YPCB_SPEED_BIN 1
`endif

`ifndef UBERDDR3_YPCB_SDRAM_CAPACITY
`define UBERDDR3_YPCB_SDRAM_CAPACITY 4
`endif

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
    localparam integer CONTROLLER_CLK_PERIOD = `UBERDDR3_YPCB_CONTROLLER_CLK_PERIOD;
    localparam integer DDR3_CLK_PERIOD = `UBERDDR3_YPCB_DDR3_CLK_PERIOD;
    localparam integer ROW_BITS = `UBERDDR3_YPCB_ROW_BITS;
    localparam integer COL_BITS = `UBERDDR3_YPCB_COL_BITS;
    localparam integer BA_BITS = `UBERDDR3_YPCB_BA_BITS;
    localparam integer BYTE_LANES = `UBERDDR3_YPCB_BYTE_LANES;
    localparam integer AUX_WIDTH = `UBERDDR3_YPCB_AUX_WIDTH;
    localparam integer WB2_ADDR_BITS = `UBERDDR3_YPCB_WB2_ADDR_BITS;
    localparam integer WB2_DATA_BITS = `UBERDDR3_YPCB_WB2_DATA_BITS;
    localparam [0:0] MICRON_SIM = `UBERDDR3_YPCB_MICRON_SIM;
    localparam [0:0] ODELAY_SUPPORTED = `UBERDDR3_YPCB_ODELAY_SUPPORTED;
    localparam [0:0] SECOND_WISHBONE = `UBERDDR3_YPCB_SECOND_WISHBONE;
    localparam [0:0] WB_ERROR = `UBERDDR3_YPCB_WB_ERROR;
    localparam [1:0] BIST_MODE = `UBERDDR3_YPCB_BIST_MODE;
    localparam [0:0] BIST_TEST_DATAMASK = `UBERDDR3_YPCB_BIST_TEST_DATAMASK;
    localparam [1:0] ECC_ENABLE = `UBERDDR3_YPCB_ECC_ENABLE;
    localparam [1:0] DIC = `UBERDDR3_YPCB_DIC;
    localparam [2:0] RTT_NOM = `UBERDDR3_YPCB_RTT_NOM;
    localparam [1:0] SELF_REFRESH = `UBERDDR3_YPCB_SELF_REFRESH;
    localparam integer SPEED_BIN = `UBERDDR3_YPCB_SPEED_BIN;
    localparam integer SDRAM_CAPACITY = `UBERDDR3_YPCB_SDRAM_CAPACITY;
    localparam integer WB_ADDR_BITS = ROW_BITS + COL_BITS + BA_BITS - 3;
    localparam integer WB_DATA_BITS = 8 * BYTE_LANES * 8;
    localparam integer WB_SEL_BITS = WB_DATA_BITS / 8;
    localparam integer WB2_SEL_BITS = WB2_DATA_BITS / 8;

    wire controller_clk;
    wire ddr3_clk;
    wire ref_clk;
    wire ddr3_clk_90;
    wire clk_locked;
    wire calib_complete;
    wire [31:0] debug1;
    wire [63:0] debug8;
    wire [2047:0] jtag_debug_payload;
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
        .CONTROLLER_CLK_PERIOD(CONTROLLER_CLK_PERIOD),
        .DDR3_CLK_PERIOD(DDR3_CLK_PERIOD),
        .ROW_BITS(ROW_BITS),
        .COL_BITS(COL_BITS),
        .BA_BITS(BA_BITS),
        .BYTE_LANES(BYTE_LANES),
        .AUX_WIDTH(AUX_WIDTH),
        .WB2_ADDR_BITS(WB2_ADDR_BITS),
        .WB2_DATA_BITS(WB2_DATA_BITS),
        .DUAL_RANK_DIMM(0),
        .MICRON_SIM(MICRON_SIM),
        .ODELAY_SUPPORTED(ODELAY_SUPPORTED),
        .SECOND_WISHBONE(SECOND_WISHBONE),
        .DLL_OFF(0),
        .WB_ERROR(WB_ERROR),
        .BIST_MODE(BIST_MODE),
        .BIST_TEST_DATAMASK(BIST_TEST_DATAMASK),
        .ECC_ENABLE(ECC_ENABLE),
        .SPEED_BIN(SPEED_BIN),
        .SDRAM_CAPACITY(SDRAM_CAPACITY),
        .DIC(DIC),
        .RTT_NOM(RTT_NOM),
        .SELF_REFRESH(SELF_REFRESH)
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
        .i_aux({AUX_WIDTH{1'b0}}),
        .o_wb_stall(),
        .o_wb_ack(),
        .o_wb_err(),
        .o_wb_data(),
        .o_aux(),

        .i_wb2_cyc(1'b0),
        .i_wb2_stb(1'b0),
        .i_wb2_we(1'b0),
        .i_wb2_addr({WB2_ADDR_BITS{1'b0}}),
        .i_wb2_data({WB2_DATA_BITS{1'b0}}),
        .i_wb2_sel({WB2_SEL_BITS{1'b0}}),
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
        .i_user_self_refresh(1'b0),
        .uart_tx(uart_tx_unused)
    );

    assign jtag_debug_payload = {
        782'd0,
        610'd0,
        128'd0,
        16'd0,
        debug8,
        348'd0,
        8'h04,
        32'h33445244,
        debug1,
        24'd0,
        calib_complete,
        bist_done,
        clk_locked,
        rst_n
    };

    jtag_debug_bscan #(
        .WIDTH(2048),
        .JTAG_CHAIN(1)
    ) jtag_debug_bscan_inst (
        .debug_data(jtag_debug_payload),
        .selected(jtag_debug_selected)
    );

    wire unused_jtag_debug_selected = jtag_debug_selected;
endmodule

`default_nettype wire

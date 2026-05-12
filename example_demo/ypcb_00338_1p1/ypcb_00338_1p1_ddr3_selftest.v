`default_nettype none
`timescale 1ps / 1ps

module ypcb_00338_1p1_ddr3_selftest (
    input  wire SYS_CLK,
    input  wire SYS_RSTN,
    input  wire i_clk200_p,
    input  wire i_clk200_n,
    output wire [2:0] led_3bits_tri_o,

    output wire [0:0] ddr3_ck_p,
    output wire [0:0] ddr3_ck_n,
    output wire       ddr3_reset_n,
    output wire [0:0] ddr3_cke,
    output wire [0:0] ddr3_cs_n,
    output wire       ddr3_ras_n,
    output wire       ddr3_cas_n,
    output wire       ddr3_we_n,
    output wire [14:0] ddr3_addr,
    output wire [2:0] ddr3_ba,
    inout  wire [15:0] ddr3_dq,
    inout  wire [1:0] ddr3_dqs_p,
    inout  wire [1:0] ddr3_dqs_n,
    output wire [0:0] ddr3_odt
);
    localparam CONTROLLER_CLK_PERIOD = 10_000;
    localparam DDR3_CLK_PERIOD = 2_500;
    localparam ROW_BITS = 15;
    localparam COL_BITS = 10;
    localparam BA_BITS = 3;
    localparam BYTE_LANES = 2;
    localparam AUX_WIDTH = 4;
    localparam BIST_ADDR_BITS = 12;
    localparam WB_ADDR_BITS = ROW_BITS + COL_BITS + BA_BITS - 3;
    localparam WB_DATA_BITS = 8 * BYTE_LANES * 8;
    localparam WB_SEL_BITS = WB_DATA_BITS / 8;

    wire sys_clk_200;
    wire controller_clk;
    wire ddr3_clk;
    wire ddr3_clk_n;
    wire ref_clk;
    wire ddr3_clk_90;
    wire clk_locked;
    wire calib_complete;
    wire [31:0] debug1;
    wire [BYTE_LANES-1:0] unused_ddr3_dm;
    wire wb2_cyc;
    wire wb2_stb;
    wire wb2_we;
    wire [31:0] wb2_addr;
    wire [31:0] wb2_wdata;
    wire [3:0] wb2_sel;
    wire wb2_stall;
    wire wb2_ack;
    wire [31:0] wb2_rdata;

    reg [25:0] heartbeat_counter = 26'd0;

    IBUFDS sys_clk_ibuf (
        .I(i_clk200_p),
        .IB(i_clk200_n),
        .O(sys_clk_200)
    );

    clk_wiz_ypcb clk_wiz_inst (
        .clk_in1(sys_clk_200),
        .reset(!SYS_RSTN),
        .locked(clk_locked),
        .controller_clk(controller_clk),
        .ddr3_clk(ddr3_clk),
        .ddr3_clk_n(ddr3_clk_n),
        .ref_clk(ref_clk),
        .ddr3_clk_90(ddr3_clk_90)
    );

    always @(posedge controller_clk) begin
        if (!SYS_RSTN || !clk_locked || !calib_complete) begin
            heartbeat_counter <= 26'd0;
        end else begin
            heartbeat_counter <= heartbeat_counter + 26'd1;
        end
    end

    assign led_3bits_tri_o[0] = clk_locked;
    assign led_3bits_tri_o[1] = calib_complete;
    assign led_3bits_tri_o[2] = calib_complete && heartbeat_counter[25];

    ddr3_top #(
        .CONTROLLER_CLK_PERIOD(CONTROLLER_CLK_PERIOD),
        .DDR3_CLK_PERIOD(DDR3_CLK_PERIOD),
        .ROW_BITS(ROW_BITS),
        .COL_BITS(COL_BITS),
        .BA_BITS(BA_BITS),
        .BYTE_LANES(BYTE_LANES),
        .AUX_WIDTH(AUX_WIDTH),
        .WB2_ADDR_BITS(32),
        .WB2_DATA_BITS(32),
        .MICRON_SIM(1'b0),
        .ODELAY_SUPPORTED(1'b0),
        .SECOND_WISHBONE(1'b1),
        .DLL_OFF(1'b0),
        .WB_ERROR(1'b0),
        .BIST_MODE(2'd1),
        .BIST_ADDR_BITS(BIST_ADDR_BITS),
        .ECC_ENABLE(2'd0),
        .DIC(2'b01),
        .RTT_NOM(3'b001),
        .SELF_REFRESH(2'b00),
        .DUAL_RANK_DIMM(1'b0),
        .SPEED_BIN(1),
        .SDRAM_CAPACITY(4)
    ) ddr3_top_inst (
        .i_controller_clk(controller_clk),
        .i_ddr3_clk(ddr3_clk),
        .i_ddr3_clk_n(ddr3_clk_n),
        .i_ref_clk(ref_clk),
        .i_ddr3_clk_90(ddr3_clk_90),
        .i_rst_n(SYS_RSTN && clk_locked),

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

        .i_wb2_cyc(wb2_cyc),
        .i_wb2_stb(wb2_stb),
        .i_wb2_we(wb2_we),
        .i_wb2_addr(wb2_addr),
        .i_wb2_data(wb2_wdata),
        .i_wb2_sel(wb2_sel),
        .o_wb2_stall(wb2_stall),
        .o_wb2_ack(wb2_ack),
        .o_wb2_data(wb2_rdata),

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
        .io_ddr3_dq(ddr3_dq),
        .io_ddr3_dqs(ddr3_dqs_p),
        .io_ddr3_dqs_n(ddr3_dqs_n),
        .o_ddr3_dm(unused_ddr3_dm),
        .o_ddr3_odt(ddr3_odt),
        .o_calib_complete(calib_complete),
        .o_debug1(debug1),
        .i_user_self_refresh(1'b0),
        .uart_tx()
    );

    jtag_wb2_bridge #(
        .WB2_ADDR_BITS(32),
        .WB2_DATA_BITS(32)
    ) jtag_wb2_bridge_inst (
        .i_clk(controller_clk),
        .i_rst(!SYS_RSTN || !clk_locked),
        .o_wb2_cyc(wb2_cyc),
        .o_wb2_stb(wb2_stb),
        .o_wb2_we(wb2_we),
        .o_wb2_addr(wb2_addr),
        .o_wb2_data(wb2_wdata),
        .o_wb2_sel(wb2_sel),
        .i_wb2_stall(wb2_stall),
        .i_wb2_ack(wb2_ack),
        .i_wb2_data(wb2_rdata)
    );

    wire unused = SYS_CLK ^ ^debug1 ^ ^unused_ddr3_dm;
endmodule

`default_nettype wire

`timescale 1ps / 1ps
`default_nettype none

module ypcb_rtl_bist_tb;
`include "sim_defines.vh"

`ifdef den1024Mb
    `include "1024Mb_ddr3_parameters.vh"
`elsif den2048Mb
    `include "2048Mb_ddr3_parameters.vh"
`elsif den4096Mb
    `include "4096Mb_ddr3_parameters.vh"
`elsif den8192Mb
    `include "8192Mb_ddr3_parameters.vh"
`else
    ERROR: You must specify component density with +define+den____Mb.
`endif

    localparam integer CONTROLLER_CLK_PERIOD = 12_000;
    localparam integer DDR3_CLK_PERIOD = 3_000;
    localparam integer BYTE_LANES = 2;
    localparam integer AUX_WIDTH = 4;
    localparam integer WB_DATA_BITS = 8 * BYTE_LANES * 4 * 2;
    localparam integer WB_SEL_BITS = WB_DATA_BITS / 8;
    localparam integer WB_ADDR_BITS = 15 + 10 + 3 - 3;

    reg i_controller_clk = 1'b1;
    reg i_ddr3_clk = 1'b1;
    reg i_ref_clk = 1'b1;
    reg i_ddr3_clk_90 = 1'b1;
    reg i_rst_n = 1'b0;

    wire [0:0] ck_en;
    wire [0:0] cs_n;
    wire [0:0] odt;
    wire ras_n;
    wire cas_n;
    wire we_n;
    wire reset_n;
    wire [14:0] addr;
    wire [2:0] ba_addr;
    wire [BYTE_LANES-1:0] ddr3_dm;
    wire [(8*BYTE_LANES)-1:0] dq;
    wire [BYTE_LANES-1:0] dqs;
    wire [BYTE_LANES-1:0] dqs_n;
    wire [0:0] ddr3_clk_p;
    wire [0:0] ddr3_clk_n;
    wire calib_complete;
    wire [31:0] debug1;
    wire [63:0] bist_counts;

    wire bist_done = calib_complete && (debug1[4:0] == 5'd23);

    always #(CONTROLLER_CLK_PERIOD/2) i_controller_clk = !i_controller_clk;
    always #(DDR3_CLK_PERIOD/2) i_ddr3_clk = !i_ddr3_clk;
    always #2500 i_ref_clk = !i_ref_clk;

    initial begin
        #(DDR3_CLK_PERIOD/4);
        forever #(DDR3_CLK_PERIOD/2) i_ddr3_clk_90 = !i_ddr3_clk_90;
    end

    ddr3_top #(
        .CONTROLLER_CLK_PERIOD(CONTROLLER_CLK_PERIOD),
        .DDR3_CLK_PERIOD(DDR3_CLK_PERIOD),
        .ROW_BITS(15),
        .COL_BITS(10),
        .BA_BITS(3),
        .BYTE_LANES(BYTE_LANES),
        .AUX_WIDTH(AUX_WIDTH),
        .WB2_ADDR_BITS(32),
        .WB2_DATA_BITS(32),
        .DUAL_RANK_DIMM(0),
        .MICRON_SIM(1),
        .ODELAY_SUPPORTED(0),
        .SECOND_WISHBONE(0),
        .DLL_OFF(0),
        .WB_ERROR(0),
        .BIST_MODE(2),
        .BIST_TEST_DATAMASK(1'b0),
        .ECC_ENABLE(0),
        .SPEED_BIN(1),
        .SDRAM_CAPACITY(4)
    ) dut (
        .i_controller_clk(i_controller_clk),
        .i_ddr3_clk(i_ddr3_clk),
        .i_ref_clk(i_ref_clk),
        .i_ddr3_clk_90(i_ddr3_clk_90),
        .i_rst_n(i_rst_n),

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
        .i_wb2_addr(32'b0),
        .i_wb2_data(32'b0),
        .i_wb2_sel(4'b0),
        .o_wb2_stall(),
        .o_wb2_ack(),
        .o_wb2_data(),

        .o_ddr3_clk_p(ddr3_clk_p),
        .o_ddr3_clk_n(ddr3_clk_n),
        .o_ddr3_cke(ck_en),
        .o_ddr3_cs_n(cs_n),
        .o_ddr3_odt(odt),
        .o_ddr3_ras_n(ras_n),
        .o_ddr3_cas_n(cas_n),
        .o_ddr3_we_n(we_n),
        .o_ddr3_reset_n(reset_n),
        .o_ddr3_addr(addr),
        .o_ddr3_ba_addr(ba_addr),
        .io_ddr3_dq(dq),
        .io_ddr3_dqs(dqs),
        .io_ddr3_dqs_n(dqs_n),
        .o_ddr3_dm(ddr3_dm),
        .o_calib_complete(calib_complete),
        .o_debug1(debug1),
        .o_debug8(),
        .o_bist_counts(bist_counts),
        .i_user_self_refresh(1'b0),
        .uart_tx()
    );

    ddr3 #(.DLL_OFF(0)) dram (
        .rst_n(reset_n),
        .ck(ddr3_clk_p[0]),
        .ck_n(ddr3_clk_n[0]),
        .cke(ck_en[0]),
        .cs_n(cs_n[0]),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .dm_tdqs(ddr3_dm),
        .ba(ba_addr),
        .addr(addr),
        .dq(dq),
        .dqs(dqs),
        .dqs_n(dqs_n),
        .tdqs_n(),
        .odt(odt[0])
    );

    initial begin
        $display("YPCB RTL BIST simulation starting");
        repeat (4) @(posedge i_controller_clk);
        i_rst_n <= 1'b1;
    end

    always @(posedge i_controller_clk) begin
        if (calib_complete) begin
            $display("YPCB calibration complete at %0t ps debug1=%h bist_counts=%h", $time, debug1, bist_counts);
        end
        if (bist_done) begin
            $display("YPCB BIST done at %0t ps debug1=%h bist_counts=%h", $time, debug1, bist_counts);
            $finish;
        end
    end

    initial begin
        #50_000_000_000;
        $display("YPCB RTL BIST timeout at %0t ps debug1=%h bist_counts=%h", $time, debug1, bist_counts);
        $finish;
    end
endmodule

`default_nettype wire

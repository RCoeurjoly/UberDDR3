`default_nettype none

`ifndef YPCB_CALIB_COMMAND_WB_ENABLE
`define YPCB_CALIB_COMMAND_WB_ENABLE 0
`endif

`ifndef YPCB_CALIB_COMMAND_JTAG_ENABLE
`define YPCB_CALIB_COMMAND_JTAG_ENABLE 0
`endif

`ifndef YPCB_CALIB_DEBUG_LOADER_PAYLOAD_ENABLE
`define YPCB_CALIB_DEBUG_LOADER_PAYLOAD_ENABLE 0
`endif

`ifndef YPCB_CALIB_COMMAND_FULLBEAT_ENABLE
`define YPCB_CALIB_COMMAND_FULLBEAT_ENABLE 1
`endif

`ifndef YPCB_CALIB_COMMAND_READBACK_ENABLE
`define YPCB_CALIB_COMMAND_READBACK_ENABLE 1
`endif

`ifndef YPCB_CALIB_DEBUG_WB_DATA_ENABLE
`define YPCB_CALIB_DEBUG_WB_DATA_ENABLE 1
`endif

module ypcb_00338_1p1_uberddr3_calib_only (
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
    output wire [0:0]  ddr3_odt
);
  task6_ypcb_uberddr3_calib_only_top #(
        .COMMAND_WB_ENABLE(`YPCB_CALIB_COMMAND_WB_ENABLE),
        .COMMAND_JTAG_ENABLE(`YPCB_CALIB_COMMAND_JTAG_ENABLE),
        .DEBUG_LOADER_PAYLOAD_ENABLE(`YPCB_CALIB_DEBUG_LOADER_PAYLOAD_ENABLE),
        .COMMAND_FULLBEAT_ENABLE(`YPCB_CALIB_COMMAND_FULLBEAT_ENABLE),
        .COMMAND_READBACK_ENABLE(`YPCB_CALIB_COMMAND_READBACK_ENABLE),
        .DEBUG_WB_DATA_ENABLE(`YPCB_CALIB_DEBUG_WB_DATA_ENABLE)
    ) calib_top (
        .clk50(clk50),
        .SYS_RSTN(rst_n),
        .ddram_a(ddr3_addr),
        .ddram_ba(ddr3_ba),
        .ddram_cas_n(ddr3_cas_n),
        .ddram_cke(ddr3_cke[0]),
        .ddram_clk_n(ddr3_ck_n[0]),
        .ddram_clk_p(ddr3_ck_p[0]),
        .ddram_cs_n(ddr3_cs_n[0]),
        .ddram_dq(ddr3_dq),
        .ddram_dqs_n(ddr3_dqs_n),
        .ddram_dqs_p(ddr3_dqs_p),
        .ddram_odt(ddr3_odt[0]),
        .ddram_ras_n(ddr3_ras_n),
        .ddram_reset_n(ddr3_reset_n),
        .ddram_we_n(ddr3_we_n)
    );
endmodule

`default_nettype wire

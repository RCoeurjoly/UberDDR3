`default_nettype none

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
  task6_ypcb_uberddr3_calib_only_top calib_top (
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

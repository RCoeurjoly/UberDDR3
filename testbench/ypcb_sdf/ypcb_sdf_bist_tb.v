`default_nettype none
`timescale 1ps / 1ps

module ypcb_sdf_bist_tb;
    reg clk50 = 1'b0;
    reg rst_n = 1'b0;

    wire [0:0] ddr3_ck_p;
    wire [0:0] ddr3_ck_n;
    wire ddr3_reset_n;
    wire [0:0] ddr3_cke;
    wire [0:0] ddr3_cs_n;
    wire ddr3_ras_n;
    wire ddr3_cas_n;
    wire ddr3_we_n;
    wire [14:0] ddr3_addr;
    wire [2:0] ddr3_ba;
    wire [63:0] ddr3_dq;
    wire [7:0] ddr3_dqs_p;
    wire [7:0] ddr3_dqs_n;
    wire [0:0] ddr3_odt;
    wire [2:0] led;

    wire [17:0] ddr3_dqs_p_module = {10'b0, ddr3_dqs_p};
    wire [17:0] ddr3_dqs_n_module = {10'b0, ddr3_dqs_n};
    wire sda;

    ypcb_00338_1p1_ddr3 dut (
        .clk50(clk50),
        .rst_n(rst_n),
        .ddr3_ck_p(ddr3_ck_p),
        .ddr3_ck_n(ddr3_ck_n),
        .ddr3_reset_n(ddr3_reset_n),
        .ddr3_cke(ddr3_cke),
        .ddr3_cs_n(ddr3_cs_n),
        .ddr3_ras_n(ddr3_ras_n),
        .ddr3_cas_n(ddr3_cas_n),
        .ddr3_we_n(ddr3_we_n),
        .ddr3_addr(ddr3_addr),
        .ddr3_ba(ddr3_ba),
        .ddr3_dq(ddr3_dq),
        .ddr3_dqs_p(ddr3_dqs_p),
        .ddr3_dqs_n(ddr3_dqs_n),
        .ddr3_odt(ddr3_odt),
        .led(led)
    );

    ddr3_module #(
        .DLL_OFF(0)
    ) ddr3_model (
        .reset_n(ddr3_reset_n),
        .ck({1'b0, ddr3_ck_p[0]}),
        .ck_n({1'b1, ddr3_ck_n[0]}),
        .cke({1'b0, ddr3_cke[0]}),
        .s_n({1'b1, ddr3_cs_n[0]}),
        .ras_n(ddr3_ras_n),
        .cas_n(ddr3_cas_n),
        .we_n(ddr3_we_n),
        .ba(ddr3_ba),
        .addr({1'b0, ddr3_addr}),
        .odt({1'b0, ddr3_odt[0]}),
        .dqs(ddr3_dqs_p_module),
        .dqs_n(ddr3_dqs_n_module),
        .dq(ddr3_dq),
        .scl(1'b0),
        .sa(2'b00),
        .sda(sda)
    );

    always #10000 clk50 = !clk50;

    initial begin
        if ($test$plusargs("sdf")) begin
            $display("Annotating SDF: ypcb_00338_1p1_ddr3.sdf");
            $sdf_annotate("ypcb_00338_1p1_ddr3.sdf", dut);
        end

        repeat (20) @(posedge clk50);
        rst_n <= 1'b1;
    end

    initial begin
        repeat (5000000) @(posedge clk50);
        $display("TIMEOUT led=%b", led);
        $finish;
    end

    always @(posedge clk50) begin
        if (led[0]) begin
            $display("PASS led=%b", led);
            $finish;
        end
        if (led[1] && rst_n) begin
            // Keep running; LED1 is also high before BIST completes in this design.
        end
    end
endmodule

`default_nettype wire

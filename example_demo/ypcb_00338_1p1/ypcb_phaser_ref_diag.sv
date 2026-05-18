`default_nettype none

module ypcb_phaser_ref_diag (
    input wire clk50,
    input wire rst_n,
    output wire [2:0] led
);
    wire rst = ~rst_n;
    wire inactive_low = 1'b0;

    reg [25:0] heartbeat_q = 26'h0;
    always @(posedge clk50 or posedge rst) begin
        if (rst)
            heartbeat_q <= 26'h0;
        else
            heartbeat_q <= heartbeat_q + 1'b1;
    end

    wire phaser_pll_fb;
    wire phaser_freq_refclk;
    wire phaser_ref_locked;
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
        .CLKIN1_PERIOD(20.000)
    ) phaser_pll_i (
        .CLKFBOUT(phaser_pll_fb),
        .CLKOUT0(phaser_freq_refclk),
        .CLKFBIN(phaser_pll_fb),
        .CLKIN1(clk50),
        .CLKINSEL(1'b1),
        .LOCKED(phaser_pll_locked),
        .PWRDWN(inactive_low),
        .RST(rst)
    );

    (* keep, dont_touch, PHASER_CLOCKED_ORACLE_ROUTE = 1 *)
    PHASER_REF phaser_ref_i (
        .LOCKED(phaser_ref_locked),
        .CLKIN(phaser_freq_refclk),
        .PWRDWN(inactive_low),
        .RST(rst)
    );

    wire [31:0] status_word = {
        27'h0,
        heartbeat_q[25],
        rst_n,
        1'b0,
        phaser_ref_locked,
        phaser_pll_locked
    };
    wire [127:0] read_payload = {
        56'h0,
        status_word,
        8'h02,
        32'h50485344
    };

    ypcb_bscan_readback #(
        .WIDTH(128),
        .JTAG_CHAIN(1)
    ) readback_port (
        .payload_i(read_payload)
    );

    assign led[0] = phaser_ref_locked;
    assign led[1] = phaser_pll_locked;
    assign led[2] = heartbeat_q[25];
endmodule

`default_nettype wire

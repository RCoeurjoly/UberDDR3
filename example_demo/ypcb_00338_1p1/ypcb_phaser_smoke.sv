`default_nettype none

module ypcb_phaser_smoke (
    input  wire       clk50,
    input  wire       rst_n,
    output wire [2:0] led
);
    wire rst = ~rst_n;

    reg [25:0] blink_counter = 26'h0;

    always @(posedge clk50 or posedge rst) begin
        if (rst)
            blink_counter <= 26'h0;
        else
            blink_counter <= blink_counter + 1'b1;
    end

    (* keep, dont_touch *) PHASER_REF phaser_ref_i ();

    (* keep, dont_touch *)
    PHY_CONTROL #(
        .BURST_MODE("FALSE"),
        .CLK_RATIO(4),
        .SYNC_MODE("FALSE")
    ) phy_control_i ();

    (* keep, dont_touch *)
    PHASER_IN_PHY #(
        .CLKOUT_DIV(4),
        .OUTPUT_CLK_SRC("PHASE_REF"),
        .REFCLK_PERIOD(20.000),
        .MEMREFCLK_PERIOD(20.000),
        .PHASEREFCLK_PERIOD(20.000)
    ) phaser_in_i ();

    (* keep, dont_touch *)
    PHASER_OUT_PHY #(
        .CLKOUT_DIV(4),
        .OUTPUT_CLK_SRC("PHASE_REF"),
        .REFCLK_PERIOD(20.000),
        .MEMREFCLK_PERIOD(20.000),
        .PHASEREFCLK_PERIOD(20.000)
    ) phaser_out_i ();

    (* keep, dont_touch *) IN_FIFO in_fifo_i ();

    (* keep, dont_touch *) OUT_FIFO out_fifo_i ();

    assign led[0] = blink_counter[23];
    assign led[1] = blink_counter[24];
    assign led[2] = blink_counter[25];
endmodule

`default_nettype wire

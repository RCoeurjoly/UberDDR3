`default_nettype none
`timescale 1ps / 1ps

module jtag_debug_bscan #(
    parameter integer WIDTH = 64,
    parameter integer JTAG_CHAIN = 1
) (
    input  wire [WIDTH-1:0] debug_data,
    output wire             selected,
    output reg              capture_toggle = 1'b0
);
    wire capture;
    wire drck;
    wire reset;
    wire runtest;
    wire sel;
    wire shift;
    wire tck;
    wire tdi;
    wire tms;
    wire update;
    wire tdo;

    reg [WIDTH-1:0] shift_reg = {WIDTH{1'b0}};

    BSCANE2 #(
        .JTAG_CHAIN(JTAG_CHAIN)
    ) bscan_inst (
        .CAPTURE(capture),
        .DRCK(drck),
        .RESET(reset),
        .RUNTEST(runtest),
        .SEL(sel),
        .SHIFT(shift),
        .TCK(tck),
        .TDI(tdi),
        .TMS(tms),
        .UPDATE(update),
        .TDO(tdo)
    );

    always @(posedge tck) begin
        if (reset) begin
            capture_toggle <= 1'b0;
            shift_reg <= {WIDTH{1'b0}};
        end else if (sel && capture) begin
            capture_toggle <= !capture_toggle;
            shift_reg <= debug_data;
        end else if (sel && shift) begin
            shift_reg <= {tdi, shift_reg[WIDTH-1:1]};
        end
    end

    assign tdo = shift_reg[0];
    assign selected = sel;

    wire unused = drck ^ runtest ^ tms ^ update;
endmodule

`default_nettype wire

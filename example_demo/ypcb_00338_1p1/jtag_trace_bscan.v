`default_nettype none
`timescale 1ps / 1ps

module jtag_trace_bscan #(
    parameter integer WORD_WIDTH = 64,
    parameter integer ADDR_WIDTH = 6,
    parameter integer JTAG_CHAIN = 2
) (
    input  wire [WORD_WIDTH-1:0]      trace_word,
    output reg  [ADDR_WIDTH-1:0]      read_addr = {ADDR_WIDTH{1'b0}},
    output wire                       selected
);
    localparam integer DR_WIDTH = WORD_WIDTH + ADDR_WIDTH;

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

    reg [DR_WIDTH-1:0] shift_reg = {DR_WIDTH{1'b0}};
    integer addr_bit;

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
            shift_reg <= {DR_WIDTH{1'b0}};
        end else if (sel && capture) begin
            shift_reg <= {{ADDR_WIDTH{1'b0}}, trace_word};
        end else if (sel && shift) begin
            shift_reg <= {tdi, shift_reg[DR_WIDTH-1:1]};
        end
    end

    always @(posedge update or posedge reset) begin
        if (reset) begin
            read_addr <= {ADDR_WIDTH{1'b0}};
        end else begin
            for (addr_bit = 0; addr_bit < ADDR_WIDTH; addr_bit = addr_bit + 1) begin
                read_addr[addr_bit] <= shift_reg[addr_bit];
            end
        end
    end

    assign tdo = shift_reg[0];
    assign selected = sel;

    wire unused = drck ^ runtest ^ tms ^ update;
endmodule

`default_nettype wire

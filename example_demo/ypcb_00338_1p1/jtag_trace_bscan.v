`default_nettype none
`timescale 1ps / 1ps

module jtag_trace_bscan #(
    parameter integer ADDR_WIDTH = 16,
    parameter integer JTAG_CHAIN = 2
) (
    input  wire [31:0]                response_data,
    input  wire [31:0]                response_status,
    output reg                        command_toggle = 1'b0,
    output reg                        command_we = 1'b0,
    output reg  [ADDR_WIDTH-1:0]      command_addr = {ADDR_WIDTH{1'b0}},
    output reg  [31:0]                command_data = 32'd0,
    output wire                       selected
);
    localparam integer DR_WIDTH = 72;

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
            shift_reg <= {8'd0, response_status, response_data};
        end else if (sel && shift) begin
            shift_reg <= {tdi, shift_reg[DR_WIDTH-1:1]};
        end
    end

    always @(posedge update or posedge reset) begin
        if (reset) begin
            command_toggle <= 1'b0;
            command_we <= 1'b0;
            command_addr <= {ADDR_WIDTH{1'b0}};
            command_data <= 32'd0;
        end else if (shift_reg[17]) begin
            command_addr <= shift_reg[ADDR_WIDTH-1:0];
            command_we <= shift_reg[16];
            command_data <= shift_reg[63:32];
            command_toggle <= !command_toggle;
        end
    end

    assign tdo = shift_reg[0];
    assign selected = sel;

    wire unused = drck ^ runtest ^ tms ^ update;
endmodule

`default_nettype wire

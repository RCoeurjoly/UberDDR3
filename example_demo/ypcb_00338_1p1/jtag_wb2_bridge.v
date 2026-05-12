`default_nettype none

module jtag_wb2_bridge #(
    parameter integer WB2_ADDR_BITS = 32,
    parameter integer WB2_DATA_BITS = 32
) (
    input  wire                     i_clk,
    input  wire                     i_rst,

    output reg                      o_wb2_cyc,
    output reg                      o_wb2_stb,
    output reg                      o_wb2_we,
    output reg  [WB2_ADDR_BITS-1:0] o_wb2_addr,
    output reg  [WB2_DATA_BITS-1:0] o_wb2_data,
    output reg  [3:0]               o_wb2_sel,
    input  wire                     i_wb2_stall,
    input  wire                     i_wb2_ack,
    input  wire [WB2_DATA_BITS-1:0] i_wb2_data
);
    localparam [7:0] CMD_MAGIC  = 8'h5a;
    localparam [7:0] RESP_MAGIC = 8'ha5;

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

    reg [63:0] shift_reg = 64'd0;
    reg [63:0] response_tck = {RESP_MAGIC, 56'd0};
    reg req_toggle_tck = 1'b0;
    reg busy_tck = 1'b0;
    reg [1:0] ack_sync_tck = 2'b00;
    reg ack_seen_tck = 1'b0;

    reg cmd_we_tck = 1'b0;
    reg [3:0] cmd_sel_tck = 4'h0;
    reg [WB2_ADDR_BITS-1:0] cmd_addr_tck = {WB2_ADDR_BITS{1'b0}};
    reg [WB2_DATA_BITS-1:0] cmd_data_tck = {WB2_DATA_BITS{1'b0}};

    reg [1:0] req_sync_clk = 2'b00;
    reg req_seen_clk = 1'b0;
    reg ack_toggle_clk = 1'b0;
    reg [63:0] response_clk = {RESP_MAGIC, 56'd0};
    reg [1:0] wb_state = 2'd0;

    BSCANE2 #(
        .JTAG_CHAIN(1)
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

    assign tdo = shift_reg[0];

    always @(posedge drck or posedge reset) begin
        if (reset) begin
            shift_reg <= 64'd0;
        end else begin
            if (capture) begin
                shift_reg <= response_tck | (busy_tck ? 64'h0080_0000_0000_0000 : 64'd0);
            end else if (shift) begin
                shift_reg <= {tdi, shift_reg[63:1]};
            end
        end
    end

    always @(posedge tck or posedge reset) begin
        if (reset) begin
            req_toggle_tck <= 1'b0;
            busy_tck <= 1'b0;
            ack_sync_tck <= 2'b00;
            ack_seen_tck <= 1'b0;
            response_tck <= {RESP_MAGIC, 56'd0};
            cmd_we_tck <= 1'b0;
            cmd_sel_tck <= 4'h0;
            cmd_addr_tck <= {WB2_ADDR_BITS{1'b0}};
            cmd_data_tck <= {WB2_DATA_BITS{1'b0}};
        end else begin
            ack_sync_tck <= {ack_sync_tck[0], ack_toggle_clk};
            if (ack_sync_tck[1] != ack_seen_tck) begin
                ack_seen_tck <= ack_sync_tck[1];
                response_tck <= response_clk;
                busy_tck <= 1'b0;
            end
            if (update && shift_reg[63:56] == CMD_MAGIC && shift_reg[54] && !busy_tck) begin
                cmd_we_tck <= shift_reg[55];
                cmd_sel_tck <= shift_reg[51:48];
                cmd_addr_tck <= {{(WB2_ADDR_BITS-16){1'b0}}, shift_reg[47:32]};
                cmd_data_tck <= shift_reg[31:0];
                req_toggle_tck <= !req_toggle_tck;
                busy_tck <= 1'b1;
            end
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            req_sync_clk <= 2'b00;
            req_seen_clk <= 1'b0;
            ack_toggle_clk <= 1'b0;
            response_clk <= {RESP_MAGIC, 56'd0};
            wb_state <= 2'd0;
            o_wb2_cyc <= 1'b0;
            o_wb2_stb <= 1'b0;
            o_wb2_we <= 1'b0;
            o_wb2_addr <= {WB2_ADDR_BITS{1'b0}};
            o_wb2_data <= {WB2_DATA_BITS{1'b0}};
            o_wb2_sel <= 4'h0;
        end else begin
            req_sync_clk <= {req_sync_clk[0], req_toggle_tck};

            case (wb_state)
                2'd0: begin
                    o_wb2_cyc <= 1'b0;
                    o_wb2_stb <= 1'b0;
                    if (req_sync_clk[1] != req_seen_clk) begin
                        req_seen_clk <= req_sync_clk[1];
                        o_wb2_cyc <= 1'b1;
                        o_wb2_stb <= 1'b1;
                        o_wb2_we <= cmd_we_tck;
                        o_wb2_addr <= cmd_addr_tck;
                        o_wb2_data <= cmd_data_tck;
                        o_wb2_sel <= cmd_sel_tck;
                        wb_state <= 2'd1;
                    end
                end

                2'd1: begin
                    if (!i_wb2_stall) begin
                        o_wb2_stb <= 1'b0;
                        wb_state <= 2'd2;
                    end
                end

                default: begin
                    if (i_wb2_ack) begin
                        response_clk <= {
                            RESP_MAGIC,
                            1'b0,
                            ack_toggle_clk,
                            1'b1,
                            i_wb2_stall,
                            15'd0,
                            o_wb2_addr[4:0],
                            i_wb2_data
                        };
                        ack_toggle_clk <= !ack_toggle_clk;
                        o_wb2_cyc <= 1'b0;
                        o_wb2_stb <= 1'b0;
                        o_wb2_we <= 1'b0;
                        wb_state <= 2'd0;
                    end
                end
            endcase
        end
    end

    wire unused = runtest ^ tck ^ tms ^ sel;
endmodule

`default_nettype wire

`default_nettype none
`timescale 1ps / 1ps

module ypcb_debug_wb_scope #(
    parameter integer DATA_WIDTH = 64,
    parameter integer DEPTH = 32,
    parameter integer INDEX_WIDTH = 5
) (
    input  wire                  i_clk,
    input  wire                  i_rst_n,

    input  wire [DATA_WIDTH-1:0] i_sample_data,
    input  wire                  i_sample_valid,
    input  wire                  i_trigger,

    input  wire                  i_wb_cyc,
    input  wire                  i_wb_stb,
    input  wire                  i_wb_we,
    input  wire [3:0]            i_wb_addr,
    input  wire [31:0]           i_wb_data,
    input  wire [3:0]            i_wb_sel,
    output wire                  o_wb_stall,
    output reg                   o_wb_ack,
    output reg  [31:0]           o_wb_data
);
    localparam [31:0] MAGIC = 32'h53435031; // SCP1
    localparam [7:0] DEPTH_COUNT = DEPTH[7:0];

    reg [DATA_WIDTH-1:0] samples_q [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] last_sample_q = {DATA_WIDTH{1'b0}};
    reg [INDEX_WIDTH-1:0] write_index_q = {INDEX_WIDTH{1'b0}};
    reg [7:0] count_q = 8'd0;
    reg frozen_q = 1'b0;
    reg overflow_q = 1'b0;
    reg [INDEX_WIDTH-1:0] read_index_q = {INDEX_WIDTH{1'b0}};
    integer sample_index;

    wire wb_fire = i_wb_cyc && i_wb_stb && !o_wb_ack;
    wire sample_changed = i_sample_data != last_sample_q;
    wire capture_now = i_sample_valid && !frozen_q && sample_changed;

    assign o_wb_stall = 1'b0;

    always @(posedge i_clk) begin
        if(!i_rst_n) begin
            write_index_q <= {INDEX_WIDTH{1'b0}};
            read_index_q <= {INDEX_WIDTH{1'b0}};
            count_q <= 8'd0;
            frozen_q <= 1'b0;
            overflow_q <= 1'b0;
            last_sample_q <= {DATA_WIDTH{1'b0}};
            o_wb_ack <= 1'b0;
            o_wb_data <= 32'd0;
            for(sample_index = 0; sample_index < DEPTH; sample_index = sample_index + 1) begin
                samples_q[sample_index] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            o_wb_ack <= wb_fire;

            if(capture_now) begin
                samples_q[write_index_q] <= i_sample_data;
                last_sample_q <= i_sample_data;
                write_index_q <= write_index_q + {{(INDEX_WIDTH-1){1'b0}}, 1'b1};
                if(count_q != DEPTH_COUNT) begin
                    count_q <= count_q + 8'd1;
                end else begin
                    overflow_q <= 1'b1;
                end
            end

            if(i_trigger) begin
                frozen_q <= 1'b1;
            end

            if(wb_fire && i_wb_we) begin
                case(i_wb_addr)
                    4'h1: begin
                        if(i_wb_data[0]) begin
                            frozen_q <= 1'b0;
                            overflow_q <= 1'b0;
                            count_q <= 8'd0;
                            write_index_q <= {INDEX_WIDTH{1'b0}};
                            last_sample_q <= {DATA_WIDTH{1'b0}};
                        end
                        if(i_wb_data[1]) begin
                            frozen_q <= 1'b1;
                        end
                    end
                    4'h2: read_index_q <= i_wb_data[INDEX_WIDTH-1:0];
                    default: begin end
                endcase
            end

            if(wb_fire && !i_wb_we) begin
                case(i_wb_addr)
                    4'h0: o_wb_data <= MAGIC;
                    4'h1: o_wb_data <= {16'd0, overflow_q, frozen_q, count_q[7:0], 1'b0, write_index_q};
                    4'h2: o_wb_data <= {{(32-INDEX_WIDTH){1'b0}}, read_index_q};
                    4'h3: o_wb_data <= samples_q[read_index_q][31:0];
                    4'h4: o_wb_data <= samples_q[read_index_q][63:32];
                    4'h5: o_wb_data <= i_sample_data[31:0];
                    4'h6: o_wb_data <= i_sample_data[63:32];
                    default: o_wb_data <= 32'd0;
                endcase
            end
        end
    end
endmodule

`default_nettype wire

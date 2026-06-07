`default_nettype none
`timescale 1ps / 1ps

module ypcb_debug_axi_lite #(
    parameter integer STATUS_WIDTH = 128,
    parameter integer PCIE_SAMPLE_WIDTH = 64,
    parameter integer SCOPE_DEPTH = 32,
    parameter integer SCOPE_INDEX_WIDTH = 5
) (
    input  wire                          i_axi_clk,
    input  wire                          i_axi_rst_n,

    input  wire [STATUS_WIDTH-1:0]       i_status_snapshot,

    input  wire [PCIE_SAMPLE_WIDTH-1:0]  i_pcie_sample_data,
    input  wire                          i_pcie_sample_valid,
    input  wire                          i_pcie_trigger,

    output reg                           o_debug_rearm,
    output reg                           o_debug_freeze,

    input  wire [31:0]                   s_axi_awaddr,
    input  wire                          s_axi_awvalid,
    output reg                           s_axi_awready,

    input  wire [31:0]                   s_axi_wdata,
    input  wire [3:0]                    s_axi_wstrb,
    input  wire                          s_axi_wvalid,
    output reg                           s_axi_wready,

    output reg [1:0]                     s_axi_bresp,
    output reg                           s_axi_bvalid,
    input  wire                          s_axi_bready,

    input  wire [31:0]                   s_axi_araddr,
    input  wire                          s_axi_arvalid,
    output reg                           s_axi_arready,

    output reg [31:0]                    s_axi_rdata,
    output reg                           s_axi_rvalid,
    input  wire                          s_axi_rready,
    output reg [1:0]                     s_axi_rresp
);
    localparam [31:0] MAGIC = 32'h59444247; // YDBG
    localparam [31:0] VERSION = 32'h0000_0001;
    localparam [7:0] SCOPE_DEPTH_U8 = SCOPE_DEPTH[7:0];

    reg [31:0] write_addr_q = 32'd0;
    reg [31:0] status0_q = 32'd0;
    reg [31:0] status1_q = 32'd0;
    reg [31:0] status2_q = 32'd0;
    reg [31:0] status3_q = 32'd0;

    wire pcie_wb_cyc = write_addr_q[15:12] == 4'h4 && s_axi_wvalid && !s_axi_bvalid;
    wire pcie_wb_stb = pcie_wb_cyc;
    wire pcie_wb_we = pcie_wb_cyc;
    wire [3:0] pcie_wb_addr = write_addr_q[5:2];
    wire [31:0] pcie_wb_rdata;
    wire pcie_wb_stall;
    wire pcie_wb_ack;

    ypcb_debug_wb_scope #(
        .DATA_WIDTH(PCIE_SAMPLE_WIDTH),
        .DEPTH(SCOPE_DEPTH),
        .INDEX_WIDTH(SCOPE_INDEX_WIDTH)
    ) pcie_scope_inst (
        .i_clk(i_axi_clk),
        .i_rst_n(i_axi_rst_n),
        .i_sample_data(i_pcie_sample_data),
        .i_sample_valid(i_pcie_sample_valid),
        .i_trigger(i_pcie_trigger),
        .i_wb_cyc(pcie_wb_cyc),
        .i_wb_stb(pcie_wb_stb),
        .i_wb_we(pcie_wb_we),
        .i_wb_addr(pcie_wb_addr),
        .i_wb_data(s_axi_wdata),
        .i_wb_sel(s_axi_wstrb),
        .o_wb_stall(pcie_wb_stall),
        .o_wb_ack(pcie_wb_ack),
        .o_wb_data(pcie_wb_rdata)
    );

    always @(posedge i_axi_clk) begin
        if(!i_axi_rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bresp <= 2'b00;
            s_axi_bvalid <= 1'b0;
            s_axi_arready <= 1'b0;
            s_axi_rdata <= 32'd0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            write_addr_q <= 32'd0;
            status0_q <= 32'd0;
            status1_q <= 32'd0;
            status2_q <= 32'd0;
            status3_q <= 32'd0;
            o_debug_rearm <= 1'b0;
            o_debug_freeze <= 1'b0;
        end else begin
            o_debug_rearm <= 1'b0;
            o_debug_freeze <= 1'b0;
            status0_q <= i_status_snapshot[31:0];
            status1_q <= i_status_snapshot[63:32];
            status2_q <= i_status_snapshot[95:64];
            status3_q <= i_status_snapshot[127:96];

            s_axi_awready <= s_axi_awvalid && !s_axi_awready && !s_axi_bvalid;
            s_axi_wready <= s_axi_wvalid && !s_axi_wready && !s_axi_bvalid;
            s_axi_arready <= s_axi_arvalid && !s_axi_arready && !s_axi_rvalid;

            if(s_axi_awvalid && s_axi_awready) begin
                write_addr_q <= s_axi_awaddr;
            end

            if(s_axi_wvalid && s_axi_wready) begin
                if(write_addr_q[15:0] == 16'h000c) begin
                    o_debug_rearm <= s_axi_wdata[0];
                    o_debug_freeze <= s_axi_wdata[1];
                end
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;
            end else if(s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            if(s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;
                case(s_axi_araddr[15:0])
                    16'h0000: s_axi_rdata <= MAGIC;
                    16'h0004: s_axi_rdata <= VERSION;
                    16'h0008: s_axi_rdata <= {16'd0, SCOPE_DEPTH_U8, 8'd1};
                    16'h0010: s_axi_rdata <= status0_q;
                    16'h0014: s_axi_rdata <= status1_q;
                    16'h0018: s_axi_rdata <= status2_q;
                    16'h001c: s_axi_rdata <= status3_q;
                    default: begin
                        if(s_axi_araddr[15:12] == 4'h4) begin
                            s_axi_rdata <= pcie_wb_rdata;
                        end else begin
                            s_axi_rdata <= 32'd0;
                        end
                    end
                endcase
            end else if(s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    wire unused = pcie_wb_stall ^ pcie_wb_ack;
endmodule

`default_nettype wire

`default_nettype none
`timescale 1ps / 1ps

module ypcb_00338_1p1_ddr3 (
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
    output wire [0:0]  ddr3_odt,

    output wire [2:0]  led
);
    localparam integer BYTE_LANES = 2;
    localparam integer WB_ADDR_BITS = 15 + 10 + 3 - 3;
    localparam integer WB_DATA_BITS = 8 * BYTE_LANES * 8;
    localparam integer WB_SEL_BITS = WB_DATA_BITS / 8;

    wire controller_clk;
    wire ddr3_clk;
    wire ref_clk;
    wire ddr3_clk_90;
    wire clk_locked;
    wire calib_complete;
    wire [31:0] debug1;
    wire [63:0] debug8;
    wire [63:0] bist_counts;
`ifdef UBERDDR3_DEBUG_JTAG
    wire [2047:0] jtag_debug_payload_live;
    reg [2047:0] jtag_debug_payload_snapshot = 2048'd0;
    wire jtag_debug_selected;
    wire jtag_debug_capture_toggle_tck;
    reg jtag_debug_capture_toggle_meta = 1'b0;
    reg jtag_debug_capture_toggle_sync = 1'b0;
    reg jtag_debug_capture_toggle_last = 1'b0;
    wire [347:0] calib_debug_payload;
    wire [15:0] init_reset_debug_payload;
    wire [127:0] init_seq_debug_payload;
    wire [609:0] bist_debug_payload;
    wire [781:0] panopticon_debug_payload;
    reg [63:0] canonical_debug_status_payload = 64'd0;
    wire [5:0] trace_debug_addr_tck = 6'd0;
    reg [5:0] trace_debug_addr_meta = 6'd0;
    reg [5:0] trace_debug_addr_sync = 6'd0;
    wire [63:0] trace_debug_word;
    wire trace_jtag_command_toggle_tck;
    wire trace_jtag_command_we_tck;
    wire [15:0] trace_jtag_command_addr_tck;
    wire [31:0] trace_jtag_command_data_tck;
    reg trace_jtag_command_toggle_meta = 1'b0;
    reg trace_jtag_command_toggle_sync = 1'b0;
    reg trace_jtag_command_toggle_last = 1'b0;
    reg trace_jtag_command_pending = 1'b0;
    reg trace_jtag_command_we_meta = 1'b0;
    reg trace_jtag_command_we_sync = 1'b0;
    reg [15:0] trace_jtag_command_addr_meta = 16'd0;
    reg [15:0] trace_jtag_command_addr_sync = 16'd0;
    reg [31:0] trace_jtag_command_data_meta = 32'd0;
    reg [31:0] trace_jtag_command_data_sync = 32'd0;
    reg trace_wb_cyc = 1'b0;
    reg trace_wb_stb = 1'b0;
    reg trace_wb_we = 1'b0;
    reg [15:0] trace_wb_addr = 16'd0;
    reg [31:0] trace_wb_data = 32'd0;
    wire trace_wb_stall;
    wire trace_wb_ack;
    wire [31:0] trace_wb_rdata;
    reg [31:0] trace_jtag_response_data = 32'd0;
    reg [31:0] trace_jtag_response_status = 32'd0;
    reg [7:0] trace_jtag_response_seq = 8'd0;
    reg trace_jtag_response_pending = 1'b0;
`endif
    wire uart_tx_unused;
    wire [BYTE_LANES-1:0] ddr3_dm_unused;

    wire bist_done = calib_complete && (debug1[4:0] == 5'd23);

    assign led[0] = bist_done;
    assign led[1] = !bist_done;
    assign led[2] = clk_locked;

    clk_wiz clk_wiz_inst (
        .clk_in1(clk50),
        .clk_out1(controller_clk),
        .clk_out2(ddr3_clk),
        .clk_out3(ref_clk),
        .clk_out4(ddr3_clk_90),
        .reset(!rst_n),
        .locked(clk_locked)
    );

    ddr3_top #(
        .CONTROLLER_CLK_PERIOD(12_000),
        .DDR3_CLK_PERIOD(3_000),
        .ROW_BITS(15),
        .COL_BITS(10),
        .BA_BITS(3),
        .BYTE_LANES(BYTE_LANES),
        .AUX_WIDTH(4),
        .WB2_ADDR_BITS(32),
        .WB2_DATA_BITS(32),
        .DUAL_RANK_DIMM(0),
        .MICRON_SIM(0),
        .ODELAY_SUPPORTED(0),
        .SECOND_WISHBONE(0),
        .DLL_OFF(0),
        .WB_ERROR(0),
        .BIST_MODE(2'd2),
        .BIST_TEST_DATAMASK(1'b0),
        .ECC_ENABLE(0),
        .SPEED_BIN(1),
        .SDRAM_CAPACITY(4)
    ) ddr3_top_inst (
        .i_controller_clk(controller_clk),
        .i_ddr3_clk(ddr3_clk),
        .i_ref_clk(ref_clk),
        .i_ddr3_clk_90(ddr3_clk_90),
        .i_rst_n(rst_n && clk_locked),

        .i_wb_cyc(1'b1),
        .i_wb_stb(1'b0),
        .i_wb_we(1'b0),
        .i_wb_addr({WB_ADDR_BITS{1'b0}}),
        .i_wb_data({WB_DATA_BITS{1'b0}}),
        .i_wb_sel({WB_SEL_BITS{1'b1}}),
        .i_aux(4'b0),
        .o_wb_stall(),
        .o_wb_ack(),
        .o_wb_err(),
        .o_wb_data(),
        .o_aux(),

        .i_wb2_cyc(1'b0),
        .i_wb2_stb(1'b0),
        .i_wb2_we(1'b0),
        .i_wb2_addr(32'b0),
        .i_wb2_data(32'b0),
        .i_wb2_sel(4'b0),
        .o_wb2_stall(),
        .o_wb2_ack(),
        .o_wb2_data(),

        .o_ddr3_clk_p(ddr3_ck_p),
        .o_ddr3_clk_n(ddr3_ck_n),
        .o_ddr3_reset_n(ddr3_reset_n),
        .o_ddr3_cke(ddr3_cke),
        .o_ddr3_cs_n(ddr3_cs_n),
        .o_ddr3_ras_n(ddr3_ras_n),
        .o_ddr3_cas_n(ddr3_cas_n),
        .o_ddr3_we_n(ddr3_we_n),
        .o_ddr3_addr(ddr3_addr),
        .o_ddr3_ba_addr(ddr3_ba),
        .io_ddr3_dq(ddr3_dq[(8*BYTE_LANES)-1:0]),
        .io_ddr3_dqs(ddr3_dqs_p[BYTE_LANES-1:0]),
        .io_ddr3_dqs_n(ddr3_dqs_n[BYTE_LANES-1:0]),
        .o_ddr3_dm(ddr3_dm_unused),
        .o_ddr3_odt(ddr3_odt),
        .o_calib_complete(calib_complete),
        .o_debug1(debug1),
        .o_debug8(debug8),
        .o_bist_counts(bist_counts),
`ifdef UBERDDR3_DEBUG_JTAG
        .o_calib_debug(calib_debug_payload),
        .o_init_reset_debug(init_reset_debug_payload),
        .o_init_seq_debug(init_seq_debug_payload),
        .o_bist_debug(bist_debug_payload),
        .o_panopticon_debug(panopticon_debug_payload),
        .i_trace_debug_addr(trace_debug_addr_sync),
        .o_trace_debug_word(trace_debug_word),
        .i_trace_wb_cyc(trace_wb_cyc),
        .i_trace_wb_stb(trace_wb_stb),
        .i_trace_wb_we(trace_wb_we),
        .i_trace_wb_addr(trace_wb_addr),
        .i_trace_wb_data(trace_wb_data),
        .o_trace_wb_stall(trace_wb_stall),
        .o_trace_wb_ack(trace_wb_ack),
        .o_trace_wb_data(trace_wb_rdata),
`else
        .o_calib_debug(),
        .o_init_reset_debug(),
        .o_init_seq_debug(),
        .o_bist_debug(),
        .o_panopticon_debug(),
        .i_trace_debug_addr(6'd0),
        .o_trace_debug_word(),
        .i_trace_wb_cyc(1'b0),
        .i_trace_wb_stb(1'b0),
        .i_trace_wb_we(1'b0),
        .i_trace_wb_addr(16'd0),
        .i_trace_wb_data(32'd0),
        .o_trace_wb_stall(),
        .o_trace_wb_ack(),
        .o_trace_wb_data(),
`endif
        .i_user_self_refresh(1'b0),
        .uart_tx(uart_tx_unused)
    );

`ifdef UBERDDR3_DEBUG_JTAG
    localparam integer JTAG_DEBUG_WIDTH = 2048;
    always @(posedge controller_clk) begin
        canonical_debug_status_payload <= {
            init_reset_debug_payload[15:12], // sticky init diagnostics
            16'hCACE,
            8'h01,
            calib_debug_payload[28:10],   // delay_counter
            init_reset_debug_payload[10], // pause_counter
            init_reset_debug_payload[3],  // sync_rst_controller
            init_reset_debug_payload[9],  // reset_done
            init_reset_debug_payload[2],  // o_phy_reset
            init_reset_debug_payload[1],  // i_phy_idelayctrl_rdy
            init_reset_debug_payload[0],  // i_rst_n
            calib_debug_payload[29],      // delay_counter_is_zero
            calib_debug_payload[9:5],     // instruction_address
            debug1[4:0]
        };
    end
    assign jtag_debug_payload_live = {
        panopticon_debug_payload,
        bist_debug_payload,
        init_seq_debug_payload,
        init_reset_debug_payload,
        bist_counts,
        canonical_debug_status_payload,
        calib_debug_payload[283:0],
`ifdef UBERDDR3_PANOPTICON
        8'h04,
`else
        8'h02,
`endif
        32'h33445244,
        debug1,
        24'd0,
        calib_complete,
        bist_done,
        clk_locked,
        rst_n
    };

    always @(posedge controller_clk) begin
        jtag_debug_capture_toggle_meta <= jtag_debug_capture_toggle_tck;
        jtag_debug_capture_toggle_sync <= jtag_debug_capture_toggle_meta;
        jtag_debug_capture_toggle_last <= jtag_debug_capture_toggle_sync;
        if (jtag_debug_capture_toggle_sync != jtag_debug_capture_toggle_last) begin
            jtag_debug_payload_snapshot <= jtag_debug_payload_live;
        end
    end

    jtag_debug_bscan #(
        .WIDTH(JTAG_DEBUG_WIDTH),
        .JTAG_CHAIN(1)
    ) jtag_debug_bscan_inst (
        .debug_data(jtag_debug_payload_snapshot),
        .selected(jtag_debug_selected),
        .capture_toggle(jtag_debug_capture_toggle_tck)
    );

`ifdef UBERDDR3_TRACE_SCOPE
    wire jtag_trace_selected;
    always @(posedge controller_clk) begin
        trace_debug_addr_meta <= trace_debug_addr_tck;
        trace_debug_addr_sync <= trace_debug_addr_meta;
        trace_jtag_command_toggle_meta <= trace_jtag_command_toggle_tck;
        trace_jtag_command_toggle_sync <= trace_jtag_command_toggle_meta;
        trace_jtag_command_toggle_last <= trace_jtag_command_toggle_sync;
        trace_jtag_command_we_meta <= trace_jtag_command_we_tck;
        trace_jtag_command_we_sync <= trace_jtag_command_we_meta;
        trace_jtag_command_addr_meta <= trace_jtag_command_addr_tck;
        trace_jtag_command_addr_sync <= trace_jtag_command_addr_meta;
        trace_jtag_command_data_meta <= trace_jtag_command_data_tck;
        trace_jtag_command_data_sync <= trace_jtag_command_data_meta;

        if (trace_jtag_response_pending) begin
            trace_jtag_response_pending <= 1'b0;
            trace_jtag_response_data <= trace_wb_rdata;
            trace_jtag_response_seq <= trace_jtag_response_seq + 8'd1;
            trace_jtag_response_status <= {7'h53, trace_jtag_response_seq + 8'd1, trace_wb_we, trace_wb_addr};
        end
        else if (trace_wb_ack) begin
            trace_wb_cyc <= 1'b0;
            trace_wb_stb <= 1'b0;
            trace_jtag_response_pending <= 1'b1;
        end
        else if (!trace_wb_cyc && trace_jtag_command_pending) begin
            trace_wb_cyc <= 1'b1;
            trace_wb_stb <= 1'b1;
            trace_wb_we <= trace_jtag_command_we_sync;
            trace_wb_addr <= trace_jtag_command_addr_sync;
            trace_wb_data <= trace_jtag_command_data_sync;
            trace_jtag_command_pending <= 1'b0;
        end
        else if (!trace_wb_cyc && (trace_jtag_command_toggle_sync != trace_jtag_command_toggle_last)) begin
            trace_jtag_command_pending <= 1'b1;
        end
    end

    jtag_trace_bscan #(
        .ADDR_WIDTH(16),
        .JTAG_CHAIN(2)
    ) jtag_trace_bscan_inst (
        .response_data(trace_jtag_response_data),
        .response_status(trace_jtag_response_status),
        .command_toggle(trace_jtag_command_toggle_tck),
        .command_we(trace_jtag_command_we_tck),
        .command_addr(trace_jtag_command_addr_tck),
        .command_data(trace_jtag_command_data_tck),
        .selected(jtag_trace_selected)
    );
    wire unused_jtag_trace = jtag_trace_selected;
`endif


    wire unused_jtag_debug_selected = jtag_debug_selected;
`else
    wire unused_debug = ^debug8 ^ ^bist_counts;
`endif
endmodule

`default_nettype wire

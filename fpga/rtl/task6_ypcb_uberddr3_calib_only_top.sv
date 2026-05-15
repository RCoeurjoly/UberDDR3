`default_nettype none

module task6_ypcb_uberddr3_calib_only_top #(
  parameter int JTAG_DEBUG_WIDTH = 512,
  parameter int JTAG_CHAIN = 1,
  parameter int JTAG_COMMAND_CHAIN = 2,
  parameter bit COMMAND_WB_ENABLE = 1'b0,
  parameter bit COMMAND_JTAG_ENABLE = 1'b0,
  parameter bit DEBUG_LOADER_PAYLOAD_ENABLE = 1'b0
) (
  input  wire        clk50,
  input  wire        SYS_RSTN,
  output wire [14:0] ddram_a,
  output wire  [2:0] ddram_ba,
  output wire        ddram_cas_n,
  output wire        ddram_cke,
  output wire        ddram_clk_n,
  output wire        ddram_clk_p,
  output wire        ddram_cs_n,
  inout  wire [63:0] ddram_dq,
  inout  wire  [7:0] ddram_dqs_n,
  inout  wire  [7:0] ddram_dqs_p,
  output wire        ddram_odt,
  output wire        ddram_ras_n,
  output wire        ddram_reset_n,
  output wire        ddram_we_n
);
  localparam logic [31:0] JTAG_DEBUG_MAGIC = 32'h54364a44;
  localparam bit COMMAND_PORT_ENABLE =
    COMMAND_WB_ENABLE || COMMAND_JTAG_ENABLE || DEBUG_LOADER_PAYLOAD_ENABLE;
  localparam logic [7:0] JTAG_DEBUG_VERSION =
    COMMAND_PORT_ENABLE ? 8'd89 : 8'd88;
  localparam int JTAG_COMMAND_WIDTH = 192;
  localparam int ROW_BITS = 15;
  localparam int COL_BITS = 10;
  localparam int BA_BITS = 3;
  localparam int BYTE_LANES = 8;
  localparam int WB_ADDR_BITS = ROW_BITS + COL_BITS + BA_BITS - 3;
  localparam int WB_DATA_BITS = 8 * BYTE_LANES * 8;
  localparam int WB_SEL_BITS = WB_DATA_BITS / 8;

  wire controller_clk;
  wire ddr3_clk;
  wire ddr3_clk_90;
  wire ref_clk;
  wire clk400_raw;
  wire clk400_90_raw;
  wire clk100_raw;
  wire clk200_raw;
  wire pll_clkfb;
  wire mmcm_locked;
  wire rst_n;
  logic [31:0] clk50_count_q;

  always_ff @(posedge clk50) begin
    clk50_count_q <= clk50_count_q + 32'd1;
  end

  PLLE2_BASE #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKFBOUT_MULT(16),
    .CLKFBOUT_PHASE(0.000),
    .CLKIN1_PERIOD(20.000),
    .CLKOUT0_DIVIDE(2),
    .CLKOUT0_DUTY_CYCLE(0.500),
    .CLKOUT0_PHASE(0.000),
    .CLKOUT1_DIVIDE(2),
    .CLKOUT1_DUTY_CYCLE(0.500),
    .CLKOUT1_PHASE(90.000),
    .CLKOUT2_DIVIDE(8),
    .CLKOUT2_DUTY_CYCLE(0.500),
    .CLKOUT2_PHASE(0.000),
    .CLKOUT3_DIVIDE(4),
    .CLKOUT3_DUTY_CYCLE(0.500),
    .CLKOUT3_PHASE(0.000),
    .DIVCLK_DIVIDE(1),
    .REF_JITTER1(0.010),
    .STARTUP_WAIT("FALSE")
  ) clock_pll (
    .CLKFBOUT(pll_clkfb),
    .CLKOUT0(clk400_raw),
    .CLKOUT1(clk400_90_raw),
    .CLKOUT2(clk100_raw),
    .CLKOUT3(clk200_raw),
    .CLKOUT4(),
    .CLKOUT5(),
    .LOCKED(mmcm_locked),
    .CLKFBIN(pll_clkfb),
    .CLKIN1(clk50),
    .PWRDWN(1'b0),
    .RST(1'b0)
  );

  BUFG clk100_bufg (
    .I(clk400_raw),
    .O(ddr3_clk)
  );

  BUFG clk100_90_bufg (
    .I(clk400_90_raw),
    .O(ddr3_clk_90)
  );

  BUFG clk25_bufg (
    .I(clk100_raw),
    .O(controller_clk)
  );

  BUFG clk200_bufg (
    .I(clk200_raw),
    .O(ref_clk)
  );

  assign rst_n = mmcm_locked;

  wire wb_stall;
  wire wb_ack;
  wire wb_err;
  wire [WB_DATA_BITS - 1:0] wb_data;
  wire [3:0] wb_aux;
  wire command_wb_cyc;
  wire command_wb_stb;
  wire command_wb_we;
  wire [WB_ADDR_BITS - 1:0] command_wb_addr;
  wire [WB_DATA_BITS - 1:0] command_wb_data;
  wire [WB_SEL_BITS - 1:0] command_wb_sel;
  wire [3:0] command_wb_aux;
  wire [31:0] command_debug_word;
  wire [31:0] command_status_word;
  wire [127:0] command_read_chunk;
  wire [31:0] command_wait_cycles;
  wire [14:0] command_addr_low;
  wire [15:0] command_count;
  wire [0:0] ddr3_clk_p_w;
  wire [0:0] ddr3_clk_n_w;
  wire [0:0] ddr3_cke_w;
  wire [0:0] ddr3_cs_n_w;
  wire [0:0] ddr3_odt_w;
  wire [BYTE_LANES - 1:0] ddr3_dm_w;
  wire calib_complete;
  wire [31:0] debug1;
  wire uart_tx;

  assign ddram_clk_p = ddr3_clk_p_w[0];
  assign ddram_clk_n = ddr3_clk_n_w[0];
  assign ddram_cke = ddr3_cke_w[0];
  assign ddram_cs_n = ddr3_cs_n_w[0];
  assign ddram_odt = ddr3_odt_w[0];

  logic [31:0] cycle_count_q;
  logic [31:0] calib_seen_cycle_q;
  logic [31:0] wb_ack_count_q;
  logic [31:0] wb_err_count_q;
  logic [31:0] wb_stall_count_q;
  logic calib_seen_q;
  logic [JTAG_DEBUG_WIDTH - 1:0] jtag_debug_payload_q;

  always_ff @(posedge controller_clk or negedge rst_n) begin
    if (!rst_n) begin
      cycle_count_q <= 32'd0;
      calib_seen_cycle_q <= 32'd0;
      wb_ack_count_q <= 32'd0;
      wb_err_count_q <= 32'd0;
      wb_stall_count_q <= 32'd0;
      calib_seen_q <= 1'b0;
      jtag_debug_payload_q <= '0;
    end else begin
      cycle_count_q <= cycle_count_q + 32'd1;
      if (calib_complete && !calib_seen_q) begin
        calib_seen_q <= 1'b1;
        calib_seen_cycle_q <= cycle_count_q;
      end
      if (wb_ack)
        wb_ack_count_q <= wb_ack_count_q + 32'd1;
      if (wb_err)
        wb_err_count_q <= wb_err_count_q + 32'd1;
      if (wb_stall)
        wb_stall_count_q <= wb_stall_count_q + 32'd1;

      jtag_debug_payload_q <= '0;
      jtag_debug_payload_q[0 +: 32] <= JTAG_DEBUG_MAGIC;
      jtag_debug_payload_q[32 +: 8] <= JTAG_DEBUG_VERSION;
      jtag_debug_payload_q[40 +: 8] <= {
        1'b0,
        uart_tx,
        1'b0,
        1'b0,
        wb_err,
        wb_ack,
        calib_seen_q,
        calib_complete
      };
      jtag_debug_payload_q[47] <= mmcm_locked;
      jtag_debug_payload_q[48 +: 32] <= cycle_count_q;
      jtag_debug_payload_q[80 +: 32] <= calib_seen_cycle_q;
      jtag_debug_payload_q[112 +: 32] <= debug1;
      jtag_debug_payload_q[144 +: 32] <= wb_ack_count_q;
      jtag_debug_payload_q[176 +: 32] <= wb_err_count_q;
      jtag_debug_payload_q[208 +: 32] <= wb_stall_count_q;
      jtag_debug_payload_q[240 +: 32] <= wb_data[31:0];
      if (DEBUG_LOADER_PAYLOAD_ENABLE) begin
        jtag_debug_payload_q[272 +: 32] <= command_debug_word;
        jtag_debug_payload_q[304 +: 32] <= command_status_word;
        jtag_debug_payload_q[336 +: 128] <= command_read_chunk;
        jtag_debug_payload_q[464 +: 32] <= command_wait_cycles;
        jtag_debug_payload_q[496 +: 15] <= command_addr_low;
      end
    end
  end

  ddr3_top #(
    .CONTROLLER_CLK_PERIOD(10_000),
    .DDR3_CLK_PERIOD(2_500),
    .ROW_BITS(ROW_BITS),
    .COL_BITS(COL_BITS),
    .BA_BITS(BA_BITS),
    .BYTE_LANES(BYTE_LANES),
    .AUX_WIDTH(4),
    .WB2_ADDR_BITS(7),
    .WB2_DATA_BITS(32),
    .DUAL_RANK_DIMM(0),
    .SPEED_BIN(0),
    .SDRAM_CAPACITY(5),
    .TRCD(13_750),
    .TRP(13_750),
    .TRAS(35_000),
    .ODELAY_SUPPORTED(0),
    .SECOND_WISHBONE(0),
    .DLL_OFF(0),
    .WB_ERROR(0),
    .BIST_MODE(0),
    .BIST_ADDR_BITS(0),
    .ECC_ENABLE(0)
  ) uberddr3 (
    .i_controller_clk(controller_clk),
    .i_ddr3_clk(ddr3_clk),
    .i_ref_clk(ref_clk),
    .i_ddr3_clk_90(ddr3_clk_90),
    .i_rst_n(rst_n),
    .i_wb_cyc(COMMAND_WB_ENABLE ? command_wb_cyc : 1'b0),
    .i_wb_stb(COMMAND_WB_ENABLE ? command_wb_stb : 1'b0),
    .i_wb_we(COMMAND_WB_ENABLE ? command_wb_we : 1'b0),
    .i_wb_addr(COMMAND_WB_ENABLE ? command_wb_addr : {WB_ADDR_BITS{1'b0}}),
    .i_wb_data(COMMAND_WB_ENABLE ? command_wb_data : {WB_DATA_BITS{1'b0}}),
    .i_wb_sel(COMMAND_WB_ENABLE ? command_wb_sel : {WB_SEL_BITS{1'b0}}),
    .i_aux(COMMAND_WB_ENABLE ? command_wb_aux : 4'd0),
    .o_wb_stall(wb_stall),
    .o_wb_ack(wb_ack),
    .o_wb_err(wb_err),
    .o_wb_data(wb_data),
    .o_aux(wb_aux),
    .i_wb2_cyc(1'b0),
    .i_wb2_stb(1'b0),
    .i_wb2_we(1'b0),
    .i_wb2_addr(7'd0),
    .i_wb2_data(32'd0),
    .i_wb2_sel(4'd0),
    .o_wb2_stall(),
    .o_wb2_ack(),
    .o_wb2_data(),
    .o_ddr3_clk_p(ddr3_clk_p_w),
    .o_ddr3_clk_n(ddr3_clk_n_w),
    .o_ddr3_reset_n(ddram_reset_n),
    .o_ddr3_cke(ddr3_cke_w),
    .o_ddr3_cs_n(ddr3_cs_n_w),
    .o_ddr3_ras_n(ddram_ras_n),
    .o_ddr3_cas_n(ddram_cas_n),
    .o_ddr3_we_n(ddram_we_n),
    .o_ddr3_addr(ddram_a),
    .o_ddr3_ba_addr(ddram_ba),
    .io_ddr3_dq(ddram_dq),
    .io_ddr3_dqs(ddram_dqs_p),
    .io_ddr3_dqs_n(ddram_dqs_n),
    .o_ddr3_dm(ddr3_dm_w),
    .o_ddr3_odt(ddr3_odt_w),
    .o_calib_complete(calib_complete),
    .o_debug1(debug1),
    .i_user_self_refresh(1'b0),
    .uart_tx(uart_tx)
  );

  generate
    if (COMMAND_PORT_ENABLE) begin : gen_command_port
      task6_uberddr3_rowstream_command_port #(
        .JTAG_COMMAND_WIDTH(JTAG_COMMAND_WIDTH),
        .JTAG_COMMAND_CHAIN(JTAG_COMMAND_CHAIN),
        .WB_ADDR_BITS(WB_ADDR_BITS),
        .WB_DATA_BITS(WB_DATA_BITS),
        .WB_SEL_BITS(WB_SEL_BITS)
      ) command_port (
        .controller_clk_i(controller_clk),
        .rst_ni(rst_n),
        .calib_seen_i(calib_seen_q),
        .wb_stall_i(wb_stall),
        .wb_ack_i(wb_ack),
        .wb_err_i(wb_err),
        .wb_data_i(wb_data),
        .wb_cyc_o(command_wb_cyc),
        .wb_stb_o(command_wb_stb),
        .wb_we_o(command_wb_we),
        .wb_addr_o(command_wb_addr),
        .wb_data_o(command_wb_data),
        .wb_sel_o(command_wb_sel),
        .wb_aux_o(command_wb_aux),
        .command_word_o(command_debug_word),
        .status_word_o(command_status_word),
        .read_chunk_o(command_read_chunk),
        .wait_cycles_o(command_wait_cycles),
        .command_addr_low_o(command_addr_low),
        .command_count_o(command_count)
      );
    end else begin : gen_no_command_port
      assign command_wb_cyc = 1'b0;
      assign command_wb_stb = 1'b0;
      assign command_wb_we = 1'b0;
      assign command_wb_addr = '0;
      assign command_wb_data = '0;
      assign command_wb_sel = '0;
      assign command_wb_aux = 4'd0;
      assign command_debug_word = 32'd0;
      assign command_status_word = 32'd0;
      assign command_read_chunk = 128'd0;
      assign command_wait_cycles = 32'd0;
      assign command_addr_low = 15'd0;
      assign command_count = 16'd0;
    end
  endgenerate

  task6_uberddr3_calib_jtag_debug_shift #(
    .WIDTH(JTAG_DEBUG_WIDTH),
    .JTAG_CHAIN(JTAG_CHAIN)
  ) jtag_debug_shift (
    .payload_i(jtag_debug_payload_q)
  );
endmodule

module task6_uberddr3_calib_jtag_debug_shift #(
  parameter int WIDTH = 512,
  parameter int JTAG_CHAIN = 1
) (
  input logic [WIDTH - 1:0] payload_i
);
  logic capture;
  logic drck;
  logic reset;
  logic runtest;
  logic sel;
  logic shift;
  logic tck;
  logic tdi;
  logic tms;
  logic update;
  logic tdo;
  logic [WIDTH - 1:0] shift_q;

  assign tdo = shift_q[0];

  always_ff @(posedge drck or posedge reset) begin
    if (reset)
      shift_q <= '0;
    else if (sel && capture)
      shift_q <= payload_i;
    else if (sel && shift)
      shift_q <= {tdi, shift_q[WIDTH - 1:1]};
  end

  BSCANE2 #(
    .DISABLE_JTAG("FALSE"),
    .JTAG_CHAIN(JTAG_CHAIN)
  ) bscan (
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
endmodule

`default_nettype wire

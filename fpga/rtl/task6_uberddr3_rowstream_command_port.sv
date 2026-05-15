`default_nettype none

module task6_uberddr3_rowstream_command_port #(
  parameter int JTAG_COMMAND_WIDTH = 192,
  parameter int JTAG_COMMAND_CHAIN = 2,
  parameter int WB_ADDR_BITS = 25,
  parameter int WB_DATA_BITS = 512,
  parameter int WB_SEL_BITS = 64
) (
  input  logic                      controller_clk_i,
  input  logic                      rst_ni,
  input  logic                      calib_seen_i,
  input  logic                      wb_stall_i,
  input  logic                      wb_ack_i,
  input  logic                      wb_err_i,
  input  logic [WB_DATA_BITS - 1:0] wb_data_i,
  output logic                      wb_cyc_o,
  output logic                      wb_stb_o,
  output logic                      wb_we_o,
  output logic [WB_ADDR_BITS - 1:0] wb_addr_o,
  output logic [WB_DATA_BITS - 1:0] wb_data_o,
  output logic [WB_SEL_BITS - 1:0]  wb_sel_o,
  output logic [3:0]                wb_aux_o,
  output logic [31:0]               command_word_o,
  output logic [31:0]               status_word_o,
  output logic [127:0]              read_chunk_o,
  output logic [31:0]               wait_cycles_o,
  output logic [14:0]               command_addr_low_o,
  output logic [15:0]               command_count_o
);
  localparam logic [31:0] LOADER_COMMAND_MAGIC = 32'h33445244;
  localparam logic [7:0] LOADER_OP_WRITE_CHUNK = 8'h01;
  localparam logic [7:0] LOADER_OP_READ_BEAT = 8'h02;
  localparam logic [7:0] LOADER_OP_WRITE_LOWBYTE = 8'h03;
  localparam logic [7:0] LOADER_OP_READ_LOWBYTE = 8'h04;

  typedef enum logic [3:0] {
    LOADER_RESET = 4'd0,
    LOADER_IDLE = 4'd1,
    LOADER_ISSUE = 4'd2,
    LOADER_WAIT_ACK = 4'd3,
    LOADER_ERROR = 4'd4
  } loader_state_t;

  logic [JTAG_COMMAND_WIDTH - 1:0] jtag_payload;
  logic jtag_event;
  wire [31:0] jtag_magic = jtag_payload[0 +: 32];
  wire [7:0] jtag_opcode = jtag_payload[32 +: 8];
  wire [1:0] jtag_chunk = jtag_payload[40 +: 2];
  wire [31:0] jtag_addr = jtag_payload[48 +: 32];
  wire [127:0] jtag_data = jtag_payload[64 +: 128];
  wire jtag_magic_ok = jtag_magic == LOADER_COMMAND_MAGIC;

  loader_state_t state_q;
  logic done_q;
  logic error_q;
  logic stall_seen_q;
  logic write_ack_seen_q;
  logic read_ack_seen_q;
  logic command_pending_q;
  logic last_accepted_q;
  logic last_magic_ok_q;
  logic [7:0] last_opcode_q;
  logic [1:0] last_chunk_q;
  logic [1:0] read_chunk_q;
  logic [7:0] cmd_opcode_q;
  logic [1:0] cmd_chunk_q;
  logic [31:0] cmd_addr_q;
  logic [127:0] cmd_data_q;
  logic cmd_magic_ok_q;
  logic [WB_DATA_BITS - 1:0] stage_data_q;
  logic [WB_DATA_BITS - 1:0] stage_data_next;

  always_comb begin
    stage_data_next = stage_data_q;
    stage_data_next[cmd_chunk_q * 128 +: 128] = cmd_data_q;
  end

  always_ff @(posedge controller_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= LOADER_RESET;
      wb_cyc_o <= 1'b0;
      wb_stb_o <= 1'b0;
      wb_we_o <= 1'b0;
      wb_addr_o <= '0;
      wb_data_o <= '0;
      wb_sel_o <= '0;
      wb_aux_o <= 4'd1;
      done_q <= 1'b0;
      error_q <= 1'b0;
      stall_seen_q <= 1'b0;
      write_ack_seen_q <= 1'b0;
      read_ack_seen_q <= 1'b0;
      command_pending_q <= 1'b0;
      last_accepted_q <= 1'b0;
      last_magic_ok_q <= 1'b0;
      last_opcode_q <= '0;
      last_chunk_q <= '0;
      read_chunk_q <= '0;
      cmd_opcode_q <= '0;
      cmd_chunk_q <= '0;
      cmd_addr_q <= '0;
      cmd_data_q <= '0;
      cmd_magic_ok_q <= 1'b0;
      stage_data_q <= '0;
      read_chunk_o <= '0;
      wait_cycles_o <= '0;
      command_addr_low_o <= '0;
    end else begin
      done_q <= 1'b0;
      last_accepted_q <= 1'b0;

      if (jtag_event && (state_q == LOADER_IDLE || state_q == LOADER_ERROR)) begin
        command_pending_q <= 1'b1;
        cmd_opcode_q <= jtag_opcode;
        cmd_chunk_q <= jtag_chunk;
        cmd_addr_q <= jtag_addr;
        cmd_data_q <= jtag_data;
        cmd_magic_ok_q <= jtag_magic_ok;
        last_opcode_q <= jtag_opcode;
        last_chunk_q <= jtag_chunk;
        command_addr_low_o <= jtag_addr[14:0];
        last_magic_ok_q <= jtag_magic_ok;
      end else if (command_pending_q && state_q == LOADER_ERROR) begin
        command_pending_q <= 1'b0;
        if (cmd_magic_ok_q) begin
          error_q <= 1'b0;
          stall_seen_q <= 1'b0;
          wb_cyc_o <= 1'b0;
          wb_stb_o <= 1'b0;
          wb_we_o <= 1'b0;
          state_q <= calib_seen_i ? LOADER_IDLE : LOADER_RESET;
        end
      end else if (command_pending_q && calib_seen_i && state_q == LOADER_IDLE) begin
        command_pending_q <= 1'b0;
        if (cmd_magic_ok_q) begin
          last_accepted_q <= 1'b1;
          error_q <= 1'b0;
          stall_seen_q <= 1'b0;
          wait_cycles_o <= 32'd0;
          if (cmd_opcode_q == LOADER_OP_WRITE_CHUNK) begin
            stage_data_q <= stage_data_next;
            if (cmd_chunk_q == 2'd3) begin
              wb_addr_o <= cmd_addr_q[WB_ADDR_BITS - 1:0];
              wb_data_o <= stage_data_next;
              wb_sel_o <= {WB_SEL_BITS{1'b1}};
              wb_we_o <= 1'b1;
              wb_cyc_o <= 1'b1;
              wb_stb_o <= 1'b1;
              state_q <= LOADER_ISSUE;
            end else begin
              done_q <= 1'b1;
            end
          end else if (cmd_opcode_q == LOADER_OP_READ_BEAT) begin
            wb_addr_o <= cmd_addr_q[WB_ADDR_BITS - 1:0];
            read_chunk_q <= cmd_chunk_q;
            wb_sel_o <= {WB_SEL_BITS{1'b1}};
            wb_we_o <= 1'b0;
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            state_q <= LOADER_ISSUE;
          end else if (cmd_opcode_q == LOADER_OP_WRITE_LOWBYTE) begin
            wb_addr_o <= cmd_addr_q[WB_ADDR_BITS - 1:0];
            wb_data_o <= {{(WB_DATA_BITS - 8){1'b0}}, cmd_data_q[7:0]};
            wb_sel_o <= {{(WB_SEL_BITS - 1){1'b0}}, 1'b1};
            wb_we_o <= 1'b1;
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            state_q <= LOADER_ISSUE;
          end else if (cmd_opcode_q == LOADER_OP_READ_LOWBYTE) begin
            wb_addr_o <= cmd_addr_q[WB_ADDR_BITS - 1:0];
            read_chunk_q <= 2'd0;
            wb_sel_o <= {{(WB_SEL_BITS - 1){1'b0}}, 1'b1};
            wb_we_o <= 1'b0;
            wb_cyc_o <= 1'b1;
            wb_stb_o <= 1'b1;
            state_q <= LOADER_ISSUE;
          end else begin
            error_q <= 1'b1;
            state_q <= LOADER_ERROR;
          end
        end else begin
          error_q <= 1'b1;
          state_q <= LOADER_ERROR;
        end
      end else begin
        case (state_q)
        LOADER_RESET: begin
          wb_cyc_o <= 1'b0;
          wb_stb_o <= 1'b0;
          wb_we_o <= 1'b0;
          wb_sel_o <= '0;
          if (calib_seen_i)
            state_q <= LOADER_IDLE;
        end
        LOADER_IDLE: begin
          wb_cyc_o <= 1'b0;
          wb_stb_o <= 1'b0;
          wb_we_o <= 1'b0;
          wb_sel_o <= '0;
        end
        LOADER_ISSUE: begin
          if (wb_stall_i) begin
            stall_seen_q <= 1'b1;
            wait_cycles_o <= wait_cycles_o + 32'd1;
          end else begin
            wb_stb_o <= 1'b0;
            state_q <= wb_ack_i ? LOADER_IDLE : LOADER_WAIT_ACK;
          end
          if (wb_err_i) begin
            error_q <= 1'b1;
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            state_q <= LOADER_ERROR;
          end
          if (wb_ack_i) begin
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            if (wb_we_o) begin
              write_ack_seen_q <= 1'b1;
            end else begin
              read_ack_seen_q <= 1'b1;
              read_chunk_o <= wb_data_i[read_chunk_q * 128 +: 128];
            end
            done_q <= 1'b1;
            state_q <= LOADER_IDLE;
          end
        end
        LOADER_WAIT_ACK: begin
          wait_cycles_o <= wait_cycles_o + 32'd1;
          if (wb_err_i) begin
            error_q <= 1'b1;
            wb_cyc_o <= 1'b0;
            wb_stb_o <= 1'b0;
            state_q <= LOADER_ERROR;
          end else if (wb_ack_i) begin
            wb_cyc_o <= 1'b0;
            if (wb_we_o) begin
              write_ack_seen_q <= 1'b1;
            end else begin
              read_ack_seen_q <= 1'b1;
              read_chunk_o <= wb_data_i[read_chunk_q * 128 +: 128];
            end
            done_q <= 1'b1;
            state_q <= LOADER_IDLE;
          end
        end
        LOADER_ERROR: begin
          wb_cyc_o <= 1'b0;
          wb_stb_o <= 1'b0;
          wb_we_o <= 1'b0;
          wb_sel_o <= '0;
        end
        default: state_q <= LOADER_ERROR;
        endcase
      end
    end
  end

  always_comb begin
    command_word_o = {
      command_count_o[7:0],
      last_opcode_q,
      6'd0,
      last_chunk_q,
      last_magic_ok_q,
      last_accepted_q
    };
    status_word_o = {
      16'd0,
      calib_seen_i,
      stall_seen_q,
      error_q,
      read_ack_seen_q,
      write_ack_seen_q,
      done_q,
      wb_cyc_o,
      wb_stb_o,
      state_q
    };
  end

  task6_uberddr3_loader_jtag_command_shift #(
    .WIDTH(JTAG_COMMAND_WIDTH),
    .JTAG_CHAIN(JTAG_COMMAND_CHAIN)
  ) jtag_command_shift (
    .controller_clk_i(controller_clk_i),
    .rst_ni(rst_ni),
    .payload_o(jtag_payload),
    .event_o(jtag_event),
    .command_count_o(command_count_o)
  );
endmodule

module task6_uberddr3_loader_jtag_command_shift #(
  parameter int WIDTH = 16,
  parameter int JTAG_CHAIN = 2
) (
  input  logic        controller_clk_i,
  input  logic        rst_ni,
  output logic [WIDTH - 1:0] payload_o,
  output logic        event_o,
  output logic [15:0] command_count_o
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
  logic [WIDTH - 1:0] payload_tck_q;
  logic [WIDTH - 1:0] payload_meta_q;
  logic [WIDTH - 1:0] payload_sync_q;
  logic toggle_tck_q;
  logic toggle_meta_q;
  logic toggle_sync_q;
  logic toggle_seen_q;

  assign tdo = shift_q[0];

  always_ff @(posedge drck or posedge reset) begin
    if (reset) begin
      shift_q <= '0;
    end else begin
      if (sel && capture)
        shift_q <= payload_tck_q;
      else if (sel && shift)
        shift_q <= {tdi, shift_q[WIDTH - 1:1]};
    end
  end

  always_ff @(posedge tck or posedge reset) begin
    if (reset) begin
      payload_tck_q <= '0;
      toggle_tck_q <= 1'b0;
    end else if (sel && update) begin
      payload_tck_q <= shift_q;
      toggle_tck_q <= ~toggle_tck_q;
    end
  end

  always_ff @(posedge controller_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      toggle_meta_q <= 1'b0;
      toggle_sync_q <= 1'b0;
      toggle_seen_q <= 1'b0;
      payload_meta_q <= '0;
      payload_sync_q <= '0;
      payload_o <= '0;
      event_o <= 1'b0;
      command_count_o <= 16'd0;
    end else begin
      payload_meta_q <= payload_tck_q;
      payload_sync_q <= payload_meta_q;
      toggle_meta_q <= toggle_tck_q;
      toggle_sync_q <= toggle_meta_q;
      event_o <= toggle_sync_q ^ toggle_seen_q;
      if (toggle_sync_q ^ toggle_seen_q) begin
        toggle_seen_q <= toggle_sync_q;
        payload_o <= payload_sync_q;
        command_count_o <= command_count_o + 16'd1;
      end
    end
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

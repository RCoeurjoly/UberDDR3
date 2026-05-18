`default_nettype none

module task6_ypcb_phaser_shell_bscan_port #(
  parameter int COMMAND_WIDTH = 256,
  parameter int STATUS_WIDTH = 384,
  parameter int JTAG_COMMAND_CHAIN = 2,
  parameter int JTAG_STATUS_CHAIN = 1
) (
  input  logic                 controller_clk_i,
  input  logic                 rst_ni,
  input  logic [7:0]           shell_state_i,
  input  logic [15:0]          status_flags_i,
  input  logic [15:0]          write_count_i,
  input  logic [15:0]          read_count_i,
  input  logic [31:0]          user0_i,
  input  logic [31:0]          user1_i,
  input  logic [31:0]          user2_i,
  input  logic [127:0]         read_data128_i,
  output logic                 command_event_o,
  output logic                 command_valid_o,
  output logic                 command_magic_ok_o,
  output logic [7:0]           command_opcode_o,
  output logic [7:0]           command_flags_o,
  output logic [7:0]           command_chunk_o,
  output logic [31:0]          command_addr_o,
  output logic [39:0]          command_aux_o,
  output logic [127:0]         command_data128_o,
  output logic [15:0]          command_count_o
);
  localparam logic [31:0] COMMAND_MAGIC = 32'h5048434e; // "PHCN"
  localparam logic [31:0] STATUS_MAGIC = 32'h50485354; // "PHST"
  localparam logic [7:0] STATUS_VERSION = 8'h01;

  logic [COMMAND_WIDTH - 1:0] jtag_payload;
  logic jtag_event;
  logic [31:0] last_addr_q;
  logic [7:0] last_opcode_q;
  logic [7:0] last_chunk_q;

  wire [31:0] command_magic = jtag_payload[0 +: 32];
  wire command_magic_ok = command_magic == COMMAND_MAGIC;

  wire [STATUS_WIDTH - 1:0] status_payload = {
    read_data128_i,
    user2_i,
    user1_i,
    user0_i,
    last_addr_q,
    status_flags_i,
    read_count_i,
    write_count_i,
    command_count_o,
    last_chunk_q,
    last_opcode_q,
    shell_state_i,
    STATUS_VERSION,
    STATUS_MAGIC
  };

  always_ff @(posedge controller_clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      command_event_o <= 1'b0;
      command_valid_o <= 1'b0;
      command_magic_ok_o <= 1'b0;
      command_opcode_o <= '0;
      command_flags_o <= '0;
      command_chunk_o <= '0;
      command_addr_o <= '0;
      command_aux_o <= '0;
      command_data128_o <= '0;
      last_addr_q <= '0;
      last_opcode_q <= '0;
      last_chunk_q <= '0;
    end else begin
      command_event_o <= jtag_event;
      command_valid_o <= 1'b0;
      if (jtag_event) begin
        command_magic_ok_o <= command_magic_ok;
        command_opcode_o <= jtag_payload[32 +: 8];
        command_flags_o <= jtag_payload[40 +: 8];
        command_chunk_o <= jtag_payload[48 +: 8];
        command_addr_o <= jtag_payload[56 +: 32];
        command_aux_o <= jtag_payload[88 +: 40];
        command_data128_o <= jtag_payload[128 +: 128];
        last_addr_q <= jtag_payload[56 +: 32];
        last_opcode_q <= jtag_payload[32 +: 8];
        last_chunk_q <= jtag_payload[48 +: 8];
        if (command_magic_ok)
          command_valid_o <= 1'b1;
      end
    end
  end

  task6_ypcb_phaser_jtag_command_shift #(
    .WIDTH(COMMAND_WIDTH),
    .JTAG_CHAIN(JTAG_COMMAND_CHAIN)
  ) jtag_command_shift (
    .controller_clk_i(controller_clk_i),
    .rst_ni(rst_ni),
    .payload_o(jtag_payload),
    .event_o(jtag_event),
    .command_count_o(command_count_o)
  );

  task6_ypcb_phaser_jtag_readback #(
    .WIDTH(STATUS_WIDTH),
    .JTAG_CHAIN(JTAG_STATUS_CHAIN)
  ) jtag_readback (
    .payload_i(status_payload)
  );
endmodule

module task6_ypcb_phaser_jtag_command_shift #(
  parameter int WIDTH = 16,
  parameter int JTAG_CHAIN = 2
) (
  input  logic             controller_clk_i,
  input  logic             rst_ni,
  output logic [WIDTH-1:0] payload_o,
  output logic             event_o,
  output logic [15:0]      command_count_o
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
    end else if (sel && capture) begin
      shift_q <= payload_tck_q;
    end else if (sel && shift) begin
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

module task6_ypcb_phaser_jtag_readback #(
  parameter int WIDTH = 128,
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
    if (reset) begin
      shift_q <= '0;
    end else if (sel && capture) begin
      shift_q <= payload_i;
    end else if (sel && shift) begin
      shift_q <= {tdi, shift_q[WIDTH - 1:1]};
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

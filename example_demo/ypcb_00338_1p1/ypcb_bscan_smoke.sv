`default_nettype none

module ypcb_bscan_readback #(
  parameter int WIDTH = 128,
  parameter int JTAG_CHAIN = 1
) (
  input  wire [WIDTH - 1:0] payload_i
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
  reg [WIDTH - 1:0] shift_q;

  assign tdo = shift_q[0];

  always @(posedge drck or posedge reset) begin
    if (reset)
      shift_q <= {WIDTH{1'b0}};
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

module ypcb_bscan_command #(
  parameter int WIDTH = 96,
  parameter int JTAG_CHAIN = 2
) (
  input  wire             clk_i,
  input  wire             rst_ni,
  output reg [WIDTH-1:0]  payload_o,
  output reg              event_o,
  output reg [15:0]       command_count_o
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
  reg [WIDTH - 1:0] shift_q;
  reg [WIDTH - 1:0] payload_tck_q;
  reg [WIDTH - 1:0] payload_meta_q;
  reg [WIDTH - 1:0] payload_sync_q;
  reg toggle_tck_q;
  reg toggle_meta_q;
  reg toggle_sync_q;
  reg toggle_seen_q;

  assign tdo = 1'b0;

  always @(posedge drck or posedge reset) begin
    if (reset)
      shift_q <= {WIDTH{1'b0}};
    else if (sel && capture)
      shift_q <= payload_tck_q;
    else if (sel && shift)
      shift_q <= {tdi, shift_q[WIDTH - 1:1]};
  end

  always @(posedge tck or posedge reset) begin
    if (reset) begin
      payload_tck_q <= {WIDTH{1'b0}};
      toggle_tck_q <= 1'b0;
    end else if (sel && update) begin
      payload_tck_q <= shift_q;
      toggle_tck_q <= ~toggle_tck_q;
    end
  end

  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      payload_o <= {WIDTH{1'b0}};
      payload_meta_q <= {WIDTH{1'b0}};
      payload_sync_q <= {WIDTH{1'b0}};
      toggle_meta_q <= 1'b0;
      toggle_sync_q <= 1'b0;
      toggle_seen_q <= 1'b0;
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

module ypcb_bscan_smoke (
  input  wire       clk50,
  input  wire       rst_n,
  output wire [2:0] led
);
  localparam [31:0] READ_MAGIC = 32'h42535244; // "BSRD"
  localparam [31:0] WRITE_MAGIC = 32'h4253434e; // "BSCN"
  localparam [7:0] OP_WRITE_SCRATCH = 8'h01;
  localparam [7:0] OP_CLEAR_SCRATCH = 8'h02;

  reg [31:0] counter_q;
  reg [31:0] scratch_q;
  reg [7:0] last_opcode_q;
  reg [7:0] status_q;
  wire [95:0] command_payload;
  wire command_event;
  wire [15:0] command_count;
  reg [95:0] command_payload_q;
  reg command_event_q;
  wire command_valid = command_payload_q[31:0] == WRITE_MAGIC;
  wire [7:0] command_opcode = command_payload_q[39:32];
  wire [31:0] command_data = command_payload_q[95:64];

  always @(posedge clk50 or negedge rst_n) begin
    if (!rst_n) begin
      counter_q <= 32'd0;
      scratch_q <= 32'h00000000;
      last_opcode_q <= 8'h00;
      status_q <= 8'h01;
      command_payload_q <= 96'd0;
      command_event_q <= 1'b0;
    end else begin
      counter_q <= counter_q + 32'd1;
      command_payload_q <= command_payload;
      command_event_q <= command_event;
      status_q <= {6'd0, command_valid, 1'b0};
      if (command_event_q) begin
        last_opcode_q <= command_opcode;
        if (command_valid && command_opcode == OP_WRITE_SCRATCH)
          scratch_q <= command_data;
        else if (command_valid && command_opcode == OP_CLEAR_SCRATCH)
          scratch_q <= 32'h00000000;
      end
    end
  end

  wire [127:0] read_payload = {
    status_q,
    last_opcode_q,
    command_count,
    counter_q,
    scratch_q,
    READ_MAGIC
  };

  assign led[0] = counter_q[24];
  assign led[1] = scratch_q[0];
  assign led[2] = command_count[0];

  ypcb_bscan_command #(
    .WIDTH(96),
    .JTAG_CHAIN(2)
  ) command_port (
    .clk_i(clk50),
    .rst_ni(rst_n),
    .payload_o(command_payload),
    .event_o(command_event),
    .command_count_o(command_count)
  );

  ypcb_bscan_readback #(
    .WIDTH(128),
    .JTAG_CHAIN(1)
  ) readback_port (
    .payload_i(read_payload)
  );
endmodule

`default_nettype wire

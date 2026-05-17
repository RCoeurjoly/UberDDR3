`default_nettype none

module ypcb_bscan_ddr_pins (
  input  wire        clk50,
  input  wire        rst_n,
  output wire [2:0]  led,
  input  wire [31:0] ddr3_dq,
  input  wire [3:0]  ddr3_dqs_p,
  input  wire [3:0]  ddr3_dqs_n
);
  localparam [31:0] READ_MAGIC = 32'h44515244; // "DQRD"

  reg [31:0] counter_q;
  reg [31:0] dq_meta_q;
  reg [31:0] dq_sync_q;
  reg [31:0] dq_prev_q;
  reg [31:0] dq_seen_high_q;
  reg [31:0] dq_seen_low_q;
  reg [31:0] dq_toggle_seen_q;
  reg [3:0] dqs_p_meta_q;
  reg [3:0] dqs_p_sync_q;
  reg [3:0] dqs_p_prev_q;
  reg [3:0] dqs_p_seen_high_q;
  reg [3:0] dqs_p_seen_low_q;
  reg [3:0] dqs_p_toggle_seen_q;
  reg [3:0] dqs_n_meta_q;
  reg [3:0] dqs_n_sync_q;
  reg [3:0] dqs_n_prev_q;
  reg [3:0] dqs_n_seen_high_q;
  reg [3:0] dqs_n_seen_low_q;
  reg [3:0] dqs_n_toggle_seen_q;

  always @(posedge clk50 or negedge rst_n) begin
    if (!rst_n) begin
      counter_q <= 32'd0;
      dq_meta_q <= 32'd0;
      dq_sync_q <= 32'd0;
      dq_prev_q <= 32'd0;
      dq_seen_high_q <= 32'd0;
      dq_seen_low_q <= 32'd0;
      dq_toggle_seen_q <= 32'd0;
      dqs_p_meta_q <= 4'd0;
      dqs_p_sync_q <= 4'd0;
      dqs_p_prev_q <= 4'd0;
      dqs_p_seen_high_q <= 4'd0;
      dqs_p_seen_low_q <= 4'd0;
      dqs_p_toggle_seen_q <= 4'd0;
      dqs_n_meta_q <= 4'd0;
      dqs_n_sync_q <= 4'd0;
      dqs_n_prev_q <= 4'd0;
      dqs_n_seen_high_q <= 4'd0;
      dqs_n_seen_low_q <= 4'd0;
      dqs_n_toggle_seen_q <= 4'd0;
    end else begin
      counter_q <= counter_q + 32'd1;

      dq_meta_q <= ddr3_dq;
      dq_sync_q <= dq_meta_q;
      dq_prev_q <= dq_sync_q;
      dq_seen_high_q <= dq_seen_high_q | dq_sync_q;
      dq_seen_low_q <= dq_seen_low_q | ~dq_sync_q;
      dq_toggle_seen_q <= dq_toggle_seen_q | (dq_sync_q ^ dq_prev_q);

      dqs_p_meta_q <= ddr3_dqs_p;
      dqs_p_sync_q <= dqs_p_meta_q;
      dqs_p_prev_q <= dqs_p_sync_q;
      dqs_p_seen_high_q <= dqs_p_seen_high_q | dqs_p_sync_q;
      dqs_p_seen_low_q <= dqs_p_seen_low_q | ~dqs_p_sync_q;
      dqs_p_toggle_seen_q <= dqs_p_toggle_seen_q | (dqs_p_sync_q ^ dqs_p_prev_q);

      dqs_n_meta_q <= ddr3_dqs_n;
      dqs_n_sync_q <= dqs_n_meta_q;
      dqs_n_prev_q <= dqs_n_sync_q;
      dqs_n_seen_high_q <= dqs_n_seen_high_q | dqs_n_sync_q;
      dqs_n_seen_low_q <= dqs_n_seen_low_q | ~dqs_n_sync_q;
      dqs_n_toggle_seen_q <= dqs_n_toggle_seen_q | (dqs_n_sync_q ^ dqs_n_prev_q);
    end
  end

  wire [31:0] dqs_status = {
    8'd0,
    dqs_n_toggle_seen_q,
    dqs_p_toggle_seen_q,
    dqs_n_seen_low_q,
    dqs_p_seen_low_q,
    dqs_n_seen_high_q,
    dqs_p_seen_high_q
  };

  wire [255:0] read_payload = {
    dqs_status,
    dqs_n_sync_q,
    dqs_p_sync_q,
    24'd0,
    dq_toggle_seen_q,
    dq_seen_low_q,
    dq_seen_high_q,
    dq_sync_q,
    counter_q,
    READ_MAGIC
  };

  assign led[0] = counter_q[24];
  assign led[1] = |dq_seen_high_q;
  assign led[2] = |dq_toggle_seen_q | |dqs_p_toggle_seen_q | |dqs_n_toggle_seen_q;

  ypcb_bscan_readback #(
    .WIDTH(256),
    .JTAG_CHAIN(1)
  ) readback_port (
    .payload_i(read_payload)
  );
endmodule

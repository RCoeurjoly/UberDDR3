`default_nettype none

module ypcb_phaser_shell_smoke (
  input  wire       clk50,
  input  wire       rst_n,
  output wire [2:0] led
);
  localparam [7:0] PHASER_OP_WRITE_CHUNK = 8'h01;
  localparam [7:0] PHASER_OP_READ_CHUNK = 8'h02;
  localparam [7:0] PHASER_OP_WRITE_LOWBYTE = 8'h03;
  localparam [7:0] PHASER_OP_READ_LOWBYTE = 8'h04;

  localparam [7:0] PHASER_STATE_IDLE = 8'h00;
  localparam [7:0] PHASER_STATE_BUSY = 8'h01;
  localparam [7:0] PHASER_STATE_ERROR = 8'h02;

  localparam integer FLAG_READY = 0;
  localparam integer FLAG_ERROR = 1;
  localparam integer FLAG_COMMAND_VALID = 2;
  localparam integer FLAG_WRITE_DATA_STAGED = 3;
  localparam integer FLAG_READ_DATA_VALID = 4;
  localparam integer FLAG_LOWBYTE_MODE = 13;
  localparam integer FLAG_FULLBEAT_MODE = 14;

  wire rst = ~rst_n;

  reg [25:0] heartbeat_q = 26'd0;
  reg [7:0] shell_state_q = PHASER_STATE_IDLE;
  reg error_q = 1'b0;
  reg last_command_valid_q = 1'b0;
  reg write_data_staged_q = 1'b0;
  reg read_data_valid_q = 1'b0;
  reg lowbyte_mode_q = 1'b0;
  reg fullbeat_mode_q = 1'b0;
  reg [15:0] write_count_q = 16'd0;
  reg [15:0] read_count_q = 16'd0;
  reg [31:0] user0_q = 32'd0;
  reg [31:0] user1_q = 32'd0;
  reg [31:0] user2_q = 32'd0;
  reg [127:0] read_data128_q = 128'd0;
  reg [511:0] scratch_mem_q [0:15];
  integer lane;

  wire command_event;
  wire command_valid;
  wire command_magic_ok;
  wire [7:0] command_opcode;
  wire [7:0] command_flags;
  wire [7:0] command_chunk;
  wire [31:0] command_addr;
  wire [39:0] command_aux;
  wire [127:0] command_data128;
  wire [15:0] command_count;
  wire [3:0] command_slot = command_addr[3:0];

  wire [15:0] status_flags = {
    1'b0,
    fullbeat_mode_q,
    lowbyte_mode_q,
    8'd0,
    read_data_valid_q,
    write_data_staged_q,
    last_command_valid_q,
    error_q,
    1'b1
  };

  always @(posedge clk50 or posedge rst) begin
    if (rst) begin
      heartbeat_q <= 26'd0;
      shell_state_q <= PHASER_STATE_IDLE;
      error_q <= 1'b0;
      last_command_valid_q <= 1'b0;
      write_data_staged_q <= 1'b0;
      read_data_valid_q <= 1'b0;
      lowbyte_mode_q <= 1'b0;
      fullbeat_mode_q <= 1'b0;
      write_count_q <= 16'd0;
      read_count_q <= 16'd0;
      user0_q <= 32'd0;
      user1_q <= 32'd0;
      user2_q <= 32'd0;
      read_data128_q <= 128'd0;
      for (lane = 0; lane < 16; lane = lane + 1)
        scratch_mem_q[lane] <= 512'd0;
    end else begin
      heartbeat_q <= heartbeat_q + 1'b1;
      shell_state_q <= PHASER_STATE_IDLE;

      if (command_event) begin
        user0_q <= command_aux[31:0];
        user1_q <= {command_flags, command_chunk, command_opcode, 8'h00};
        user2_q <= {12'd0, command_slot, heartbeat_q[15:0]};
        if (!command_magic_ok) begin
          error_q <= 1'b1;
          shell_state_q <= PHASER_STATE_ERROR;
        end
      end

      if (command_valid) begin
        last_command_valid_q <= 1'b1;
        error_q <= 1'b0;
        shell_state_q <= PHASER_STATE_BUSY;
        if (command_opcode == PHASER_OP_WRITE_CHUNK) begin
          fullbeat_mode_q <= 1'b1;
          lowbyte_mode_q <= 1'b0;
          write_data_staged_q <= 1'b1;
          read_data_valid_q <= 1'b0;
          write_count_q <= write_count_q + 1'b1;
          case (command_chunk[1:0])
            2'd0: scratch_mem_q[command_slot][0 +: 128] <= command_data128;
            2'd1: scratch_mem_q[command_slot][128 +: 128] <= command_data128;
            2'd2: scratch_mem_q[command_slot][256 +: 128] <= command_data128;
            2'd3: scratch_mem_q[command_slot][384 +: 128] <= command_data128;
          endcase
        end else if (command_opcode == PHASER_OP_READ_CHUNK) begin
          fullbeat_mode_q <= 1'b1;
          lowbyte_mode_q <= 1'b0;
          read_data_valid_q <= 1'b1;
          read_count_q <= read_count_q + 1'b1;
          case (command_chunk[1:0])
            2'd0: read_data128_q <= scratch_mem_q[command_slot][0 +: 128];
            2'd1: read_data128_q <= scratch_mem_q[command_slot][128 +: 128];
            2'd2: read_data128_q <= scratch_mem_q[command_slot][256 +: 128];
            2'd3: read_data128_q <= scratch_mem_q[command_slot][384 +: 128];
          endcase
        end else if (command_opcode == PHASER_OP_WRITE_LOWBYTE) begin
          fullbeat_mode_q <= 1'b0;
          lowbyte_mode_q <= 1'b1;
          write_data_staged_q <= 1'b1;
          read_data_valid_q <= 1'b0;
          write_count_q <= write_count_q + 1'b1;
          scratch_mem_q[command_slot][7:0] <= command_aux[7:0];
        end else if (command_opcode == PHASER_OP_READ_LOWBYTE) begin
          fullbeat_mode_q <= 1'b0;
          lowbyte_mode_q <= 1'b1;
          read_data_valid_q <= 1'b1;
          read_count_q <= read_count_q + 1'b1;
          read_data128_q <= {120'd0, scratch_mem_q[command_slot][7:0]};
        end else begin
          error_q <= 1'b1;
          shell_state_q <= PHASER_STATE_ERROR;
        end
      end
    end
  end

  assign led[0] = heartbeat_q[25];
  assign led[1] = error_q;
  assign led[2] = command_count[0];

  task6_ypcb_phaser_shell_bscan_port phaser_shell_port (
    .controller_clk_i(clk50),
    .rst_ni(rst_n),
    .shell_state_i(shell_state_q),
    .status_flags_i(status_flags),
    .write_count_i(write_count_q),
    .read_count_i(read_count_q),
    .user0_i(user0_q),
    .user1_i(user1_q),
    .user2_i(user2_q),
    .read_data128_i(read_data128_q),
    .command_event_o(command_event),
    .command_valid_o(command_valid),
    .command_magic_ok_o(command_magic_ok),
    .command_opcode_o(command_opcode),
    .command_flags_o(command_flags),
    .command_chunk_o(command_chunk),
    .command_addr_o(command_addr),
    .command_aux_o(command_aux),
    .command_data128_o(command_data128),
    .command_count_o(command_count)
  );
endmodule

`default_nettype wire

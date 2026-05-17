// Raw BSCAN status/control bridge for YPCB LiteDRAM BIST experiments.
//
// USER1 (IR 0x02, JTAG_CHAIN=1) shifts out a 1024-bit status payload.
// USER2 (IR 0x03, JTAG_CHAIN=2) shifts in a 128-bit command payload.

module ypcb_litedram_bscan_bridge #(
    parameter [31:0] BYTE_GROUP_MASK = 32'h0000000f,
    parameter [1:0] RDPHASE = 2'd2,
    parameter [1:0] WRPHASE = 2'd3
) (
    input  wire        sys_clk,
    input  wire        sys_rst,
    input  wire        clkin,
    input  wire        idelay_clk,
    input  wire        rst_n_raw,
    input  wire        pll_locked,
    input  wire [31:0] ddr_dq_sample,
    input  wire [127:0] ddr_phase_sample,
    input  wire [3:0]  ddr_dqs_p_sample,
    input  wire [3:0]  ddr_dqs_n_sample,

    input  wire        generator_done,
    input  wire [31:0] generator_ticks,
    input  wire        checker_done,
    input  wire [31:0] checker_ticks,
    input  wire [31:0] checker_errors,

    output reg         bist_reset,
    output reg         generator_start,
    output reg         checker_start,
    output reg  [31:0] bist_base,
    output reg  [31:0] bist_length,
    output reg         bist_random_data,
    output reg         bist_random_addr,

    output reg  [29:0] wb_adr,
    output reg  [31:0] wb_dat_w,
    input  wire [31:0] wb_dat_r,
    output wire [3:0]  wb_sel,
    output reg         wb_cyc,
    output reg         wb_stb,
    output reg         wb_we,
    input  wire        wb_ack,
    input  wire        wb_err
`ifdef YPCB_BRIDGE_SIM
    ,
    input  wire        sim_command_valid,
    input  wire [7:0]  sim_command_opcode,
    input  wire [31:0] sim_command_addr,
    input  wire [31:0] sim_command_data,
    output wire        sim_diag_active,
    output wire [7:0]  sim_diag_status,
    output wire [31:0] sim_diag_count,
    output wire [31:0] sim_diag_error_count
`endif
);
    localparam [31:0] READ_MAGIC  = 32'h4c445244; // "LDRD"
    localparam [31:0] WRITE_MAGIC = 32'h4c44434e; // "LDCN"

    localparam [7:0] OP_WRITE_SCRATCH = 8'h01;
    localparam [7:0] OP_CLEAR_SCRATCH = 8'h02;
    localparam [7:0] OP_START_GEN     = 8'h10;
    localparam [7:0] OP_START_CHECK   = 8'h11;
    localparam [7:0] OP_RESET_BIST    = 8'h12;
    localparam [7:0] OP_SET_BASE      = 8'h20;
    localparam [7:0] OP_SET_LENGTH    = 8'h21;
    localparam [7:0] OP_SET_RANDOM    = 8'h22;
    localparam [7:0] OP_WB_WRITE      = 8'h30;
    localparam [7:0] OP_WB_READ       = 8'h31;
    localparam [7:0] OP_APPLY_RDLY    = 8'h40;
    localparam [7:0] OP_MEM32_CHECK   = 8'h41;
    localparam [7:0] OP_DFII_PATTERN  = 8'h42;
    localparam [7:0] OP_CLEAR_PHY_SAMPLE = 8'h43;

    localparam [31:0] CSR_DDRPHY_DLY_SEL             = 32'h00000804;
    localparam [31:0] CSR_DDRPHY_RDLY_DQ_RST         = 32'h00000814;
    localparam [31:0] CSR_DDRPHY_RDLY_DQ_INC         = 32'h00000818;
    localparam [31:0] CSR_DDRPHY_RDLY_DQ_BITSLIP_RST = 32'h0000081c;
    localparam [31:0] CSR_DDRPHY_RDLY_DQ_BITSLIP     = 32'h00000820;
    localparam [31:0] CSR_SDRAM_DFII_CONTROL         = 32'h00001800;
    localparam [31:0] CSR_SDRAM_DFII_BASE             = 32'h00001804;

    localparam [31:0] DFII_CONTROL_SOFTWARE = 32'h0000000e;
    localparam [31:0] DFII_CONTROL_HARDWARE = 32'h00000001;

    localparam [31:0] DFII_PATTERN0_HI = 32'hdb6db001;
    localparam [31:0] DFII_PATTERN0_LO = 32'h00400007;
    localparam [31:0] DFII_PATTERN1_HI = 32'hbb0aa0ee;
    localparam [31:0] DFII_PATTERN1_LO = 32'h1ab3ce79;
    localparam [31:0] DFII_PATTERN2_HI = 32'he6b84bf7;
    localparam [31:0] DFII_PATTERN2_LO = 32'h4cfacd77;
    localparam [31:0] DFII_PATTERN3_HI = 32'hed76555a;
    localparam [31:0] DFII_PATTERN3_LO = 32'hd4f69721;

    localparam [31:0] DFII_CMD_ACT     = 32'h00000009;
    localparam [31:0] DFII_CMD_WRITE   = 32'h00000017;
    localparam [31:0] DFII_CMD_READ    = 32'h00000025;
    localparam [31:0] DFII_CMD_PRE     = 32'h0000000b;

    wire read_capture;
    wire read_drck;
    wire read_sel;
    wire read_shift;
    wire read_tdi;
    wire read_update;
    reg  read_tdo;

    wire write_capture;
    wire write_drck;
    wire write_sel;
    wire write_shift;
    wire write_tdi;
    wire write_update;

    reg [1023:0] read_shift_q;
    reg [127:0] write_shift_q;

    reg [31:0] clkin_counter;
    reg [31:0] idelay_counter;
    reg [31:0] counter;
    reg [31:0] scratch;
    reg [15:0] command_count;
    reg [7:0] last_opcode;
    reg command_toggle_tck;
    reg [7:0] command_opcode_tck;
    reg [31:0] command_addr_tck;
    reg [31:0] command_data_tck;
    reg [31:0] wb_addr_byte;
    reg [31:0] wb_rdata_q;
    reg [7:0] wb_status;
    reg [15:0] wb_count;
    reg [19:0] wb_timeout_counter;
    reg wb_done_pulse;
    reg wb_is_read;

    reg diag_active;
    reg [7:0] diag_opcode;
    reg [7:0] diag_state;
    reg [7:0] diag_module_mask;
    reg [7:0] diag_bitslip_target;
    reg [7:0] diag_delay_target;
    reg [7:0] diag_bitslip_count;
    reg [7:0] diag_delay_count;
    reg [31:0] diag_addr;
    reg [31:0] diag_expected;
    reg [31:0] diag_actual;
    reg [31:0] diag_count;
    reg [31:0] diag_error_count;
    reg [7:0] diag_status;
    reg [7:0] diag_phase;
    reg [7:0] diag_wait_count;
    reg [31:0] ddr_dq_meta;
    reg [31:0] ddr_dq_sync;
    reg [31:0] ddr_dq_prev;
    reg [31:0] ddr_dq_seen_high;
    reg [31:0] ddr_dq_seen_low;
    reg [31:0] ddr_dq_toggle_seen;
    reg [127:0] ddr_phase_meta;
    reg [127:0] ddr_phase_sync;
    reg [127:0] ddr_phase_prev;
    reg [31:0] ddr_phase_seen_high;
    reg [31:0] ddr_phase_toggle_seen;
    reg [3:0] ddr_phase_nonzero_seen;
    reg [3:0] ddr_phase_nonzero_toggle_seen;
    reg [3:0] ddr_dqs_p_meta;
    reg [3:0] ddr_dqs_p_sync;
    reg [3:0] ddr_dqs_p_prev;
    reg [3:0] ddr_dqs_p_seen_high;
    reg [3:0] ddr_dqs_p_seen_low;
    reg [3:0] ddr_dqs_p_toggle_seen;
    reg [3:0] ddr_dqs_n_meta;
    reg [3:0] ddr_dqs_n_sync;
    reg [3:0] ddr_dqs_n_prev;
    reg [3:0] ddr_dqs_n_seen_high;
    reg [3:0] ddr_dqs_n_seen_low;
    reg [3:0] ddr_dqs_n_toggle_seen;

`ifdef YPCB_BRIDGE_SIM
    assign sim_diag_active = diag_active;
    assign sim_diag_status = diag_status;
    assign sim_diag_count = diag_count;
    assign sim_diag_error_count = diag_error_count;
`endif

    function [31:0] phase_reg;
        input [1:0] phase;
        input [7:0] offset;
        begin
            phase_reg = CSR_SDRAM_DFII_BASE + {28'd0, phase, 5'd0} + {24'd0, offset};
        end
    endfunction

    function [29:0] phase_wadr;
        input [1:0] phase;
        input [7:0] offset;
        reg [31:0] byte_addr;
        begin
            byte_addr = phase_reg(phase, offset);
            phase_wadr = byte_addr[31:2];
        end
    endfunction

    function [5:0] popcount32;
        input [31:0] value;
        integer i;
        begin
            popcount32 = 6'd0;
            for (i = 0; i < 32; i = i + 1) begin
                popcount32 = popcount32 + value[i];
            end
        end
    endfunction

    function [31:0] pattern_hi;
        input [1:0] phase;
        begin
            case (phase)
                2'd0: pattern_hi = DFII_PATTERN0_HI;
                2'd1: pattern_hi = DFII_PATTERN1_HI;
                2'd2: pattern_hi = DFII_PATTERN2_HI;
                default: pattern_hi = DFII_PATTERN3_HI;
            endcase
        end
    endfunction

    function [31:0] pattern_lo;
        input [1:0] phase;
        begin
            case (phase)
                2'd0: pattern_lo = DFII_PATTERN0_LO;
                2'd1: pattern_lo = DFII_PATTERN1_LO;
                2'd2: pattern_lo = DFII_PATTERN2_LO;
                default: pattern_lo = DFII_PATTERN3_LO;
            endcase
        end
    endfunction

    assign wb_sel = 4'hf;

    wire [7:0] status = {
        2'b00,
        rst_n_raw,
        |checker_errors,
        checker_done,
        generator_done,
        pll_locked,
        ~sys_rst
    };

    wire [31:0] ddr_dqs_status = {
        8'd0,
        ddr_dqs_n_toggle_seen,
        ddr_dqs_p_toggle_seen,
        ddr_dqs_n_seen_low,
        ddr_dqs_p_seen_low,
        ddr_dqs_n_seen_high,
        ddr_dqs_p_seen_high
    };

    wire [31:0] ddr_phase0_sync = ddr_phase_sync[31:0];
    wire [31:0] ddr_phase1_sync = ddr_phase_sync[63:32];
    wire [31:0] ddr_phase2_sync = ddr_phase_sync[95:64];
    wire [31:0] ddr_phase3_sync = ddr_phase_sync[127:96];
    wire [31:0] ddr_phase0_prev = ddr_phase_prev[31:0];
    wire [31:0] ddr_phase1_prev = ddr_phase_prev[63:32];
    wire [31:0] ddr_phase2_prev = ddr_phase_prev[95:64];
    wire [31:0] ddr_phase3_prev = ddr_phase_prev[127:96];
    wire [3:0] ddr_phase_nonzero_now = {
        |ddr_phase3_sync,
        |ddr_phase2_sync,
        |ddr_phase1_sync,
        |ddr_phase0_sync
    };
    wire [3:0] ddr_phase_nonzero_toggle_now = {
        |(ddr_phase3_sync ^ ddr_phase3_prev),
        |(ddr_phase2_sync ^ ddr_phase2_prev),
        |(ddr_phase1_sync ^ ddr_phase1_prev),
        |(ddr_phase0_sync ^ ddr_phase0_prev)
    };
    wire [31:0] ddr_phase_seen_high_next =
        ddr_phase0_sync | ddr_phase1_sync | ddr_phase2_sync | ddr_phase3_sync;
    wire [31:0] ddr_phase_toggle_seen_next =
        (ddr_phase0_sync ^ ddr_phase0_prev) |
        (ddr_phase1_sync ^ ddr_phase1_prev) |
        (ddr_phase2_sync ^ ddr_phase2_prev) |
        (ddr_phase3_sync ^ ddr_phase3_prev);
    wire [31:0] ddr_phase_status = {
        20'd0,
        ddr_phase_nonzero_toggle_seen,
        ddr_phase_nonzero_seen,
        ddr_phase_nonzero_now
    };

    wire [1023:0] read_payload = {
        ddr_phase_toggle_seen,
        ddr_phase_seen_high,
        ddr_phase_status,
        ddr_dqs_status,
        ddr_dq_toggle_seen,
        ddr_dq_seen_low,
        ddr_dq_seen_high,
        ddr_dq_sync,
        48'd0,
        diag_error_count,
        diag_count,
        diag_actual,
        diag_expected,
        diag_addr,
        diag_delay_target,
        diag_bitslip_target,
        diag_module_mask,
        diag_opcode,
        diag_status,
        diag_state,
        diag_active,
        7'd0,
        wb_count,
        wb_status,
        wb_rdata_q,
        wb_dat_w,
        wb_addr_byte,
        idelay_counter,
        clkin_counter,
        BYTE_GROUP_MASK,
        checker_errors,
        checker_ticks,
        generator_ticks,
        bist_length,
        bist_base,
        status,
        last_opcode,
        command_count,
        counter,
        scratch,
        READ_MAGIC
    };

    BSCANE2 #(
        .DISABLE_JTAG("FALSE"),
        .JTAG_CHAIN(1)
    ) read_bscan (
        .CAPTURE(read_capture),
        .DRCK(read_drck),
        .RESET(),
        .RUNTEST(),
        .SEL(read_sel),
        .SHIFT(read_shift),
        .TCK(),
        .TDI(read_tdi),
        .TMS(),
        .UPDATE(read_update),
        .TDO(read_tdo)
    );

    BSCANE2 #(
        .DISABLE_JTAG("FALSE"),
        .JTAG_CHAIN(2)
    ) write_bscan (
        .CAPTURE(write_capture),
        .DRCK(write_drck),
        .RESET(),
        .RUNTEST(),
        .SEL(write_sel),
        .SHIFT(write_shift),
        .TCK(),
        .TDI(write_tdi),
        .TMS(),
        .UPDATE(write_update),
        .TDO(1'b0)
    );

    always @(posedge read_drck) begin
        if (read_capture) begin
            read_shift_q <= read_payload;
            read_tdo <= read_payload[0];
        end else if (read_sel && read_shift) begin
            read_tdo <= read_shift_q[0];
            read_shift_q <= {1'b0, read_shift_q[1023:1]};
        end
    end

    always @(posedge write_drck) begin
        if (write_capture) begin
            write_shift_q <= 128'd0;
        end else if (write_sel && write_shift) begin
            write_shift_q <= {write_tdi, write_shift_q[127:1]};
        end
    end

    always @(posedge write_update) begin
        if (write_sel && write_shift_q[31:0] == WRITE_MAGIC) begin
            command_opcode_tck <= write_shift_q[39:32];
            command_addr_tck <= write_shift_q[71:40];
            command_data_tck <= write_shift_q[103:72];
            command_toggle_tck <= ~command_toggle_tck;
        end
    end

    reg [2:0] command_toggle_sys;
    reg [7:0] command_opcode_sys;
    reg [31:0] command_addr_sys;
    reg [31:0] command_data_sys;

`ifdef YPCB_BRIDGE_SIM
    wire command_pending_sys = sim_command_valid || (command_toggle_sys[2] != command_toggle_sys[1]);
    wire [7:0] command_opcode_active = sim_command_valid ? sim_command_opcode : command_opcode_tck;
    wire [31:0] command_addr_active = sim_command_valid ? sim_command_addr : command_addr_tck;
    wire [31:0] command_data_active = sim_command_valid ? sim_command_data : command_data_tck;
`else
    wire command_pending_sys = command_toggle_sys[2] != command_toggle_sys[1];
    wire [7:0] command_opcode_active = command_opcode_tck;
    wire [31:0] command_addr_active = command_addr_tck;
    wire [31:0] command_data_active = command_data_tck;
`endif

    always @(posedge clkin) begin
        clkin_counter <= clkin_counter + 1'd1;
    end

    always @(posedge idelay_clk) begin
        idelay_counter <= idelay_counter + 1'd1;
    end

    always @(posedge sys_clk) begin
        if (sys_rst) begin
            counter <= 32'd0;
            scratch <= 32'd0;
            command_count <= 16'd0;
            last_opcode <= 8'd0;
            command_toggle_sys <= 3'd0;
            bist_reset <= 1'b0;
            generator_start <= 1'b0;
            checker_start <= 1'b0;
            bist_base <= 32'd0;
            bist_length <= 32'h00001000;
            bist_random_data <= 1'b0;
            bist_random_addr <= 1'b0;
            wb_adr <= 30'd0;
            wb_dat_w <= 32'd0;
            wb_cyc <= 1'b0;
            wb_stb <= 1'b0;
            wb_we <= 1'b0;
            wb_addr_byte <= 32'd0;
            wb_rdata_q <= 32'd0;
            wb_status <= 8'd0;
            wb_count <= 16'd0;
            wb_timeout_counter <= 20'd0;
            wb_done_pulse <= 1'b0;
            wb_is_read <= 1'b0;
            diag_active <= 1'b0;
            diag_opcode <= 8'd0;
            diag_state <= 8'd0;
            diag_module_mask <= 8'd0;
            diag_bitslip_target <= 8'd0;
            diag_delay_target <= 8'd0;
            diag_bitslip_count <= 8'd0;
            diag_delay_count <= 8'd0;
            diag_addr <= 32'd0;
            diag_expected <= 32'd0;
            diag_actual <= 32'd0;
            diag_count <= 32'd0;
            diag_error_count <= 32'd0;
            diag_status <= 8'd0;
            diag_phase <= 8'd0;
            diag_wait_count <= 8'd0;
            ddr_dq_meta <= 32'd0;
            ddr_dq_sync <= 32'd0;
            ddr_dq_prev <= 32'd0;
            ddr_dq_seen_high <= 32'd0;
            ddr_dq_seen_low <= 32'd0;
            ddr_dq_toggle_seen <= 32'd0;
            ddr_phase_meta <= 128'd0;
            ddr_phase_sync <= 128'd0;
            ddr_phase_prev <= 128'd0;
            ddr_phase_seen_high <= 32'd0;
            ddr_phase_toggle_seen <= 32'd0;
            ddr_phase_nonzero_seen <= 4'd0;
            ddr_phase_nonzero_toggle_seen <= 4'd0;
            ddr_dqs_p_meta <= 4'd0;
            ddr_dqs_p_sync <= 4'd0;
            ddr_dqs_p_prev <= 4'd0;
            ddr_dqs_p_seen_high <= 4'd0;
            ddr_dqs_p_seen_low <= 4'd0;
            ddr_dqs_p_toggle_seen <= 4'd0;
            ddr_dqs_n_meta <= 4'd0;
            ddr_dqs_n_sync <= 4'd0;
            ddr_dqs_n_prev <= 4'd0;
            ddr_dqs_n_seen_high <= 4'd0;
            ddr_dqs_n_seen_low <= 4'd0;
            ddr_dqs_n_toggle_seen <= 4'd0;
        end else begin
            counter <= counter + 1'd1;
            ddr_dq_meta <= ddr_dq_sample;
            ddr_dq_sync <= ddr_dq_meta;
            ddr_dq_prev <= ddr_dq_sync;
            ddr_dq_seen_high <= ddr_dq_seen_high | ddr_dq_sync;
            ddr_dq_seen_low <= ddr_dq_seen_low | ~ddr_dq_sync;
            ddr_dq_toggle_seen <= ddr_dq_toggle_seen | (ddr_dq_sync ^ ddr_dq_prev);
            ddr_phase_meta <= ddr_phase_sample;
            ddr_phase_sync <= ddr_phase_meta;
            ddr_phase_prev <= ddr_phase_sync;
            ddr_phase_seen_high <= ddr_phase_seen_high | ddr_phase_seen_high_next;
            ddr_phase_toggle_seen <= ddr_phase_toggle_seen | ddr_phase_toggle_seen_next;
            ddr_phase_nonzero_seen <= ddr_phase_nonzero_seen | ddr_phase_nonzero_now;
            ddr_phase_nonzero_toggle_seen <= ddr_phase_nonzero_toggle_seen | ddr_phase_nonzero_toggle_now;
            ddr_dqs_p_meta <= ddr_dqs_p_sample;
            ddr_dqs_p_sync <= ddr_dqs_p_meta;
            ddr_dqs_p_prev <= ddr_dqs_p_sync;
            ddr_dqs_p_seen_high <= ddr_dqs_p_seen_high | ddr_dqs_p_sync;
            ddr_dqs_p_seen_low <= ddr_dqs_p_seen_low | ~ddr_dqs_p_sync;
            ddr_dqs_p_toggle_seen <= ddr_dqs_p_toggle_seen | (ddr_dqs_p_sync ^ ddr_dqs_p_prev);
            ddr_dqs_n_meta <= ddr_dqs_n_sample;
            ddr_dqs_n_sync <= ddr_dqs_n_meta;
            ddr_dqs_n_prev <= ddr_dqs_n_sync;
            ddr_dqs_n_seen_high <= ddr_dqs_n_seen_high | ddr_dqs_n_sync;
            ddr_dqs_n_seen_low <= ddr_dqs_n_seen_low | ~ddr_dqs_n_sync;
            ddr_dqs_n_toggle_seen <= ddr_dqs_n_toggle_seen | (ddr_dqs_n_sync ^ ddr_dqs_n_prev);
            bist_reset <= 1'b0;
            generator_start <= 1'b0;
            checker_start <= 1'b0;
            wb_done_pulse <= 1'b0;
            command_toggle_sys <= {command_toggle_sys[1:0], command_toggle_tck};
            if (wb_cyc) begin
                wb_timeout_counter <= wb_timeout_counter + 1'd1;
                if (wb_ack || wb_err) begin
                    wb_rdata_q <= wb_dat_r;
                    if (wb_is_read) begin
                        diag_actual <= wb_dat_r;
                    end
                    wb_cyc <= 1'b0;
                    wb_stb <= 1'b0;
                    wb_we <= 1'b0;
                    wb_count <= wb_count + 1'd1;
                    wb_status <= {4'd0, wb_err, 1'b0, 1'b1, 1'b0};
                    wb_done_pulse <= 1'b1;
                end else if (&wb_timeout_counter) begin
                    wb_cyc <= 1'b0;
                    wb_stb <= 1'b0;
                    wb_we <= 1'b0;
                    wb_count <= wb_count + 1'd1;
                    wb_status <= 8'b0000_0110;
                    wb_done_pulse <= 1'b1;
                end
            end

            if (diag_active && !wb_cyc && !wb_done_pulse) begin
                case (diag_state)
                    8'd0: begin
                        wb_addr_byte <= CSR_DDRPHY_DLY_SEL;
                        wb_adr <= CSR_DDRPHY_DLY_SEL[31:2];
                        wb_dat_w <= {24'd0, diag_module_mask};
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd1;
                    end
                    8'd1: if (wb_status[1]) diag_state <= 8'd2;
                    8'd2: begin
                        wb_addr_byte <= CSR_DDRPHY_RDLY_DQ_RST;
                        wb_adr <= CSR_DDRPHY_RDLY_DQ_RST[31:2];
                        wb_dat_w <= 32'd1;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd3;
                    end
                    8'd3: if (wb_status[1]) diag_state <= 8'd4;
                    8'd4: begin
                        wb_addr_byte <= CSR_DDRPHY_RDLY_DQ_BITSLIP_RST;
                        wb_adr <= CSR_DDRPHY_RDLY_DQ_BITSLIP_RST[31:2];
                        wb_dat_w <= 32'd1;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd5;
                    end
                    8'd5: if (wb_status[1]) diag_state <= 8'd6;
                    8'd6: begin
                        if (diag_bitslip_count < diag_bitslip_target) begin
                            wb_addr_byte <= CSR_DDRPHY_RDLY_DQ_BITSLIP;
                            wb_adr <= CSR_DDRPHY_RDLY_DQ_BITSLIP[31:2];
                            wb_dat_w <= 32'd1;
                            wb_cyc <= 1'b1;
                            wb_stb <= 1'b1;
                            wb_we <= 1'b1;
                            wb_is_read <= 1'b0;
                            wb_timeout_counter <= 20'd0;
                            wb_status <= 8'b0000_0001;
                            diag_bitslip_count <= diag_bitslip_count + 1'd1;
                        end else begin
                            diag_state <= 8'd8;
                        end
                    end
                    8'd7: if (wb_status[1]) diag_state <= 8'd6;
                    8'd8: begin
                        if (diag_delay_count < diag_delay_target) begin
                            wb_addr_byte <= CSR_DDRPHY_RDLY_DQ_INC;
                            wb_adr <= CSR_DDRPHY_RDLY_DQ_INC[31:2];
                            wb_dat_w <= 32'd1;
                            wb_cyc <= 1'b1;
                            wb_stb <= 1'b1;
                            wb_we <= 1'b1;
                            wb_is_read <= 1'b0;
                            wb_timeout_counter <= 20'd0;
                            wb_status <= 8'b0000_0001;
                            diag_delay_count <= diag_delay_count + 1'd1;
                        end else begin
                            diag_state <= 8'd10;
                        end
                    end
                    8'd9: if (wb_status[1]) diag_state <= 8'd8;
                    8'd10: begin
                        wb_addr_byte <= CSR_DDRPHY_DLY_SEL;
                        wb_adr <= CSR_DDRPHY_DLY_SEL[31:2];
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        if (diag_opcode == OP_MEM32_CHECK) begin
                            diag_state <= 8'd12;
                        end else if (diag_opcode == OP_DFII_PATTERN) begin
                            diag_phase <= 8'd0;
                            diag_wait_count <= 8'd0;
                            diag_actual <= 32'd0;
                            diag_error_count <= 32'd0;
                            diag_state <= 8'd29;
                        end else begin
                            diag_state <= 8'd20;
                        end
                    end
                    8'd11: if (wb_status[1]) diag_state <= 8'd20;
                    8'd29: begin
                        wb_addr_byte <= CSR_SDRAM_DFII_CONTROL;
                        wb_adr <= CSR_SDRAM_DFII_CONTROL[31:2];
                        wb_dat_w <= DFII_CONTROL_SOFTWARE;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd28;
                    end
                    8'd28: if (wb_status[1]) diag_state <= 8'd30;
                    8'd12: begin
                        wb_addr_byte <= diag_addr;
                        wb_adr <= diag_addr[31:2];
                        wb_dat_w <= diag_expected;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd13;
                    end
                    8'd13: if (wb_status[1]) diag_state <= 8'd14;
                    8'd14: begin
                        wb_addr_byte <= diag_addr;
                        wb_adr <= diag_addr[31:2];
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b0;
                        wb_is_read <= 1'b1;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd15;
                    end
                    8'd15: if (wb_status[1]) begin
                        if (diag_actual == diag_expected) begin
                            diag_state <= 8'd20;
                        end else begin
                            diag_status <= 8'h03;
                            diag_error_count <= diag_error_count + 1'd1;
                            diag_count <= diag_count + 1'd1;
                            diag_active <= 1'b0;
                        end
                    end
                    8'd20: begin
                        diag_count <= diag_count + 1'd1;
                        diag_status <= 8'h02;
                        diag_active <= 1'b0;
                    end
                    8'd30: begin
                        wb_addr_byte <= phase_reg(2'd0, 8'h08);
                        wb_adr <= phase_wadr(2'd0, 8'h08);
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd31;
                    end
                    8'd31: if (wb_status[1]) diag_state <= 8'd32;
                    8'd32: begin
                        wb_addr_byte <= phase_reg(2'd0, 8'h0c);
                        wb_adr <= phase_wadr(2'd0, 8'h0c);
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd33;
                    end
                    8'd33: if (wb_status[1]) diag_state <= 8'd34;
                    8'd34: begin
                        wb_addr_byte <= phase_reg(2'd0, 8'h00);
                        wb_adr <= phase_wadr(2'd0, 8'h00);
                        wb_dat_w <= DFII_CMD_ACT;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd35;
                    end
                    8'd35: if (wb_status[1]) diag_state <= 8'd36;
                    8'd36: begin
                        wb_addr_byte <= phase_reg(2'd0, 8'h04);
                        wb_adr <= phase_wadr(2'd0, 8'h04);
                        wb_dat_w <= 32'd1;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_phase <= 8'd0;
                        diag_state <= 8'd37;
                    end
                    8'd37: if (wb_status[1]) diag_state <= 8'd38;
                    8'd38: begin
                        wb_addr_byte <= phase_reg(diag_phase[1:0], 8'h10);
                        wb_adr <= phase_wadr(diag_phase[1:0], 8'h10);
                        wb_dat_w <= pattern_hi(diag_phase[1:0]);
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd39;
                    end
                    8'd39: if (wb_status[1]) diag_state <= 8'd40;
                    8'd40: begin
                        wb_addr_byte <= phase_reg(diag_phase[1:0], 8'h14);
                        wb_adr <= phase_wadr(diag_phase[1:0], 8'h14);
                        wb_dat_w <= pattern_lo(diag_phase[1:0]);
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd41;
                    end
                    8'd41: if (wb_status[1]) begin
                        if (diag_phase == 8'd3) begin
                            diag_state <= 8'd42;
                        end else begin
                            diag_phase <= diag_phase + 1'd1;
                            diag_state <= 8'd38;
                        end
                    end
                    8'd42: begin
                        wb_addr_byte <= phase_reg(WRPHASE, 8'h08);
                        wb_adr <= phase_wadr(WRPHASE, 8'h08);
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd43;
                    end
                    8'd43: if (wb_status[1]) diag_state <= 8'd44;
                    8'd44: begin
                        wb_addr_byte <= phase_reg(WRPHASE, 8'h0c);
                        wb_adr <= phase_wadr(WRPHASE, 8'h0c);
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd45;
                    end
                    8'd45: if (wb_status[1]) diag_state <= 8'd46;
                    8'd46: begin
                        wb_addr_byte <= phase_reg(WRPHASE, 8'h00);
                        wb_adr <= phase_wadr(WRPHASE, 8'h00);
                        wb_dat_w <= DFII_CMD_WRITE;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd47;
                    end
                    8'd47: if (wb_status[1]) diag_state <= 8'd48;
                    8'd48: begin
                        wb_addr_byte <= phase_reg(WRPHASE, 8'h04);
                        wb_adr <= phase_wadr(WRPHASE, 8'h04);
                        wb_dat_w <= 32'd1;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_wait_count <= 8'd0;
                        diag_state <= 8'd49;
                    end
                    8'd49: begin
                        if (diag_wait_count == 8'd64) begin
                            diag_state <= 8'd50;
                        end else begin
                            diag_wait_count <= diag_wait_count + 1'd1;
                        end
                    end
                    8'd50: begin
                        wb_addr_byte <= phase_reg(RDPHASE, 8'h08);
                        wb_adr <= phase_wadr(RDPHASE, 8'h08);
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd51;
                    end
                    8'd51: if (wb_status[1]) diag_state <= 8'd52;
                    8'd52: begin
                        wb_addr_byte <= phase_reg(RDPHASE, 8'h0c);
                        wb_adr <= phase_wadr(RDPHASE, 8'h0c);
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd53;
                    end
                    8'd53: if (wb_status[1]) diag_state <= 8'd54;
                    8'd54: begin
                        wb_addr_byte <= phase_reg(RDPHASE, 8'h00);
                        wb_adr <= phase_wadr(RDPHASE, 8'h00);
                        wb_dat_w <= DFII_CMD_READ;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd55;
                    end
                    8'd55: if (wb_status[1]) diag_state <= 8'd56;
                    8'd56: begin
                        wb_addr_byte <= phase_reg(RDPHASE, 8'h04);
                        wb_adr <= phase_wadr(RDPHASE, 8'h04);
                        wb_dat_w <= 32'd1;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_wait_count <= 8'd0;
                        diag_state <= 8'd57;
                    end
                    8'd57: begin
                        if (diag_wait_count == 8'd64) begin
                            diag_phase <= 8'd0;
                            diag_state <= 8'd58;
                        end else begin
                            diag_wait_count <= diag_wait_count + 1'd1;
                        end
                    end
                    8'd58: begin
                        wb_addr_byte <= phase_reg(diag_phase[1:0], 8'h18);
                        wb_adr <= phase_wadr(diag_phase[1:0], 8'h18);
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b0;
                        wb_is_read <= 1'b1;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd59;
                    end
                    8'd59: if (wb_status[1]) begin
                        diag_error_count <= diag_error_count + popcount32(wb_rdata_q ^ pattern_hi(diag_phase[1:0]));
                        diag_state <= 8'd60;
                    end
                    8'd60: begin
                        wb_addr_byte <= phase_reg(diag_phase[1:0], 8'h1c);
                        wb_adr <= phase_wadr(diag_phase[1:0], 8'h1c);
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b0;
                        wb_is_read <= 1'b1;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd61;
                    end
                    8'd61: if (wb_status[1]) begin
                        diag_error_count <= diag_error_count + popcount32(wb_rdata_q ^ pattern_lo(diag_phase[1:0]));
                        if (diag_phase == 8'd3) begin
                            diag_state <= 8'd62;
                        end else begin
                            diag_phase <= diag_phase + 1'd1;
                            diag_state <= 8'd58;
                        end
                    end
                    8'd62: begin
                        wb_addr_byte <= phase_reg(2'd0, 8'h08);
                        wb_adr <= phase_wadr(2'd0, 8'h08);
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd63;
                    end
                    8'd63: if (wb_status[1]) diag_state <= 8'd64;
                    8'd64: begin
                        wb_addr_byte <= phase_reg(2'd0, 8'h0c);
                        wb_adr <= phase_wadr(2'd0, 8'h0c);
                        wb_dat_w <= 32'd0;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd65;
                    end
                    8'd65: if (wb_status[1]) diag_state <= 8'd66;
                    8'd66: begin
                        wb_addr_byte <= phase_reg(2'd0, 8'h00);
                        wb_adr <= phase_wadr(2'd0, 8'h00);
                        wb_dat_w <= DFII_CMD_PRE;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd67;
                    end
                    8'd67: if (wb_status[1]) diag_state <= 8'd68;
                    8'd68: begin
                        wb_addr_byte <= phase_reg(2'd0, 8'h04);
                        wb_adr <= phase_wadr(2'd0, 8'h04);
                        wb_dat_w <= 32'd1;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_wait_count <= 8'd0;
                        diag_state <= 8'd69;
                    end
                    8'd69: begin
                        if (diag_wait_count == 8'd64) begin
                            diag_state <= 8'd70;
                        end else begin
                            diag_wait_count <= diag_wait_count + 1'd1;
                        end
                    end
                    8'd70: begin
                        wb_addr_byte <= CSR_SDRAM_DFII_CONTROL;
                        wb_adr <= CSR_SDRAM_DFII_CONTROL[31:2];
                        wb_dat_w <= DFII_CONTROL_HARDWARE;
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                        wb_we <= 1'b1;
                        wb_is_read <= 1'b0;
                        wb_timeout_counter <= 20'd0;
                        wb_status <= 8'b0000_0001;
                        diag_state <= 8'd71;
                    end
                    8'd71: if (wb_status[1]) diag_state <= 8'd72;
                    8'd72: begin
                        diag_count <= diag_count + 1'd1;
                        diag_status <= (diag_error_count == 32'd0) ? 8'h02 : 8'h03;
                        diag_active <= 1'b0;
                    end
                    default: begin
                        diag_status <= 8'he0;
                        diag_error_count <= diag_error_count + 1'd1;
                        diag_active <= 1'b0;
                    end
                endcase
            end

            if (wb_done_pulse && diag_active) begin
                if (wb_status[2]) begin
                    diag_status <= 8'he1;
                    diag_error_count <= diag_error_count + 1'd1;
                    diag_active <= 1'b0;
                end else begin
                    case (diag_state)
                        8'd1: diag_state <= 8'd2;
                        8'd3: diag_state <= 8'd4;
                        8'd5: diag_state <= 8'd6;
                        8'd6: diag_state <= 8'd6;
                        8'd8: diag_state <= 8'd8;
                        8'd13: diag_state <= 8'd14;
                        8'd15: begin
                            wb_status <= 8'b0000_0010;
                            if (diag_actual == diag_expected) begin
                                diag_state <= 8'd20;
                            end else begin
                                diag_status <= 8'h03;
                                diag_error_count <= diag_error_count + 1'd1;
                                diag_count <= diag_count + 1'd1;
                                diag_active <= 1'b0;
                            end
                        end
                        8'd28: diag_state <= 8'd30;
                        8'd31: diag_state <= 8'd32;
                        8'd33: diag_state <= 8'd34;
                        8'd35: diag_state <= 8'd36;
                        8'd37: diag_state <= 8'd38;
                        8'd39: diag_state <= 8'd40;
                        8'd41: begin
                            if (diag_phase == 8'd3) begin
                                diag_state <= 8'd42;
                            end else begin
                                diag_phase <= diag_phase + 1'd1;
                                diag_state <= 8'd38;
                            end
                        end
                        8'd43: diag_state <= 8'd44;
                        8'd45: diag_state <= 8'd46;
                        8'd47: diag_state <= 8'd48;
                        8'd51: diag_state <= 8'd52;
                        8'd53: diag_state <= 8'd54;
                        8'd55: diag_state <= 8'd56;
                        8'd59: begin
                            diag_error_count <= diag_error_count + popcount32(wb_dat_r ^ pattern_hi(diag_phase[1:0]));
                            diag_state <= 8'd60;
                        end
                        8'd61: begin
                            diag_error_count <= diag_error_count + popcount32(wb_dat_r ^ pattern_lo(diag_phase[1:0]));
                            if (diag_phase == 8'd3) begin
                                diag_state <= 8'd62;
                            end else begin
                                diag_phase <= diag_phase + 1'd1;
                                diag_state <= 8'd58;
                            end
                        end
                        8'd63: diag_state <= 8'd64;
                        8'd65: diag_state <= 8'd66;
                        8'd67: diag_state <= 8'd68;
                        8'd71: diag_state <= 8'd72;
                        default: begin
                        end
                    endcase
                end
            end

            if (command_pending_sys) begin
                command_opcode_sys <= command_opcode_active;
                command_addr_sys <= command_addr_active;
                command_data_sys <= command_data_active;
                command_count <= command_count + 1'd1;
                last_opcode <= command_opcode_active;
                case (command_opcode_active)
                    OP_WRITE_SCRATCH: scratch <= command_data_active;
                    OP_CLEAR_SCRATCH: scratch <= 32'd0;
                    OP_CLEAR_PHY_SAMPLE: begin
                        ddr_dq_seen_high <= 32'd0;
                        ddr_dq_seen_low <= 32'd0;
                        ddr_dq_toggle_seen <= 32'd0;
                        ddr_phase_seen_high <= 32'd0;
                        ddr_phase_toggle_seen <= 32'd0;
                        ddr_phase_nonzero_seen <= 4'd0;
                        ddr_phase_nonzero_toggle_seen <= 4'd0;
                        ddr_dqs_p_seen_high <= 4'd0;
                        ddr_dqs_p_seen_low <= 4'd0;
                        ddr_dqs_p_toggle_seen <= 4'd0;
                        ddr_dqs_n_seen_high <= 4'd0;
                        ddr_dqs_n_seen_low <= 4'd0;
                        ddr_dqs_n_toggle_seen <= 4'd0;
                    end
                    OP_START_GEN:     generator_start <= 1'b1;
                    OP_START_CHECK:   checker_start <= 1'b1;
                    OP_RESET_BIST:    bist_reset <= 1'b1;
                    OP_SET_BASE:      bist_base <= command_data_active;
                    OP_SET_LENGTH:    bist_length <= command_data_active;
                    OP_SET_RANDOM: begin
                        bist_random_data <= command_data_active[0];
                        bist_random_addr <= command_data_active[1];
                    end
                    OP_WB_WRITE: begin
                        if (!wb_cyc && !diag_active) begin
                            wb_addr_byte <= command_addr_active;
                            wb_adr <= command_addr_active[31:2];
                            wb_dat_w <= command_data_active;
                            wb_cyc <= 1'b1;
                            wb_stb <= 1'b1;
                            wb_we <= 1'b1;
                            wb_is_read <= 1'b0;
                            wb_timeout_counter <= 20'd0;
                            wb_status <= 8'b0000_0001;
                        end
                    end
                    OP_WB_READ: begin
                        if (!wb_cyc && !diag_active) begin
                            wb_addr_byte <= command_addr_active;
                            wb_adr <= command_addr_active[31:2];
                            wb_dat_w <= 32'd0;
                            wb_cyc <= 1'b1;
                            wb_stb <= 1'b1;
                            wb_we <= 1'b0;
                            wb_is_read <= 1'b1;
                            wb_timeout_counter <= 20'd0;
                            wb_status <= 8'b0000_0001;
                        end
                    end
                    OP_APPLY_RDLY, OP_MEM32_CHECK, OP_DFII_PATTERN: begin
                        if (!wb_cyc && !diag_active) begin
                            diag_active <= 1'b1;
                            diag_opcode <= command_opcode_active;
                            diag_state <= 8'd0;
                            diag_module_mask <= command_data_active[7:0];
                            diag_bitslip_target <= command_data_active[15:8];
                            diag_delay_target <= command_data_active[23:16];
                            diag_bitslip_count <= 8'd0;
                            diag_delay_count <= 8'd0;
                            diag_addr <= command_addr_active;
                            diag_expected <= scratch;
                            diag_actual <= 32'd0;
                            diag_status <= 8'h01;
                        end
                    end
                    default: begin
                    end
                endcase
            end
        end
    end
endmodule

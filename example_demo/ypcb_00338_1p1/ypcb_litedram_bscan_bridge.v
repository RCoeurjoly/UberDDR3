// Raw BSCAN status/control bridge for YPCB LiteDRAM BIST experiments.
//
// USER1 (IR 0x02, JTAG_CHAIN=1) shifts out a 768-bit status payload.
// USER2 (IR 0x03, JTAG_CHAIN=2) shifts in a 128-bit command payload.

module ypcb_litedram_bscan_bridge #(
    parameter [31:0] BYTE_GROUP_MASK = 32'h0000000f
) (
    input  wire        sys_clk,
    input  wire        sys_rst,
    input  wire        clkin,
    input  wire        idelay_clk,
    input  wire        rst_n_raw,
    input  wire        pll_locked,

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

    localparam [31:0] CSR_DDRPHY_DLY_SEL             = 32'h00000804;
    localparam [31:0] CSR_DDRPHY_RDLY_DQ_RST         = 32'h00000814;
    localparam [31:0] CSR_DDRPHY_RDLY_DQ_INC         = 32'h00000818;
    localparam [31:0] CSR_DDRPHY_RDLY_DQ_BITSLIP_RST = 32'h0000081c;
    localparam [31:0] CSR_DDRPHY_RDLY_DQ_BITSLIP     = 32'h00000820;

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

    reg [767:0] read_shift_q;
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

    wire [767:0] read_payload = {
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
            read_shift_q <= {1'b0, read_shift_q[767:1]};
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
        end else begin
            counter <= counter + 1'd1;
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
                        diag_state <= (diag_opcode == OP_MEM32_CHECK) ? 8'd12 : 8'd20;
                    end
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
                    8'd20: begin
                        diag_count <= diag_count + 1'd1;
                        diag_status <= 8'h02;
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
                        default: begin
                        end
                    endcase
                end
            end

            if (command_toggle_sys[2] != command_toggle_sys[1]) begin
                command_opcode_sys <= command_opcode_tck;
                command_addr_sys <= command_addr_tck;
                command_data_sys <= command_data_tck;
                command_count <= command_count + 1'd1;
                last_opcode <= command_opcode_tck;
                case (command_opcode_tck)
                    OP_WRITE_SCRATCH: scratch <= command_data_tck;
                    OP_CLEAR_SCRATCH: scratch <= 32'd0;
                    OP_START_GEN:     generator_start <= 1'b1;
                    OP_START_CHECK:   checker_start <= 1'b1;
                    OP_RESET_BIST:    bist_reset <= 1'b1;
                    OP_SET_BASE:      bist_base <= command_data_tck;
                    OP_SET_LENGTH:    bist_length <= command_data_tck;
                    OP_SET_RANDOM: begin
                        bist_random_data <= command_data_tck[0];
                        bist_random_addr <= command_data_tck[1];
                    end
                    OP_WB_WRITE: begin
                        if (!wb_cyc && !diag_active) begin
                            wb_addr_byte <= command_addr_tck;
                            wb_adr <= command_addr_tck[31:2];
                            wb_dat_w <= command_data_tck;
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
                            wb_addr_byte <= command_addr_tck;
                            wb_adr <= command_addr_tck[31:2];
                            wb_dat_w <= 32'd0;
                            wb_cyc <= 1'b1;
                            wb_stb <= 1'b1;
                            wb_we <= 1'b0;
                            wb_is_read <= 1'b1;
                            wb_timeout_counter <= 20'd0;
                            wb_status <= 8'b0000_0001;
                        end
                    end
                    OP_APPLY_RDLY, OP_MEM32_CHECK: begin
                        if (!wb_cyc && !diag_active) begin
                            diag_active <= 1'b1;
                            diag_opcode <= command_opcode_tck;
                            diag_state <= 8'd0;
                            diag_module_mask <= command_data_tck[7:0];
                            diag_bitslip_target <= command_data_tck[15:8];
                            diag_delay_target <= command_data_tck[23:16];
                            diag_bitslip_count <= 8'd0;
                            diag_delay_count <= 8'd0;
                            diag_addr <= command_addr_tck;
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

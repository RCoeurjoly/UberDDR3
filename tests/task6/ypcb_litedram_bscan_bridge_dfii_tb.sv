`default_nettype none

module BSCANE2 #(
    parameter DISABLE_JTAG = "FALSE",
    parameter integer JTAG_CHAIN = 1
) (
    output wire CAPTURE,
    output wire DRCK,
    output wire RESET,
    output wire RUNTEST,
    output wire SEL,
    output wire SHIFT,
    output wire TCK,
    output wire TDI,
    output wire TMS,
    output wire UPDATE,
    input  wire TDO
);
    assign CAPTURE = 1'b0;
    assign DRCK = 1'b0;
    assign RESET = 1'b0;
    assign RUNTEST = 1'b0;
    assign SEL = 1'b0;
    assign SHIFT = 1'b0;
    assign TCK = 1'b0;
    assign TDI = 1'b0;
    assign TMS = 1'b0;
    assign UPDATE = 1'b0;
endmodule

module ypcb_litedram_bscan_bridge_dfii_tb;
    localparam [7:0] OP_DFII_PATTERN = 8'h42;

    localparam [31:0] CSR_SDRAM_DFII_CONTROL = 32'h00001800;
    localparam [31:0] CSR_SDRAM_DFII_BASE    = 32'h00001804;

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

    reg sys_clk = 1'b0;
    reg sys_rst = 1'b1;
    reg sim_command_valid = 1'b0;
    reg [7:0] sim_command_opcode = 8'd0;
    reg [31:0] sim_command_addr = 32'd0;
    reg [31:0] sim_command_data = 32'd0;
    reg [31:0] ddr_dq_sample = 32'hffff0000;
    reg [127:0] ddr_phase_sample = 128'h00000000_00000000_22220000_00001111;
    reg [3:0] ddr_dqs_p_sample = 4'h3;
    reg [3:0] ddr_dqs_n_sample = 4'hc;

    wire [29:0] wb_adr;
    wire [31:0] wb_dat_w;
    wire [31:0] wb_dat_r;
    wire [3:0] wb_sel;
    wire wb_cyc;
    wire wb_stb;
    wire wb_we;
    wire wb_ack;
    wire sim_diag_active;
    wire [7:0] sim_diag_status;
    wire [31:0] sim_diag_count;
    wire [31:0] sim_diag_error_count;

    wire bist_reset;
    wire generator_start;
    wire checker_start;
    wire [31:0] bist_base;
    wire [31:0] bist_length;
    wire bist_random_data;
    wire bist_random_addr;

    reg software_seen = 1'b0;
    reg hardware_seen_after_software = 1'b0;
    reg phase_command_before_software = 1'b0;
    reg saw_pattern_read = 1'b0;
    reg [31:0] cycles = 32'd0;

    assign wb_ack = wb_cyc;

    function [31:0] phase_reg;
        input [1:0] phase;
        input [7:0] offset;
        begin
            phase_reg = CSR_SDRAM_DFII_BASE + {28'd0, phase, 5'd0} + {24'd0, offset};
        end
    endfunction

    function [31:0] read_data_for_addr;
        input [29:0] word_addr;
        reg [31:0] byte_addr;
        begin
            byte_addr = {word_addr, 2'b00};
            case (byte_addr)
                phase_reg(2'd0, 8'h18): read_data_for_addr = DFII_PATTERN0_HI;
                phase_reg(2'd0, 8'h1c): read_data_for_addr = DFII_PATTERN0_LO;
                phase_reg(2'd1, 8'h18): read_data_for_addr = DFII_PATTERN1_HI;
                phase_reg(2'd1, 8'h1c): read_data_for_addr = DFII_PATTERN1_LO;
                phase_reg(2'd2, 8'h18): read_data_for_addr = DFII_PATTERN2_HI;
                phase_reg(2'd2, 8'h1c): read_data_for_addr = DFII_PATTERN2_LO;
                phase_reg(2'd3, 8'h18): read_data_for_addr = DFII_PATTERN3_HI;
                phase_reg(2'd3, 8'h1c): read_data_for_addr = DFII_PATTERN3_LO;
                default: read_data_for_addr = 32'd0;
            endcase
        end
    endfunction

    assign wb_dat_r = read_data_for_addr(wb_adr);

    always @(posedge sys_clk) begin
        cycles <= cycles + 1'd1;
        if (cycles == 32'd2) begin
            sys_rst <= 1'b0;
        end
        if (cycles == 32'd4) begin
            sim_command_valid <= 1'b1;
            sim_command_opcode <= OP_DFII_PATTERN;
            sim_command_addr <= 32'd0;
            sim_command_data <= 32'h00000001;
        end else begin
            sim_command_valid <= 1'b0;
        end
        ddr_dq_sample <= {ddr_dq_sample[30:0], ddr_dq_sample[31]};
        ddr_phase_sample <= {ddr_phase_sample[126:0], ddr_phase_sample[127]};
        ddr_dqs_p_sample <= {ddr_dqs_p_sample[2:0], ddr_dqs_p_sample[3]};
        ddr_dqs_n_sample <= {ddr_dqs_n_sample[2:0], ddr_dqs_n_sample[3]};
    end

    always @(posedge sys_clk) begin
        if (!sys_rst && wb_cyc && wb_stb && wb_we) begin
            if ({wb_adr, 2'b00} == CSR_SDRAM_DFII_CONTROL && wb_dat_w == DFII_CONTROL_SOFTWARE) begin
                software_seen <= 1'b1;
            end
            if ({wb_adr, 2'b00} == CSR_SDRAM_DFII_CONTROL && wb_dat_w == DFII_CONTROL_HARDWARE && software_seen) begin
                hardware_seen_after_software <= 1'b1;
            end
            if (!software_seen && {wb_adr, 2'b00} >= CSR_SDRAM_DFII_BASE && {wb_adr, 2'b00} < 32'h00001884) begin
                phase_command_before_software <= 1'b1;
            end
        end
        if (!sys_rst && wb_cyc && wb_stb && !wb_we && wb_dat_r != 32'd0) begin
            saw_pattern_read <= 1'b1;
        end

        if (phase_command_before_software) begin
            $display("FAIL: DFII phase CSR was accessed before software control");
            $finish_and_return(1);
        end
        if (sim_diag_count == 32'd1) begin
            if (!software_seen) begin
                $display("FAIL: DFII software control was not written");
                $finish_and_return(1);
            end
            if (!hardware_seen_after_software) begin
                $display("FAIL: DFII hardware control was not restored");
                $finish_and_return(1);
            end
            if (!saw_pattern_read) begin
                $display("FAIL: pattern readback was not observed");
                $finish_and_return(1);
            end
            if (sim_diag_count != 32'd1) begin
                $display("FAIL: diag_count=%0d", sim_diag_count);
                $finish_and_return(1);
            end
            if (sim_diag_status != 8'h02) begin
                $display("FAIL: diag_status=0x%02x", sim_diag_status);
                $finish_and_return(1);
            end
            if (sim_diag_error_count != 32'd0) begin
                $display("FAIL: diag_error_count=%0d", sim_diag_error_count);
                $finish_and_return(1);
            end
            if (sim_diag_active) begin
                $display("FAIL: diagnostic still active");
                $finish_and_return(1);
            end
            $display("PASS: bridge-local DFII pattern diagnostic sequence");
            $finish;
        end
        if (cycles > 32'd600) begin
            $display("FAIL: diagnostic did not complete");
            $finish_and_return(1);
        end
    end

    always #1 sys_clk = ~sys_clk;

    ypcb_litedram_bscan_bridge #(
        .BYTE_GROUP_MASK(32'h0000000f),
        .RDPHASE(2'd2),
        .WRPHASE(2'd3)
    ) dut (
        .sys_clk(sys_clk),
        .sys_rst(sys_rst),
        .clkin(sys_clk),
        .idelay_clk(sys_clk),
        .rst_n_raw(1'b1),
        .pll_locked(1'b1),
        .ddr_dq_sample(ddr_dq_sample),
        .ddr_phase_sample(ddr_phase_sample),
        .ddr_dqs_p_sample(ddr_dqs_p_sample),
        .ddr_dqs_n_sample(ddr_dqs_n_sample),
        .generator_done(1'b0),
        .generator_ticks(32'd0),
        .checker_done(1'b0),
        .checker_ticks(32'd0),
        .checker_errors(32'd0),
        .bist_reset(bist_reset),
        .generator_start(generator_start),
        .checker_start(checker_start),
        .bist_base(bist_base),
        .bist_length(bist_length),
        .bist_random_data(bist_random_data),
        .bist_random_addr(bist_random_addr),
        .wb_adr(wb_adr),
        .wb_dat_w(wb_dat_w),
        .wb_dat_r(wb_dat_r),
        .wb_sel(wb_sel),
        .wb_cyc(wb_cyc),
        .wb_stb(wb_stb),
        .wb_we(wb_we),
        .wb_ack(wb_ack),
        .wb_err(1'b0),
        .sim_command_valid(sim_command_valid),
        .sim_command_opcode(sim_command_opcode),
        .sim_command_addr(sim_command_addr),
        .sim_command_data(sim_command_data),
        .sim_diag_active(sim_diag_active),
        .sim_diag_status(sim_diag_status),
        .sim_diag_count(sim_diag_count),
        .sim_diag_error_count(sim_diag_error_count)
    );
endmodule

`default_nettype wire

`timescale 1ps / 1ps
`default_nettype none

module ypcb_rtl_init_tb;
`include "sim_defines.vh"

`ifdef den1024Mb
    `include "1024Mb_ddr3_parameters.vh"
`elsif den2048Mb
    `include "2048Mb_ddr3_parameters.vh"
`elsif den4096Mb
    `include "4096Mb_ddr3_parameters.vh"
`elsif den8192Mb
    `include "8192Mb_ddr3_parameters.vh"
`else
    ERROR: You must specify component density with +define+den____Mb.
`endif

    localparam integer CONTROLLER_CLK_PERIOD = 12_000;
    localparam integer DDR3_CLK_PERIOD = 3_000;
    localparam integer BYTE_LANES = 2;
    localparam integer AUX_WIDTH = 4;
    localparam integer WB_DATA_BITS = 8 * BYTE_LANES * 4 * 2;
    localparam integer WB_SEL_BITS = WB_DATA_BITS / 8;
    localparam integer WB_ADDR_BITS = 15 + 10 + 3 - 3;
    localparam integer INIT_TIMEOUT_CYCLES = 2_000_000;

    reg i_controller_clk = 1'b1;
    reg i_ddr3_clk = 1'b1;
    reg i_ref_clk = 1'b1;
    reg i_ddr3_clk_90 = 1'b1;
    reg i_rst_n = 1'b0;

    wire [0:0] ck_en;
    wire [0:0] cs_n;
    wire [0:0] odt;
    wire ras_n;
    wire cas_n;
    wire we_n;
    wire reset_n;
    wire [14:0] addr;
    wire [2:0] ba_addr;
    wire [BYTE_LANES-1:0] ddr3_dm;
    wire [(8*BYTE_LANES)-1:0] dq;
    wire [BYTE_LANES-1:0] dqs;
    wire [BYTE_LANES-1:0] dqs_n;
    wire [0:0] ddr3_clk_p;
    wire [0:0] ddr3_clk_n;
    wire calib_complete;
    wire [31:0] debug1;
    wire [63:0] bist_counts;

    wire [4:0] instruction_address = dut.ddr3_controller_inst.instruction_address;
    wire [4:0] instruction_address_d = dut.ddr3_controller_inst.instruction_address_d;
    wire [27:0] instruction = dut.ddr3_controller_inst.instruction;
    wire [18:0] delay_counter = dut.ddr3_controller_inst.delay_counter;
    wire delay_counter_is_zero = dut.ddr3_controller_inst.delay_counter_is_zero;
    wire init_advance_now = dut.ddr3_controller_inst.init_advance_now;
    wire init_advance_pending = dut.ddr3_controller_inst.init_advance_pending;
    wire init_advance_ready_q = dut.ddr3_controller_inst.init_advance_ready_q;
    wire [1:0] init_timer_phase = dut.ddr3_controller_inst.init_timer_phase;
    wire init_calib_start_now = dut.ddr3_controller_inst.init_calib_start_now;
    wire init_calib_start_q = dut.ddr3_controller_inst.init_calib_start_q;
    wire reset_done = dut.ddr3_controller_inst.reset_done;
    wire sync_rst_controller = dut.ddr3_controller_inst.sync_rst_controller;
    wire o_phy_reset = dut.ddr3_controller_inst.o_phy_reset;
    wire i_phy_idelayctrl_rdy = dut.ddr3_controller_inst.i_phy_idelayctrl_rdy;
    wire [4:0] state_calibrate = dut.ddr3_controller_inst.state_calibrate;
    wire pause_counter = dut.ddr3_controller_inst.pause_counter;

    reg [4:0] last_instruction_address = 5'h1f;
    reg [4:0] last_state_calibrate = 5'h1f;
    reg last_reset_done = 1'b0;
    reg last_init_advance_now = 1'b0;
    reg last_init_advance_pending = 1'b0;
    reg last_init_advance_ready_q = 1'b0;
    reg last_init_calib_start_now = 1'b0;
    reg last_init_calib_start_q = 1'b0;
    reg last_delay_counter_is_zero = 1'b0;
    integer controller_cycles = 0;

    always #(CONTROLLER_CLK_PERIOD/2) i_controller_clk = !i_controller_clk;
    always #(DDR3_CLK_PERIOD/2) i_ddr3_clk = !i_ddr3_clk;
    always #2500 i_ref_clk = !i_ref_clk;

    initial begin
        #(DDR3_CLK_PERIOD/4);
        forever #(DDR3_CLK_PERIOD/2) i_ddr3_clk_90 = !i_ddr3_clk_90;
    end

    ddr3_top #(
        .CONTROLLER_CLK_PERIOD(CONTROLLER_CLK_PERIOD),
        .DDR3_CLK_PERIOD(DDR3_CLK_PERIOD),
        .ROW_BITS(15),
        .COL_BITS(10),
        .BA_BITS(3),
        .BYTE_LANES(BYTE_LANES),
        .AUX_WIDTH(AUX_WIDTH),
        .WB2_ADDR_BITS(32),
        .WB2_DATA_BITS(32),
        .DUAL_RANK_DIMM(0),
        .MICRON_SIM(1),
        .ODELAY_SUPPORTED(0),
        .SECOND_WISHBONE(0),
        .DLL_OFF(0),
        .WB_ERROR(0),
        .BIST_MODE(0),
        .BIST_TEST_DATAMASK(1'b0),
        .ECC_ENABLE(0),
        .SPEED_BIN(1),
        .SDRAM_CAPACITY(4)
    ) dut (
        .i_controller_clk(i_controller_clk),
        .i_ddr3_clk(i_ddr3_clk),
        .i_ref_clk(i_ref_clk),
        .i_ddr3_clk_90(i_ddr3_clk_90),
        .i_rst_n(i_rst_n),
        .i_wb_cyc(1'b1),
        .i_wb_stb(1'b0),
        .i_wb_we(1'b0),
        .i_wb_addr({WB_ADDR_BITS{1'b0}}),
        .i_wb_data({WB_DATA_BITS{1'b0}}),
        .i_wb_sel({WB_SEL_BITS{1'b1}}),
        .i_aux({AUX_WIDTH{1'b0}}),
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
        .o_ddr3_clk_p(ddr3_clk_p),
        .o_ddr3_clk_n(ddr3_clk_n),
        .o_ddr3_cke(ck_en),
        .o_ddr3_cs_n(cs_n),
        .o_ddr3_odt(odt),
        .o_ddr3_ras_n(ras_n),
        .o_ddr3_cas_n(cas_n),
        .o_ddr3_we_n(we_n),
        .o_ddr3_reset_n(reset_n),
        .o_ddr3_addr(addr),
        .o_ddr3_ba_addr(ba_addr),
        .io_ddr3_dq(dq),
        .io_ddr3_dqs(dqs),
        .io_ddr3_dqs_n(dqs_n),
        .o_ddr3_dm(ddr3_dm),
        .o_calib_complete(calib_complete),
        .o_debug1(debug1),
        .o_debug8(),
        .o_bist_counts(bist_counts),
        .o_calib_debug(),
        .o_init_reset_debug(),
        .o_init_seq_debug(),
        .o_bist_debug(),
        .o_panopticon_debug(),
        .i_user_self_refresh(1'b0),
        .uart_tx()
    );

    ddr3 #(.DLL_OFF(0)) dram (
        .rst_n(reset_n),
        .ck(ddr3_clk_p[0]),
        .ck_n(ddr3_clk_n[0]),
        .cke(ck_en[0]),
        .cs_n(cs_n[0]),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .dm_tdqs(ddr3_dm),
        .ba(ba_addr),
        .addr(addr),
        .dq(dq),
        .dqs(dqs),
        .dqs_n(dqs_n),
        .tdqs_n(),
        .odt(odt[0])
    );

    function [8*24-1:0] ddr3_cmd_name;
        input [2:0] cmd;
        begin
            case (cmd)
                3'b000: ddr3_cmd_name = "MRS";
                3'b001: ddr3_cmd_name = "REF";
                3'b010: ddr3_cmd_name = "PRE";
                3'b011: ddr3_cmd_name = "ACT";
                3'b100: ddr3_cmd_name = "WR";
                3'b101: ddr3_cmd_name = "RD";
                3'b110: ddr3_cmd_name = "ZQC";
                3'b111: ddr3_cmd_name = "NOP";
                default: ddr3_cmd_name = "UNKNOWN";
            endcase
        end
    endfunction

    function [8*28-1:0] calib_state_name;
        input [4:0] state;
        begin
            case (state)
                5'd0: calib_state_name = "IDLE";
                5'd1: calib_state_name = "BITSLIP_DQS_TRAIN_1";
                5'd2: calib_state_name = "MPR_READ";
                5'd3: calib_state_name = "COLLECT_DQS";
                5'd4: calib_state_name = "ANALYZE_DQS";
                5'd5: calib_state_name = "CALIBRATE_DQS";
                5'd6: calib_state_name = "BITSLIP_DQS_TRAIN_2";
                5'd7: calib_state_name = "START_WRITE_LEVEL";
                5'd8: calib_state_name = "WAIT_FOR_FEEDBACK";
                5'd9: calib_state_name = "ISSUE_WRITE_1";
                5'd10: calib_state_name = "ISSUE_WRITE_2";
                5'd11: calib_state_name = "READ_LEVEL";
                5'd12: calib_state_name = "ANALYZE_DATA";
                5'd13: calib_state_name = "CALIBRATE_READ";
                5'd14: calib_state_name = "WRITE_CHECK";
                5'd15: calib_state_name = "ANALYZE_WRITE";
                5'd16: calib_state_name = "CALIBRATE_WRITE";
                5'd17: calib_state_name = "READ_CHECK";
                5'd18: calib_state_name = "ISSUE_FINAL_WRITE";
                5'd19: calib_state_name = "FINAL_READ";
                5'd20: calib_state_name = "ANALYZE_FINAL";
                5'd21: calib_state_name = "FINAL_WRITE_CALIBRATE";
                5'd22: calib_state_name = "FINAL_READ_CALIBRATE";
                5'd23: calib_state_name = "DONE_CALIBRATE";
                5'd24: calib_state_name = "ANALYZE_DATA_LOW_FREQ";
                5'd25: calib_state_name = "ANALYZE_DATA_PREP";
                default: calib_state_name = "UNKNOWN";
            endcase
        end
    endfunction

    task print_init_trace;
        input [8*16-1:0] tag;
        begin
            $display("INIT_TRACE tag=%0s t=%0t cycles=%0d addr=%0d addr_d=%0d state=%0d(%0s) reset_done=%b sync_rst=%b phy_reset=%b idelayctrl_rdy=%b phase=%0d delay_counter=%0d delay_zero=%b adv_now=%b adv_pending=%b adv_ready=%b calib_start_now=%b calib_start_q=%b pause=%b instr=%h use_timer=%b rst_done_bit=%b cmd=%0s cke=%b reset_n=%b odt=%b cs_n=%b ras_n=%b cas_n=%b we_n=%b ba=%h ddr_addr=%h",
                tag, $time, controller_cycles, instruction_address, instruction_address_d,
                state_calibrate, calib_state_name(state_calibrate), reset_done,
                sync_rst_controller, o_phy_reset, i_phy_idelayctrl_rdy, init_timer_phase,
                delay_counter, delay_counter_is_zero, init_advance_now, init_advance_pending,
                init_advance_ready_q, init_calib_start_now, init_calib_start_q, pause_counter,
                instruction, instruction[26], instruction[27], ddr3_cmd_name({ras_n, cas_n, we_n}),
                ck_en[0], reset_n, odt[0], cs_n[0], ras_n, cas_n, we_n, ba_addr, addr);
        end
    endtask

    initial begin
        $display("YPCB RTL init simulation starting");
        repeat (4) @(posedge i_controller_clk);
        i_rst_n <= 1'b1;
    end

    always @(posedge i_controller_clk) begin
        controller_cycles <= controller_cycles + 1;

        if ((instruction_address !== last_instruction_address) ||
            (state_calibrate !== last_state_calibrate) ||
            (reset_done !== last_reset_done) ||
            (init_advance_now !== last_init_advance_now) ||
            (init_advance_pending !== last_init_advance_pending) ||
            (init_advance_ready_q !== last_init_advance_ready_q) ||
            (init_calib_start_now !== last_init_calib_start_now) ||
            (init_calib_start_q !== last_init_calib_start_q) ||
            (delay_counter_is_zero !== last_delay_counter_is_zero)) begin
            print_init_trace("event");
        end

        last_instruction_address <= instruction_address;
        last_state_calibrate <= state_calibrate;
        last_reset_done <= reset_done;
        last_init_advance_now <= init_advance_now;
        last_init_advance_pending <= init_advance_pending;
        last_init_advance_ready_q <= init_advance_ready_q;
        last_init_calib_start_now <= init_calib_start_now;
        last_init_calib_start_q <= init_calib_start_q;
        last_delay_counter_is_zero <= delay_counter_is_zero;

        if ((instruction_address == 5'd13) && (state_calibrate != 5'd0)) begin
            print_init_trace("success");
            $display("INIT_SUCCESS reached_instruction_13_and_calibration_started");
            $finish;
        end

        if (controller_cycles >= INIT_TIMEOUT_CYCLES) begin
            print_init_trace("timeout");
            $display("INIT_TIMEOUT did_not_reach_instruction_13_calibration_start");
            $finish;
        end
    end
endmodule

`default_nettype wire

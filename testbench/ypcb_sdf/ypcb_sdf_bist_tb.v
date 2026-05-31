`default_nettype none
`timescale 1ps / 1ps

module ypcb_sdf_bist_tb;
`include "sim_defines.vh"

    localparam integer GATE_SIM_TIMEOUT_CYCLES = 62000;
    localparam integer FAST_INIT_MAX_DELAY = 32;

    reg clk50 = 1'b0;
    reg rst_n = 1'b0;
    reg sim_controller_clk = 1'b1;
    reg sim_ddr3_clk = 1'b1;
    reg sim_ref_clk = 1'b1;
    reg sim_ddr3_clk_90 = 1'b1;

    wire [0:0] ddr3_ck_p;
    wire [0:0] ddr3_ck_n;
    wire ddr3_reset_n;
    wire [0:0] ddr3_cke;
    wire [0:0] ddr3_cs_n;
    wire ddr3_ras_n;
    wire ddr3_cas_n;
    wire ddr3_we_n;
    wire [14:0] ddr3_addr;
    wire [2:0] ddr3_ba;
    wire [63:0] ddr3_dq;
    wire [7:0] ddr3_dqs_p;
    wire [7:0] ddr3_dqs_n;
    wire [0:0] ddr3_odt;
    wire [2:0] led;

    ypcb_00338_1p1_ddr3 dut (
        .clk50(clk50),
        .rst_n(rst_n),
        .ddr3_ck_p(ddr3_ck_p),
        .ddr3_ck_n(ddr3_ck_n),
        .ddr3_reset_n(ddr3_reset_n),
        .ddr3_cke(ddr3_cke),
        .ddr3_cs_n(ddr3_cs_n),
        .ddr3_ras_n(ddr3_ras_n),
        .ddr3_cas_n(ddr3_cas_n),
        .ddr3_we_n(ddr3_we_n),
        .ddr3_addr(ddr3_addr),
        .ddr3_ba(ddr3_ba),
        .ddr3_dq(ddr3_dq),
        .ddr3_dqs_p(ddr3_dqs_p),
        .ddr3_dqs_n(ddr3_dqs_n),
        .ddr3_odt(ddr3_odt),
        .led(led)
    );

    localparam integer CMD_ADDR_START = 0;
    localparam integer CMD_BANK_START = 15;
    localparam integer CMD_RESET_N = 18;
    localparam integer CMD_CKE = 19;
    localparam integer CMD_ODT = 20;
    localparam integer CMD_WE_N = 21;
    localparam integer CMD_CAS_N = 22;
    localparam integer CMD_RAS_N = 23;
    localparam integer CMD_CS_N = 24;

    wire [99:0] model_controller_cmd = dut.\ddr3_top_inst.ddr3_phy_inst.i_controller_cmd ;
    reg [1:0] model_cmd_slot = 2'd0;
    wire [24:0] selected_model_cmd_word =
        (model_cmd_slot == 2'd0) ? model_controller_cmd[24:0] :
        (model_cmd_slot == 2'd1) ? model_controller_cmd[49:25] :
        (model_cmd_slot == 2'd2) ? model_controller_cmd[74:50] :
                                   model_controller_cmd[99:75];
    reg [24:0] model_cmd_word = 25'h1e00000;
    wire [14:0] model_ddr3_addr = model_cmd_word[CMD_BANK_START-1:CMD_ADDR_START];
    wire [2:0] model_ddr3_ba = model_cmd_word[CMD_RESET_N-1:CMD_BANK_START];
    wire model_ddr3_reset_n = model_cmd_word[CMD_RESET_N];
    wire model_ddr3_cke = model_cmd_word[CMD_CKE];
    wire model_ddr3_odt = model_cmd_word[CMD_ODT];
    wire model_ddr3_we_n = model_cmd_word[CMD_WE_N];
    wire model_ddr3_cas_n = model_cmd_word[CMD_CAS_N];
    wire model_ddr3_ras_n = model_cmd_word[CMD_RAS_N];
    wire model_ddr3_cs_n = model_cmd_word[CMD_CS_N];

    ddr3 #(.DLL_OFF(0)) ddr3_model (
        .rst_n(model_ddr3_reset_n),
        .ck(sim_ddr3_clk),
        .ck_n(!sim_ddr3_clk),
        .cke(model_ddr3_cke),
        .cs_n(model_ddr3_cs_n),
        .ras_n(model_ddr3_ras_n),
        .cas_n(model_ddr3_cas_n),
        .we_n(model_ddr3_we_n),
        .dm_tdqs(2'b00),
        .ba(model_ddr3_ba),
        .addr({1'b0, model_ddr3_addr}),
        .dq(ddr3_dq[15:0]),
        .dqs(ddr3_dqs_p[1:0]),
        .dqs_n(ddr3_dqs_n[1:0]),
        .tdqs_n(),
        .odt(model_ddr3_odt)
    );

    wire [4:0] gate_state_calibrate = dut.\ddr3_top_inst.ddr3_controller_inst.state_calibrate ;
    wire [39:0] gate_dqs_store = dut.\ddr3_top_inst.ddr3_controller_inst.dqs_store ;
    wire [2:0] gate_dqs_count_repeat = dut.\ddr3_top_inst.ddr3_controller_inst.dqs_count_repeat ;
    wire [5:0] gate_dqs_start_index = dut.\ddr3_top_inst.ddr3_controller_inst.dqs_start_index ;
    wire [5:0] gate_dqs_start_index_stored = dut.\ddr3_top_inst.ddr3_controller_inst.dqs_start_index_stored ;
    wire gate_dqs_start_index_repeat = dut.\ddr3_top_inst.ddr3_controller_inst.dqs_start_index_repeat ;
    wire [5:0] gate_dqs_target_index = dut.\ddr3_top_inst.ddr3_controller_inst.dqs_target_index ;
    wire [5:0] gate_dqs_target_index_orig = dut.\ddr3_top_inst.ddr3_controller_inst.dqs_target_index_orig ;
    wire [5:0] gate_dqs_target_index_value = dut.\ddr3_top_inst.ddr3_controller_inst.dqs_target_index_value ;
    wire [15:0] gate_iserdes_dqs = dut.\ddr3_top_inst.ddr3_controller_inst.i_phy_iserdes_dqs ;
    wire [15:0] gate_iserdes_bitslip_reference = dut.\ddr3_top_inst.ddr3_controller_inst.i_phy_iserdes_bitslip_reference ;
    wire gate_lane = dut.\ddr3_top_inst.ddr3_controller_inst.lane ;
    wire [1:0] gate_lane_read_dq_early = dut.\ddr3_top_inst.ddr3_controller_inst.lane_read_dq_early ;
    wire [1:0] gate_lane_write_dq_late = dut.\ddr3_top_inst.ddr3_controller_inst.lane_write_dq_late ;
    wire [1:0] gate_bitslip = dut.\ddr3_top_inst.ddr3_controller_inst.o_phy_bitslip ;
    wire [4:0] gate_idelay_dqs_cntvaluein = dut.\ddr3_top_inst.ddr3_controller_inst.o_phy_idelay_dqs_cntvaluein ;
    wire [1:0] gate_idelay_dqs_ld = dut.\ddr3_top_inst.ddr3_controller_inst.o_phy_idelay_dqs_ld ;
    wire [4:0] gate_idelay_dqs_cntvaluein_lane0 = dut.\ddr3_top_inst.ddr3_controller_inst.idelay_dqs_cntvaluein[0] ;
    wire [4:0] gate_idelay_dqs_cntvaluein_lane1 = dut.\ddr3_top_inst.ddr3_controller_inst.idelay_dqs_cntvaluein[1] ;
    wire [63:0] gate_read_lane_data = dut.\ddr3_top_inst.ddr3_controller_inst.read_lane_data ;
    wire [31:0] gate_read_lane_data_shifted = dut.\ddr3_top_inst.ddr3_controller_inst.read_lane_data_shifted ;
    wire [1:0] gate_top_io_ddr3_dqs = dut.\ddr3_top_inst.io_ddr3_dqs ;
    wire [1:0] gate_top_io_ddr3_dqs_n = dut.\ddr3_top_inst.io_ddr3_dqs_n ;
    wire [1:0] gate_phy_io_ddr3_dqs = dut.\ddr3_top_inst.ddr3_phy_inst.io_ddr3_dqs ;
    wire [1:0] gate_phy_io_ddr3_dqs_n = dut.\ddr3_top_inst.ddr3_phy_inst.io_ddr3_dqs_n ;
    wire [1:0] gate_phy_idelay_dqs = dut.\ddr3_top_inst.ddr3_phy_inst.idelay_dqs ;
    wire [15:0] gate_top_iserdes_dqs = dut.\ddr3_top_inst.iserdes_dqs ;
    wire [4:0] gate_instruction_address = dut.\ddr3_top_inst.ddr3_controller_inst.instruction_address ;
    wire [18:0] gate_delay_counter = dut.\ddr3_top_inst.ddr3_controller_inst.delay_counter ;
    wire gate_delay_counter_is_zero = dut.\ddr3_top_inst.ddr3_controller_inst.delay_counter_is_zero ;
    wire gate_pause_counter = dut.\ddr3_top_inst.ddr3_controller_inst.pause_counter ;
    wire gate_i_rst_n = dut.\ddr3_top_inst.ddr3_controller_inst.i_rst_n ;
    wire gate_o_phy_reset = dut.\ddr3_top_inst.ddr3_controller_inst.o_phy_reset ;
    wire gate_i_phy_idelayctrl_rdy = dut.\ddr3_top_inst.ddr3_controller_inst.i_phy_idelayctrl_rdy ;
    wire [27:0] gate_instruction = dut.\ddr3_top_inst.ddr3_controller_inst.instruction ;
    reg sim_dqs_inject = 1'b0;

    always #10000 clk50 = !clk50;
    always #6000 sim_controller_clk = !sim_controller_clk;
    always #1500 sim_ddr3_clk = !sim_ddr3_clk;
    always #2500 sim_ref_clk = !sim_ref_clk;

    initial begin
        #750;
        forever #1500 sim_ddr3_clk_90 = !sim_ddr3_clk_90;
    end

    initial begin
        force dut.\ddr3_top_inst.i_controller_clk  = sim_controller_clk;
        force dut.\ddr3_top_inst.i_ddr3_clk  = sim_ddr3_clk;
        force dut.\ddr3_top_inst.i_ddr3_clk_90  = sim_ddr3_clk_90;
        force dut.\ddr3_top_inst.i_ref_clk  = sim_ref_clk;
        force dut.ref_clk = sim_ref_clk;
        force dut.\clk_wiz_inst.locked  = 1'b1;
    end

    always @(negedge sim_ddr3_clk) begin
        model_cmd_word <= selected_model_cmd_word;
        model_cmd_slot <= model_cmd_slot + 2'd1;
    end

    initial begin
        if ($test$plusargs("sdf")) begin
            $display("Annotating SDF: ypcb_00338_1p1_ddr3.sdf");
            $sdf_annotate("ypcb_00338_1p1_ddr3.sdf", dut);
        end
        if ($test$plusargs("fast_init")) begin
            $display("FAST_INIT enabled: forcing long reset-ROM delays down to %0d controller cycles", FAST_INIT_MAX_DELAY);
        end

        repeat (20) @(posedge clk50);
        rst_n <= 1'b1;
    end

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
                default: calib_state_name = "UNKNOWN";
            endcase
        end
    endfunction

    task print_status;
        input [8*16-1:0] tag;
        begin
            $display("%0s t=%0t led=%b calib_complete=%b bist_done=%b state_calibrate=%0d(%0s) debug1=%h bist_counts=%h",
                tag,
                $time,
                led,
                dut.calib_complete,
                dut.bist_done,
                gate_state_calibrate,
                calib_state_name(gate_state_calibrate),
                dut.debug1,
                dut.bist_counts);
        end
    endtask

    task print_calib_detail;
        input [8*16-1:0] tag;
        begin
            print_status(tag);
            $display("%0s_DETAIL t=%0t lane=%0d bitslip=%b idelay_ld=%b idelay_cnt=%0d lane_cnt0=%0d lane_cnt1=%0d lane_read_early=%b lane_write_late=%b",
                tag,
                $time,
                gate_lane,
                gate_bitslip,
                gate_idelay_dqs_ld,
                gate_idelay_dqs_cntvaluein,
                gate_idelay_dqs_cntvaluein_lane0,
                gate_idelay_dqs_cntvaluein_lane1,
                gate_lane_read_dq_early,
                gate_lane_write_dq_late);
            $display("%0s_DQS t=%0t dqs_store=%h dqs_count_repeat=%0d start=%0d stored=%0d repeat=%b target=%0d target_value=%0d target_orig=%0d",
                tag,
                $time,
                gate_dqs_store,
                gate_dqs_count_repeat,
                gate_dqs_start_index,
                gate_dqs_start_index_stored,
                gate_dqs_start_index_repeat,
                gate_dqs_target_index,
                gate_dqs_target_index_value,
                gate_dqs_target_index_orig);
            $display("%0s_BOUNDARY t=%0t ext_dqs_p=%b ext_dqs_n=%b top_io_dqs=%b top_io_dqs_n=%b phy_io_dqs=%b phy_io_dqs_n=%b phy_idelay_dqs=%b top_iserdes_dqs=%h ctrl_iserdes_dqs=%h",
                tag,
                $time,
                ddr3_dqs_p[1:0],
                ddr3_dqs_n[1:0],
                gate_top_io_ddr3_dqs,
                gate_top_io_ddr3_dqs_n,
                gate_phy_io_ddr3_dqs,
                gate_phy_io_ddr3_dqs_n,
                gate_phy_idelay_dqs,
                gate_top_iserdes_dqs,
                gate_iserdes_dqs);
            $display("%0s_READ t=%0t iserdes_dqs=%h bitslip_ref=%h read_lane_data=%h read_lane_data_shifted=%h",
                tag,
                $time,
                gate_iserdes_dqs,
                gate_iserdes_bitslip_reference,
                gate_read_lane_data,
                gate_read_lane_data_shifted);
            $display("%0s_INIT t=%0t instr_addr=%0d delay_counter=%0d delay_zero=%b pause=%b i_rst_n=%b o_phy_reset=%b idelayctrl_rdy=%b instruction=%h",
                tag,
                $time,
                gate_instruction_address,
                gate_delay_counter,
                gate_delay_counter_is_zero,
                gate_pause_counter,
                gate_i_rst_n,
                gate_o_phy_reset,
                gate_i_phy_idelayctrl_rdy,
                gate_instruction);
        end
    endtask

    initial begin
        repeat (GATE_SIM_TIMEOUT_CYCLES) @(posedge clk50);
        print_calib_detail("TIMEOUT");
        $finish;
    end


    function [8*12-1:0] ddr3_cmd_name;
        input cs_n;
        input ras_n;
        input cas_n;
        input we_n;
        begin
            if (cs_n !== 1'b0) ddr3_cmd_name = "DES/NOP";
            else begin
                case ({ras_n, cas_n, we_n})
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
        end
    endfunction

    time model_mr0_dll_reset_time = 0;
    integer model_active_cmd_count = 0;

    always @(posedge sim_ddr3_clk) begin
        if (model_ddr3_cs_n === 1'b0 &&
            {model_ddr3_ras_n, model_ddr3_cas_n, model_ddr3_we_n} !== 3'b111 &&
            model_active_cmd_count < 256) begin
            if ({model_ddr3_ras_n, model_ddr3_cas_n, model_ddr3_we_n} == 3'b000 && model_ddr3_ba == 3'b000 && model_ddr3_addr[8]) begin
                model_mr0_dll_reset_time = $time;
            end
            $display("MODEL_SAMPLE t=%0t slot=%0d cmd=%0s ba=%b addr=%h odt=%b cke=%b reset_n=%b since_mr0_ps=%0t instr_addr=%0d delay_counter=%0d delay_zero=%b state_calibrate=%0d",
                $time,
                model_cmd_slot,
                ddr3_cmd_name(model_ddr3_cs_n, model_ddr3_ras_n, model_ddr3_cas_n, model_ddr3_we_n),
                model_ddr3_ba,
                model_ddr3_addr,
                model_ddr3_odt,
                model_ddr3_cke,
                model_ddr3_reset_n,
                (model_mr0_dll_reset_time == 0) ? 0 : ($time - model_mr0_dll_reset_time),
                gate_instruction_address,
                gate_delay_counter,
                gate_delay_counter_is_zero,
                gate_state_calibrate);
            model_active_cmd_count = model_active_cmd_count + 1;
        end
    end

    task print_ddr3_command;
        input [8*16-1:0] tag;
        begin
            $display("%0s_CMD t=%0t ck=%b cke=%b cs_n=%b ras_n=%b cas_n=%b we_n=%b ba=%b addr=%h odt=%b reset_n=%b",
                tag,
                $time,
                ddr3_ck_p,
                ddr3_cke,
                ddr3_cs_n,
                ddr3_ras_n,
                ddr3_cas_n,
                ddr3_we_n,
                ddr3_ba,
                ddr3_addr,
                ddr3_odt,
                ddr3_reset_n);
            $display("%0s_MODEL_CMD t=%0t slot=%0d ck=%b cke=%b cs_n=%b ras_n=%b cas_n=%b we_n=%b ba=%b addr=%h odt=%b reset_n=%b word=%h",
                tag,
                $time,
                model_cmd_slot,
                sim_ddr3_clk,
                model_ddr3_cke,
                model_ddr3_cs_n,
                model_ddr3_ras_n,
                model_ddr3_cas_n,
                model_ddr3_we_n,
                model_ddr3_ba,
                model_ddr3_addr,
                model_ddr3_odt,
                model_ddr3_reset_n,
                model_cmd_word);
        end
    endtask

    reg [2:0] last_led = 3'bxxx;
    reg last_calib_complete = 1'bx;
    reg last_bist_done = 1'bx;
    reg [4:0] last_state_calibrate = 5'bxxxxx;
    reg [4:0] last_instruction_address = 5'bxxxxx;
    reg last_i_rst_n = 1'bx;
    reg last_o_phy_reset = 1'bx;
    reg last_i_phy_idelayctrl_rdy = 1'bx;
    reg [9:0] analyze_dqs_print_div = 10'd0;
    reg [7:0] early_status_div = 8'd0;
    reg last_ddr3_cs_n = 1'bx;
    reg last_ddr3_ras_n = 1'bx;
    reg last_ddr3_cas_n = 1'bx;
    reg last_ddr3_we_n = 1'bx;
    reg [2:0] last_ddr3_ba = 3'bxxx;
    reg [14:0] last_ddr3_addr = 15'hxxxx;
    integer command_print_count = 0;

    always @(posedge ddr3_ck_p[0]) begin
        if ((ddr3_cs_n[0] !== last_ddr3_cs_n ||
             ddr3_ras_n !== last_ddr3_ras_n ||
             ddr3_cas_n !== last_ddr3_cas_n ||
             ddr3_we_n !== last_ddr3_we_n ||
             ddr3_ba !== last_ddr3_ba ||
             ddr3_addr !== last_ddr3_addr) && command_print_count < 200) begin
            print_ddr3_command("CMD_CHANGE");
            command_print_count = command_print_count + 1;
            last_ddr3_cs_n <= ddr3_cs_n[0];
            last_ddr3_ras_n <= ddr3_ras_n;
            last_ddr3_cas_n <= ddr3_cas_n;
            last_ddr3_we_n <= ddr3_we_n;
            last_ddr3_ba <= ddr3_ba;
            last_ddr3_addr <= ddr3_addr;
        end
    end

    always @(posedge sim_ddr3_clk) begin
        sim_dqs_inject <= !sim_dqs_inject;
    end

    always @* begin
        if ($test$plusargs("drive_dqs") &&
            rst_n &&
            gate_state_calibrate >= 5'd1 &&
            gate_state_calibrate <= 5'd4 &&
            (ddr3_dqs_p[0] === 1'bz || ddr3_dqs_p[0] === 1'bx)) begin
            force ddr3_dqs_p = {6'bzzzzzz, sim_dqs_inject, sim_dqs_inject};
            force ddr3_dqs_n = {6'bzzzzzz, !sim_dqs_inject, !sim_dqs_inject};
        end else begin
            release ddr3_dqs_p;
            release ddr3_dqs_n;
        end
    end

    always @(posedge sim_controller_clk) begin
        if ($test$plusargs("fast_init") &&
            rst_n &&
            !gate_pause_counter &&
            gate_instruction_address < 5'd13 &&
            gate_delay_counter != 0) begin
            force dut.\ddr3_top_inst.ddr3_controller_inst.delay_counter = 19'd1;
            force dut.\ddr3_top_inst.ddr3_controller_inst.delay_counter_d = 19'd1;
        end else begin
            release dut.\ddr3_top_inst.ddr3_controller_inst.delay_counter ;
            release dut.\ddr3_top_inst.ddr3_controller_inst.delay_counter_d ;
        end
    end

    always @(posedge clk50) begin
        early_status_div <= early_status_div + 8'd1;
        if (led !== last_led ||
            dut.calib_complete !== last_calib_complete ||
            dut.bist_done !== last_bist_done ||
            gate_state_calibrate !== last_state_calibrate ||
            gate_instruction_address !== last_instruction_address ||
            gate_i_rst_n !== last_i_rst_n ||
            gate_o_phy_reset !== last_o_phy_reset ||
            gate_i_phy_idelayctrl_rdy !== last_i_phy_idelayctrl_rdy ||
            (rst_n && !dut.calib_complete && early_status_div == 8'd0)) begin
            print_calib_detail("STATUS");
            print_ddr3_command("STATUS");
            last_led <= led;
            last_calib_complete <= dut.calib_complete;
            last_bist_done <= dut.bist_done;
            last_state_calibrate <= gate_state_calibrate;
            last_instruction_address <= gate_instruction_address;
            last_i_rst_n <= gate_i_rst_n;
            last_o_phy_reset <= gate_o_phy_reset;
            last_i_phy_idelayctrl_rdy <= gate_i_phy_idelayctrl_rdy;
        end

        if (rst_n && gate_state_calibrate == 5'd4) begin
            analyze_dqs_print_div <= analyze_dqs_print_div + 10'd1;
            if (analyze_dqs_print_div == 10'd0) begin
                print_calib_detail("ANALYZE_DQS");
                print_ddr3_command("ANALYZE_DQS");
            end
        end else begin
            analyze_dqs_print_div <= 10'd0;
        end

        if (led[0] === 1'b1) begin
            print_calib_detail("PASS");
            print_ddr3_command("PASS");
            $finish;
        end
    end
endmodule

`default_nettype wire

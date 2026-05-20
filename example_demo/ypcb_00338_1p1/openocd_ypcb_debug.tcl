# Read the YPCB-00338-1P1 UberDDR3 USER1 JTAG debug register.
#
# Example:
#   openocd -s /home/roland/openocd-code/tcl \
#     -f /home/roland/UberDDR3_PR/example_demo/ypcb_00338_1p1/openocd_ypcb_debug.tcl
#
# Override serial if needed:
#   openocd -c "set FTDI_SERIAL 210299BF3824" -s /home/roland/openocd-code/tcl -f openocd_ypcb_debug.tcl

interface ftdi
ftdi_vid_pid 0x0403 0x6014
ftdi_device_desc "Digilent USB Device"
if {[info exists FTDI_SERIAL]} {
    ftdi_serial $FTDI_SERIAL
}
ftdi_layout_init 0x2088 0x308b
ftdi_layout_signal nSRST -data 0x2000 -noe 0x1000
adapter_khz 6000
transport select jtag

set CHIPNAME ypcb_00338_1p1
jtag newtap $CHIPNAME tap -irlen 6 -ircapture 0x01 -irmask 0x03 -expected-id 0x23751093

proc hex64_lane_byte {hex lane} {
    set start [expr {(7 - $lane) * 2}]
    set end [expr {$start + 1}]
    return [string range $hex $start $end]
}

proc lane_mpr_dq_hex {b7 b6 b5 b4 b3 b2 b1 b0 lane} {
    return [format "%s%s%s%s%s%s%s%s" \
        [hex64_lane_byte $b7 $lane] \
        [hex64_lane_byte $b6 $lane] \
        [hex64_lane_byte $b5 $lane] \
        [hex64_lane_byte $b4 $lane] \
        [hex64_lane_byte $b3 $lane] \
        [hex64_lane_byte $b2 $lane] \
        [hex64_lane_byte $b1 $lane] \
        [hex64_lane_byte $b0 $lane]]
}

proc read_ypcb_debug {} {
    global CHIPNAME

    # Xilinx 7-series USER1 is IR 0x02. The FPGA design exposes a 960-bit DR:
    #   [959:448] all-lane MPR DQ bursts 7..0 from same COLLECT_DQS sample
    #   [447:384] all-lane MPR DQ burst0 from the same COLLECT_DQS sample
    #   [383:320] selected-lane DQS polarity/bit-order page from COLLECT_DQS
    #   [319:256] selected-lane MPR DQ data from the same COLLECT_DQS sample
    #   [255:192] per-lane DQS summary bytes: bit7 pass, bit6 fail, bits5:0 index
    #   [191:128] all-lane ISERDES DQS latched at COLLECT_DQS
    #   [127:64]  current-lane DQS calibration debug page
    #   [63:48]   magic 0xd3b5
    #   [47]      SYS_RSTN
    #   [46]      PLL locked
    #   [45]      calibration complete
    #   [44]      USER1 selected
    #   [43:32]   sticky state-seen bits for calibration/BIST milestones
    #   [31:0]    UberDDR3 o_debug1
    irscan $CHIPNAME.tap 0x02
    set raw [drscan $CHIPNAME.tap 960 0]
    set all_mpr_b7_hex [string range $raw 0 15]
    set all_mpr_b6_hex [string range $raw 16 31]
    set all_mpr_b5_hex [string range $raw 32 47]
    set all_mpr_b4_hex [string range $raw 48 63]
    set all_mpr_b3_hex [string range $raw 64 79]
    set all_mpr_b2_hex [string range $raw 80 95]
    set all_mpr_b1_hex [string range $raw 96 111]
    set all_mpr_b0_hex [string range $raw 112 127]
    set all_lane_mpr_burst0 [expr 0x[string range $raw 128 143]]
    set selected_dqs_page [expr 0x[string range $raw 144 159]]
    set selected_mpr_dq [expr 0x[string range $raw 160 175]]
    set bist_data_low $selected_mpr_dq
    set bist_req_page [expr 0x[string range $raw 144 159]]
    set bist_addr_sel_page $all_lane_mpr_burst0
    set dqs_summary [expr 0x[string range $raw 176 191]]
    set dqs_snapshot [expr 0x[string range $raw 192 207]]
    set dqs_debug [expr 0x[string range $raw 208 223]]
    set value [expr 0x[string range $raw 224 239]]
    set magic [expr {($value >> 48) & 0xffff}]
    set sys_rstn [expr {($value >> 47) & 1}]
    set pll_locked [expr {($value >> 46) & 1}]
    set calib_complete [expr {($value >> 45) & 1}]
    set user1_selected [expr {($value >> 44) & 1}]
    set done_seen [expr {($value >> 43) & 1}]
    set finish_seen [expr {($value >> 42) & 1}]
    set analyze_low_seen [expr {($value >> 41) & 1}]
    set read_data_seen [expr {($value >> 40) & 1}]
    set issue_read_seen [expr {($value >> 39) & 1}]
    set issue_write2_seen [expr {($value >> 38) & 1}]
    set issue_write1_seen [expr {($value >> 37) & 1}]
    set burst_write_seen [expr {($value >> 36) & 1}]
    set burst_read_seen [expr {($value >> 35) & 1}]
    set random_write_seen [expr {($value >> 34) & 1}]
    set random_read_seen [expr {($value >> 33) & 1}]
    set alternate_seen [expr {($value >> 32) & 1}]
    set debug1 [expr {$value & 0xffffffff}]
    set state [expr {$debug1 & 0x1f}]
    set read_ack_seen [expr {($debug1 >> 5) & 1}]
    set dqs_state [expr {$dqs_debug & 0x1f}]
    set dqs_start_index_repeat [expr {($dqs_debug >> 5) & 0xf}]
    set dqs_start_index_stored [expr {($dqs_debug >> 9) & 0x3f}]
    set dqs_start_index [expr {($dqs_debug >> 15) & 0x3f}]
    set dqs_lane [expr {($dqs_debug >> 21) & 0x7}]
    set dqs_current [expr {($dqs_debug >> 24) & 0xff}]
    set dqs_store [expr {($dqs_debug >> 32) & 0xffffffff}]
    set lane_dqs_summary_text ""
    for {set debug_summary_lane 0} {$debug_summary_lane < 8} {incr debug_summary_lane} {
        set lane_dqs_summary_byte [expr {($dqs_summary >> ($debug_summary_lane * 8)) & 0xff}]
        set lane_dqs_pass [expr {($lane_dqs_summary_byte >> 7) & 1}]
        set lane_dqs_fail [expr {($lane_dqs_summary_byte >> 6) & 1}]
        set lane_dqs_index [expr {$lane_dqs_summary_byte & 0x3f}]
        append lane_dqs_summary_text [format "l%d:p%d/f%d/i%d" $debug_summary_lane $lane_dqs_pass $lane_dqs_fail $lane_dqs_index]
        if {$debug_summary_lane < 7} {
            append lane_dqs_summary_text " "
        }
    }
    set lane1_collect_dqs [expr {($dqs_snapshot >> 8) & 0xff}]
    set lane1_mpr_dq_hex [lane_mpr_dq_hex $all_mpr_b7_hex $all_mpr_b6_hex $all_mpr_b5_hex $all_mpr_b4_hex $all_mpr_b3_hex $all_mpr_b2_hex $all_mpr_b1_hex $all_mpr_b0_hex 1]
    set lane1_mpr_dq [expr 0x${lane1_mpr_dq_hex}]
    set lane_collect_text ""
    set lane_mpr_text ""
    for {set debug_print_lane 0} {$debug_print_lane < 8} {incr debug_print_lane} {
        set lane_collect_value [expr {($dqs_snapshot >> ($debug_print_lane * 8)) & 0xff}]
        set lane_mpr_hex [lane_mpr_dq_hex $all_mpr_b7_hex $all_mpr_b6_hex $all_mpr_b5_hex $all_mpr_b4_hex $all_mpr_b3_hex $all_mpr_b2_hex $all_mpr_b1_hex $all_mpr_b0_hex $debug_print_lane]
        append lane_collect_text [format "l%d:0x%02x" $debug_print_lane $lane_collect_value]
        append lane_mpr_text [format "l%d:0x%s" $debug_print_lane $lane_mpr_hex]
        if {$debug_print_lane < 7} {
            append lane_collect_text " "
            append lane_mpr_text " "
        }
    }
    set selected_dqs_collect [expr {$selected_dqs_page & 0xff}]
    set selected_dqs_reversed [expr {($selected_dqs_page >> 8) & 0xff}]
    set selected_dqs_inverted [expr {($selected_dqs_page >> 16) & 0xff}]
    set selected_dqs_inv_reversed [expr {($selected_dqs_page >> 24) & 0xff}]
    set selected_collect_samples [expr {($selected_dqs_page >> 32) & 0xff}]
    set selected_collect_lane [expr {($selected_dqs_page >> 40) & 0x7}]
    set dqs_text [format " dqs_debug=0x%016x dqs_state=%d dqs_lane=%d dqs_current=0x%02x dqs_store=0x%08x dqs_start_index=%d dqs_start_index_stored=%d dqs_start_index_repeat=%d all_lane_dqs_collect=0x%016x lane_collects={%s} lane1_collect_dqs=0x%02x dqs_summary=0x%016x lane_dqs_summary={%s} selected_collect_lane=%d all_lane_mpr_bursts={b7:%s b6:%s b5:%s b4:%s b3:%s b2:%s b1:%s b0:%s} all_lane_mpr_burst0=0x%016x lane_mpr_dq={%s} lane1_mpr_dq=0x%016x selected_mpr_dq=0x%016x selected_dqs_collect=0x%02x selected_dqs_rev=0x%02x selected_dqs_inv=0x%02x selected_dqs_inv_rev=0x%02x selected_collect_samples=%d"         $dqs_debug $dqs_state $dqs_lane $dqs_current $dqs_store $dqs_start_index $dqs_start_index_stored $dqs_start_index_repeat         $dqs_snapshot $lane_collect_text $lane1_collect_dqs $dqs_summary $lane_dqs_summary_text $selected_collect_lane $all_mpr_b7_hex $all_mpr_b6_hex $all_mpr_b5_hex $all_mpr_b4_hex $all_mpr_b3_hex $all_mpr_b2_hex $all_mpr_b1_hex $all_mpr_b0_hex $all_lane_mpr_burst0 $lane_mpr_text $lane1_mpr_dq $selected_mpr_dq $selected_dqs_collect $selected_dqs_reversed $selected_dqs_inverted $selected_dqs_inv_reversed $selected_collect_samples]
    if {$state >= 17 && $state <= 23} {
        set calib_stb [expr {($debug1 >> 5) & 1}]
        set o_wb_stall_calib [expr {($debug1 >> 6) & 1}]
        set reset_from_test [expr {($debug1 >> 7) & 1}]
        set write_addr_low [expr {($debug1 >> 8) & 0xff}]
        set correct_low [expr {($debug1 >> 16) & 0xff}]
        set wrong_low [expr {($debug1 >> 24) & 0xff}]
        set o_wb_ack_uncalibrated [expr {$bist_req_page & 1}]
        set req_stall [expr {($bist_req_page >> 1) & 1}]
        set req_calib_stb [expr {($bist_req_page >> 2) & 1}]
        set req_calib_we [expr {($bist_req_page >> 3) & 1}]
        set req_calib_aux [expr {($bist_req_page >> 4) & 0xf}]
        set req_write_byte [expr {($bist_req_page >> 8) & 0x3f}]
        set req_write_addr [expr {($bist_req_page >> 14) & 0x1ffffff}]
        set req_read_addr [expr {($bist_req_page >> 39) & 0x1ffffff}]
        set req_calib_addr [expr {$bist_addr_sel_page & 0x1ffffff}]
        set bist_flags [expr {($bist_addr_sel_page >> 25) & 0x7f}]
        set req_calib_sel_low [expr {($bist_addr_sel_page >> 32) & 0xffffffff}]
        set bist_mode [expr {($bist_flags >> 5) & 0x3}]
        set initial_done [expr {($bist_flags >> 4) & 1}]
        set final_done [expr {($bist_flags >> 3) & 1}]
        set reset_from_calibrate [expr {($bist_flags >> 2) & 1}]
        set debug_reset_from_test [expr {($bist_flags >> 1) & 1}]
        set short_bist [expr {$bist_flags & 1}]
        echo [format "ypcb_debug raw=0x%s magic=0x%04x sys_rstn=%d pll_locked=%d calib_complete=%d user1_selected=%d debug1=0x%08x state=%d%s bist_write_addr_low=0x%02x correct_low=0x%02x wrong_low=0x%02x calib_stb=%d o_wb_stall_calib=%d req_stall=%d o_wb_ack_uncalibrated=%d reset_from_test=%d bist_flags={mode:%d initial_done:%d final_done:%d reset_from_calibrate:%d reset_from_test:%d short:%d} bist_req={we:%d aux:0x%x write_byte:%d write_addr:0x%07x read_addr:0x%07x calib_addr:0x%07x sel_low:0x%08x data_low:0x%016x} seen={done:%d finish:%d analyze_low:%d read_data:%d issue_read:%d issue_write2:%d issue_write1:%d burst_write:%d burst_read:%d random_write:%d random_read:%d alternate:%d}" \
            $raw $magic $sys_rstn $pll_locked $calib_complete $user1_selected $debug1 $state \
            $dqs_text \
            $write_addr_low $correct_low $wrong_low $calib_stb $o_wb_stall_calib $req_stall $o_wb_ack_uncalibrated $reset_from_test \
            $bist_mode $initial_done $final_done $reset_from_calibrate $debug_reset_from_test $short_bist \
            $req_calib_we $req_calib_aux $req_write_byte $req_write_addr $req_read_addr $req_calib_addr $req_calib_sel_low $bist_data_low \
            $done_seen $finish_seen $analyze_low_seen $read_data_seen $issue_read_seen $issue_write2_seen $issue_write1_seen \
            $burst_write_seen $burst_read_seen $random_write_seen $random_read_seen $alternate_seen]
    } else {
        set pattern_match [expr {($debug1 >> 6) & 1}]
        set lane_read_early [expr {($debug1 >> 7) & 1}]
        set lane_write_late [expr {($debug1 >> 8) & 1}]
        set debug_reset_from_test [expr {($debug1 >> 20) & 1}]
        set reset_from_calibrate [expr {($debug1 >> 21) & 1}]
        set final_done [expr {($debug1 >> 22) & 1}]
        set initial_done [expr {($debug1 >> 23) & 1}]
        set bist_mode [expr {($debug1 >> 24) & 0x3}]
        set bist_limit_bits [expr {($debug1 >> 26) & 0x3f}]
        set shift_read_pipe 0
        set bitslip_counter 0
        set lane $dqs_lane
        set read_lane_byte0 0
        set data_start_index $dqs_start_index

        echo [format "ypcb_debug raw=0x%s magic=0x%04x sys_rstn=%d pll_locked=%d calib_complete=%d user1_selected=%d debug1=0x%08x state=%d%s lane=%d bitslip=%d shift_read_pipe=%d data_start_index=%d lane_write_late=%d lane_read_early=%d pattern_match=%d read_ack_seen=%d read_lane_byte0=0x%02x calib_flags={mode:%d limit_bits:%d initial_done:%d final_done:%d reset_from_calibrate:%d reset_from_test:%d} seen={done:%d finish:%d analyze_low:%d read_data:%d issue_read:%d issue_write2:%d issue_write1:%d burst_write:%d burst_read:%d random_write:%d random_read:%d alternate:%d}" \
            $raw $magic $sys_rstn $pll_locked $calib_complete $user1_selected $debug1 $state \
            $dqs_text \
            $lane $bitslip_counter $shift_read_pipe $data_start_index $lane_write_late $lane_read_early $pattern_match $read_ack_seen $read_lane_byte0 \
            $bist_mode $bist_limit_bits $initial_done $final_done $reset_from_calibrate $debug_reset_from_test \
            $done_seen $finish_seen $analyze_low_seen $read_data_seen $issue_read_seen $issue_write2_seen $issue_write1_seen \
            $burst_write_seen $burst_read_seen $random_write_seen $random_read_seen $alternate_seen]
    }
}

init
if {![info exists YPCB_DEBUG_SAMPLES]} {
    set YPCB_DEBUG_SAMPLES 1
}
if {![info exists YPCB_DEBUG_DELAY_MS]} {
    set YPCB_DEBUG_DELAY_MS 100
}

for {set sample 0} {$sample < $YPCB_DEBUG_SAMPLES} {incr sample} {
    read_ypcb_debug
    if {$sample + 1 < $YPCB_DEBUG_SAMPLES} {
        sleep $YPCB_DEBUG_DELAY_MS
    }
}
shutdown

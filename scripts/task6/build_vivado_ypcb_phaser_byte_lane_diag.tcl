# Build the real YPCB clocked PHASER byte-lane JTAG diagnostic with Vivado.
#
# Usage:
#   vivado -mode batch -nojournal -nolog \
#     -source scripts/task6/build_vivado_ypcb_phaser_byte_lane_diag.tcl \
#     -tclargs <out_dir> ?sequence_spec_json? ?extra_verilog_defines?
#
# This is an oracle bitstream only.  The deliverable flow remains open-source.

proc write_file {path text} {
    set fp [open $path w]
    puts -nonewline $fp $text
    close $fp
}

if {$argc < 1 || $argc > 3} {
    error "usage: build_vivado_ypcb_phaser_byte_lane_diag.tcl <out_dir> ?sequence_spec_json? ?extra_verilog_defines?"
}

set out_dir [lindex $argv 0]
set sequence_spec "example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_sequence_observed.json"
if {$argc >= 2 && [lindex $argv 1] ne ""} {
    set sequence_spec [lindex $argv 1]
}
set extra_verilog_defines {}
if {$argc == 3 && [lindex $argv 2] ne ""} {
    set extra_verilog_defines [split [lindex $argv 2] ","]
}
set verilog_defines [concat {YPCB_PHASER_BYTE_LANE_DIAG_CLOCKED} $extra_verilog_defines]
set ddr3_lane0_context [expr {[lsearch -exact $verilog_defines "YPCB_PHASER_BYTE_LANE_DIAG_DDR3_LANE0"] >= 0}]
set dqs_phaseref_context [expr {[lsearch -exact $verilog_defines "YPCB_PHASER_BYTE_LANE_DIAG_DDR3_DQS_PHASEREF"] >= 0}]
set golden_c0_group2a_context [expr {[lsearch -exact $verilog_defines "YPCB_PHASER_BYTE_LANE_DIAG_GOLDEN_C0_GROUP2A"] >= 0}]
set golden_c0_group2b_context [expr {[lsearch -exact $verilog_defines "YPCB_PHASER_BYTE_LANE_DIAG_GOLDEN_C0_GROUP2B"] >= 0}]
file mkdir $out_dir

set sequence_header "example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_sequence.vh"
exec python3 scripts/task6/generate_ypcb_phaser_sequence_header.py \
    --spec $sequence_spec \
    --out $sequence_header

set xdc_path [file join $out_dir "ypcb_phaser_byte_lane_diag_vivado.xdc"]
set xdc_text {
set_property LOC AA28 [get_ports {clk50}]
set_property IOSTANDARD LVCMOS18 [get_ports {clk50}]
create_clock -name clk50 -period 20.000 [get_ports clk50]

set_property LOC R28 [get_ports {rst_n}]
set_property IOSTANDARD LVCMOS18 [get_ports {rst_n}]

set_property LOC P30 [get_ports {led[0]}]
set_property LOC M30 [get_ports {led[1]}]
set_property LOC N30 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {led[2]}]

set_property LOC PHASER_REF_X0Y0 [get_cells phaser_ref_i]
set_property LOC PHY_CONTROL_X0Y0 [get_cells phy_control_i]
set_property LOC PLLE2_ADV_X0Y1 [get_cells phaser_pll_i]
}
if {$golden_c0_group2b_context} {
    append xdc_text "set_property LOC PHASER_OUT_PHY_X0Y1 \[get_cells phaser_out_i\]\n"
} else {
    append xdc_text "set_property LOC PHASER_OUT_PHY_X0Y0 \[get_cells phaser_out_i\]\n"
}
if {$golden_c0_group2a_context} {
    append xdc_text "set_property LOC PHASER_IN_PHY_X0Y0 \[get_cells phaser_in_i\]\n"
} elseif {$dqs_phaseref_context || $golden_c0_group2b_context} {
    append xdc_text "set_property LOC PHASER_IN_PHY_X0Y1 \[get_cells phaser_in_i\]\n"
} else {
    append xdc_text "set_property LOC PHASER_IN_PHY_X0Y0 \[get_cells phaser_in_i\]\n"
}
if {$ddr3_lane0_context} {
    set lane0_xdc_path "example_demo/ypcb_00338_1p1/ypcb_phaser_ddr3_lane0_probe.xdc"
    set fp [open $lane0_xdc_path r]
    append xdc_text "\n" [read $fp]
    close $fp
}
if {[lsearch -exact $verilog_defines "YPCB_PHASER_BYTE_LANE_DIAG_IN_FIFO"] >= 0} {
    if {$golden_c0_group2b_context} {
        append xdc_text "set_property LOC IN_FIFO_X0Y1 \[get_cells in_fifo_i\]\n"
    } else {
        append xdc_text "set_property LOC IN_FIFO_X0Y0 \[get_cells in_fifo_i\]\n"
    }
}
write_file $xdc_path $xdc_text

create_project -force ypcb_phaser_byte_lane_diag_vivado \
    [file join $out_dir "vivado_project"] \
    -part xc7k480tffg1156-2

read_verilog -sv example_demo/ypcb_00338_1p1/ypcb_bscan_smoke.sv
set_property verilog_define $verilog_defines [current_fileset]
read_verilog -sv example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag.sv
read_xdc $xdc_path

synth_design -top ypcb_phaser_byte_lane_diag -part xc7k480tffg1156-2
opt_design
place_design
route_design

write_checkpoint -force [file join $out_dir "post-route.dcp"]
write_xdc -force [file join $out_dir "implemented.xdc"]
write_bitstream -force [file join $out_dir "ypcb_phaser_byte_lane_diag_vivado.bit"]
report_utilization -file [file join $out_dir "utilization.rpt"]
report_drc -file [file join $out_dir "drc.rpt"]

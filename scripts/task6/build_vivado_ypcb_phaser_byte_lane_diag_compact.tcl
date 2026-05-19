# Build a compact Vivado oracle for the YPCB PHASER byte-lane diagnostic.
#
# This oracle intentionally uses the repository diagnostic RTL instead of the
# full YPCB SYSTEST/MIG project, so CMT/PHASER frame deltas against OpenXC7 are
# small enough to classify. The final deliverable flow remains open-source.

proc write_file {path text} {
    set fp [open $path w]
    puts -nonewline $fp $text
    close $fp
}

if {$argc != 1} {
    error "usage: build_vivado_ypcb_phaser_byte_lane_diag_compact.tcl <out_dir>"
}

set out_dir [lindex $argv 0]
file mkdir $out_dir

set repo_root [file normalize [file join [file dirname [file normalize [info script]]] ../..]]
set example_dir [file join $repo_root example_demo ypcb_00338_1p1]
set xdc_path [file join $out_dir "ypcb_phaser_byte_lane_diag_compact.xdc"]

write_file $xdc_path {
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
set_property LOC PHASER_IN_PHY_X0Y0 [get_cells phaser_in_i]
set_property LOC PHASER_OUT_PHY_X0Y0 [get_cells phaser_out_i]
set_property LOC PLLE2_ADV_X0Y1 [get_cells phaser_pll_i]
}

create_project -force ypcb_phaser_byte_lane_diag_compact_vivado \
    [file join $out_dir "vivado_project"] \
    -part xc7k480tffg1156-2

set_property include_dirs [list $example_dir] [current_fileset]
set_property verilog_define {YPCB_PHASER_BYTE_LANE_DIAG_CLOCKED=1} [current_fileset]

read_verilog -sv [file join $example_dir ypcb_bscan_smoke.sv]
read_verilog -sv [file join $example_dir ypcb_phaser_byte_lane_diag.sv]
read_xdc $xdc_path

synth_design -top ypcb_phaser_byte_lane_diag -part xc7k480tffg1156-2 \
    -verilog_define {YPCB_PHASER_BYTE_LANE_DIAG_CLOCKED=1} \
    -include_dirs [list $example_dir]
opt_design
place_design
phys_opt_design
route_design

report_timing_summary -delay_type max -report_unconstrained -max_paths 20 \
    -file [file join $out_dir "timing-summary.rpt"]
report_drc -file [file join $out_dir "drc.rpt"]
write_checkpoint -force [file join $out_dir "post-route.dcp"]
write_xdc -force [file join $out_dir "implemented.xdc"]
write_bitstream -force [file join $out_dir "ypcb_phaser_byte_lane_diag_compact_vivado.bit"]
report_utilization -file [file join $out_dir "utilization.rpt"]

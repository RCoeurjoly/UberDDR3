# Build the real YPCB PHASER_REF JTAG-readback diagnostic with Vivado.
#
# Usage:
#   vivado -mode batch -nojournal -nolog \
#     -source scripts/task6/build_vivado_ypcb_phaser_ref_diag.tcl \
#     -tclargs <out_dir>
#
# This is an oracle bitstream only.  The deliverable flow remains open-source.

proc write_file {path text} {
    set fp [open $path w]
    puts -nonewline $fp $text
    close $fp
}

if {$argc != 1} {
    error "usage: build_vivado_ypcb_phaser_ref_diag.tcl <out_dir>"
}

set out_dir [lindex $argv 0]
file mkdir $out_dir

set xdc_path [file join $out_dir "ypcb_phaser_ref_diag_vivado.xdc"]
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
set_property LOC PLLE2_ADV_X0Y1 [get_cells phaser_pll_i]
}

create_project -force ypcb_phaser_ref_diag_vivado \
    [file join $out_dir "vivado_project"] \
    -part xc7k480tffg1156-2

read_verilog -sv example_demo/ypcb_00338_1p1/ypcb_bscan_smoke.sv
read_verilog -sv example_demo/ypcb_00338_1p1/ypcb_phaser_ref_diag.sv
read_xdc $xdc_path

synth_design -top ypcb_phaser_ref_diag -part xc7k480tffg1156-2
opt_design
place_design
route_design

write_checkpoint -force [file join $out_dir "post-route.dcp"]
write_xdc -force [file join $out_dir "implemented.xdc"]
write_bitstream -force [file join $out_dir "ypcb_phaser_ref_diag_vivado.bit"]
report_utilization -file [file join $out_dir "utilization.rpt"]
report_drc -file [file join $out_dir "drc.rpt"]

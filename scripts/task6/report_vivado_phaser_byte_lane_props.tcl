# Report resolved Vivado properties for the PHASER byte-lane diagnostic.
#
# Usage:
#   vivado -mode batch -nojournal -nolog \
#     -source scripts/task6/report_vivado_phaser_byte_lane_props.tcl \
#     -tclargs <checkpoint.dcp> <out.txt> \
#       ?phaser_ref_cell phy_control_cell phaser_in_cell phaser_out_cell?

proc emit_cell_props {fp cell_name props} {
    set cell [get_cells $cell_name]
    puts $fp "CELL $cell_name"
    puts $fp "  REF_NAME [get_property REF_NAME $cell]"
    puts $fp "  LOC [get_property LOC $cell]"
    puts $fp "  BEL [get_property BEL $cell]"
    foreach prop $props {
        if {[catch {set value [get_property $prop $cell]} err]} {
            puts $fp "  $prop <ERROR: $err>"
        } elseif {$value eq ""} {
            puts $fp "  $prop <empty>"
        } else {
            puts $fp "  $prop $value"
        }
    }
    puts $fp ""
}

if {$argc != 2 && $argc != 6} {
    error "usage: report_vivado_phaser_byte_lane_props.tcl <checkpoint.dcp> <out.txt> ?phaser_ref_cell phy_control_cell phaser_in_cell phaser_out_cell?"
}

set dcp_path [lindex $argv 0]
set out_path [lindex $argv 1]
set phaser_ref_cell phaser_ref_i
set phy_control_cell phy_control_i
set phaser_in_cell phaser_in_i
set phaser_out_cell phaser_out_i

if {$argc == 6} {
    set phaser_ref_cell [lindex $argv 2]
    set phy_control_cell [lindex $argv 3]
    set phaser_in_cell [lindex $argv 4]
    set phaser_out_cell [lindex $argv 5]
}

open_checkpoint $dcp_path

set fp [open $out_path w]

emit_cell_props $fp $phaser_ref_cell {
    IS_CLK_INVERTED
    IS_PWRDWN_INVERTED
    IS_RST_INVERTED
}

emit_cell_props $fp $phy_control_cell {
    BURST_MODE
    CLK_RATIO
    IS_MEMREFCLK_INVERTED
    IS_PHYCLK_INVERTED
    IS_PHYCTLWRENABLE_INVERTED
    IS_PLLLOCK_INVERTED
    IS_READCALIBENABLE_INVERTED
    IS_REFDLLLOCK_INVERTED
    IS_RESET_INVERTED
    IS_SYNCIN_INVERTED
    IS_WRITECALIBENABLE_INVERTED
    SYNC_MODE
}

emit_cell_props $fp $phaser_in_cell {
    CLKOUT_DIV
    DQS_BIAS
    FINE_DELAY
    FREQ_REF_DIV
    HALF_CYCLE_ADJ
    ICLK_TO_RCLK_BYPASS
    IS_BURSTPENDINGPHY_INVERTED
    IS_COUNTERLOADEN_INVERTED
    IS_COUNTERREADEN_INVERTED
    IS_FINEENABLE_INVERTED
    IS_FINEINC_INVERTED
    IS_FREQREFCLK_INVERTED
    IS_MEMREFCLK_INVERTED
    IS_PHASEREFCLK_INVERTED
    IS_RST_INVERTED
    IS_RSTDQSFIND_INVERTED
    IS_SYNCIN_INVERTED
    IS_SYSCLK_INVERTED
    OUTPUT_CLK_SRC
    PD_REVERSE
    PHASEREFCLK_PERIOD
    REFCLK_PERIOD
    MEMREFCLK_PERIOD
}

emit_cell_props $fp $phaser_out_cell {
    CLKOUT_DIV
    COARSE_BYPASS
    DATA_CTL_N
    DATA_RD_CYCLES
    FINE_DELAY
    FREQ_REF_DIV
    HALF_CYCLE_ADJ
    IS_BURSTPENDINGPHY_INVERTED
    IS_COARSEENABLE_INVERTED
    IS_COARSEINC_INVERTED
    IS_COUNTERLOADEN_INVERTED
    IS_COUNTERREADEN_INVERTED
    IS_FINEENABLE_INVERTED
    IS_FINEINC_INVERTED
    IS_FREQREFCLK_INVERTED
    IS_MEMREFCLK_INVERTED
    IS_PHASEREFCLK_INVERTED
    IS_RST_INVERTED
    IS_SELFINEOCLKDELAY_INVERTED
    IS_SYNCIN_INVERTED
    IS_SYSCLK_INVERTED
    OUTPUT_CLK_SRC
    OCLKDELAY_INV
    PHASEREFCLK_PERIOD
    REFCLK_PERIOD
    MEMREFCLK_PERIOD
}

close $fp

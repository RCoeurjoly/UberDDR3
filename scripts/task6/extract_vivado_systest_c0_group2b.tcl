# Extract focused Vivado SYSTEST evidence for c0.group2.B PHASER/FIFO bring-up.
#
# Usage:
#   vivado -mode batch -nojournal -nolog \
#     -source scripts/task6/extract_vivado_systest_c0_group2b.tcl \
#     -tclargs <routed.dcp> <out_dir>

proc sanitize {value} {
    set text "$value"
    regsub -all {\t} $text { } text
    regsub -all {\r?\n} $text { | } text
    return $text
}

proc prop_or_empty {obj prop} {
    set value ""
    catch {set value [get_property $prop $obj]}
    return [sanitize $value]
}

proc write_tsv_line {fp fields} {
    set escaped {}
    foreach field $fields {
        lappend escaped [sanitize $field]
    }
    puts $fp [join $escaped "\t"]
}

proc pips_for_net {net} {
    set pips [get_pips -quiet -of_objects $net]
    if {[llength $pips] == 0} {
        return {}
    }
    return [lsort [get_property NAME $pips]]
}

proc pin_net_name {pin} {
    set nets [get_nets -quiet -of_objects $pin]
    if {[llength $nets] == 0} {
        return "<none>"
    }
    return [get_property NAME [lindex $nets 0]]
}

proc net_driver_pins {net} {
    set drivers {}
    foreach pin [get_pins -quiet -of_objects $net] {
        if {[get_property DIRECTION $pin] eq "OUT"} {
            lappend drivers [get_property NAME $pin]
        }
    }
    return [lsort $drivers]
}

proc net_load_pins {net} {
    set loads {}
    foreach pin [get_pins -quiet -of_objects $net] {
        if {[get_property DIRECTION $pin] ne "OUT"} {
            lappend loads [get_property NAME $pin]
        }
    }
    return [lsort $loads]
}

if {$argc != 2} {
    error "usage: extract_vivado_systest_c0_group2b.tcl <routed.dcp> <out_dir>"
}

set dcp_path [lindex $argv 0]
set out_dir [lindex $argv 1]
file mkdir $out_dir
open_checkpoint $dcp_path

set lane_prefix "top_i/mig_7series_0/u_top_mig_7series_0_0_mig/c0_u_memc_ui_top_axi/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_2.u_ddr_phy_4lanes/ddr_byte_lane_B.ddr_byte_lane_B"
set group_prefix "top_i/mig_7series_0/u_top_mig_7series_0_0_mig/c0_u_memc_ui_top_axi/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_2.u_ddr_phy_4lanes"

set cell_filter {
    REF_NAME =~ PHASER_REF ||
    REF_NAME =~ PHASER_IN_PHY ||
    REF_NAME =~ PHASER_OUT_PHY ||
    REF_NAME =~ PHY_CONTROL ||
    REF_NAME =~ IN_FIFO ||
    REF_NAME =~ OUT_FIFO ||
    REF_NAME =~ ISERDESE2 ||
    REF_NAME =~ OSERDESE2 ||
    REF_NAME =~ IDELAYE2 ||
    REF_NAME =~ ODELAYE2
}

set prop_names {
    REF_NAME LOC BEL SITE
    IS_LOC_FIXED IS_BEL_FIXED DONT_TOUCH KEEP
    OUTPUT_CLK_SRC CLKOUT_DIV FREQ_REF_DIV PHASEREFCLK_PERIOD REFCLK_PERIOD MEMREFCLK_PERIOD
    DQS_BIAS FINE_DELAY HALF_CYCLE_ADJ ICLK_TO_RCLK_BYPASS COARSE_BYPASS DATA_CTL_N DATA_RD_CYCLES
    BURST_MODE CLK_RATIO SYNC_MODE
    IS_CLK_INVERTED IS_RST_INVERTED IS_PWRDWN_INVERTED
    IS_MEMREFCLK_INVERTED IS_PHYCLK_INVERTED IS_PHYCTLWRENABLE_INVERTED IS_PLLLOCK_INVERTED
    IS_READCALIBENABLE_INVERTED IS_REFDLLLOCK_INVERTED IS_RESET_INVERTED IS_SYNCIN_INVERTED
    IS_WRITECALIBENABLE_INVERTED IS_PHASEREFCLK_INVERTED IS_FREQREFCLK_INVERTED IS_SYSCLK_INVERTED
    IS_RSTDQSFIND_INVERTED IS_BURSTPENDINGPHY_INVERTED IS_COUNTERLOADEN_INVERTED IS_COUNTERREADEN_INVERTED
    IS_FINEENABLE_INVERTED IS_FINEINC_INVERTED IS_COARSEENABLE_INVERTED IS_COARSEINC_INVERTED
    SIM_DEVICE
}

set cells {}
foreach cell [get_cells -quiet -hier -filter $cell_filter] {
    set name [get_property NAME $cell]
    set ref [get_property REF_NAME $cell]
    if {[string first $lane_prefix $name] == 0} {
        lappend cells $cell
    } elseif {[string first $group_prefix $name] == 0 && ($ref eq "PHY_CONTROL" || $ref eq "PHASER_REF")} {
        lappend cells $cell
    }
}
set cells [lsort -unique $cells]

set cells_fp [open [file join $out_dir cells.tsv] w]
set props_fp [open [file join $out_dir properties.tsv] w]
set pins_fp [open [file join $out_dir pins.tsv] w]
set nets_fp [open [file join $out_dir nets.tsv] w]
set pips_fp [open [file join $out_dir net-pips.tsv] w]
set summary_fp [open [file join $out_dir summary.txt] w]

write_tsv_line $cells_fp {role cell ref_name loc bel site}
write_tsv_line $props_fp {cell ref_name property value}
write_tsv_line $pins_fp {cell ref_name pin ref_pin direction net net_type}
write_tsv_line $nets_fp {net driver_count load_count drivers loads}
write_tsv_line $pips_fp {net pip_count sampled_pips}

array set seen_nets {}
foreach cell $cells {
    set name [get_property NAME $cell]
    set ref [get_property REF_NAME $cell]
    set role $ref
    if {$name eq "${group_prefix}/phy_control_i"} { set role "GROUP_PHY_CONTROL" }
    if {$name eq "${group_prefix}/phaser_ref"} { set role "GROUP_PHASER_REF" }
    write_tsv_line $cells_fp [list $role $name $ref [prop_or_empty $cell LOC] [prop_or_empty $cell BEL] [prop_or_empty $cell SITE]]

    foreach prop $prop_names {
        set value [prop_or_empty $cell $prop]
        if {$value ne ""} {
            write_tsv_line $props_fp [list $name $ref $prop $value]
        }
    }

    foreach pin [lsort [get_pins -quiet -of_objects $cell]] {
        set pin_name [get_property NAME $pin]
        set ref_pin [prop_or_empty $pin REF_PIN_NAME]
        set direction [prop_or_empty $pin DIRECTION]
        set nets [get_nets -quiet -of_objects $pin]
        if {[llength $nets] == 0} {
            write_tsv_line $pins_fp [list $name $ref $pin_name $ref_pin $direction "<none>" ""]
            continue
        }
        set net [lindex $nets 0]
        set net_name [get_property NAME $net]
        write_tsv_line $pins_fp [list $name $ref $pin_name $ref_pin $direction $net_name [prop_or_empty $net TYPE]]
        if {![info exists seen_nets($net_name)]} {
            set seen_nets($net_name) 1
            set drivers [net_driver_pins $net]
            set loads [net_load_pins $net]
            write_tsv_line $nets_fp [list $net_name [llength $drivers] [llength $loads] [join $drivers ","] [join $loads ","]]
            set pips [pips_for_net $net]
            write_tsv_line $pips_fp [list $net_name [llength $pips] [join [lrange $pips 0 127] ","]]
        }
    }
}

puts $summary_fp "DCP $dcp_path"
puts $summary_fp "LANE_PREFIX $lane_prefix"
puts $summary_fp "GROUP_PREFIX $group_prefix"
puts $summary_fp "CELL_COUNT [llength $cells]"
foreach ref {PHASER_REF PHASER_IN_PHY PHASER_OUT_PHY PHY_CONTROL IN_FIFO OUT_FIFO IDELAYE2 ISERDESE2 OSERDESE2 ODELAYE2} {
    set count 0
    foreach cell $cells {
        if {[get_property REF_NAME $cell] eq $ref} { incr count }
    }
    puts $summary_fp "$ref $count"
}
puts $summary_fp "NET_COUNT [array size seen_nets]"

close $cells_fp
close $props_fp
close $pins_fp
close $nets_fp
close $pips_fp
close $summary_fp
close_design

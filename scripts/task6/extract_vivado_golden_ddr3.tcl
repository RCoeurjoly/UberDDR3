# Extract full Vivado systest DDR3/PHASER hard-macro evidence from a routed DCP.
#
# Usage:
#   vivado -mode batch -nojournal -nolog \
#     -source scripts/task6/extract_vivado_golden_ddr3.tcl \
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

proc should_sample_pips {net_name} {
    return [regexp -nocase {(dqs|phase|phy|fifo|dqsf|rden|wren|rst)} $net_name]
}

if {$argc != 2} {
    error "usage: extract_vivado_golden_ddr3.tcl <routed.dcp> <out_dir>"
}

set dcp_path [lindex $argv 0]
set out_dir [lindex $argv 1]
file mkdir $out_dir

open_checkpoint $dcp_path

set hardmacro_filter {
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

set pip_ref_names {
    PHASER_REF
    PHASER_IN_PHY
    PHASER_OUT_PHY
    PHY_CONTROL
    IN_FIFO
    OUT_FIFO
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
}

set cells [lsort [get_cells -quiet -hier -filter $hardmacro_filter]]

set cells_fp [open [file join $out_dir cells.tsv] w]
set props_fp [open [file join $out_dir cell-properties.tsv] w]
set pins_fp [open [file join $out_dir pins.tsv] w]
set pips_fp [open [file join $out_dir net-pips.tsv] w]
set clocks_fp [open [file join $out_dir clocks.tsv] w]
set summary_fp [open [file join $out_dir summary.txt] w]

write_tsv_line $cells_fp {cell ref_name loc bel site primitive_group}
write_tsv_line $props_fp {cell property value}
write_tsv_line $pins_fp {cell pin ref_pin direction net net_type}
write_tsv_line $pips_fp {net pip_count sampled_pips}
write_tsv_line $clocks_fp {clock period waveform targets}

array set seen_nets {}
foreach cell $cells {
    set cell_name [get_property NAME $cell]
    set ref_name [prop_or_empty $cell REF_NAME]
    set loc [prop_or_empty $cell LOC]
    set bel [prop_or_empty $cell BEL]
    set site [prop_or_empty $cell SITE]
    set group $ref_name
    if {[regexp {^(IBUF|OBUF|IOBUF)} $ref_name -> buf_kind]} {
        set group $buf_kind
    }
    write_tsv_line $cells_fp [list $cell_name $ref_name $loc $bel $site $group]

    foreach prop $prop_names {
        set value [prop_or_empty $cell $prop]
        if {$value ne ""} {
            write_tsv_line $props_fp [list $cell_name $prop $value]
        }
    }

    foreach pin [lsort [get_pins -quiet -of_objects $cell]] {
        set pin_name [get_property NAME $pin]
        set ref_pin [prop_or_empty $pin REF_PIN_NAME]
        set direction [prop_or_empty $pin DIRECTION]
        set nets [get_nets -quiet -of_objects $pin]
        if {[llength $nets] == 0} {
            write_tsv_line $pins_fp [list $cell_name $pin_name $ref_pin $direction "<none>" ""]
            continue
        }
        set net [lindex $nets 0]
        set net_name [get_property NAME $net]
        set net_type [prop_or_empty $net TYPE]
        write_tsv_line $pins_fp [list $cell_name $pin_name $ref_pin $direction $net_name $net_type]
        if {[lsearch -exact $pip_ref_names $ref_name] >= 0 && ![info exists seen_nets($net_name)]} {
            set seen_nets($net_name) 1
            if {[should_sample_pips $net_name]} {
                set pips [pips_for_net $net]
                set sample [lrange $pips 0 63]
                write_tsv_line $pips_fp [list $net_name [llength $pips] [join $sample ","]]
            } else {
                write_tsv_line $pips_fp [list $net_name 0 "<not-sampled>"]
            }
        }
    }
}

foreach clock [lsort [get_clocks -quiet]] {
    set clock_name [get_property NAME $clock]
    set period [prop_or_empty $clock PERIOD]
    set waveform [prop_or_empty $clock WAVEFORM]
    set clock_pins [get_pins -quiet -of_objects $clock]
    if {[llength $clock_pins] == 0} {
        set targets ""
    } else {
        set targets [join [lsort [get_property NAME $clock_pins]] ","]
    }
    write_tsv_line $clocks_fp [list $clock_name $period $waveform $targets]
}

puts $summary_fp "DCP $dcp_path"
puts $summary_fp "CELL_COUNT [llength $cells]"
foreach ref {PHASER_REF PHASER_IN_PHY PHASER_OUT_PHY PHY_CONTROL IN_FIFO OUT_FIFO ISERDESE2 OSERDESE2 IDELAYE2 ODELAYE2} {
    set count [llength [get_cells -quiet -hier -filter "REF_NAME =~ $ref"]]
    puts $summary_fp "$ref $count"
}

close $cells_fp
close $props_fp
close $pins_fp
close $pips_fp
close $clocks_fp
close $summary_fp
close_design

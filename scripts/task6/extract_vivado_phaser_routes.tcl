# Extract PHASER/FIFO/PHY_CONTROL pin-to-net and pip evidence from a routed
# Vivado checkpoint.
#
# Usage:
#   vivado -mode batch -nojournal -nolog \
#     -source scripts/task6/extract_vivado_phaser_routes.tcl \
#     -tclargs <post-route.dcp> <out.txt>

proc write_line {fp text} {
    puts $fp $text
}

proc prop_or_empty {obj prop} {
    set value ""
    catch {set value [get_property $prop $obj]}
    return $value
}

proc pips_for_net {net} {
    set pips [get_pips -quiet -of_objects $net]
    if {[llength $pips] == 0} {
        return {}
    }
    return [lsort [get_property NAME $pips]]
}

proc dump_cell {fp cell} {
    set cell_name [get_property NAME $cell]
    write_line $fp "CELL $cell_name"
    write_line $fp "  REF_NAME [prop_or_empty $cell REF_NAME]"
    write_line $fp "  LOC [prop_or_empty $cell LOC]"
    write_line $fp "  BEL [prop_or_empty $cell BEL]"

    foreach pin [lsort [get_pins -quiet -of_objects $cell]] {
        set pin_name [get_property NAME $pin]
        set pin_ref [prop_or_empty $pin REF_PIN_NAME]
        set pin_dir [prop_or_empty $pin DIRECTION]
        set net [get_nets -quiet -of_objects $pin]
        if {[llength $net] == 0} {
            write_line $fp "  PIN $pin_name REF_PIN $pin_ref DIR $pin_dir NET <none>"
            continue
        }
        set net_name [get_property NAME $net]
        set net_type [prop_or_empty $net TYPE]
        write_line $fp "  PIN $pin_name REF_PIN $pin_ref DIR $pin_dir NET $net_name TYPE $net_type"
        foreach pip [pips_for_net $net] {
            write_line $fp "    PIP $pip"
        }
    }
}

if {$argc != 2} {
    error "usage: extract_vivado_phaser_routes.tcl <post-route.dcp> <out.txt>"
}

set dcp [lindex $argv 0]
set out_path [lindex $argv 1]

open_checkpoint $dcp
set fp [open $out_path w]

set filters {
    {REF_NAME == PHASER_REF && LOC == PHASER_REF_X0Y0}
    {REF_NAME == PHY_CONTROL && LOC == PHY_CONTROL_X0Y0}
    {REF_NAME == PHASER_IN_PHY && LOC == PHASER_IN_PHY_X0Y0}
    {REF_NAME == PHASER_OUT_PHY && LOC == PHASER_OUT_PHY_X0Y0}
}

foreach filter $filters {
    set cells [get_cells -quiet -hier -filter $filter]
    write_line $fp "FILTER $filter COUNT [llength $cells]"
    foreach cell $cells {
        dump_cell $fp $cell
    }
}

close $fp
close_design

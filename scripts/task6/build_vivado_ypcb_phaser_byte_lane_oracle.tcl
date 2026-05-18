#!/usr/bin/env tclsh

proc env_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

proc resolve_file_path {path} {
    set candidate $path
    if {[file exists $candidate]} {
        return [file normalize $candidate]
    }
    set cwd_candidate [file normalize [file join [pwd] $path]]
    if {[file exists $cwd_candidate]} {
        return $cwd_candidate
    }
    if {[file exists [info script]]} {
        set script_dir [file dirname [file normalize [info script]]]
        set script_candidate [file normalize [file join $script_dir $path]]
        if {[file exists $script_candidate]} {
            return $script_candidate
        }
    }
    if {[file exists $path]} {
        return [file normalize $path]
    }
    if {[file exists [file join [file dirname [file normalize [info script]]] $path]]} {
        return [file normalize [file join [file dirname [file normalize [info script]]] $path]]
    }
    return $candidate
}

proc write_file {path text} {
    set fh [open $path w]
    puts -nonewline $fh $text
    close $fh
}

proc resolve_probe_nets {alias pattern_list} {
    set matches {}
    foreach pattern $pattern_list {
        set candidates [lsort [get_nets -hier -quiet $pattern]]
        if {[llength $candidates] == 1} {
            return [lindex $candidates 0]
        }
        if {[llength $candidates] > 1} {
            set matches [concat $matches $candidates]
        }
    }

    set unique [lsort -unique $matches]
    if {[llength $unique] == 1} {
        return [lindex $unique 0]
    }
    if {[llength $unique] == 0} {
        error "No matching net for probe alias '$alias' using patterns: $pattern_list"
    }
    error "Multiple matches for probe alias '$alias' using patterns '$pattern_list': $unique"
}

proc insert_phaser_byte_lane_ila {out_dir} {
    file mkdir $out_dir
    global PHASER_BYTE_LANE_ORACLE_PROBES
    if {![info exists PHASER_BYTE_LANE_ORACLE_PROBES]} {
        error "probe mapping not loaded: PHASER_BYTE_LANE_ORACLE_PROBES is not defined"
    }
    set probe_specs $PHASER_BYTE_LANE_ORACLE_PROBES
    if {[llength $probe_specs] == 0} {
        error "empty PHASER_BYTE_LANE_ORACLE_PROBES"
    }

    set capture_clk_entry ""
    foreach entry $probe_specs {
        if {[lindex $entry 0] eq "capture_clk"} {
            set capture_clk_entry $entry
            break
        }
    }
    if {$capture_clk_entry eq ""} {
        error "capture_clk must be defined in PHASER_BYTE_LANE_ORACLE_PROBES"
    }

    set clk_patterns [lindex $capture_clk_entry 1]
    set capture_clk [resolve_probe_nets "capture_clk" $clk_patterns]
    set debug_core [create_debug_core ypcb_phaser_byte_lane_ila ila]
    set_property C_DATA_DEPTH 4096 $debug_core
    set_property C_TRIGIN_EN false $debug_core
    set_property C_TRIGOUT_EN false $debug_core
    set_property C_INPUT_PIPE_STAGES 1 $debug_core
    connect_debug_port $debug_core/clk $capture_clk

    set manifest "# Vivado probe map used for PHASER byte-lane migration capture\n"
    append manifest "capture_clk=$capture_clk\n"
    set idx 0
    foreach entry $probe_specs {
        set alias [lindex $entry 0]
        if {$alias eq "capture_clk"} {
            continue
        }
        set patterns [lindex $entry 1]
        set width [lindex $entry 2]
        if {$width == ""} {
            set width 1
        }

        set net [resolve_probe_nets $alias $patterns]
        if {$idx > 0} {
            create_debug_port $debug_core probe
        }
        set probe_port "$debug_core/probe$idx"
        set probe_obj [get_debug_ports $probe_port]
        if {[llength $probe_obj] == 0} {
            error "Missing debug port $probe_port"
        }
        set_property port_width $width $probe_obj
        connect_debug_port $probe_port $net
        append manifest "$alias=$net;width=$width\n"
        incr idx
    }

    opt_design
    place_design
    phys_opt_design
    route_design
    report_timing_summary -delay_type max -report_unconstrained -max_paths 20 -file [file join $out_dir "debug-timing-summary.rpt"]
    report_drc -file [file join $out_dir "debug-drc.rpt"]
    write_debug_probes -force [file join $out_dir "top_wrapper_debug.ltx"]
    write_checkpoint -force [file join $out_dir "post-route-debug.dcp"]
    write_bitstream -force [file join $out_dir "top_wrapper_debug.bit"]
    write_file [file join $out_dir "calibration-ila-probes.txt"] $manifest
    puts "Vivado PHASER byte-lane oracle debug bitstream written to [file join $out_dir top_wrapper_debug.bit]"
}

if {$argc < 1 || $argc > 2} {
    error "usage: build_vivado_ypcb_phaser_byte_lane_oracle.tcl <out_dir> ?probe_map_tcl?"
}

set out_dir [lindex $argv 0]
set script_dir [file dirname [file normalize [info script]]]
set default_probe_map [file join $script_dir "ypcb_phaser_byte_lane_oracle_probes.tcl"]
set probe_map_path [env_default "YPCB_PHASER_BYTE_LANE_ORACLE_PROBE_MAP" $default_probe_map]
if {$argc == 2} {
    set probe_map_path [lindex $argv 1]
}
set probe_map_path [resolve_file_path $probe_map_path]
if {![file exists $probe_map_path]} {
    error "No probe map file found at $probe_map_path"
}
source $probe_map_path
if {![info exists PHASER_BYTE_LANE_ORACLE_PROBES] && [info exists ::PHASER_BYTE_LANE_ORACLE_PROBES]} {
    set PHASER_BYTE_LANE_ORACLE_PROBES $::PHASER_BYTE_LANE_ORACLE_PROBES
}
if {![info exists PHASER_BYTE_LANE_ORACLE_PROBES]} {
    error "Probe map file $probe_map_path must define PHASER_BYTE_LANE_ORACLE_PROBES"
}

set project [env_default YPCB_VIVADO_PROJECT "/home/roland/ypcb_00338_1p1_hack/examples/YPCB_00338_1P1_systest/YPCB_00338_1P1_systest.xpr"]
set jobs [env_default YPCB_VIVADO_JOBS "8"]

if {![file exists $project]} {
    error "Project not found at $project"
}
open_project $project
set impl_run [lindex [get_runs impl_1] 0]
if {$impl_run eq ""} {
    error "run impl_1 not found in project $project"
}
if {![string equal [get_property PROGRESS $impl_run] "100%"]} {
    launch_runs impl_1 -to_step write_bitstream -jobs $jobs
    wait_on_run impl_1
}

open_run impl_1
insert_phaser_byte_lane_ila $out_dir
close_project

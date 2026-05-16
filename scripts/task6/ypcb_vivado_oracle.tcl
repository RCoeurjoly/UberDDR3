proc env_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

proc write_file {path contents} {
    set fh [open $path w]
    puts $fh $contents
    close $fh
}

proc copy_first_match {patterns out_dir} {
    foreach pattern $patterns {
        foreach path [glob -nocomplain $pattern] {
            file copy -force $path [file join $out_dir [file tail $path]]
        }
    }
}

proc export_mig_source_artifacts {project_dir out_dir} {
    set mig_files [list]
    foreach pattern [list \
        [file join $project_dir "*.srcs/sources_1/bd/top/ip/top_mig_7series_0_0*/board.prj"] \
        [file join $project_dir "*.gen/sources_1/bd/top/ip/top_mig_7series_0_0*/top_mig_7series_0_0/mig.prj"] \
        [file join $project_dir "*.gen/sources_1/bd/top/ip/top_mig_7series_0_0*/top_mig_7series_0_0/user_design/constraints/top_mig_7series_0_0.xdc"] \
        [file join $project_dir "*.gen/sources_1/bd/top/ip/top_mig_7series_0_0*/top_mig_7series_0_0/user_design/constraints/top_mig_7series_0_0.ucf"] \
        [file join $project_dir "*.gen/sources_1/bd/top/ip/top_mig_7series_0_0*/top_mig_7series_0_0/example_design/par/example_top.xdc"] \
    ] {
        foreach path [glob -nocomplain $pattern] {
            lappend mig_files $path
            file copy -force $path [file join $out_dir [file tail $path]]
        }
    }

    set manifest ""
    foreach path [lsort -unique $mig_files] {
        append manifest "$path\n"
    }
    write_file [file join $out_dir "mig-source-artifacts.txt"] $manifest
}

proc export_placement_csv {out_dir} {
    set path [file join $out_dir "ddr3-primitive-placement.csv"]
    set fh [open $path w]
    puts $fh "cell,ref_name,primitive_type,site,bel,loc"

    foreach cell [lsort [get_cells -hier -quiet]] {
        set ref [get_property REF_NAME $cell]
        set primitive [get_property PRIMITIVE_TYPE $cell]
        set name [get_property NAME $cell]
        set site [get_property SITE $cell]
        set bel [get_property BEL $cell]
        set loc [get_property LOC $cell]

        set keep 0
        if {[regexp -nocase {mig|ddr|dqs|dq|phaser|idelay|odelay|iserdes|oserdes|phy|mmcm|pll|bufg|bufio|bufr|iobuf|ibuf|obuf} $name]} {
            set keep 1
        }
        if {[regexp -nocase {IDELAY|ODELAY|ISERDES|OSERDES|PHASER|PHY_CONTROL|IDELAYCTRL|MMCM|PLL|BUFG|BUFIO|BUFR|IOB|IBUF|OBUF} "$ref $primitive"]} {
            set keep 1
        }
        if {$keep} {
            puts $fh "\"$name\",\"$ref\",\"$primitive\",\"$site\",\"$bel\",\"$loc\""
        }
    }

    close $fh
}

proc export_reports {out_dir} {
    file mkdir $out_dir

    report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -max_paths 20 -file [file join $out_dir "timing-summary.rpt"]
    report_utilization -hierarchical -file [file join $out_dir "utilization-hierarchical.rpt"]
    report_io -file [file join $out_dir "io.rpt"]
    report_clock_utilization -file [file join $out_dir "clock-utilization.rpt"]
    report_drc -file [file join $out_dir "drc.rpt"]
    write_checkpoint -force [file join $out_dir "post-route.dcp"]
    write_xdc -force [file join $out_dir "implemented.xdc"]
    export_placement_csv $out_dir
}

proc prepare_ip_outputs {out_dir} {
    file mkdir $out_dir
    report_ip_status -file [file join $out_dir "ip-status-before.rpt"]

    set ips [get_ips -quiet]
    if {[llength $ips] > 0} {
        puts "Upgrading IP instances where Vivado has a current catalog definition..."
        catch {upgrade_ip $ips} upgrade_result
        puts $upgrade_result
    }

    set bd_files [list]
    foreach bd [get_files -quiet *.bd] {
        if {[string first ".srcs/" $bd] >= 0} {
            lappend bd_files $bd
        }
    }
    if {[llength $bd_files] == 0} {
        foreach bd [get_files -quiet */*.bd] {
            if {[string first ".srcs/" $bd] >= 0} {
                lappend bd_files $bd
            }
        }
    }
    foreach bd $bd_files {
        puts "Generating targets for $bd"
        generate_target all $bd
        export_ip_user_files -of_objects $bd -no_script -sync -force -quiet
    }

    report_ip_status -file [file join $out_dir "ip-status-after.rpt"]
}

proc write_calibration_debug_net_report {out_dir} {
    file mkdir $out_dir

    set path [file join $out_dir "calibration-debug-nets.txt"]
    set fh [open $path w]
    puts $fh "# Nets"

    set net_patterns [list \
        *init_calib* \
        *calib_complete* \
        *ui_clk_sync_rst* \
        *mmcm_locked* \
        *pll_locked* \
        *tg_compare_error* \
        *vio* \
        *ila* \
    ]
    foreach pattern $net_patterns {
        set nets [lsort [get_nets -hier -quiet $pattern]]
        if {[llength $nets] > 0} {
            puts $fh ""
            puts $fh "pattern=$pattern"
            foreach net $nets {
                puts $fh "  $net"
            }
        }
    }

    puts $fh ""
    puts $fh "# Pins"
    set pin_patterns [list \
        *init_calib* \
        *calib_complete* \
        *ui_clk_sync_rst* \
        *mmcm_locked* \
        *pll_locked* \
        *tg_compare_error* \
    ]
    foreach pattern $pin_patterns {
        set pins [lsort [get_pins -hier -quiet $pattern]]
        if {[llength $pins] > 0} {
            puts $fh ""
            puts $fh "pattern=$pattern"
            foreach pin $pins {
                puts $fh "  $pin"
            }
        }
    }

    close $fh
    puts "Calibration debug net report written to $path"
}

set action "check"
if {[llength $argv] > 0} {
    set action [lindex $argv 0]
}

set project [env_default YPCB_VIVADO_PROJECT "/home/roland/ypcb_00338_1p1_hack/examples/YPCB_00338_1P1_systest/YPCB_00338_1P1_systest.xpr"]
set board_repo [env_default YPCB_BOARD_REPO "/home/roland/ypcb_00338_1p1_hack"]
set out_dir [env_default YPCB_VIVADO_ORACLE_OUT "artifacts/task6/vivado-oracle/ypcb-systest"]
set jobs [env_default YPCB_VIVADO_JOBS "8"]
set serial [env_default YPCB_VIVADO_HW_SERIAL "210299BF3824"]

file mkdir $out_dir
set_param board.repoPaths $board_repo

if {$action eq "check"} {
    set summary ""
    append summary "vivado_version=[version -short]\n"
    append summary "project=$project\n"
    append summary "board_repo=$board_repo\n"
    append summary "part_xc7k480tffg1156_2=[join [get_parts -quiet xc7k480tffg1156-2] ,]\n"
    append summary "part_xc7k480tffg1156_1=[join [get_parts -quiet xc7k480tffg1156-1] ,]\n"
    append summary "memory_ipdefs=[join [get_ipdefs -quiet *mig*] ,]\n"

    if {[file exists $project]} {
        open_project $project
        append summary "current_part=[get_property PART [current_project]]\n"
        append summary "board_part=[get_property BOARD_PART [current_project]]\n"
        append summary "runs=[join [get_runs] ,]\n"
        append summary "ip=[join [get_ips -quiet *mig*] ,]\n"
        append summary "ipdefs_after_open=[join [get_ipdefs -quiet *mig*] ,]\n"
        close_project
    } else {
        append summary "project_exists=false\n"
    }

    write_file [file join $out_dir "vivado-check.txt"] $summary
    puts $summary
    exit
}

open_project $project

if {$action eq "prepare-ip"} {
    prepare_ip_outputs $out_dir
    close_project
    puts "Vivado IP output preparation artifacts written to $out_dir"
    exit
}

if {$action eq "build"} {
    prepare_ip_outputs $out_dir
    reset_run synth_1
    launch_runs synth_1 -jobs $jobs
    wait_on_run synth_1
    if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
        error "synth_1 did not complete"
    }

    launch_runs impl_1 -to_step write_bitstream -jobs $jobs
    wait_on_run impl_1
    if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
        error "impl_1 did not complete"
    }
}

if {$action eq "build" || $action eq "export"} {
    open_run impl_1
    export_reports $out_dir
    export_mig_source_artifacts [file dirname $project] $out_dir
    copy_first_match [list \
        [file join [file dirname $project] "*.runs/impl_1/*.bit"] \
        [file join [file dirname $project] "*.runs/impl_1/*.ltx"] \
    ] $out_dir
    close_project
    puts "Vivado oracle artifacts written to $out_dir"
    exit
}

if {$action eq "debug-nets"} {
    open_run impl_1
    write_calibration_debug_net_report $out_dir
    close_project
    exit
}

if {$action eq "program"} {
    set bit [lindex [glob -nocomplain [file join $out_dir "*.bit"]] 0]
    set ltx [lindex [glob -nocomplain [file join $out_dir "*.ltx"]] 0]
    if {$bit eq ""} {
        error "No bitstream found in $out_dir; run build or export first"
    }

    open_hw_manager
    connect_hw_server
    open_hw_target
    set devs [get_hw_devices -quiet *]
    if {[llength $devs] == 0} {
        error "No hardware devices found"
    }
    set dev [lindex $devs 0]
    current_hw_device $dev
    set_property PROGRAM.FILE $bit $dev
    if {$ltx ne ""} {
        set_property PROBES.FILE $ltx $dev
    }
    program_hw_devices $dev
    refresh_hw_device $dev
    puts "Programmed $bit"
    close_hw_manager
    close_project
    exit
}

error "Unknown action: $action"

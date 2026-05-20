# Build tiny Vivado CMT_FIFO route bitstream-delta oracle variants.
#
# Usage:
#   vivado -mode batch -nojournal -nolog \
#     -source scripts/task6/build_vivado_cmt_fifo_route_oracle.tcl \
#     -tclargs build <variant> <out_dir>
#
# Variants:
#   none                         no FIFO baseline for same top-level shell
#   in_fifo_empty, out_fifo_empty
#   in_fifo_dNN, out_fifo_dNN      route FIFO data input D<N>[N]
#   in_fifo_rdclk, in_fifo_wrclk, out_fifo_rdclk, out_fifo_wrclk
#   in_fifo_reset, out_fifo_reset, in_fifo_rden, out_fifo_wren
#   both_fifo_clkrst            combined IN/OUT FIFO clock/reset footprint
#
# These bitstreams are for route segbit discovery only, not hardware use.

proc write_file {path text} {
    set fp [open $path w]
    puts -nonewline $fp $text
    close $fp
}

proc variant_kind {variant} {
    if {$variant eq "none"} {
        return "none"
    }
    if {$variant eq "both_fifo_clkrst"} {
        return "both_fifo"
    }
    if {[regexp {^(in_fifo|out_fifo)_} $variant -> kind]} {
        return $kind
    }
    error "unknown CMT_FIFO oracle variant '$variant'"
}

proc fifo_loc {kind} {
    if {$kind eq "in_fifo"} {
        return "IN_FIFO_X0Y0"
    }
    if {$kind eq "out_fifo"} {
        return "OUT_FIFO_X0Y0"
    }
    error "unknown FIFO kind '$kind'"
}

proc fifo_ref {kind} {
    if {$kind eq "in_fifo"} {
        return "IN_FIFO"
    }
    if {$kind eq "out_fifo"} {
        return "OUT_FIFO"
    }
    error "unknown FIFO kind '$kind'"
}

proc fifo_d_width {kind port_index} {
    if {$kind eq "in_fifo"} {
        if {$port_index in {5 6}} {
            return 8
        }
        return 4
    }
    return 8
}

proc fifo_instance {variant} {
    if {$variant eq "none"} {
        return ""
    }
    if {$variant eq "both_fifo_clkrst"} {
        return "    (* keep = \"true\", dont_touch = \"true\" *) IN_FIFO in_fifo_i (
        .RDCLK(clk50),
        .WRCLK(clk50),
        .RESET(route_sig)
    );

    (* keep = \"true\", dont_touch = \"true\" *) OUT_FIFO out_fifo_i (
        .RDCLK(clk50),
        .WRCLK(clk50),
        .RESET(route_sig)
    );
"
    }

    set kind [variant_kind $variant]
    set ref [fifo_ref $kind]
    set ports {}

    set declarations ""
    if {[regexp {^(in_fifo|out_fifo)_d([0-9])([0-9])$} $variant -> _ port_index bit_index]} {
        set width [fifo_d_width $kind $port_index]
        if {$bit_index >= $width} {
            error "$kind D$port_index bit $bit_index exceeds width $width"
        }
        set declarations "    wire \[[expr {$width - 1}]:0\] route_bus;
    assign route_bus\[$bit_index\] = route_sig;

"
        lappend ports ".D${port_index}(route_bus)"
    } elseif {$variant eq "${kind}_rdclk"} {
        lappend ports ".RDCLK(clk50)"
    } elseif {$variant eq "${kind}_wrclk"} {
        lappend ports ".WRCLK(clk50)"
    } elseif {$variant eq "${kind}_reset"} {
        lappend ports ".RESET(route_sig)"
    } elseif {$variant eq "${kind}_rden"} {
        lappend ports ".RDEN(route_sig)"
    } elseif {$variant eq "${kind}_wren"} {
        lappend ports ".WREN(route_sig)"
    } elseif {$variant eq "${kind}_empty"} {
        # Baseline: instantiate only, with no routed pins.
    } else {
        error "unknown CMT_FIFO oracle variant '$variant'"
    }

    if {[llength $ports] == 0} {
        return "    (* keep = \"true\", dont_touch = \"true\" *) $ref fifo_i ();\n"
    }

    set joined [join $ports ",
        "]
    return "$declarations    (* keep = \"true\", dont_touch = \"true\" *) $ref fifo_i (
        $joined
    );
"
}

proc top_verilog {variant} {
    set inst [fifo_instance $variant]
    return "`default_nettype none

module top (
    input wire clk50,
    input wire rst_n,
    output wire \[2:0\] led
);
    wire rst = ~rst_n;
    reg \[25:0\] blink_counter = 26'h0;

    always @(posedge clk50 or posedge rst) begin
        if (rst)
            blink_counter <= 26'h0;
        else
            blink_counter <= blink_counter + 1'b1;
    end

    (* keep = \"true\" *) wire route_sig = blink_counter\[3\];

$inst

    assign led\[0\] = blink_counter\[23\];
    assign led\[1\] = blink_counter\[24\];
    assign led\[2\] = blink_counter\[25\];
endmodule

`default_nettype wire
"
}

proc top_xdc {variant} {
    set kind [variant_kind $variant]
    set loc ""
    if {$kind ne "both_fifo" && $kind ne "none"} {
        set loc [fifo_loc $kind]
    }
    set xdc "set_property LOC AA28 \[get_ports clk50\]
set_property IOSTANDARD LVCMOS18 \[get_ports clk50\]
create_clock -name clk50 -period 20.000 \[get_ports clk50\]

set_property LOC R28 \[get_ports rst_n\]
set_property IOSTANDARD LVCMOS18 \[get_ports rst_n\]

set_property LOC P30 \[get_ports {led\[0\]}\]
set_property LOC M30 \[get_ports {led\[1\]}\]
set_property LOC N30 \[get_ports {led\[2\]}\]
set_property IOSTANDARD LVCMOS18 \[get_ports {led\[0\]}\]
set_property IOSTANDARD LVCMOS18 \[get_ports {led\[1\]}\]
set_property IOSTANDARD LVCMOS18 \[get_ports {led\[2\]}\]

"
    if {$kind eq "none"} {
        # No hard FIFO instance in this variant.
    } elseif {$kind eq "both_fifo"} {
        append xdc "set_property LOC IN_FIFO_X0Y0 \[get_cells in_fifo_i\]
"
        append xdc "set_property LOC OUT_FIFO_X0Y0 \[get_cells out_fifo_i\]
"
    } else {
        append xdc "set_property LOC $loc \[get_cells fifo_i\]
"
    }
    return $xdc
}

proc build_variant {variant out_dir} {
    file mkdir $out_dir
    set src [file join $out_dir "top_${variant}.v"]
    set xdc [file join $out_dir "top_${variant}.xdc"]
    write_file $src [top_verilog $variant]
    write_file $xdc [top_xdc $variant]

    create_project -force "cmt_fifo_${variant}" [file join $out_dir "vivado_project"] -part xc7k480tffg1156-2
    read_verilog $src
    read_xdc $xdc
    synth_design -top top -part xc7k480tffg1156-2
    opt_design
    place_design
    route_design
    write_checkpoint -force [file join $out_dir "post-route.dcp"]
    write_xdc -force [file join $out_dir "implemented.xdc"]
    write_bitstream -force [file join $out_dir "top_${variant}.bit"]
    report_utilization -file [file join $out_dir "utilization.rpt"]
    report_drc -file [file join $out_dir "drc.rpt"]
}

if {$argc < 3} {
    error "usage: build_vivado_cmt_fifo_route_oracle.tcl build <variant> <out_dir>"
}

set action [lindex $argv 0]
set variant [lindex $argv 1]
set out_dir [lindex $argv 2]

if {$action ne "build"} {
    error "unknown action '$action'"
}

build_variant $variant $out_dir

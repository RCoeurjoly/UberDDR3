# Build tiny Vivado oracle variants for dedicated PHASER_IN -> IN_FIFO routes.
#
# Usage:
#   vivado -mode batch -nojournal -nolog \
#     -source scripts/task6/build_vivado_cmt_fifo_phaser_route_oracle.tcl \
#     -tclargs build <variant> <out_dir>
#
# Variants:
#   phaser_in_fifo_empty
#   phaser_in_fifo_wrclk
#   phaser_in_fifo_wren
#
# These bitstreams are for CMT_FIFO_R route segbit discovery only, not hardware.

proc write_file {path text} {
    set fp [open $path w]
    puts -nonewline $fp $text
    close $fp
}

proc top_verilog {variant} {
    set fifo_ports ""
    if {$variant eq "phaser_in_fifo_wrclk"} {
        set fifo_ports "        .WRCLK(iclkdiv)\n"
    } elseif {$variant eq "phaser_in_fifo_wren"} {
        set fifo_ports "        .WREN(wrenable)\n"
    } elseif {$variant ne "phaser_in_fifo_empty"} {
        error "unknown PHASER/FIFO oracle variant '$variant'"
    }

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

    wire phaser_freq_refclk;
    wire phaser_sync_refclk;
    wire phaser_pll_fb;
    wire phaser_pll_locked;
    wire phaser_ref_locked;
    wire dqs_found;
    wire dqs_out_of_range;
    wire fine_overflow;
    wire iclk;
    wire iclkdiv;
    wire iserdes_rst;
    wire phase_locked;
    wire rclk;
    wire wrenable;
    wire \[5:0\] counter_read;

    (* keep = \"true\", dont_touch = \"true\" *)
    PLLE2_ADV #(
        .BANDWIDTH(\"OPTIMIZED\"),
        .COMPENSATION(\"INTERNAL\"),
        .STARTUP_WAIT(\"FALSE\"),
        .DIVCLK_DIVIDE(1),
        .CLKFBOUT_MULT(16),
        .CLKFBOUT_PHASE(0.000),
        .CLKOUT0_DIVIDE(2),
        .CLKOUT0_PHASE(0.000),
        .CLKOUT0_DUTY_CYCLE(0.500),
        .CLKOUT1_DIVIDE(2),
        .CLKOUT1_PHASE(0.000),
        .CLKOUT1_DUTY_CYCLE(0.500),
        .CLKIN1_PERIOD(20.000)
    ) phaser_pll_i (
        .CLKFBOUT(phaser_pll_fb),
        .CLKOUT0(phaser_freq_refclk),
        .CLKOUT1(phaser_sync_refclk),
        .CLKFBIN(phaser_pll_fb),
        .CLKIN1(clk50),
        .CLKINSEL(1'b1),
        .LOCKED(phaser_pll_locked),
        .PWRDWN(1'b0),
        .RST(rst)
    );

    (* keep = \"true\", dont_touch = \"true\" *)
    PHASER_REF phaser_ref_i (
        .LOCKED(phaser_ref_locked),
        .CLKIN(phaser_freq_refclk),
        .PWRDWN(1'b0),
        .RST(rst)
    );

    (* keep = \"true\", dont_touch = \"true\" *)
    PHASER_IN_PHY #(
        .CLKOUT_DIV(4),
        .OUTPUT_CLK_SRC(\"PHASE_REF\"),
        .REFCLK_PERIOD(2.500),
        .MEMREFCLK_PERIOD(2.500),
        .PHASEREFCLK_PERIOD(2.500)
    ) phaser_in_i (
        .DQSFOUND(dqs_found),
        .DQSOUTOFRANGE(dqs_out_of_range),
        .FINEOVERFLOW(fine_overflow),
        .ICLK(iclk),
        .ICLKDIV(iclkdiv),
        .ISERDESRST(iserdes_rst),
        .PHASELOCKED(phase_locked),
        .RCLK(rclk),
        .WRENABLE(wrenable),
        .COUNTERREADVAL(counter_read),
        .BURSTPENDINGPHY(1'b0),
        .COUNTERLOADEN(1'b0),
        .COUNTERREADEN(blink_counter\[20\]),
        .FINEENABLE(1'b0),
        .FINEINC(1'b0),
        .FREQREFCLK(phaser_freq_refclk),
        .MEMREFCLK(phaser_freq_refclk),
        .PHASEREFCLK(),
        .RST(rst),
        .RSTDQSFIND(rst),
        .SYNCIN(phaser_sync_refclk),
        .SYSCLK(clk50),
        .ENCALIBPHY(2'b00),
        .RANKSELPHY(2'b00),
        .COUNTERLOADVAL(blink_counter\[5:0\])
    );

    (* keep = \"true\", dont_touch = \"true\" *)
    IN_FIFO in_fifo_i (
$fifo_ports    );

    assign led\[0\] = blink_counter\[23\] ^ phaser_ref_locked;
    assign led\[1\] = blink_counter\[24\] ^ phase_locked;
    assign led\[2\] = blink_counter\[25\] ^ dqs_found;
endmodule

`default_nettype wire
"
}

proc top_xdc {} {
    return "set_property LOC AA28 \[get_ports clk50\]
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

set_property LOC PHASER_REF_X0Y0 \[get_cells phaser_ref_i\]
set_property LOC PLLE2_ADV_X0Y1 \[get_cells phaser_pll_i\]
set_property LOC PHASER_IN_PHY_X0Y0 \[get_cells phaser_in_i\]
set_property LOC IN_FIFO_X0Y0 \[get_cells in_fifo_i\]
"
}

proc write_routes {path} {
    set fp [open $path w]
    foreach net [lsort [get_nets -hierarchical]] {
        set pips [get_pips -quiet -of_objects $net]
        if {[llength $pips] == 0} {
            continue
        }
        puts $fp "NET [get_property NAME $net]"
        foreach pip [lsort $pips] {
            puts $fp "  PIP $pip"
        }
    }
    close $fp
}

proc build_variant {variant out_dir} {
    file mkdir $out_dir
    set src [file join $out_dir "top_${variant}.v"]
    set xdc [file join $out_dir "top_${variant}.xdc"]
    write_file $src [top_verilog $variant]
    write_file $xdc [top_xdc]

    create_project -force "cmt_fifo_${variant}" [file join $out_dir "vivado_project"] -part xc7k480tffg1156-2
    read_verilog $src
    read_xdc $xdc
    synth_design -top top -part xc7k480tffg1156-2
    opt_design
    place_design
    route_design
    write_routes [file join $out_dir "routes.txt"]
    write_checkpoint -force [file join $out_dir "post-route.dcp"]
    write_xdc -force [file join $out_dir "implemented.xdc"]
    write_bitstream -force [file join $out_dir "top_${variant}.bit"]
    report_utilization -file [file join $out_dir "utilization.rpt"]
    report_drc -file [file join $out_dir "drc.rpt"]
}

if {$argc < 3} {
    error "usage: build_vivado_cmt_fifo_phaser_route_oracle.tcl build <variant> <out_dir>"
}

set action [lindex $argv 0]
set variant [lindex $argv 1]
set out_dir [lindex $argv 2]

if {$action ne "build"} {
    error "unknown action '$action'"
}

build_variant $variant $out_dir

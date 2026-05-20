# Build tiny Vivado PHASER/FIFO/PHY_CONTROL bitstream-delta oracle variants.
#
# Usage:
#   vivado -mode batch -nojournal -nolog -source scripts/task6/ypcb_phaser_feature_oracle.tcl \
#     -tclargs build <variant> <out_dir>
#
# Variants are intentionally tiny and differ by one hard macro or parameter.
# The output bitstreams are for prjxray frame-delta discovery, not hardware use.

proc write_file {path text} {
    set fp [open $path w]
    puts -nonewline $fp $text
    close $fp
}

proc variant_body {variant} {
    set common {
    (* keep = "true", dont_touch = "true" *) PHASER_REF phaser_ref_i ();
}
    set phaser_ref_clocked {
    wire phaser_pll_fb;
    wire phaser_freq_refclk;
    wire phaser_sync_refclk;
    wire phaser_pll_locked;
    wire phaser_ref_locked;

    (* keep = "true", dont_touch = "true" *)
    PLLE2_ADV #(
        .BANDWIDTH("OPTIMIZED"),
        .COMPENSATION("INTERNAL"),
        .STARTUP_WAIT("FALSE"),
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

    (* keep = "true", dont_touch = "true" *) PHASER_REF phaser_ref_i (
        .LOCKED(phaser_ref_locked),
        .CLKIN(phaser_freq_refclk),
        .PWRDWN(1'b0),
        .RST(rst)
    );
}
    switch -- $variant {
        none {
            return ""
        }
        phaser_ref {
            return $common
        }
        phaser_ref_clocked {
            return $phaser_ref_clocked
        }
        phaser_ref_ddr3_laneA_clocked {
            return $phaser_ref_clocked
        }
        phy_control {
            return "$common
    (* keep = \"true\", dont_touch = \"true\" *)
    PHY_CONTROL #(
        .BURST_MODE(\"FALSE\"),
        .CLK_RATIO(4),
        .SYNC_MODE(\"FALSE\")
    ) phy_control_i ();
"
        }
        phaser_in_div4 {
            return "$common
    (* keep = \"true\", dont_touch = \"true\" *)
    PHASER_IN_PHY #(
        .CLKOUT_DIV(4),
        .OUTPUT_CLK_SRC(\"PHASE_REF\"),
        .REFCLK_PERIOD(2.500),
        .MEMREFCLK_PERIOD(2.500),
        .PHASEREFCLK_PERIOD(2.500)
    ) phaser_in_i ();
"
        }
        phaser_in_div4_clocked {
            return "$phaser_ref_clocked
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
"
        }
        phaser_in_ddr3_laneA_clocked {
            return "$phaser_ref_clocked
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
    PHASER_IN_PHY #(
        .CLKOUT_DIV(2),
        .FINE_DELAY(33),
        .OUTPUT_CLK_SRC(\"DELAYED_REF\"),
        .REFCLK_PERIOD(1.875),
        .MEMREFCLK_PERIOD(1.875),
        .PHASEREFCLK_PERIOD(1.875)
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
"
        }
        phaser_in_div2 {
            return "$common
    (* keep = \"true\", dont_touch = \"true\" *)
    PHASER_IN_PHY #(
        .CLKOUT_DIV(2),
        .OUTPUT_CLK_SRC(\"PHASE_REF\"),
        .REFCLK_PERIOD(2.500),
        .MEMREFCLK_PERIOD(2.500),
        .PHASEREFCLK_PERIOD(2.500)
    ) phaser_in_i ();
"
        }
        phaser_out_div4 {
            return "$common
    (* keep = \"true\", dont_touch = \"true\" *)
    PHASER_OUT_PHY #(
        .CLKOUT_DIV(4),
        .OUTPUT_CLK_SRC(\"PHASE_REF\"),
        .REFCLK_PERIOD(2.500),
        .MEMREFCLK_PERIOD(2.500),
        .PHASEREFCLK_PERIOD(2.500)
    ) phaser_out_i ();
"
        }
        phaser_out_div2 {
            return "$common
    (* keep = \"true\", dont_touch = \"true\" *)
    PHASER_OUT_PHY #(
        .CLKOUT_DIV(2),
        .OUTPUT_CLK_SRC(\"PHASE_REF\"),
        .REFCLK_PERIOD(2.500),
        .MEMREFCLK_PERIOD(2.500),
        .PHASEREFCLK_PERIOD(2.500)
    ) phaser_out_i ();
"
        }
        phaser_out_div4_clocked {
            return "$phaser_ref_clocked
    wire coarse_overflow;
    wire fine_overflow;
    wire oclk;
    wire oclk_delayed;
    wire oclkdiv;
    wire oserdes_rst;
    wire rd_enable;
    wire \[1:0\] cts_bus;
    wire \[1:0\] dqs_bus;
    wire \[1:0\] dts_bus;
    wire \[8:0\] counter_read;

    (* keep = \"true\", dont_touch = \"true\" *)
    PHASER_OUT_PHY #(
        .CLKOUT_DIV(4),
        .OUTPUT_CLK_SRC(\"PHASE_REF\"),
        .REFCLK_PERIOD(2.500),
        .MEMREFCLK_PERIOD(2.500),
        .PHASEREFCLK_PERIOD(2.500)
    ) phaser_out_i (
        .COARSEOVERFLOW(coarse_overflow),
        .FINEOVERFLOW(fine_overflow),
        .OCLK(oclk),
        .OCLKDELAYED(oclk_delayed),
        .OCLKDIV(oclkdiv),
        .OSERDESRST(oserdes_rst),
        .RDENABLE(rd_enable),
        .CTSBUS(cts_bus),
        .DQSBUS(dqs_bus),
        .DTSBUS(dts_bus),
        .COUNTERREADVAL(counter_read),
        .COARSEENABLE(1'b0),
        .COARSEINC(1'b0),
        .COUNTERLOADEN(1'b0),
        .COUNTERREADEN(blink_counter\[20\]),
        .FINEENABLE(1'b0),
        .FINEINC(1'b0),
        .FREQREFCLK(phaser_freq_refclk),
        .MEMREFCLK(phaser_freq_refclk),
        .PHASEREFCLK(),
        .RST(rst),
        .SELFINEOCLKDELAY(1'b0),
        .SYNCIN(phaser_sync_refclk),
        .SYSCLK(clk50),
        .ENCALIBPHY(2'b00),
        .COUNTERLOADVAL(blink_counter\[8:0\])
    );
"
        }
        phaser_out_ddr3_laneA_clocked {
            return "$phaser_ref_clocked
    wire coarse_overflow;
    wire fine_overflow;
    wire oclk;
    wire oclk_delayed;
    wire oclkdiv;
    wire oserdes_rst;
    wire rd_enable;
    wire \[1:0\] cts_bus;
    wire \[1:0\] dqs_bus;
    wire \[1:0\] dts_bus;
    wire \[8:0\] counter_read;

    (* keep = \"true\", dont_touch = \"true\" *)
    PHASER_OUT_PHY #(
        .CLKOUT_DIV(2),
        .DATA_CTL_N(\"TRUE\"),
        .FINE_DELAY(60),
        .OCLKDELAY_INV(\"TRUE\"),
        .OUTPUT_CLK_SRC(\"DELAYED_REF\"),
        .REFCLK_PERIOD(1.875),
        .MEMREFCLK_PERIOD(1.875),
        .PHASEREFCLK_PERIOD(1.000)
    ) phaser_out_i (
        .COARSEOVERFLOW(coarse_overflow),
        .FINEOVERFLOW(fine_overflow),
        .OCLK(oclk),
        .OCLKDELAYED(oclk_delayed),
        .OCLKDIV(oclkdiv),
        .OSERDESRST(oserdes_rst),
        .RDENABLE(rd_enable),
        .CTSBUS(cts_bus),
        .DQSBUS(dqs_bus),
        .DTSBUS(dts_bus),
        .COUNTERREADVAL(counter_read),
        .BURSTPENDINGPHY(1'b0),
        .COARSEENABLE(1'b0),
        .COARSEINC(1'b0),
        .COUNTERLOADEN(1'b0),
        .COUNTERREADEN(blink_counter\[20\]),
        .FINEENABLE(1'b0),
        .FINEINC(1'b0),
        .FREQREFCLK(phaser_freq_refclk),
        .MEMREFCLK(phaser_freq_refclk),
        .PHASEREFCLK(),
        .RST(rst),
        .SELFINEOCLKDELAY(1'b0),
        .SYNCIN(phaser_sync_refclk),
        .SYSCLK(clk50),
        .ENCALIBPHY(2'b00),
        .COUNTERLOADVAL(blink_counter\[8:0\])
    );
"
        }
        in_fifo {
            return "$common
    (* keep = \"true\", dont_touch = \"true\" *) IN_FIFO in_fifo_i ();
"
        }
        out_fifo {
            return "$common
    (* keep = \"true\", dont_touch = \"true\" *) OUT_FIFO out_fifo_i ();
"
        }
        default {
            error "unknown PHASER oracle variant '$variant'"
        }
    }
}

proc placement_constraints {variant} {
    set locks ""
    if {$variant in {phaser_ref phaser_ref_clocked phaser_ref_ddr3_laneA_clocked phy_control phaser_in_div4 phaser_in_div2 phaser_in_div4_clocked phaser_in_ddr3_laneA_clocked phaser_out_div4 phaser_out_div2 phaser_out_div4_clocked phaser_out_ddr3_laneA_clocked in_fifo out_fifo}} {
        append locks "set_property LOC PHASER_REF_X0Y0 \[get_cells phaser_ref_i\]\n"
    }
    if {$variant in {phaser_ref_ddr3_laneA_clocked phaser_in_ddr3_laneA_clocked phaser_out_ddr3_laneA_clocked}} {
        set locks ""
        append locks "set_property LOC PHASER_REF_X0Y2 \[get_cells phaser_ref_i\]\n"
    }
    if {$variant in {phaser_ref_clocked phaser_ref_ddr3_laneA_clocked}} {
        append locks "set_property LOC PLLE2_ADV_X0Y1 \[get_cells phaser_pll_i\]\n"
    }
    if {$variant in {phaser_in_div4_clocked phaser_out_div4_clocked phaser_in_ddr3_laneA_clocked phaser_out_ddr3_laneA_clocked}} {
        append locks "set_property LOC PLLE2_ADV_X0Y1 \[get_cells phaser_pll_i\]\n"
    }
    if {$variant eq "phy_control"} {
        append locks "set_property LOC PHY_CONTROL_X0Y0 \[get_cells phy_control_i\]\n"
    }
    if {$variant in {phaser_in_div4 phaser_in_div2 phaser_in_div4_clocked}} {
        append locks "set_property LOC PHASER_IN_PHY_X0Y0 \[get_cells phaser_in_i\]\n"
    }
    if {$variant eq "phaser_in_ddr3_laneA_clocked"} {
        append locks "set_property LOC PHASER_IN_PHY_X0Y8 \[get_cells phaser_in_i\]\n"
    }
    if {$variant in {phaser_out_div4 phaser_out_div2 phaser_out_div4_clocked}} {
        append locks "set_property LOC PHASER_OUT_PHY_X0Y0 \[get_cells phaser_out_i\]\n"
    }
    if {$variant eq "phaser_out_ddr3_laneA_clocked"} {
        append locks "set_property LOC PHASER_OUT_PHY_X0Y8 \[get_cells phaser_out_i\]\n"
    }
    if {$variant eq "in_fifo"} {
        append locks "set_property LOC IN_FIFO_X0Y0 \[get_cells in_fifo_i\]\n"
    }
    if {$variant eq "out_fifo"} {
        append locks "set_property LOC OUT_FIFO_X0Y0 \[get_cells out_fifo_i\]\n"
    }
    return $locks
}

proc top_verilog {variant} {
    set body [variant_body $variant]
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

$body

    assign led\[0\] = blink_counter\[23\];
    assign led\[1\] = blink_counter\[24\];
    assign led\[2\] = blink_counter\[25\];
endmodule

`default_nettype wire
"
}

proc top_xdc {variant} {
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

[placement_constraints $variant]"
}

proc build_variant {variant out_dir} {
    file mkdir $out_dir
    set src [file join $out_dir "top_${variant}.v"]
    set xdc [file join $out_dir "top_${variant}.xdc"]
    write_file $src [top_verilog $variant]
    write_file $xdc [top_xdc $variant]

    create_project -force "phaser_${variant}" [file join $out_dir "vivado_project"] -part xc7k480tffg1156-2
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
    error "usage: ypcb_phaser_feature_oracle.tcl build <variant> <out_dir>"
}

set action [lindex $argv 0]
set variant [lindex $argv 1]
set out_dir [lindex $argv 2]

if {$action ne "build"} {
    error "unknown action '$action'"
}

build_variant $variant $out_dir

# Probe map for the YPCB SYSTEST MIG PHASER byte-lane sequencing oracle.
# The paths target channel 0, ddr_phy_4lanes_0, byte lane A in the routed
# working Vivado reference. Entries are hard-macro pin paths where possible;
# the build script resolves each pin to its connected routed net.

set c0_lane0_base {top_i/mig_7series_0/u_top_mig_7series_0_0_mig/c0_u_memc_ui_top_axi/mem_intfc0/ddr_phy_top0/u_ddr_mc_phy_wrapper/u_ddr_mc_phy/ddr_phy_4lanes_0.u_ddr_phy_4lanes}
set c0_laneA_base "$c0_lane0_base/ddr_byte_lane_A.ddr_byte_lane_A"
set c0_phyctl "$c0_lane0_base/phy_control_i"
set c0_phaser_ref "$c0_lane0_base/phaser_ref_i"
set c0_phaser_in "$c0_laneA_base/phaser_in_gen.phaser_in"
set c0_phaser_out "$c0_laneA_base/phaser_out"

set phyctlwd_pins {}
for {set bit 0} {$bit < 32} {incr bit} {
    lappend phyctlwd_pins "$c0_phyctl/PHYCTLWD\[$bit\]"
}

set PHASER_BYTE_LANE_ORACLE_PROBES [list \
    [list capture_clk [list "$c0_phyctl/PHYCLK"] 1] \
    [list phaser_pll_locked [list "$c0_phyctl/PLLLOCK"] 1] \
    [list phaser_ref_locked [list "$c0_phaser_ref/LOCKED"] 1] \
    [list in_phase_locked [list "$c0_phaser_in/PHASELOCKED"] 1] \
    [list phyctl_ready [list "$c0_phyctl/PHYCTLREADY"] 1] \
    [list phaser_ref_pwrdwn [list "$c0_phaser_ref/PWRDWN"] 1] \
    [list phaser_ref_reset [list "$c0_phaser_ref/RST"] 1] \
    [list phyctl_reset [list "$c0_phyctl/RESET"] 1] \
    [list phyctl_readcalibenable [list "$c0_phyctl/READCALIBENABLE"] 1] \
    [list phyctl_writecalibenable [list "$c0_phyctl/WRITECALIBENABLE"] 1] \
    [list phyctlwrenable [list "$c0_phyctl/PHYCTLWRENABLE"] 1] \
    [list phyctlwd $phyctlwd_pins 32] \
    [list lane_reset [list "$c0_phaser_in/RST"] 1] \
    [list rstdqsfind [list "$c0_phaser_in/RSTDQSFIND"] 1] \
    [list sync_enable [list "$c0_phyctl/SYNCIN"] 1] \
    [list phaser_in_syncin [list "$c0_phaser_in/SYNCIN"] 1] \
    [list dqs_found [list "$c0_phaser_in/DQSFOUND"] 1] \
]

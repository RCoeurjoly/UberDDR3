################################################################################
# IO constraints
################################################################################
# clk200:0.p
set_property LOC AH27 [get_ports {clk200_p}]
set_property IOSTANDARD LVDS_25 [get_ports {clk200_p}]

# clk200:0.n
set_property LOC AH28 [get_ports {clk200_n}]
set_property IOSTANDARD LVDS_25 [get_ports {clk200_n}]

# rst_n:0
set_property LOC R28 [get_ports {rst_n}]
set_property IOSTANDARD LVCMOS18 [get_ports {rst_n}]

# ddram_reduced:0.a
set_property LOC AK27 [get_ports {ddram_reduced0_a[0]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[0]}]

# ddram_reduced:0.a
set_property LOC AN23 [get_ports {ddram_reduced0_a[1]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[1]}]

# ddram_reduced:0.a
set_property LOC AL24 [get_ports {ddram_reduced0_a[2]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[2]}]

# ddram_reduced:0.a
set_property LOC AK26 [get_ports {ddram_reduced0_a[3]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[3]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[3]}]

# ddram_reduced:0.a
set_property LOC AH24 [get_ports {ddram_reduced0_a[4]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[4]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[4]}]

# ddram_reduced:0.a
set_property LOC AH25 [get_ports {ddram_reduced0_a[5]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[5]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[5]}]

# ddram_reduced:0.a
set_property LOC AL26 [get_ports {ddram_reduced0_a[6]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[6]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[6]}]

# ddram_reduced:0.a
set_property LOC AJ24 [get_ports {ddram_reduced0_a[7]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[7]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[7]}]

# ddram_reduced:0.a
set_property LOC AJ25 [get_ports {ddram_reduced0_a[8]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[8]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[8]}]

# ddram_reduced:0.a
set_property LOC AM23 [get_ports {ddram_reduced0_a[9]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[9]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[9]}]

# ddram_reduced:0.a
set_property LOC AL28 [get_ports {ddram_reduced0_a[10]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[10]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[10]}]

# ddram_reduced:0.a
set_property LOC AL25 [get_ports {ddram_reduced0_a[11]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[11]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[11]}]

# ddram_reduced:0.a
set_property LOC AM25 [get_ports {ddram_reduced0_a[12]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[12]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[12]}]

# ddram_reduced:0.a
set_property LOC AK24 [get_ports {ddram_reduced0_a[13]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[13]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[13]}]

# ddram_reduced:0.a
set_property LOC AM27 [get_ports {ddram_reduced0_a[14]}]
set_property SLEW FAST [get_ports {ddram_reduced0_a[14]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_a[14]}]

# ddram_reduced:0.ba
set_property LOC AM26 [get_ports {ddram_reduced0_ba[0]}]
set_property SLEW FAST [get_ports {ddram_reduced0_ba[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_ba[0]}]

# ddram_reduced:0.ba
set_property LOC AP24 [get_ports {ddram_reduced0_ba[1]}]
set_property SLEW FAST [get_ports {ddram_reduced0_ba[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_ba[1]}]

# ddram_reduced:0.ba
set_property LOC AN28 [get_ports {ddram_reduced0_ba[2]}]
set_property SLEW FAST [get_ports {ddram_reduced0_ba[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_ba[2]}]

# ddram_reduced:0.ras_n
set_property LOC AJ29 [get_ports {ddram_reduced0_ras_n}]
set_property SLEW FAST [get_ports {ddram_reduced0_ras_n}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_ras_n}]

# ddram_reduced:0.cas_n
set_property LOC AP26 [get_ports {ddram_reduced0_cas_n}]
set_property SLEW FAST [get_ports {ddram_reduced0_cas_n}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_cas_n}]

# ddram_reduced:0.we_n
set_property LOC AN27 [get_ports {ddram_reduced0_we_n}]
set_property SLEW FAST [get_ports {ddram_reduced0_we_n}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_we_n}]

# ddram_reduced:0.cs_n
set_property LOC AK28 [get_ports {ddram_reduced0_cs_n}]
set_property SLEW FAST [get_ports {ddram_reduced0_cs_n}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_cs_n}]

# ddram_reduced:0.cke
set_property LOC AP27 [get_ports {ddram_reduced0_cke}]
set_property SLEW FAST [get_ports {ddram_reduced0_cke}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_cke}]

# ddram_reduced:0.odt
set_property LOC AK29 [get_ports {ddram_reduced0_odt}]
set_property SLEW FAST [get_ports {ddram_reduced0_odt}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_odt}]

# ddram_reduced:0.reset_n
set_property LOC AD31 [get_ports {ddram_reduced0_reset_n}]
set_property SLEW FAST [get_ports {ddram_reduced0_reset_n}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_reset_n}]

# ddram_reduced:0.dq
set_property LOC AG17 [get_ports {ddram_reduced0_dq[0]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[0]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[0]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[0]}]

# ddram_reduced:0.dq
set_property LOC AG16 [get_ports {ddram_reduced0_dq[1]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[1]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[1]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[1]}]

# ddram_reduced:0.dq
set_property LOC AH17 [get_ports {ddram_reduced0_dq[2]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[2]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[2]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[2]}]

# ddram_reduced:0.dq
set_property LOC AJ19 [get_ports {ddram_reduced0_dq[3]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[3]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[3]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[3]}]

# ddram_reduced:0.dq
set_property LOC AH18 [get_ports {ddram_reduced0_dq[4]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[4]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[4]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[4]}]

# ddram_reduced:0.dq
set_property LOC AH19 [get_ports {ddram_reduced0_dq[5]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[5]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[5]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[5]}]

# ddram_reduced:0.dq
set_property LOC AJ16 [get_ports {ddram_reduced0_dq[6]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[6]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[6]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[6]}]

# ddram_reduced:0.dq
set_property LOC AJ17 [get_ports {ddram_reduced0_dq[7]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[7]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[7]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[7]}]

# ddram_reduced:0.dq
set_property LOC AL20 [get_ports {ddram_reduced0_dq[8]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[8]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[8]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[8]}]

# ddram_reduced:0.dq
set_property LOC AN17 [get_ports {ddram_reduced0_dq[9]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[9]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[9]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[9]}]

# ddram_reduced:0.dq
set_property LOC AL19 [get_ports {ddram_reduced0_dq[10]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[10]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[10]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[10]}]

# ddram_reduced:0.dq
set_property LOC AM16 [get_ports {ddram_reduced0_dq[11]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[11]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[11]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[11]}]

# ddram_reduced:0.dq
set_property LOC AL18 [get_ports {ddram_reduced0_dq[12]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[12]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[12]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[12]}]

# ddram_reduced:0.dq
set_property LOC AL16 [get_ports {ddram_reduced0_dq[13]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[13]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[13]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[13]}]

# ddram_reduced:0.dq
set_property LOC AM20 [get_ports {ddram_reduced0_dq[14]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[14]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[14]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[14]}]

# ddram_reduced:0.dq
set_property LOC AN18 [get_ports {ddram_reduced0_dq[15]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[15]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[15]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[15]}]

# ddram_reduced:0.dq
set_property LOC AL23 [get_ports {ddram_reduced0_dq[16]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[16]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[16]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[16]}]

# ddram_reduced:0.dq
set_property LOC AN20 [get_ports {ddram_reduced0_dq[17]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[17]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[17]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[17]}]

# ddram_reduced:0.dq
set_property LOC AK23 [get_ports {ddram_reduced0_dq[18]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[18]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[18]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[18]}]

# ddram_reduced:0.dq
set_property LOC AP19 [get_ports {ddram_reduced0_dq[19]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[19]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[19]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[19]}]

# ddram_reduced:0.dq
set_property LOC AN22 [get_ports {ddram_reduced0_dq[20]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[20]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[20]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[20]}]

# ddram_reduced:0.dq
set_property LOC AN19 [get_ports {ddram_reduced0_dq[21]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[21]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[21]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[21]}]

# ddram_reduced:0.dq
set_property LOC AM22 [get_ports {ddram_reduced0_dq[22]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[22]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[22]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[22]}]

# ddram_reduced:0.dq
set_property LOC AP20 [get_ports {ddram_reduced0_dq[23]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[23]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[23]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[23]}]

# ddram_reduced:0.dq
set_property LOC AJ21 [get_ports {ddram_reduced0_dq[24]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[24]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[24]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[24]}]

# ddram_reduced:0.dq
set_property LOC AH22 [get_ports {ddram_reduced0_dq[25]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[25]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[25]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[25]}]

# ddram_reduced:0.dq
set_property LOC AK21 [get_ports {ddram_reduced0_dq[26]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[26]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[26]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[26]}]

# ddram_reduced:0.dq
set_property LOC AG21 [get_ports {ddram_reduced0_dq[27]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[27]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[27]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[27]}]

# ddram_reduced:0.dq
set_property LOC AG22 [get_ports {ddram_reduced0_dq[28]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[28]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[28]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[28]}]

# ddram_reduced:0.dq
set_property LOC AG20 [get_ports {ddram_reduced0_dq[29]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[29]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[29]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[29]}]

# ddram_reduced:0.dq
set_property LOC AH23 [get_ports {ddram_reduced0_dq[30]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[30]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[30]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[30]}]

# ddram_reduced:0.dq
set_property LOC AG23 [get_ports {ddram_reduced0_dq[31]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dq[31]}]
set_property IOSTANDARD SSTL15 [get_ports {ddram_reduced0_dq[31]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dq[31]}]

# ddram_reduced:0.dqs_p
set_property LOC AK16 [get_ports {ddram_reduced0_dqs_p[0]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dqs_p[0]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddram_reduced0_dqs_p[0]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dqs_p[0]}]

# ddram_reduced:0.dqs_p
set_property LOC AM17 [get_ports {ddram_reduced0_dqs_p[1]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dqs_p[1]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddram_reduced0_dqs_p[1]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dqs_p[1]}]

# ddram_reduced:0.dqs_p
set_property LOC AP21 [get_ports {ddram_reduced0_dqs_p[2]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dqs_p[2]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddram_reduced0_dqs_p[2]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dqs_p[2]}]

# ddram_reduced:0.dqs_p
set_property LOC AH20 [get_ports {ddram_reduced0_dqs_p[3]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dqs_p[3]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddram_reduced0_dqs_p[3]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dqs_p[3]}]

# ddram_reduced:0.dqs_n
set_property LOC AK17 [get_ports {ddram_reduced0_dqs_n[0]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dqs_n[0]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddram_reduced0_dqs_n[0]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dqs_n[0]}]

# ddram_reduced:0.dqs_n
set_property LOC AM18 [get_ports {ddram_reduced0_dqs_n[1]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dqs_n[1]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddram_reduced0_dqs_n[1]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dqs_n[1]}]

# ddram_reduced:0.dqs_n
set_property LOC AP22 [get_ports {ddram_reduced0_dqs_n[2]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dqs_n[2]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddram_reduced0_dqs_n[2]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dqs_n[2]}]

# ddram_reduced:0.dqs_n
set_property LOC AJ20 [get_ports {ddram_reduced0_dqs_n[3]}]
set_property SLEW FAST [get_ports {ddram_reduced0_dqs_n[3]}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddram_reduced0_dqs_n[3]}]
set_property IN_TERM UNTUNED_SPLIT_40 [get_ports {ddram_reduced0_dqs_n[3]}]

# ddram_reduced:0.clk_p
set_property LOC AN25 [get_ports {ddram_reduced0_clk_p}]
set_property SLEW FAST [get_ports {ddram_reduced0_clk_p}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddram_reduced0_clk_p}]

# ddram_reduced:0.clk_n
set_property LOC AP25 [get_ports {ddram_reduced0_clk_n}]
set_property SLEW FAST [get_ports {ddram_reduced0_clk_n}]
set_property IOSTANDARD DIFF_SSTL15 [get_ports {ddram_reduced0_clk_n}]

################################################################################
# Clock constraints
################################################################################

create_clock -name {name} -period 5.0 [get_ports clk200_p]
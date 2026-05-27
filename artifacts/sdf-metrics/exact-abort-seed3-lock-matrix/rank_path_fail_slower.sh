#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Strict fail-slower candidate endpoints.

echo '## 1: exact-abort-seed3-idelay-control-full-locked fail idelay_dqs_cntvaluein lane1 dqs1 4 1819.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEIN4' --limit 10

echo '## 2: exact-abort-seed3-idelay-control-full-locked fail idelay_dqs_cntvaluein lane0 dqs0 4 2141.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN4' --limit 10

echo '## 3: exact-abort-seed3-idelay-control-full-locked fail clocking all   6974.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A2' --limit 10

echo '## 4: exact-abort-seed3-idelay-control-full-locked fail clocking all   6914.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A4' --limit 10

echo '## 5: exact-abort-seed3-idelay-control-full-locked fail clocking all   6885.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A2' --limit 10

echo '## 6: exact-abort-seed3-idelay-control-full-locked fail clocking all   6885.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197697.A2' --limit 10

echo '## 7: exact-abort-seed3-idelay-control-full-locked fail clocking all   6855.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A2' --limit 10

echo '## 8: exact-abort-seed3-idelay-control-full-locked fail clocking all   6690.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198391.A3' --limit 10

echo '## 9: exact-abort-seed3-idelay-control-full-locked fail clocking all   6074.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192486.A5' --limit 10

echo '## 10: exact-abort-seed3-idelay-control-full-locked fail clocking all   2730.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198399.A4' --limit 10

echo '## 11: exact-abort-seed3-idelay-control-full-locked fail clocking all   1735.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$iopadmap\$ypcb_00338_1p1_ddr3\.led_2\$intcell\$OBUF.IN' --limit 10

echo '## 12: exact-abort-seed3-idelay-control-full-locked fail clocking all   1422.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$ff\.cc\:266\:slice\$45520.D' --limit 10

echo '## 13: exact-abort-seed3-idelay-control-full-locked fail clocking all   1312.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$iopadmap\$ypcb_00338_1p1_ddr3\.clk50\$intcell\$IBUF.OUT' 'clk_wiz_inst\.plle2_adv_inst.CLKIN1' --limit 10

echo '## 14: exact-abort-seed3-idelay-control-full-locked fail clocking all   1294.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.CLKOUT0' 'clk_wiz_inst\.clkout1_buf.I0' --limit 10

echo '## 15: exact-abort-seed3-idelay-control-full-locked fail clocking all   1294.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.CLKOUT1' 'clk_wiz_inst\.clkout2_buf.I0' --limit 10

echo '## 16: exact-abort-seed3-idelay-control-full-locked fail clocking all   1294.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.CLKOUT2' 'clk_wiz_inst\.clkout3_buf.I0' --limit 10

echo '## 17: exact-abort-seed3-idelay-control-full-locked fail clocking all   1294.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.CLKOUT3' 'clk_wiz_inst\.clkout4_buf.I0' --limit 10

echo '## 18: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[0\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 19: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[10\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 20: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[11\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 21: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[12\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 22: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[13\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 23: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[14\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 24: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[15\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 25: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[16\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 26: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[17\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 27: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[19\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 28: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[1\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 29: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[20\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 30: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[21\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 31: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[22\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 32: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[23\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 33: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[24\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 34: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[2\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 35: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[3\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 36: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[4\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 37: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[5\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 38: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[6\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 39: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[7\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 40: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[8\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 41: exact-abort-seed3-idelay-control-full-locked fail clocking all   1243.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[9\]\.OSERDESE2_cmd.CLK' --limit 10

echo '## 42: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[0\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 43: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[10\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 44: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[11\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 45: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[12\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 46: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[13\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 47: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[14\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 48: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[15\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 49: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[16\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 50: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[17\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 51: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[19\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 52: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[1\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 53: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[20\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 54: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[21\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 55: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[22\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 56: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[23\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 57: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[24\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 58: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[2\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 59: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[3\]\.OSERDESE2_cmd.CLKDIV' --limit 10

echo '## 60: exact-abort-seed3-idelay-control-full-locked fail clocking all   1208.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout1_buf.O' 'ddr3_top_inst\.ddr3_phy_inst\.genblk1\[4\]\.OSERDESE2_cmd.CLKDIV' --limit 10

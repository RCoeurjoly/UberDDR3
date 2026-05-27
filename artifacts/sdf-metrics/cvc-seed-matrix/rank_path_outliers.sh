#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: seed2-fail fail clocking all   6914.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$aiger179447\$17594.A1' --limit 10

echo '## 2: seed2-fail fail clocking all   6914.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$not\$aiger179447\$155.A1' --limit 10

echo '## 3: seed3-pass pass clocking all   6855.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$not\$aiger179447\$155.A1' --limit 10

echo '## 4: seed3-pass pass clocking all   6855.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[3\]\[4\].A1' --limit 10

echo '## 5: seed1-robust robust clocking all   5985.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184242.A2' --limit 10

echo '## 6: seed2-robust robust clocking all   5519.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A2' --limit 10

echo '## 7: seed3-pass pass clocking all   5429.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184240.A5' --limit 10

echo '## 8: seed1-fail fail clocking all   5159.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A1' --limit 10

echo '## 9: seed2-fail fail clocking all   4994.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A4' --limit 10

echo '## 10: seed2-fail fail clocking all   4949.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180133.A1' --limit 10

echo '## 11: seed3-pass pass clocking all   4635.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184236.A1' --limit 10

echo '## 12: seed3-pass pass clocking all   4635.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180119.A3' --limit 10

echo '## 13: seed3-pass pass clocking all   4635.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A3' --limit 10

echo '## 14: seed3-pass pass clocking all   4349.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180133.A1' --limit 10

echo '## 15: seed3-pass pass clocking all   3822.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184242.A4' --limit 10

echo '## 16: seed1-robust robust clocking all   3690.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184236.A2' --limit 10

echo '## 17: seed1-fail fail dq_iologic lane0 dq4  3608.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.ISERDESE2_data.RST' --limit 10

echo '## 18: seed1-fail fail dq_iologic lane0 dq4  3608.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 19: seed1-fail fail dq_iologic lane0 dq1  3444.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.RST' --limit 10

echo '## 20: seed1-fail fail dq_iologic lane0 dq1  3444.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 21: seed1-fail fail clocking all   3420.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184236.A2' --limit 10

echo '## 22: seed2-robust robust clocking all   3420.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184236.A2' --limit 10

echo '## 23: seed1-fail fail dq_iologic lane1 dq15  3417.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.ISERDESE2_data.RST' --limit 10

echo '## 24: seed1-fail fail dq_iologic lane1 dq15  3417.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 25: seed2-robust robust dqs_iologic lane1 dqs1  3404.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.ISERDESE2_dqs.RST' --limit 10

echo '## 26: seed2-robust robust dqs_iologic lane1 dqs1  3404.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.genblk1\.OSERDESE2_dqs.RST' --limit 10

echo '## 27: seed2-fail fail clocking all   3390.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184236.A1' --limit 10

echo '## 28: seed1-fail fail dqs_iologic lane1 dqs1  3378.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.ISERDESE2_dqs.RST' --limit 10

echo '## 29: seed1-fail fail dqs_iologic lane1 dqs1  3378.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.genblk1\.OSERDESE2_dqs.RST' --limit 10

echo '## 30: seed1-fail fail idelayctrl all   3371.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RST' --limit 10

echo '## 31: seed1-fail fail dq_iologic lane1 dq12  3240.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.ISERDESE2_data.RST' --limit 10

echo '## 32: seed1-fail fail dq_iologic lane1 dq12  3240.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 33: seed1-robust robust clocking all   3237.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184240.A4' --limit 10

echo '## 34: seed3-pass pass dq_iologic lane1 dq8  3213.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.ISERDESE2_data.RST' --limit 10

echo '## 35: seed3-pass pass dq_iologic lane1 dq8  3213.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 36: seed1-fail fail dq_iologic lane1 dq14  3163.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.ISERDESE2_data.RST' --limit 10

echo '## 37: seed1-fail fail dq_iologic lane1 dq14  3163.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 38: seed2-robust robust dqs_iologic lane0 dqs0  3128.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.ISERDESE2_dqs.RST' --limit 10

echo '## 39: seed2-robust robust dqs_iologic lane0 dqs0  3128.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.genblk1\.OSERDESE2_dqs.RST' --limit 10

echo '## 40: seed3-pass pass dqs_iologic lane0 dqs0  3122.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.ISERDESE2_dqs.RST' --limit 10

echo '## 41: seed3-pass pass dqs_iologic lane0 dqs0  3122.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.genblk1\.OSERDESE2_dqs.RST' --limit 10

echo '## 42: seed2-fail fail clocking all   3092.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184240.A4' --limit 10

echo '## 43: seed2-fail fail idelayctrl all   3089.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$179448\$lut\$aiger179447\$4266.A2' --limit 10

echo '## 44: seed1-fail fail dq_iologic lane1 dq8  3085.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.ISERDESE2_data.RST' --limit 10

echo '## 45: seed1-fail fail dq_iologic lane1 dq8  3085.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 46: seed2-robust robust clocking all   3076.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184242.A4' --limit 10

echo '## 47: seed3-pass pass dq_iologic lane0 dq5  3075.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.ISERDESE2_data.RST' --limit 10

echo '## 48: seed3-pass pass dq_iologic lane0 dq5  3075.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 49: seed1-fail fail dqs_iologic lane0 dqs0  3072.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.ISERDESE2_dqs.RST' --limit 10

echo '## 50: seed1-fail fail dqs_iologic lane0 dqs0  3072.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.genblk1\.OSERDESE2_dqs.RST' --limit 10

echo '## 51: seed2-robust robust dq_iologic lane0 dq4  3066.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.ISERDESE2_data.RST' --limit 10

echo '## 52: seed2-robust robust dq_iologic lane0 dq4  3066.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 53: seed1-fail fail clocking all   3059.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184242.A4' --limit 10

echo '## 54: seed1-fail fail clocking all   3059.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184240.A4' --limit 10

echo '## 55: seed2-robust robust dq_iologic lane1 dq8  3058.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.ISERDESE2_data.RST' --limit 10

echo '## 56: seed2-robust robust dq_iologic lane1 dq8  3058.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 57: seed2-robust robust dq_iologic lane0 dq3  3049.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.ISERDESE2_data.RST' --limit 10

echo '## 58: seed2-robust robust dq_iologic lane0 dq3  3049.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 59: seed2-fail fail idelayctrl all   3045.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$179476.A5' --limit 10

echo '## 60: seed3-pass pass dq_iologic lane1 dq9  3042.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[9\]\.ISERDESE2_data.RST' --limit 10

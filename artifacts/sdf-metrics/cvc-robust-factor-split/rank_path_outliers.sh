#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: seed2-no-tmdriv no_tmdriv clocking all   7050.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$aiger179447\$12148.A1' --limit 10

echo '## 2: seed2-no-tmdriv no_tmdriv clocking all   7050.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$not\$aiger179447\$155.A1' --limit 10

echo '## 3: seed2-fail fail clocking all   6914.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$aiger179447\$17594.A1' --limit 10

echo '## 4: seed2-fail fail clocking all   6914.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$not\$aiger179447\$155.A1' --limit 10

echo '## 5: seed3-pass pass clocking all   6855.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$not\$aiger179447\$155.A1' --limit 10

echo '## 6: seed3-pass pass clocking all   6855.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[3\]\[4\].A1' --limit 10

echo '## 7: seed5-pass pass clocking all   6824.0 ps'
sdf-toolkit rank-paths result-sdf-seed5-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$not\$aiger179447\$155.A1' --limit 10

echo '## 8: seed5-pass pass clocking all   6824.0 ps'
sdf-toolkit rank-paths result-sdf-seed5-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$179735.A1' --limit 10

echo '## 9: seed1-no-tmdriv no_tmdriv clocking all   6494.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$aiger179447\$16117.A1' --limit 10

echo '## 10: seed1-no-tmdriv no_tmdriv clocking all   6494.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$179448\$lut\$not\$aiger179447\$155.A1' --limit 10

echo '## 11: seed1-robust robust clocking all   5985.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184242.A2' --limit 10

echo '## 12: seed2-no-tmdriv no_tmdriv clocking all   5670.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184240.A2' --limit 10

echo '## 13: seed1-reset-locks-only reset_locks_only clocking all   5579.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184240.A1' --limit 10

echo '## 14: seed1-no-tmdriv no_tmdriv clocking all   5550.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184240.A3' --limit 10

echo '## 15: seed1-reset-locks-only reset_locks_only clocking all   5550.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184242.A1' --limit 10

echo '## 16: seed2-robust robust clocking all   5519.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A2' --limit 10

echo '## 17: seed1-no-tmdriv no_tmdriv clocking all   5460.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184242.A5' --limit 10

echo '## 18: seed1-no-tmdriv no_tmdriv clocking all   5460.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A1' --limit 10

echo '## 19: seed2-reset-locks-only reset_locks_only clocking all   5460.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184242.A3' --limit 10

echo '## 20: seed3-pass pass clocking all   5429.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184240.A5' --limit 10

echo '## 21: seed4-pass pass clocking all   5429.0 ps'
sdf-toolkit rank-paths result-sdf-seed4-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184240.A5' --limit 10

echo '## 22: seed4-pass pass clocking all   5429.0 ps'
sdf-toolkit rank-paths result-sdf-seed4-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A4' --limit 10

echo '## 23: seed2-reset-locks-only reset_locks_only clocking all   5429.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184240.A3' --limit 10

echo '## 24: seed1-reset-locks-only reset_locks_only clocking all   5355.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180133.A1' --limit 10

echo '## 25: seed2-no-tmdriv no_tmdriv clocking all   5324.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A2' --limit 10

echo '## 26: seed1-fail fail clocking all   5159.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A1' --limit 10

echo '## 27: seed1-no-tmdriv no_tmdriv clocking all   5144.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180133.A3' --limit 10

echo '## 28: seed5-pass pass clocking all   5130.0 ps'
sdf-toolkit rank-paths result-sdf-seed5-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180133.A5' --limit 10

echo '## 29: seed1-reset-locks-only reset_locks_only clocking all   5085.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A5' --limit 10

echo '## 30: seed2-reset-locks-only reset_locks_only clocking all   5054.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A1' --limit 10

echo '## 31: seed2-reset-locks-only reset_locks_only clocking all   5054.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180133.A1' --limit 10

echo '## 32: seed2-fail fail clocking all   4994.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A4' --limit 10

echo '## 33: seed2-fail fail clocking all   4949.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180133.A1' --limit 10

echo '## 34: seed4-pass pass clocking all   4949.0 ps'
sdf-toolkit rank-paths result-sdf-seed4-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180133.A1' --limit 10

echo '## 35: seed5-pass pass clocking all   4875.0 ps'
sdf-toolkit rank-paths result-sdf-seed5-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A2' --limit 10

echo '## 36: seed3-pass pass clocking all   4635.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184236.A1' --limit 10

echo '## 37: seed3-pass pass clocking all   4635.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180119.A3' --limit 10

echo '## 38: seed3-pass pass clocking all   4635.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180120.A3' --limit 10

echo '## 39: seed3-pass pass clocking all   4349.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$180133.A1' --limit 10

echo '## 40: seed2-reset-locks-only reset_locks_only dq_iologic lane0 dq7  3875.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.ISERDESE2_data.RST' --limit 10

echo '## 41: seed2-reset-locks-only reset_locks_only dq_iologic lane0 dq7  3875.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 42: seed3-pass pass clocking all   3822.0 ps'
sdf-toolkit rank-paths result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184242.A4' --limit 10

echo '## 43: seed1-no-tmdriv no_tmdriv clocking all   3795.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184236.A4' --limit 10

echo '## 44: seed2-no-tmdriv no_tmdriv clocking all   3795.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184236.A4' --limit 10

echo '## 45: seed2-reset-locks-only reset_locks_only dq_iologic lane0 dq4  3759.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.ISERDESE2_data.RST' --limit 10

echo '## 46: seed2-reset-locks-only reset_locks_only dq_iologic lane0 dq4  3759.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 47: seed1-reset-locks-only reset_locks_only dq_iologic lane0 dq5  3750.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.ISERDESE2_data.RST' --limit 10

echo '## 48: seed1-reset-locks-only reset_locks_only dq_iologic lane0 dq5  3750.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 49: seed2-reset-locks-only reset_locks_only dq_iologic lane0 dq5  3706.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.ISERDESE2_data.RST' --limit 10

echo '## 50: seed2-reset-locks-only reset_locks_only dq_iologic lane0 dq5  3706.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 51: seed2-reset-locks-only reset_locks_only dqs_iologic lane0 dqs0  3704.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.ISERDESE2_dqs.RST' --limit 10

echo '## 52: seed2-reset-locks-only reset_locks_only dqs_iologic lane0 dqs0  3704.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.genblk1\.OSERDESE2_dqs.RST' --limit 10

echo '## 53: seed1-robust robust clocking all   3690.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$184236.A2' --limit 10

echo '## 54: seed1-reset-locks-only reset_locks_only dq_iologic lane0 dq3  3665.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.ISERDESE2_data.RST' --limit 10

echo '## 55: seed1-reset-locks-only reset_locks_only dq_iologic lane0 dq3  3665.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 56: seed1-reset-locks-only reset_locks_only dq_iologic lane1 dq9  3657.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[9\]\.ISERDESE2_data.RST' --limit 10

echo '## 57: seed1-reset-locks-only reset_locks_only dq_iologic lane1 dq9  3657.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[9\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 58: seed1-reset-locks-only reset_locks_only dqs_iologic lane1 dqs1  3653.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.ISERDESE2_dqs.RST' --limit 10

echo '## 59: seed1-reset-locks-only reset_locks_only dqs_iologic lane1 dqs1  3653.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.genblk1\.OSERDESE2_dqs.RST' --limit 10

echo '## 60: seed1-reset-locks-only reset_locks_only dqs_iologic lane0 dqs0  3644.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43799.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.ISERDESE2_dqs.RST' --limit 10

#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: seed3-pass pass clocking all   6855.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$198366.A2' --limit 10

echo '## 2: seed3-pass pass clocking all   6855.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193147.A4' --limit 10

echo '## 3: seed3-pass pass clocking all   6105.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$198370.A4' --limit 10

echo '## 4: seed3-pass pass clocking all   6000.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$abc\$192946\$lut\$aiger192945\$4921.A5' --limit 10

echo '## 5: seed3-pass pass clocking all   5610.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$199198.A3' --limit 10

echo '## 6: seed3-pass pass clocking all   5445.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$199194.A5' --limit 10

echo '## 7: seed3-pass pass clocking all   5039.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$198368.A1' --limit 10

echo '## 8: seed3-pass pass clocking all   4248.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$198372.A1' --limit 10

echo '## 9: seed3-pass pass clocking all   3765.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$199200.A1' --limit 10

echo '## 10: seed3-pass pass dqs_iologic lane0 dqs0  3255.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193589.A2' --limit 10

echo '## 11: seed3-pass pass dqs_iologic lane0 dqs0  3224.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193603.A4' --limit 10

echo '## 12: seed3-pass pass dq_iologic lane1 dq12  3059.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45935.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.genblk1\.OSERDESE2_data.D5' --limit 10

echo '## 13: seed3-pass pass dqs_iologic lane0 dqs0  3015.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193540.A5' --limit 10

echo '## 14: seed3-pass pass dqs_iologic lane0 dqs0  3015.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$abc\$192946\$lut\$aiger192945\$6015.A2' --limit 10

echo '## 15: seed3-pass pass dqs_iologic lane0 dqs0  3015.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$abc\$192946\$lut\$aiger192945\$6015.A4' --limit 10

echo '## 16: seed3-pass pass dqs_iologic lane0 dqs0  3000.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193524.A1' --limit 10

echo '## 17: seed3-pass pass dq_iologic lane1 dq12  2964.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45919.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.genblk1\.OSERDESE2_data.D4' --limit 10

echo '## 18: seed3-pass pass idelayctrl all   2954.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193144.A3' --limit 10

echo '## 19: seed3-pass pass idelayctrl all   2954.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$192946\$lut\$aiger192945\$5004.A3' --limit 10

echo '## 20: seed3-pass pass idelayctrl all   2940.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193597.A1' --limit 10

echo '## 21: seed3-pass pass idelayctrl all   2940.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193660.A1' --limit 10

echo '## 22: seed3-pass pass dqs_iologic lane1 dqs1  2924.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193128.A4' --limit 10

echo '## 23: seed3-pass pass dqs_iologic lane0 dqs0  2924.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$abc\$192946\$lut\$aiger192945\$6008.A4' --limit 10

echo '## 24: seed3-pass pass dqs_iologic lane0 dqs0  2924.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$abc\$192946\$lut\$aiger192945\$6008.A1' --limit 10

echo '## 25: seed3-pass pass dqs_iologic lane0 dqs0  2924.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$192946\$lut\$auto\$opt_dff\.cc\:219\:make_patterns_logic\$28130.A4' --limit 10

echo '## 26: seed3-pass pass dqs_iologic lane1 dqs1  2865.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193589.A4' --limit 10

echo '## 27: seed3-pass pass dq_iologic lane1 dq12  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45967.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.genblk1\.OSERDESE2_data.D7' --limit 10

echo '## 28: seed3-pass pass dq_iologic lane1 dq12  2721.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45951.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 29: seed3-pass pass dq_iologic lane1 dq12  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$192946\$lut\$aiger192945\$12025.A2' --limit 10

echo '## 30: seed3-pass pass dq_iologic lane1 dq12  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$192946\$lut\$aiger192945\$5028.A2' --limit 10

echo '## 31: seed3-pass pass dq_iologic lane1 dq10  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192946\$lut\$aiger192945\$5085.A5' --limit 10

echo '## 32: seed3-pass pass dq_iologic lane1 dq12  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192946\$lut\$aiger192945\$5028.A1' --limit 10

echo '## 33: seed3-pass pass dq_iologic lane1 dq10  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$192946\$lut\$aiger192945\$5093.A2' --limit 10

echo '## 34: seed3-pass pass dq_iologic lane1 dq12  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$192946\$lut\$aiger192945\$5036.A4' --limit 10

echo '## 35: seed3-pass pass dq_iologic lane0 dq7  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192946\$lut\$aiger192945\$15492.A4' --limit 10

echo '## 36: seed3-pass pass dq_iologic lane1 dq10  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192946\$lut\$aiger192945\$5085.A4' --limit 10

echo '## 37: seed3-pass pass dq_iologic lane1 dq12  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192946\$lut\$aiger192945\$5028.A5' --limit 10

echo '## 38: seed3-pass pass dq_iologic lane1 dq12  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192946\$lut\$aiger192945\$5036.A5' --limit 10

echo '## 39: seed3-pass pass dq_iologic lane1 dq10  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192946\$lut\$aiger192945\$5093.A1' --limit 10

echo '## 40: seed3-pass pass dq_iologic lane1 dq12  2654.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192946\$lut\$aiger192945\$13382.A3' --limit 10

echo '## 41: seed3-pass pass dqs_iologic lane1 dqs1  2654.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$abc\$192946\$lut\$aiger192945\$5186.A5' --limit 10

echo '## 42: seed3-pass pass dqs_iologic lane1 dqs1  2654.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$192946\$lut\$aiger192945\$5193.A4' --limit 10

echo '## 43: seed3-pass pass dqs_iologic lane1 dqs1  2654.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$abc\$192946\$lut\$aiger192945\$5193.A1' --limit 10

echo '## 44: seed3-pass pass dqs_iologic lane1 dqs1  2654.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$abc\$192946\$lut\$auto\$opt_dff\.cc\:219\:make_patterns_logic\$28133.A5' --limit 10

echo '## 45: seed3-pass pass dqs_iologic lane1 dqs1  2625.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193540.A2' --limit 10

echo '## 46: seed3-pass pass dqs_iologic lane1 dqs1  2609.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193524.A4' --limit 10

echo '## 47: seed3-pass pass dq_iologic lane1 dq11  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$192946\$lut\$aiger192945\$5066.A5' --limit 10

echo '## 48: seed3-pass pass dq_iologic lane1 dq8  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192946\$lut\$aiger192945\$13368.A5' --limit 10

echo '## 49: seed3-pass pass dq_iologic lane1 dq8  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192946\$lut\$aiger192945\$13370.A5' --limit 10

echo '## 50: seed3-pass pass dq_iologic lane1 dq11  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192946\$lut\$aiger192945\$5066.A1' --limit 10

echo '## 51: seed3-pass pass dq_iologic lane1 dq14  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192946\$lut\$aiger192945\$13381.A1' --limit 10

echo '## 52: seed3-pass pass dq_iologic lane1 dq14  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192946\$lut\$aiger192945\$12037.A1' --limit 10

echo '## 53: seed3-pass pass dq_iologic lane1 dq11  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$192946\$lut\$aiger192945\$5074.A2' --limit 10

echo '## 54: seed3-pass pass dq_iologic lane1 dq11  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192946\$lut\$aiger192945\$5066.A3' --limit 10

echo '## 55: seed3-pass pass dq_iologic lane1 dq11  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192946\$lut\$aiger192945\$5074.A1' --limit 10

echo '## 56: seed3-pass pass dq_iologic lane1 dq14  2572.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45969.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.genblk1\.OSERDESE2_data.D7' --limit 10

echo '## 57: seed3-pass pass dq_iologic lane1 dq13  2565.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$192946\$lut\$aiger192945\$5126.A1' --limit 10

echo '## 58: seed3-pass pass dq_iologic lane1 dq13  2565.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192946\$lut\$aiger192945\$5126.A5' --limit 10

echo '## 59: seed3-pass pass dq_iologic lane1 dq13  2565.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$192946\$lut\$aiger192945\$5134.A5' --limit 10

echo '## 60: seed3-pass pass dq_iologic lane1 dq13  2565.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192946\$lut\$aiger192945\$5134.A2' --limit 10

#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: seed3-pass pass clocking all   7110.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$195936.A4' --limit 10

echo '## 2: seed3-pass pass clocking all   7110.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$190580.A2' --limit 10

echo '## 3: seed3-pass pass clocking all   6989.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$195934.A2' --limit 10

echo '## 4: seed3-pass pass clocking all   6989.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$195920.A5' --limit 10

echo '## 5: seed3-pass pass clocking all   6420.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$191311.A4' --limit 10

echo '## 6: seed3-pass pass clocking all   6420.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$abc\$190551\$lut\$aiger190550\$8642.A4' --limit 10

echo '## 7: seed3-pass pass clocking all   5849.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$196522.A1' --limit 10

echo '## 8: seed3-pass pass clocking all   4526.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$195922.A2' --limit 10

echo '## 9: seed3-pass pass clocking all   4434.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$195924.A2' --limit 10

echo '## 10: seed3-pass pass clocking all   4353.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$195926.A2' --limit 10

echo '## 11: seed3-pass pass dq_iologic lane0 dq7  3026.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45587.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.genblk1\.OSERDESE2_data.D7' --limit 10

echo '## 12: seed3-pass pass dq_iologic lane0 dq3  2852.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45551.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.genblk1\.OSERDESE2_data.D5' --limit 10

echo '## 13: seed3-pass pass dq_iologic lane1 dq8  2819.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45508.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.D2' --limit 10

echo '## 14: seed3-pass pass dqs_iologic lane0 dqs0  2805.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$190551\$lut\$aiger190550\$9392.A5' --limit 10

echo '## 15: seed3-pass pass dqs_iologic lane0 dqs0  2805.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$abc\$190551\$lut\$aiger190550\$9392.A1' --limit 10

echo '## 16: seed3-pass pass dqs_iologic lane0 dqs0  2775.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$abc\$190551\$lut\$aiger190550\$9385.A5' --limit 10

echo '## 17: seed3-pass pass dqs_iologic lane0 dqs0  2775.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$abc\$190551\$lut\$auto\$opt_dff\.cc\:219\:make_patterns_logic\$27957.A2' --limit 10

echo '## 18: seed3-pass pass dq_iologic lane1 dq8  2766.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45604.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.D8' --limit 10

echo '## 19: seed3-pass pass dq_iologic lane0 dq3  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45503.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.genblk1\.OSERDESE2_data.D2' --limit 10

echo '## 20: seed3-pass pass idelayctrl all   2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$190551\$lut\$aiger190550\$8813.A5' --limit 10

echo '## 21: seed3-pass pass idelayctrl all   2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$190551\$lut\$aiger190550\$8809.A5' --limit 10

echo '## 22: seed3-pass pass dq_iologic lane1 dq15  2648.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45563.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.genblk1\.OSERDESE2_data.D5' --limit 10

echo '## 23: seed3-pass pass dq_iologic lane1 dq9  2609.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[9\]\.ISERDESE2_data.RST' --limit 10

echo '## 24: seed3-pass pass dq_iologic lane1 dq9  2609.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[9\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 25: seed3-pass pass dq_iologic lane0 dq3  2605.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45583.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.genblk1\.OSERDESE2_data.D7' --limit 10

echo '## 26: seed3-pass pass dqs_iologic lane0 dqs0  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$191186.A3' --limit 10

echo '## 27: seed3-pass pass dqs_iologic lane0 dqs0  2595.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$191253.A3' --limit 10

echo '## 28: seed3-pass pass dq_iologic lane1 dq8  2578.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45572.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 29: seed3-pass pass dqs_iologic lane0 dqs0  2548.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$190551\$lut\$not\$aiger190550\$283.O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.genblk1\.OSERDESE2_dqs.CLK' --limit 10

echo '## 30: seed3-pass pass dq_iologic lane0 dq5  2543.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45553.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.genblk1\.OSERDESE2_data.D5' --limit 10

echo '## 31: seed3-pass pass dqs_iologic lane0 dqs0  2535.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$191214.A4' --limit 10

echo '## 32: seed3-pass pass dq_iologic lane1 dq15  2525.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.ISERDESE2_data.RST' --limit 10

echo '## 33: seed3-pass pass dq_iologic lane1 dq15  2525.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 34: seed3-pass pass dqs_iologic lane0 dqs0  2519.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$191141.A1' --limit 10

echo '## 35: seed3-pass pass dq_iologic lane0 dq7  2507.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45523.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.genblk1\.OSERDESE2_data.D3' --limit 10

echo '## 36: seed3-pass pass dq_iologic lane0 dq5  2417.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.ISERDESE2_data.RST' --limit 10

echo '## 37: seed3-pass pass dq_iologic lane0 dq5  2417.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 38: seed3-pass pass dq_iologic lane0 dq7  2410.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45491.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.genblk1\.OSERDESE2_data.D1' --limit 10

echo '## 39: seed3-pass pass dqs_iologic lane1 dqs1  2404.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.ISERDESE2_dqs.RST' --limit 10

echo '## 40: seed3-pass pass dqs_iologic lane1 dqs1  2404.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.genblk1\.OSERDESE2_dqs.RST' --limit 10

echo '## 41: seed3-pass pass dq_iologic lane1 dq9  2398.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45541.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[9\]\.genblk1\.OSERDESE2_data.D4' --limit 10

echo '## 42: seed3-pass pass dq_iologic lane0 dq3  2367.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45487.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.genblk1\.OSERDESE2_data.D1' --limit 10

echo '## 43: seed3-pass pass dq_iologic lane0 dq7  2365.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.ISERDESE2_data.RST' --limit 10

echo '## 44: seed3-pass pass dq_iologic lane0 dq7  2365.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 45: seed3-pass pass dq_iologic lane0 dq3  2332.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.ISERDESE2_data.RST' --limit 10

echo '## 46: seed3-pass pass dq_iologic lane0 dq3  2332.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 47: seed3-pass pass dq_iologic lane0 dq7  2328.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45555.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.genblk1\.OSERDESE2_data.D5' --limit 10

echo '## 48: seed3-pass pass dqs_iologic lane1 dqs1  2325.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$abc\$190551\$lut\$aiger190550\$9361.A4' --limit 10

echo '## 49: seed3-pass pass dqs_iologic lane1 dqs1  2325.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$abc\$190551\$lut\$aiger190550\$9372.A4' --limit 10

echo '## 50: seed3-pass pass dqs_iologic lane1 dqs1  2325.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$190551\$lut\$aiger190550\$9361.A1' --limit 10

echo '## 51: seed3-pass pass dqs_iologic lane1 dqs1  2325.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$190551\$lut\$aiger190550\$9372.A1' --limit 10

echo '## 52: seed3-pass pass dqs_iologic lane1 dqs1  2325.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$abc\$190551\$lut\$aiger190550\$9369.A4' --limit 10

echo '## 53: seed3-pass pass dqs_iologic lane1 dqs1  2325.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$abc\$190551\$lut\$aiger190550\$9369.A2' --limit 10

echo '## 54: seed3-pass pass dq_iologic lane1 dq13  2309.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.ISERDESE2_data.RST' --limit 10

echo '## 55: seed3-pass pass dq_iologic lane1 dq13  2309.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 56: seed3-pass pass dq_iologic lane1 dq8  2295.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45540.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.D4' --limit 10

echo '## 57: seed3-pass pass idelay_data_cntvaluein lane0 dq7 3 2273.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$190551\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 58: seed3-pass pass dq_iologic lane0 dq7  2242.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45571.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 59: seed3-pass pass dq_iologic lane1 dq11  2236.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45495.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.genblk1\.OSERDESE2_data.D1' --limit 10

echo '## 60: seed3-pass pass dq_iologic lane0 dq6  2234.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-instrumented-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45669.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[6\]\.ISERDESE2_data.RST' --limit 10

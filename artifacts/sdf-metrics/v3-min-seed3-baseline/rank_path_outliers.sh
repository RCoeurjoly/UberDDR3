#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: seed3-pass pass clocking all   6644.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$abc\$191703\$lut\$aiger191702\$5335.A5' --limit 10

echo '## 2: seed3-pass pass clocking all   6644.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197061.A4' --limit 10

echo '## 3: seed3-pass pass clocking all   6644.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197059.A5' --limit 10

echo '## 4: seed3-pass pass clocking all   6614.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197065.A3' --limit 10

echo '## 5: seed3-pass pass clocking all   6525.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197063.A2' --limit 10

echo '## 6: seed3-pass pass clocking all   5775.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$197759.A4' --limit 10

echo '## 7: seed3-pass pass clocking all   3838.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$197757.A1' --limit 10

echo '## 8: seed3-pass pass clocking all   3437.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$197761.A1' --limit 10

echo '## 9: seed3-pass pass dqs_iologic lane0 dqs0  3210.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192446.A5' --limit 10

echo '## 10: seed3-pass pass dqs_iologic lane0 dqs0  3210.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192289.A4' --limit 10

echo '## 11: seed3-pass pass dqs_iologic lane0 dqs0  3210.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192333.A3' --limit 10

echo '## 12: seed3-pass pass dqs_iologic lane0 dqs0  3180.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$abc\$191703\$lut\$aiger191702\$5342.A5' --limit 10

echo '## 13: seed3-pass pass dqs_iologic lane0 dqs0  3180.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192415.A4' --limit 10

echo '## 14: seed3-pass pass dqs_iologic lane0 dqs0  3180.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$191703\$lut\$aiger191702\$5349.A4' --limit 10

echo '## 15: seed3-pass pass dqs_iologic lane0 dqs0  3180.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$abc\$191703\$lut\$auto\$opt_dff\.cc\:219\:make_patterns_logic\$28097.A2' --limit 10

echo '## 16: seed3-pass pass dq_iologic lane1 dq8  3045.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45784.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 17: seed3-pass pass clocking all   2967.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$191884.A2' --limit 10

echo '## 18: seed3-pass pass clocking all   2967.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$191902.A2' --limit 10

echo '## 19: seed3-pass pass idelay_data_cntvaluein lane0 dq6 1 2892.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$191703\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[6\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 20: seed3-pass pass idelay_data_cntvaluein lane0 dq7 1 2891.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$191703\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 21: seed3-pass pass dq_iologic lane1 dq12  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$191703\$lut\$aiger191702\$11007.A5' --limit 10

echo '## 22: seed3-pass pass dq_iologic lane1 dq12  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$191703\$lut\$aiger191702\$11007.A4' --limit 10

echo '## 23: seed3-pass pass dq_iologic lane1 dq12  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$191703\$lut\$aiger191702\$11007.A2' --limit 10

echo '## 24: seed3-pass pass dq_iologic lane1 dq12  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$191703\$lut\$aiger191702\$11015.A5' --limit 10

echo '## 25: seed3-pass pass idelayctrl all   2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$191703\$lut\$aiger191702\$6353.A3' --limit 10

echo '## 26: seed3-pass pass idelayctrl all   2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$191703\$lut\$flatten\\ddr3_top_inst\.\\ddr3_controller_inst\.\$logic_and\$rtl/ddr3_controller\.v\:992\$7950_Y.A3' --limit 10

echo '## 27: seed3-pass pass dqs_iologic lane1 dqs1  2819.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192289.A2' --limit 10

echo '## 28: seed3-pass pass dqs_iologic lane1 dqs1  2819.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$191703\$lut\$aiger191702\$11025.A5' --limit 10

echo '## 29: seed3-pass pass dqs_iologic lane1 dqs1  2819.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$191703\$lut\$aiger191702\$11036.A5' --limit 10

echo '## 30: seed3-pass pass dqs_iologic lane1 dqs1  2819.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$abc\$191703\$lut\$aiger191702\$11033.A3' --limit 10

echo '## 31: seed3-pass pass dqs_iologic lane1 dqs1  2819.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192333.A4' --limit 10

echo '## 32: seed3-pass pass dqs_iologic lane1 dqs1  2819.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$abc\$191703\$lut\$aiger191702\$11033.A1' --limit 10

echo '## 33: seed3-pass pass dqs_iologic lane1 dqs1  2819.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$abc\$191703\$lut\$auto\$opt_dff\.cc\:219\:make_patterns_logic\$28100.A2' --limit 10

echo '## 34: seed3-pass pass dq_iologic lane1 dq10  2805.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$191703\$lut\$aiger191702\$10928.A5' --limit 10

echo '## 35: seed3-pass pass dq_iologic lane1 dq10  2805.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$191703\$lut\$aiger191702\$14325.A2' --limit 10

echo '## 36: seed3-pass pass dq_iologic lane1 dq10  2805.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$191703\$lut\$aiger191702\$12152.A2' --limit 10

echo '## 37: seed3-pass pass dq_iologic lane1 dq10  2805.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$191703\$lut\$aiger191702\$10928.A4' --limit 10

echo '## 38: seed3-pass pass dq_iologic lane1 dq10  2805.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$191703\$lut\$aiger191702\$10928.A2' --limit 10

echo '## 39: seed3-pass pass dq_iologic lane1 dq10  2805.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$191703\$lut\$aiger191702\$10936.A3' --limit 10

echo '## 40: seed3-pass pass dq_iologic lane1 dq10  2805.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$191703\$lut\$aiger191702\$10936.A4' --limit 10

echo '## 41: seed3-pass pass idelay_data_cntvaluein lane0 dq2 1 2799.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$191703\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 42: seed3-pass pass idelay_data_cntvaluein lane0 dq4 1 2798.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$191703\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 43: seed3-pass pass dqs_iologic lane1 dqs1  2789.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192415.A2' --limit 10

echo '## 44: seed3-pass pass dq_iologic lane1 dq11  2788.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45723.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.genblk1\.OSERDESE2_data.D2' --limit 10

echo '## 45: seed3-pass pass dq_iologic lane1 dq10  2775.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$191703\$lut\$aiger191702\$14329.A4' --limit 10

echo '## 46: seed3-pass pass dq_iologic lane1 dq10  2775.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$191703\$lut\$aiger191702\$14327.A4' --limit 10

echo '## 47: seed3-pass pass idelay_data_cntvaluein lane0 dq0 1 2766.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$191703\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 48: seed3-pass pass dq_iologic lane1 dq15  2752.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45759.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.genblk1\.OSERDESE2_data.D4' --limit 10

echo '## 49: seed3-pass pass dq_iologic lane1 dq13  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$191703\$lut\$aiger191702\$10950.A3' --limit 10

echo '## 50: seed3-pass pass dq_iologic lane1 dq13  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$191703\$lut\$aiger191702\$10950.A4' --limit 10

echo '## 51: seed3-pass pass dq_iologic lane1 dq13  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$191703\$lut\$aiger191702\$10950.A5' --limit 10

echo '## 52: seed3-pass pass dq_iologic lane1 dq13  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$191703\$lut\$aiger191702\$10958.A1' --limit 10

echo '## 53: seed3-pass pass dq_iologic lane1 dq13  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$191703\$lut\$aiger191702\$10958.A2' --limit 10

echo '## 54: seed3-pass pass dqs_iologic lane1 dqs1  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192354.A4' --limit 10

echo '## 55: seed3-pass pass idelay_data_cntvaluein lane0 dq1 1 2707.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$191703\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 56: seed3-pass pass dq_iologic lane1 dq14  2704.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45790.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 57: seed3-pass pass dq_iologic lane1 dq11  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$191703\$lut\$aiger191702\$10909.A5' --limit 10

echo '## 58: seed3-pass pass dq_iologic lane1 dq11  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$191703\$lut\$aiger191702\$10909.A1' --limit 10

echo '## 59: seed3-pass pass dq_iologic lane1 dq11  2684.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$191703\$lut\$aiger191702\$10917.A4' --limit 10

echo '## 60: seed3-pass pass dq_iologic lane1 dq11  2654.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$191703\$lut\$aiger191702\$14329.A2' --limit 10

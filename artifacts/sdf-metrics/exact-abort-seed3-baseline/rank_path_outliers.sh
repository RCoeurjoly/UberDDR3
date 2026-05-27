#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: seed3-exact-abort-baseline pass clocking all   6105.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A5' --limit 10

echo '## 2: seed3-exact-abort-baseline pass clocking all   6105.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A2' --limit 10

echo '## 3: seed3-exact-abort-baseline pass clocking all   5864.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A5' --limit 10

echo '## 4: seed3-exact-abort-baseline pass clocking all   5820.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197697.A4' --limit 10

echo '## 5: seed3-exact-abort-baseline pass clocking all   5760.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A3' --limit 10

echo '## 6: seed3-exact-abort-baseline pass clocking all   5760.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192486.A4' --limit 10

echo '## 7: seed3-exact-abort-baseline pass clocking all   5534.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198391.A2' --limit 10

echo '## 8: seed3-exact-abort-baseline pass clocking all   3566.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198399.A4' --limit 10

echo '## 9: seed3-exact-abort-baseline pass dqs_iologic lane0 dqs0  3329.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193120.A4' --limit 10

echo '## 10: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  3319.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46419.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.genblk1\.OSERDESE2_data.D5' --limit 10

echo '## 11: seed3-exact-abort-baseline pass dqs_iologic lane0 dqs0  3315.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193035.A5' --limit 10

echo '## 12: seed3-exact-abort-baseline pass dqs_iologic lane0 dqs0  3269.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$10037.A4' --limit 10

echo '## 13: seed3-exact-abort-baseline pass dqs_iologic lane0 dqs0  3269.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$10037.A1' --limit 10

echo '## 14: seed3-exact-abort-baseline pass dqs_iologic lane0 dqs0  3269.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$10037.A5' --limit 10

echo '## 15: seed3-exact-abort-baseline pass dqs_iologic lane0 dqs0  3269.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193055.A5' --limit 10

echo '## 16: seed3-exact-abort-baseline pass dqs_iologic lane0 dqs0  3269.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$192400\$lut\$auto\$opt_dff\.cc\:219\:make_patterns_logic\$28497.A3' --limit 10

echo '## 17: seed3-exact-abort-baseline pass dqs_iologic lane0 dqs0  3240.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192949.A2' --limit 10

echo '## 18: seed3-exact-abort-baseline pass dqs_iologic lane0 dqs0  3240.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192997.A3' --limit 10

echo '## 19: seed3-exact-abort-baseline pass dq_iologic lane1 dq8  3141.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46449.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.D7' --limit 10

echo '## 20: seed3-exact-abort-baseline pass idelayctrl all   3075.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$192400\$lut\$aiger192399\$8147.A3' --limit 10

echo '## 21: seed3-exact-abort-baseline pass idelayctrl all   3075.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$192400\$lut\$aiger192399\$8040.A3' --limit 10

echo '## 22: seed3-exact-abort-baseline pass dq_iologic lane1 dq8  3065.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46433.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 23: seed3-exact-abort-baseline pass dqs_iologic lane1 dqs1  3015.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$10053.A4' --limit 10

echo '## 24: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  3002.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46355.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.genblk1\.OSERDESE2_data.D1' --limit 10

echo '## 25: seed3-exact-abort-baseline pass dq_iologic lane1 dq14  2982.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46407.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.genblk1\.OSERDESE2_data.D4' --limit 10

echo '## 26: seed3-exact-abort-baseline pass dqs_iologic lane1 dqs1  2940.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$10060.A4' --limit 10

echo '## 27: seed3-exact-abort-baseline pass dqs_iologic lane1 dqs1  2940.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193120.A3' --limit 10

echo '## 28: seed3-exact-abort-baseline pass dqs_iologic lane1 dqs1  2940.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$10060.A5' --limit 10

echo '## 29: seed3-exact-abort-baseline pass dqs_iologic lane1 dqs1  2940.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$192400\$lut\$auto\$opt_dff\.cc\:219\:make_patterns_logic\$28500.A1' --limit 10

echo '## 30: seed3-exact-abort-baseline pass dqs_iologic lane1 dqs1  2880.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193055.A4' --limit 10

echo '## 31: seed3-exact-abort-baseline pass dq_iologic lane1 dq12  2865.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$9900.A1' --limit 10

echo '## 32: seed3-exact-abort-baseline pass dq_iologic lane1 dq12  2865.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$192400\$lut\$aiger192399\$9900.A2' --limit 10

echo '## 33: seed3-exact-abort-baseline pass dq_iologic lane1 dq12  2865.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$9892.A4' --limit 10

echo '## 34: seed3-exact-abort-baseline pass dqs_iologic lane1 dqs1  2849.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192997.A4' --limit 10

echo '## 35: seed3-exact-abort-baseline pass dqs_iologic lane1 dqs1  2849.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192949.A3' --limit 10

echo '## 36: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$9873.A5' --limit 10

echo '## 37: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$192400\$lut\$aiger192399\$9876.A2' --limit 10

echo '## 38: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$192400\$lut\$aiger192399\$9865.A2' --limit 10

echo '## 39: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$9876.A3' --limit 10

echo '## 40: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$9865.A3' --limit 10

echo '## 41: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$192400\$lut\$aiger192399\$9881.A1' --limit 10

echo '## 42: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  2835.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$9873.A4' --limit 10

echo '## 43: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  2805.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$15254.A4' --limit 10

echo '## 44: seed3-exact-abort-baseline pass dqs_iologic lane0 dqs0  2792.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$auto\$ff\.cc\:266\:slice\$45632.D' --limit 10

echo '## 45: seed3-exact-abort-baseline pass dq_iologic lane1 dq13  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$9979.A4' --limit 10

echo '## 46: seed3-exact-abort-baseline pass dq_iologic lane1 dq11  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$9930.A4' --limit 10

echo '## 47: seed3-exact-abort-baseline pass dq_iologic lane1 dq11  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$192400\$lut\$aiger192399\$9938.A5' --limit 10

echo '## 48: seed3-exact-abort-baseline pass dq_iologic lane1 dq13  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$9971.A1' --limit 10

echo '## 49: seed3-exact-abort-baseline pass dq_iologic lane1 dq11  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$9930.A5' --limit 10

echo '## 50: seed3-exact-abort-baseline pass dq_iologic lane1 dq11  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$192400\$lut\$aiger192399\$9938.A2' --limit 10

echo '## 51: seed3-exact-abort-baseline pass dq_iologic lane1 dq8  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$15250.A3' --limit 10

echo '## 52: seed3-exact-abort-baseline pass dq_iologic lane1 dq13  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[13\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$9971.A2' --limit 10

echo '## 53: seed3-exact-abort-baseline pass dq_iologic lane1 dq14  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$15256.A5' --limit 10

echo '## 54: seed3-exact-abort-baseline pass dq_iologic lane1 dq11  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$9930.A2' --limit 10

echo '## 55: seed3-exact-abort-baseline pass dq_iologic lane1 dq11  2744.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$15258.A3' --limit 10

echo '## 56: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$flatten\\ddr3_top_inst\.\\ddr3_controller_inst\.\$0\$memwr\$\\idelay_dqs_cntvaluein\$rtl/ddr3_controller\.v\:2697\$7924_DATA\[4\:0\]\$8804\[0\].A4' --limit 10

echo '## 57: seed3-exact-abort-baseline pass dq_iologic lane1 dq10  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$11590.A4' --limit 10

echo '## 58: seed3-exact-abort-baseline pass dq_iologic lane1 dq14  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$9952.A1' --limit 10

echo '## 59: seed3-exact-abort-baseline pass dq_iologic lane1 dq12  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$11596.A1' --limit 10

echo '## 60: seed3-exact-abort-baseline pass dq_iologic lane1 dq14  2714.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$192400\$lut\$aiger192399\$9944.A1' --limit 10

#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: exact-abort-seed3-idelay-control-full-locked fail clocking all   6974.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A2' --limit 10

echo '## 2: exact-abort-seed3-idelay-control-locked pass clocking all   6914.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A1' --limit 10

echo '## 3: exact-abort-seed3-idelay-control-full-locked fail clocking all   6914.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A4' --limit 10

echo '## 4: exact-abort-seed3-idelay-control-full-locked fail clocking all   6885.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A2' --limit 10

echo '## 5: exact-abort-seed3-idelay-control-full-locked fail clocking all   6885.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197697.A2' --limit 10

echo '## 6: exact-abort-seed3-idelay-control-locked pass clocking all   6855.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 7: exact-abort-seed3-idelay-control-locked pass clocking all   6855.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192715.A1' --limit 10

echo '## 8: exact-abort-seed3-idelay-control-locked pass clocking all   6855.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A2' --limit 10

echo '## 9: exact-abort-seed3-idelay-control-locked pass clocking all   6855.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A2' --limit 10

echo '## 10: exact-abort-seed3-idelay-control-full-locked fail clocking all   6855.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A2' --limit 10

echo '## 11: exact-abort-seed3-idelay-control-locked pass clocking all   6719.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198391.A1' --limit 10

echo '## 12: exact-abort-seed3-idelay-control-full-locked fail clocking all   6690.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198391.A3' --limit 10

echo '## 13: exact-abort-seed3-idelay-control-locked pass clocking all   6195.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A5' --limit 10

echo '## 14: exact-abort-seed3-idelay-control-locked pass clocking all   6195.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197697.A5' --limit 10

echo '## 15: exact-abort-seed3-baseline pass clocking all   6105.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A5' --limit 10

echo '## 16: exact-abort-seed3-baseline pass clocking all   6105.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A2' --limit 10

echo '## 17: exact-abort-seed3-idelay-control-full-locked fail clocking all   6074.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192486.A5' --limit 10

echo '## 18: exact-abort-seed3-baseline pass clocking all   5864.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A5' --limit 10

echo '## 19: exact-abort-seed3-baseline pass clocking all   5820.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197697.A4' --limit 10

echo '## 20: exact-abort-seed3-baseline pass clocking all   5760.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A3' --limit 10

echo '## 21: exact-abort-seed3-baseline pass clocking all   5760.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192486.A4' --limit 10

echo '## 22: exact-abort-seed3-baseline pass clocking all   5534.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198391.A2' --limit 10

echo '## 23: exact-abort-seed3-idelay-control-locked pass clocking all   5324.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198399.A2' --limit 10

echo '## 24: exact-abort-seed3-idelay-control-locked pass clocking all   5099.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192486.A3' --limit 10

echo '## 25: exact-abort-seed3-idelay-control-locked pass dqs_iologic lane0 dqs0  3944.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193055.A5' --limit 10

echo '## 26: exact-abort-seed3-idelay-control-locked pass dqs_iologic lane0 dqs0  3795.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193035.A2' --limit 10

echo '## 27: exact-abort-seed3-idelay-control-locked pass dqs_iologic lane1 dqs1  3615.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193120.A3' --limit 10

echo '## 28: exact-abort-seed3-baseline pass clocking all   3566.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198399.A4' --limit 10

echo '## 29: exact-abort-seed3-idelay-control-locked pass dqs_iologic lane1 dqs1  3555.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193055.A4' --limit 10

echo '## 30: exact-abort-seed3-idelay-control-locked pass dqs_iologic lane1 dqs1  3404.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193035.A3' --limit 10

echo '## 31: exact-abort-seed3-baseline pass dqs_iologic lane0 dqs0  3329.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193120.A4' --limit 10

echo '## 32: exact-abort-seed3-baseline pass dq_iologic lane1 dq10  3319.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46419.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.genblk1\.OSERDESE2_data.D5' --limit 10

echo '## 33: exact-abort-seed3-baseline pass dqs_iologic lane0 dqs0  3315.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193035.A5' --limit 10

echo '## 34: exact-abort-seed3-baseline pass dqs_iologic lane0 dqs0  3269.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$10037.A4' --limit 10

echo '## 35: exact-abort-seed3-baseline pass dqs_iologic lane0 dqs0  3269.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$10037.A1' --limit 10

echo '## 36: exact-abort-seed3-baseline pass dqs_iologic lane0 dqs0  3269.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$10037.A5' --limit 10

echo '## 37: exact-abort-seed3-baseline pass dqs_iologic lane0 dqs0  3269.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193055.A5' --limit 10

echo '## 38: exact-abort-seed3-baseline pass dqs_iologic lane0 dqs0  3269.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$192400\$lut\$auto\$opt_dff\.cc\:219\:make_patterns_logic\$28497.A3' --limit 10

echo '## 39: exact-abort-seed3-baseline pass dqs_iologic lane0 dqs0  3240.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192949.A2' --limit 10

echo '## 40: exact-abort-seed3-baseline pass dqs_iologic lane0 dqs0  3240.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192997.A3' --limit 10

echo '## 41: exact-abort-seed3-baseline pass dq_iologic lane1 dq8  3141.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46449.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.D7' --limit 10

echo '## 42: exact-abort-seed3-baseline pass idelayctrl all   3075.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$192400\$lut\$aiger192399\$8147.A3' --limit 10

echo '## 43: exact-abort-seed3-baseline pass idelayctrl all   3075.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$192400\$lut\$aiger192399\$8040.A3' --limit 10

echo '## 44: exact-abort-seed3-baseline pass dq_iologic lane1 dq8  3065.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46433.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 45: exact-abort-seed3-baseline pass dqs_iologic lane1 dqs1  3015.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$10053.A4' --limit 10

echo '## 46: exact-abort-seed3-baseline pass dq_iologic lane1 dq10  3002.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46355.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.genblk1\.OSERDESE2_data.D1' --limit 10

echo '## 47: exact-abort-seed3-baseline pass dq_iologic lane1 dq14  2982.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46407.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.genblk1\.OSERDESE2_data.D4' --limit 10

echo '## 48: exact-abort-seed3-baseline pass dqs_iologic lane1 dqs1  2940.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$10060.A4' --limit 10

echo '## 49: exact-abort-seed3-baseline pass dqs_iologic lane1 dqs1  2940.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193120.A3' --limit 10

echo '## 50: exact-abort-seed3-baseline pass dqs_iologic lane1 dqs1  2940.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$10060.A5' --limit 10

echo '## 51: exact-abort-seed3-baseline pass dqs_iologic lane1 dqs1  2940.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$abc\$192400\$lut\$auto\$opt_dff\.cc\:219\:make_patterns_logic\$28500.A1' --limit 10

echo '## 52: exact-abort-seed3-baseline pass dqs_iologic lane1 dqs1  2880.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT1' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$193055.A4' --limit 10

echo '## 53: exact-abort-seed3-idelay-control-full-locked fail dqs_iologic lane0 dqs0  2880.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$10037.A2' --limit 10

echo '## 54: exact-abort-seed3-idelay-control-full-locked fail dqs_iologic lane0 dqs0  2880.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$10037.A5' --limit 10

echo '## 55: exact-abort-seed3-baseline pass dq_iologic lane1 dq12  2865.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$9900.A1' --limit 10

echo '## 56: exact-abort-seed3-baseline pass dq_iologic lane1 dq12  2865.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$192400\$lut\$aiger192399\$9900.A2' --limit 10

echo '## 57: exact-abort-seed3-baseline pass dq_iologic lane1 dq12  2865.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$9892.A4' --limit 10

echo '## 58: exact-abort-seed3-baseline pass dqs_iologic lane1 dqs1  2849.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT3' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192997.A4' --limit 10

echo '## 59: exact-abort-seed3-baseline pass dqs_iologic lane1 dqs1  2849.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEOUT4' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192949.A3' --limit 10

echo '## 60: exact-abort-seed3-idelay-control-locked pass idelayctrl all   2849.0 ps'
sdf-toolkit rank-paths result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.IDELAYCTRL_inst\$intcell\$CTRL_DUP_0.RDY' '\$abc\$192400\$lut\$aiger192399\$8040.A2' --limit 10

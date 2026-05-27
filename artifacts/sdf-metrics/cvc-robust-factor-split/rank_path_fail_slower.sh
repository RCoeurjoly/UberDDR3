#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Strict fail-slower candidate endpoints.

echo '## 1: seed1-fail fail idelay_dqs_cntvaluein lane0 dqs0 4 2233.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[4\].O5' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN4' --limit 10

echo '## 2: seed2-fail fail idelay_dqs_cntvaluein lane0 dqs0 4 1952.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[4\].O5' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN4' --limit 10

echo '## 3: seed1-fail fail idelay_data_cntvaluein lane1 dq14 3 2141.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 4: seed2-fail fail idelay_data_cntvaluein lane1 dq14 3 1850.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 5: seed1-fail fail idelay_data_cntvaluein lane1 dq8 2 2282.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 6: seed2-fail fail idelay_data_cntvaluein lane1 dq8 2 2000.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 7: seed1-fail fail idelay_data_cntvaluein lane1 dq10 2 2154.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 8: seed2-fail fail idelay_data_cntvaluein lane1 dq10 2 1822.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 9: seed1-fail fail idelay_data_cntvaluein lane1 dq12 2 2099.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 10: seed2-fail fail idelay_data_cntvaluein lane1 dq12 2 1906.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 11: seed1-fail fail idelay_data_cntvaluein lane0 dq4 3 2460.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 12: seed2-fail fail idelay_data_cntvaluein lane0 dq4 3 2176.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 13: seed1-fail fail idelay_data_cntvaluein lane0 dq1 3 2453.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 14: seed2-fail fail idelay_data_cntvaluein lane0 dq1 3 2174.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 15: seed1-fail fail idelay_data_cntvaluein lane1 dq12 3 2052.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 16: seed2-fail fail idelay_data_cntvaluein lane1 dq12 3 1759.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 17: seed1-fail fail idelay_data_cntvaluein lane1 dq8 3 2145.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 18: seed2-fail fail idelay_data_cntvaluein lane1 dq8 3 1853.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 19: seed1-fail fail idelay_data_cntvaluein lane1 dq14 2 2190.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 20: seed2-fail fail idelay_data_cntvaluein lane1 dq14 2 1917.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 21: seed1-fail fail idelay_data_cntvaluein lane0 dq4 2 2328.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 22: seed2-fail fail idelay_data_cntvaluein lane0 dq4 2 2141.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 23: seed1-fail fail idelay_data_cntvaluein lane0 dq0 3 2368.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 24: seed2-fail fail idelay_data_cntvaluein lane0 dq0 3 2082.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 25: seed1-fail fail idelay_data_cntvaluein lane0 dq7 2 2421.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 26: seed2-fail fail idelay_data_cntvaluein lane0 dq7 2 2207.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 27: seed1-fail fail idelay_data_cntvaluein lane0 dq1 2 2236.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 28: seed2-fail fail idelay_data_cntvaluein lane0 dq1 2 2006.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 29: seed1-fail fail idelay_data_cntvaluein lane0 dq2 2 2329.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 30: seed2-fail fail idelay_data_cntvaluein lane0 dq2 2 2088.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 31: seed1-fail fail idelay_data_cntvaluein lane0 dq5 2 2203.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 32: seed2-fail fail idelay_data_cntvaluein lane0 dq5 2 1935.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 33: seed1-fail fail idelay_dqs_cntvaluein lane0 dqs0 2 2038.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 34: seed2-fail fail idelay_dqs_cntvaluein lane0 dqs0 2 1587.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 35: seed1-fail fail idelay_data_cntvaluein lane1 dq10 3 1970.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 36: seed2-fail fail idelay_data_cntvaluein lane1 dq10 3 1580.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 37: seed1-fail fail idelay_dqs_cntvaluein lane1 dqs1 2 1726.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 38: seed2-fail fail idelay_dqs_cntvaluein lane1 dqs1 2 1309.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 39: seed1-fail fail idelay_data_cntvaluein lane0 dq6 2 2423.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[6\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 40: seed2-fail fail idelay_data_cntvaluein lane0 dq6 2 2121.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[6\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 41: seed1-fail fail idelay_data_cntvaluein lane0 dq3 2 2112.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 42: seed2-fail fail idelay_data_cntvaluein lane0 dq3 2 1855.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 43: seed1-fail fail idelay_data_cntvaluein lane1 dq11 2 1781.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 44: seed2-fail fail idelay_data_cntvaluein lane1 dq11 2 1590.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 45: seed1-fail fail idelay_dqs_cntvaluein lane1 dqs1 4 1792.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[4\].O5' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEIN4' --limit 10

echo '## 46: seed2-fail fail idelay_dqs_cntvaluein lane1 dqs1 4 1427.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[4\].O5' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEIN4' --limit 10

echo '## 47: seed1-fail fail idelay_data_cntvaluein lane1 dq9 2 1532.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[9\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 48: seed2-fail fail idelay_data_cntvaluein lane1 dq9 2 1371.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[9\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 49: seed2-fail fail idelay_data_cntvaluein lane1 dq9 1 1577.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[9\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 50: seed1-fail fail idelay_data_cntvaluein lane1 dq9 1 1481.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[9\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 51: seed2-fail fail idelay_data_cntvaluein lane1 dq15 2 1452.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 52: seed1-fail fail idelay_data_cntvaluein lane1 dq15 2 1442.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 53: seed1-fail fail idelay_data_cntvaluein lane0 dq2 3 2226.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 54: seed2-fail fail idelay_data_cntvaluein lane0 dq2 3 2042.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 55: seed2-fail fail idelay_data_cntvaluein lane0 dq7 3 2269.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 56: seed1-fail fail idelay_data_cntvaluein lane0 dq7 3 2144.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 57: seed1-fail fail idelay_data_cntvaluein lane0 dq5 1 1746.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 58: seed2-fail fail idelay_data_cntvaluein lane0 dq5 1 1726.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

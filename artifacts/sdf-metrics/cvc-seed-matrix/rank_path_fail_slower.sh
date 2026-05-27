#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Strict fail-slower candidate endpoints.

echo '## 1: seed1-fail fail idelay_dqs_cntvaluein lane0 dqs0 4 2233.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[4\].O5' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN4' --limit 10

echo '## 2: seed2-fail fail idelay_dqs_cntvaluein lane0 dqs0 4 1952.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[4\].O5' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN4' --limit 10

echo '## 3: seed1-fail fail idelay_data_cntvaluein lane0 dq4 3 2460.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 4: seed2-fail fail idelay_data_cntvaluein lane0 dq4 3 2176.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 5: seed1-fail fail idelay_data_cntvaluein lane1 dq14 3 2141.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 6: seed2-fail fail idelay_data_cntvaluein lane1 dq14 3 1850.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 7: seed1-fail fail idelay_data_cntvaluein lane1 dq8 2 2282.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 8: seed2-fail fail idelay_data_cntvaluein lane1 dq8 2 2000.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 9: seed1-fail fail idelay_data_cntvaluein lane0 dq1 3 2453.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 10: seed2-fail fail idelay_data_cntvaluein lane0 dq1 3 2174.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 11: seed1-fail fail idelay_data_cntvaluein lane1 dq8 3 2145.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 12: seed2-fail fail idelay_data_cntvaluein lane1 dq8 3 1853.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 13: seed1-fail fail idelay_data_cntvaluein lane0 dq2 3 2226.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 14: seed2-fail fail idelay_data_cntvaluein lane0 dq2 3 2042.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 15: seed1-fail fail idelay_ld lane0 dq7  2460.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43075.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.LD' --limit 10

echo '## 16: seed2-fail fail idelay_ld lane0 dq7  2151.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43075.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.LD' --limit 10

echo '## 17: seed1-fail fail idelay_data_cntvaluein lane1 dq12 3 2052.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 18: seed2-fail fail idelay_data_cntvaluein lane1 dq12 3 1759.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 19: seed1-fail fail idelay_data_cntvaluein lane0 dq5 3 2098.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 20: seed2-fail fail idelay_data_cntvaluein lane0 dq5 3 1789.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 21: seed1-fail fail idelay_data_cntvaluein lane0 dq6 3 2230.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[6\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 22: seed2-fail fail idelay_data_cntvaluein lane0 dq6 3 1904.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[6\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 23: seed2-fail fail idelay_data_cntvaluein lane0 dq7 3 2269.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 24: seed1-fail fail idelay_data_cntvaluein lane0 dq7 3 2144.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 25: seed1-fail fail idelay_data_cntvaluein lane0 dq3 3 2016.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 26: seed2-fail fail idelay_data_cntvaluein lane0 dq3 3 1707.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 27: seed1-fail fail idelay_data_cntvaluein lane0 dq0 3 2368.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 28: seed2-fail fail idelay_data_cntvaluein lane0 dq0 3 2082.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 29: seed1-fail fail idelay_data_cntvaluein lane1 dq14 2 2190.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 30: seed2-fail fail idelay_data_cntvaluein lane1 dq14 2 1917.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[14\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 31: seed1-fail fail idelay_data_cntvaluein lane0 dq5 4 2220.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 32: seed2-fail fail idelay_data_cntvaluein lane0 dq5 4 1644.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 33: seed1-fail fail idelay_data_cntvaluein lane1 dq10 3 1970.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 34: seed2-fail fail idelay_data_cntvaluein lane1 dq10 3 1580.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 35: seed1-fail fail idelay_dqs_cntvaluein lane0 dqs0 2 2038.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 36: seed2-fail fail idelay_dqs_cntvaluein lane0 dqs0 2 1587.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 37: seed1-fail fail idelay_data_cntvaluein lane1 dq11 3 1919.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 38: seed2-fail fail idelay_data_cntvaluein lane1 dq11 3 1452.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 39: seed2-fail fail idelay_data_cntvaluein lane0 dq4 1 2138.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 40: seed1-fail fail idelay_data_cntvaluein lane0 dq4 1 1600.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 41: seed1-fail fail idelay_dqs_cntvaluein lane1 dqs1 2 1726.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 42: seed2-fail fail idelay_dqs_cntvaluein lane1 dqs1 2 1309.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[1\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 43: seed1-fail fail idelay_ld lane0 dq2  2369.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43075.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.LD' --limit 10

echo '## 44: seed2-fail fail idelay_ld lane0 dq2  2155.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$43075.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.LD' --limit 10

echo '## 45: seed1-fail fail idelay_data_cntvaluein lane1 dq15 3 1858.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 46: seed2-fail fail idelay_data_cntvaluein lane1 dq15 3 1241.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[3\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN3' --limit 10

echo '## 47: seed1-fail fail idelay_data_cntvaluein lane1 dq10 4 1976.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 48: seed2-fail fail idelay_data_cntvaluein lane1 dq10 4 1421.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[10\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 49: seed2-fail fail idelay_data_cntvaluein lane1 dq12 1 1769.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 50: seed1-fail fail idelay_data_cntvaluein lane1 dq12 1 1485.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 51: seed1-fail fail idelay_data_cntvaluein lane0 dq5 2 2203.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 52: seed2-fail fail idelay_data_cntvaluein lane0 dq5 2 1935.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 53: seed1-fail fail idelay_data_cntvaluein lane0 dq2 2 2329.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 54: seed2-fail fail idelay_data_cntvaluein lane0 dq2 2 2088.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 55: seed2-fail fail idelay_data_cntvaluein lane0 dq2 1 2140.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 56: seed1-fail fail idelay_data_cntvaluein lane0 dq2 1 1695.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[2\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 57: seed2-fail fail idelay_data_cntvaluein lane0 dq1 1 2046.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 58: seed1-fail fail idelay_data_cntvaluein lane0 dq1 1 1689.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[1\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN1' --limit 10

echo '## 59: seed1-fail fail idelay_data_cntvaluein lane1 dq12 2 2099.0 ps'
sdf-toolkit rank-paths result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

echo '## 60: seed2-fail fail idelay_data_cntvaluein lane1 dq12 2 1906.0 ps'
sdf-toolkit rank-paths result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$179448\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[12\]\.IDELAYE2_data.CNTVALUEIN2' --limit 10

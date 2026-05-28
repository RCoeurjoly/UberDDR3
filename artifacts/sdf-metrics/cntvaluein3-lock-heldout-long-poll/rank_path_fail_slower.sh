#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Strict fail-slower candidate endpoints.

echo '## 1: cntvaluein3-skew-locked-seed28-long-poll fail dq_iologic lane0 dq1  3256.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46609.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.RST' --limit 10

echo '## 2: cntvaluein3-skew-locked-seed28-long-poll fail dq_iologic lane0 dq1  3256.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46609.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 3: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  3194.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46609.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.RST' --limit 10

echo '## 4: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  3194.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46609.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 5: cntvaluein3-skew-locked-seed12-long-poll fail dq_iologic lane0 dq1  2795.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46442.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D7' --limit 10

echo '## 6: cntvaluein3-skew-locked-seed12-long-poll fail dq_iologic lane0 dq1  2572.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46346.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D1' --limit 10

echo '## 7: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  2391.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q3' '\$auto\$ff\.cc\:266\:slice\$30992.D' --limit 10

echo '## 8: cntvaluein3-skew-locked-seed28-long-poll fail dq_iologic lane0 dq1  2372.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46426.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 9: cntvaluein3-skew-locked-seed12-long-poll fail dq_iologic lane0 dq1  2338.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46426.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 10: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  2309.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q3' '\$auto\$ff\.cc\:266\:slice\$45380.D' --limit 10

echo '## 11: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  2273.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q4' '\$auto\$ff\.cc\:266\:slice\$45372.D' --limit 10

echo '## 12: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  2252.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q7' '\$auto\$ff\.cc\:266\:slice\$45348.D' --limit 10

echo '## 13: cntvaluein3-skew-locked-seed28-long-poll fail dq_iologic lane0 dq1  2236.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46458.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D8' --limit 10

echo '## 14: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  2183.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46346.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D1' --limit 10

echo '## 15: cntvaluein3-skew-locked-seed12-long-poll fail dq_iologic lane0 dq1  2151.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46378.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D3' --limit 10

echo '## 16: cntvaluein3-skew-locked-seed12-long-poll fail dq_iologic lane0 dq1  2141.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46458.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D8' --limit 10

echo '## 17: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  2135.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q4' '\$auto\$ff\.cc\:266\:slice\$30984.D' --limit 10

echo '## 18: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  2127.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46609.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.RST' --limit 10

echo '## 19: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  2127.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46609.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 20: cntvaluein3-skew-locked-seed12-long-poll fail dq_iologic lane0 dq1  2114.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46609.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.RST' --limit 10

echo '## 21: cntvaluein3-skew-locked-seed12-long-poll fail dq_iologic lane0 dq1  2114.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46609.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 22: cntvaluein3-skew-locked-seed23-long-poll fail dq_iologic lane0 dq1  2111.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46362.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D2' --limit 10

echo '## 23: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  2101.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45318.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.T1' --limit 10

echo '## 24: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  2088.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q7' '\$auto\$ff\.cc\:266\:slice\$30960.D' --limit 10

echo '## 25: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  2085.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q6' '\$auto\$ff\.cc\:266\:slice\$45356.D' --limit 10

echo '## 26: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  2079.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46426.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 27: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  2075.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q3' '\$auto\$ff\.cc\:266\:slice\$30992.D' --limit 10

echo '## 28: cntvaluein3-skew-locked-seed23-long-poll fail dq_iologic lane0 dq1  2066.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46394.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D4' --limit 10

echo '## 29: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  2046.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q2' '\$auto\$ff\.cc\:266\:slice\$45388.D' --limit 10

echo '## 30: cntvaluein3-skew-locked-seed23-long-poll fail dq_iologic lane0 dq1  2029.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46458.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D8' --limit 10

echo '## 31: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  2003.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q3' '\$auto\$ff\.cc\:266\:slice\$45380.D' --limit 10

echo '## 32: cntvaluein3-skew-locked-seed23-long-poll fail dq_iologic lane0 dq1  1998.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46426.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D6' --limit 10

echo '## 33: cntvaluein3-skew-locked-seed28-long-poll fail dq_iologic lane0 dq1  1985.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q3' '\$auto\$ff\.cc\:266\:slice\$45380.D' --limit 10

echo '## 34: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1963.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46346.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D1' --limit 10

echo '## 35: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1963.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46458.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D8' --limit 10

echo '## 36: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1952.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q6' '\$auto\$ff\.cc\:266\:slice\$30968.D' --limit 10

echo '## 37: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  1937.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46362.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D2' --limit 10

echo '## 38: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1929.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46410.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D5' --limit 10

echo '## 39: cntvaluein3-skew-locked-seed28-long-poll fail dq_iologic lane0 dq1  1889.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q4' '\$auto\$ff\.cc\:266\:slice\$30984.D' --limit 10

echo '## 40: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1878.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q2' '\$auto\$ff\.cc\:266\:slice\$31000.D' --limit 10

echo '## 41: cntvaluein3-skew-locked-seed23-long-poll fail dq_iologic lane0 dq1  1875.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46378.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.D3' --limit 10

echo '## 42: cntvaluein3-skew-locked-seed28-long-poll fail dq_iologic lane0 dq1  1848.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q3' '\$auto\$ff\.cc\:266\:slice\$30992.D' --limit 10

echo '## 43: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  1838.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q2' '\$auto\$ff\.cc\:266\:slice\$45388.D' --limit 10

echo '## 44: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  1820.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$62184.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.BITSLIP' --limit 10

echo '## 45: cntvaluein3-skew-locked-seed28-long-poll fail dq_iologic lane0 dq1  1797.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q6' '\$auto\$ff\.cc\:266\:slice\$30968.D' --limit 10

echo '## 46: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  1791.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q7' '\$auto\$ff\.cc\:266\:slice\$45348.D' --limit 10

echo '## 47: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1784.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$192400\$lut\$aiger192399\$9726.A1' --limit 10

echo '## 48: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1784.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEOUT1' '\$abc\$192400\$lut\$aiger192399\$9737.A1' --limit 10

echo '## 49: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1784.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$9726.A3' --limit 10

echo '## 50: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1784.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEOUT2' '\$abc\$192400\$lut\$aiger192399\$9737.A2' --limit 10

echo '## 51: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1754.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$9734.A1' --limit 10

echo '## 52: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1754.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEOUT0' '\$abc\$192400\$lut\$aiger192399\$11596.A5' --limit 10

echo '## 53: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1754.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEOUT3' '\$abc\$192400\$lut\$aiger192399\$9742.A4' --limit 10

echo '## 54: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1754.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$9734.A5' --limit 10

echo '## 55: cntvaluein3-skew-locked-seed30-long-poll fail dq_iologic lane0 dq1  1748.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q2' '\$auto\$ff\.cc\:266\:slice\$31000.D' --limit 10

echo '## 56: cntvaluein3-skew-locked-seed23-long-poll fail dq_iologic lane0 dq1  1746.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$45318.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.genblk1\.OSERDESE2_data.T1' --limit 10

echo '## 57: cntvaluein3-skew-locked-seed23-long-poll fail dq_iologic lane0 dq1  1730.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q4' '\$auto\$ff\.cc\:266\:slice\$45372.D' --limit 10

echo '## 58: cntvaluein3-skew-locked-seed16-long-poll fail dq_iologic lane0 dq1  1725.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEOUT4' '\$abc\$192400\$lut\$aiger192399\$15273.A3' --limit 10

echo '## 59: cntvaluein3-skew-locked-seed23-long-poll fail dq_iologic lane0 dq1  1722.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q1' '\$auto\$ff\.cc\:266\:slice\$45396.D' --limit 10

echo '## 60: cntvaluein3-skew-locked-seed28-long-poll fail dq_iologic lane0 dq1  1715.0 ps'
/nix/store/whf6rvyhc760bnvd4pg4ak2hvnpc9vgq-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.ISERDESE2_data.Q4' '\$auto\$ff\.cc\:266\:slice\$45372.D' --limit 10

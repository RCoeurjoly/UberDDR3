#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Strict fail-slower candidate endpoints.

echo '## 1: baseline-no-lock-seed-32 fail idelay_dqs_cntvaluein lane0 dqs0 2 2421.0 ps'
sdf-toolkit rank-paths /nix/store/sdsvgyx8pf6m7fifnn98863wqrbiw4az-ypcb-ddr3-cvc-sdf-seed-32/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 2: baseline-no-lock-seed-45 fail idelay_dqs_cntvaluein lane0 dqs0 2 2397.0 ps'
sdf-toolkit rank-paths /nix/store/864wdf9zvakrp6v8yibr5v3avkp04mxq-ypcb-ddr3-cvc-sdf-seed-45/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 3: baseline-no-lock-seed-42 fail idelay_dqs_cntvaluein lane0 dqs0 2 2279.0 ps'
sdf-toolkit rank-paths /nix/store/aqyx2vcnfini279smlmgii0azjg0vbm0-ypcb-ddr3-cvc-sdf-seed-42/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 4: baseline-no-lock-seed-54 fail idelay_dqs_cntvaluein lane0 dqs0 2 2036.0 ps'
sdf-toolkit rank-paths /nix/store/p097hkpi3wkaxflq65k6cvjzq2xqm088-ypcb-ddr3-cvc-sdf-seed-54/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 5: baseline-no-lock-seed-44 fail idelay_dqs_cntvaluein lane0 dqs0 2 1970.0 ps'
sdf-toolkit rank-paths /nix/store/23dggz43q3rvwz54ggnhn4vz4r555pd1-ypcb-ddr3-cvc-sdf-seed-44/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 6: baseline-no-lock-seed-31 fail idelay_dqs_cntvaluein lane0 dqs0 2 1909.0 ps'
sdf-toolkit rank-paths /nix/store/rn6p13ihhvjbcn4pfs9wbcv975v23q64-ypcb-ddr3-cvc-sdf-seed-31/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 7: baseline-no-lock-seed-40 fail idelay_dqs_cntvaluein lane0 dqs0 2 1907.0 ps'
sdf-toolkit rank-paths /nix/store/xca418kd2l5z69rg3wdcy9xgyb5pml6r-ypcb-ddr3-cvc-sdf-seed-40/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 8: baseline-no-lock-seed-38 fail idelay_dqs_cntvaluein lane0 dqs0 2 1730.0 ps'
sdf-toolkit rank-paths /nix/store/9vqd2ipbcpi5lcm5a5wz0aql030kl867-ypcb-ddr3-cvc-sdf-seed-38/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 9: baseline-no-lock-seed-60 fail idelay_dqs_cntvaluein lane0 dqs0 2 1636.0 ps'
sdf-toolkit rank-paths /nix/store/jsk4ysb3i05y30j8xkqi3v0cpsf2vq18-ypcb-ddr3-cvc-sdf-seed-60/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 10: baseline-no-lock-seed-58 fail idelay_dqs_cntvaluein lane0 dqs0 2 1610.0 ps'
sdf-toolkit rank-paths /nix/store/7mcds2x62b81l2x3qxfxjgbwjjbwhjli-ypcb-ddr3-cvc-sdf-seed-58/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 11: baseline-no-lock-seed-55 fail idelay_dqs_cntvaluein lane0 dqs0 2 1340.0 ps'
sdf-toolkit rank-paths /nix/store/c5igzjqqpcyjvg0knvl8vi4qvvd7qp02-ypcb-ddr3-cvc-sdf-seed-55/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 12: baseline-no-lock-seed-34 fail idelay_dqs_cntvaluein lane0 dqs0 2 1179.0 ps'
sdf-toolkit rank-paths /nix/store/3560jfrb1q25gj4vpjl4673wnfddhyn4-ypcb-ddr3-cvc-sdf-seed-34/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 13: baseline-no-lock-seed-41 fail idelay_dqs_cntvaluein lane0 dqs0 2 1082.0 ps'
sdf-toolkit rank-paths /nix/store/cz155878nwxac4w2ril7cggakf4y39y0-ypcb-ddr3-cvc-sdf-seed-41/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 14: baseline-no-lock-seed-57 fail idelay_dqs_cntvaluein lane0 dqs0 2 1062.0 ps'
sdf-toolkit rank-paths /nix/store/27apxni2g0baf04xz784588543k6j5xn-ypcb-ddr3-cvc-sdf-seed-57/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 15: baseline-no-lock-seed-47 fail idelay_dqs_cntvaluein lane0 dqs0 2 1027.0 ps'
sdf-toolkit rank-paths /nix/store/6gb58ax36ic3afaws7pms8pp0f0w3l3d-ypcb-ddr3-cvc-sdf-seed-47/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 16: baseline-no-lock-seed-37 fail idelay_dqs_cntvaluein lane0 dqs0 2 975.0 ps'
sdf-toolkit rank-paths /nix/store/cbwvn8i0fc634rmr0c889a7cqr2dbvpr-ypcb-ddr3-cvc-sdf-seed-37/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_dqs_cntvaluein\[2\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk7\[0\]\.IDELAYE2_dqs.CNTVALUEIN2' --limit 10

echo '## 17: baseline-no-lock-seed-57 fail idelay_data_cntvaluein lane0 dq5 0 2045.0 ps'
sdf-toolkit rank-paths /nix/store/27apxni2g0baf04xz784588543k6j5xn-ypcb-ddr3-cvc-sdf-seed-57/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 18: baseline-no-lock-seed-58 fail idelay_data_cntvaluein lane0 dq5 0 1953.0 ps'
sdf-toolkit rank-paths /nix/store/7mcds2x62b81l2x3qxfxjgbwjjbwhjli-ypcb-ddr3-cvc-sdf-seed-58/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 19: baseline-no-lock-seed-31 fail idelay_data_cntvaluein lane0 dq5 0 1940.0 ps'
sdf-toolkit rank-paths /nix/store/rn6p13ihhvjbcn4pfs9wbcv975v23q64-ypcb-ddr3-cvc-sdf-seed-31/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 20: baseline-no-lock-seed-44 fail idelay_data_cntvaluein lane0 dq5 0 1909.0 ps'
sdf-toolkit rank-paths /nix/store/23dggz43q3rvwz54ggnhn4vz4r555pd1-ypcb-ddr3-cvc-sdf-seed-44/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 21: baseline-no-lock-seed-34 fail idelay_data_cntvaluein lane0 dq5 0 1865.0 ps'
sdf-toolkit rank-paths /nix/store/3560jfrb1q25gj4vpjl4673wnfddhyn4-ypcb-ddr3-cvc-sdf-seed-34/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 22: baseline-no-lock-seed-60 fail idelay_data_cntvaluein lane0 dq5 0 1776.0 ps'
sdf-toolkit rank-paths /nix/store/jsk4ysb3i05y30j8xkqi3v0cpsf2vq18-ypcb-ddr3-cvc-sdf-seed-60/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 23: baseline-no-lock-seed-38 fail idelay_data_cntvaluein lane0 dq5 0 1768.0 ps'
sdf-toolkit rank-paths /nix/store/9vqd2ipbcpi5lcm5a5wz0aql030kl867-ypcb-ddr3-cvc-sdf-seed-38/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 24: baseline-no-lock-seed-54 fail idelay_data_cntvaluein lane0 dq5 0 1754.0 ps'
sdf-toolkit rank-paths /nix/store/p097hkpi3wkaxflq65k6cvjzq2xqm088-ypcb-ddr3-cvc-sdf-seed-54/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 25: baseline-no-lock-seed-32 fail idelay_data_cntvaluein lane0 dq5 0 1733.0 ps'
sdf-toolkit rank-paths /nix/store/sdsvgyx8pf6m7fifnn98863wqrbiw4az-ypcb-ddr3-cvc-sdf-seed-32/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 26: baseline-no-lock-seed-45 fail idelay_data_cntvaluein lane0 dq5 0 1600.0 ps'
sdf-toolkit rank-paths /nix/store/864wdf9zvakrp6v8yibr5v3avkp04mxq-ypcb-ddr3-cvc-sdf-seed-45/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 27: baseline-no-lock-seed-55 fail idelay_data_cntvaluein lane0 dq5 0 1578.0 ps'
sdf-toolkit rank-paths /nix/store/c5igzjqqpcyjvg0knvl8vi4qvvd7qp02-ypcb-ddr3-cvc-sdf-seed-55/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 28: baseline-no-lock-seed-42 fail idelay_data_cntvaluein lane0 dq5 0 1544.0 ps'
sdf-toolkit rank-paths /nix/store/aqyx2vcnfini279smlmgii0azjg0vbm0-ypcb-ddr3-cvc-sdf-seed-42/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 29: baseline-no-lock-seed-41 fail idelay_data_cntvaluein lane0 dq5 0 1340.0 ps'
sdf-toolkit rank-paths /nix/store/cz155878nwxac4w2ril7cggakf4y39y0-ypcb-ddr3-cvc-sdf-seed-41/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 30: baseline-no-lock-seed-47 fail idelay_data_cntvaluein lane0 dq5 0 1297.0 ps'
sdf-toolkit rank-paths /nix/store/6gb58ax36ic3afaws7pms8pp0f0w3l3d-ypcb-ddr3-cvc-sdf-seed-47/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 31: baseline-no-lock-seed-40 fail idelay_data_cntvaluein lane0 dq5 0 1263.0 ps'
sdf-toolkit rank-paths /nix/store/xca418kd2l5z69rg3wdcy9xgyb5pml6r-ypcb-ddr3-cvc-sdf-seed-40/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 32: baseline-no-lock-seed-37 fail idelay_data_cntvaluein lane0 dq5 0 1223.0 ps'
sdf-toolkit rank-paths /nix/store/cbwvn8i0fc634rmr0c889a7cqr2dbvpr-ypcb-ddr3-cvc-sdf-seed-37/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[0\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN0' --limit 10

echo '## 33: baseline-no-lock-seed-32 fail idelay_data_cntvaluein lane1 dq15 4 1684.0 ps'
sdf-toolkit rank-paths /nix/store/sdsvgyx8pf6m7fifnn98863wqrbiw4az-ypcb-ddr3-cvc-sdf-seed-32/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 34: baseline-no-lock-seed-37 fail idelay_data_cntvaluein lane1 dq15 4 1582.0 ps'
sdf-toolkit rank-paths /nix/store/cbwvn8i0fc634rmr0c889a7cqr2dbvpr-ypcb-ddr3-cvc-sdf-seed-37/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 35: baseline-no-lock-seed-54 fail idelay_data_cntvaluein lane1 dq15 4 1473.0 ps'
sdf-toolkit rank-paths /nix/store/p097hkpi3wkaxflq65k6cvjzq2xqm088-ypcb-ddr3-cvc-sdf-seed-54/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 36: baseline-no-lock-seed-55 fail idelay_data_cntvaluein lane1 dq15 4 1419.0 ps'
sdf-toolkit rank-paths /nix/store/c5igzjqqpcyjvg0knvl8vi4qvvd7qp02-ypcb-ddr3-cvc-sdf-seed-55/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 37: baseline-no-lock-seed-58 fail idelay_data_cntvaluein lane1 dq15 4 1398.0 ps'
sdf-toolkit rank-paths /nix/store/7mcds2x62b81l2x3qxfxjgbwjjbwhjli-ypcb-ddr3-cvc-sdf-seed-58/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 38: baseline-no-lock-seed-38 fail idelay_data_cntvaluein lane1 dq15 4 1371.0 ps'
sdf-toolkit rank-paths /nix/store/9vqd2ipbcpi5lcm5a5wz0aql030kl867-ypcb-ddr3-cvc-sdf-seed-38/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 39: baseline-no-lock-seed-34 fail idelay_data_cntvaluein lane1 dq15 4 1358.0 ps'
sdf-toolkit rank-paths /nix/store/3560jfrb1q25gj4vpjl4673wnfddhyn4-ypcb-ddr3-cvc-sdf-seed-34/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 40: baseline-no-lock-seed-60 fail idelay_data_cntvaluein lane1 dq15 4 1355.0 ps'
sdf-toolkit rank-paths /nix/store/jsk4ysb3i05y30j8xkqi3v0cpsf2vq18-ypcb-ddr3-cvc-sdf-seed-60/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 41: baseline-no-lock-seed-57 fail idelay_data_cntvaluein lane1 dq15 4 1299.0 ps'
sdf-toolkit rank-paths /nix/store/27apxni2g0baf04xz784588543k6j5xn-ypcb-ddr3-cvc-sdf-seed-57/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 42: baseline-no-lock-seed-31 fail idelay_data_cntvaluein lane1 dq15 4 1197.0 ps'
sdf-toolkit rank-paths /nix/store/rn6p13ihhvjbcn4pfs9wbcv975v23q64-ypcb-ddr3-cvc-sdf-seed-31/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 43: baseline-no-lock-seed-45 fail idelay_data_cntvaluein lane1 dq15 4 1136.0 ps'
sdf-toolkit rank-paths /nix/store/864wdf9zvakrp6v8yibr5v3avkp04mxq-ypcb-ddr3-cvc-sdf-seed-45/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 44: baseline-no-lock-seed-40 fail idelay_data_cntvaluein lane1 dq15 4 1093.0 ps'
sdf-toolkit rank-paths /nix/store/xca418kd2l5z69rg3wdcy9xgyb5pml6r-ypcb-ddr3-cvc-sdf-seed-40/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 45: baseline-no-lock-seed-44 fail idelay_data_cntvaluein lane1 dq15 4 1070.0 ps'
sdf-toolkit rank-paths /nix/store/23dggz43q3rvwz54ggnhn4vz4r555pd1-ypcb-ddr3-cvc-sdf-seed-44/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 46: baseline-no-lock-seed-42 fail idelay_data_cntvaluein lane1 dq15 4 1052.0 ps'
sdf-toolkit rank-paths /nix/store/aqyx2vcnfini279smlmgii0azjg0vbm0-ypcb-ddr3-cvc-sdf-seed-42/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 47: baseline-no-lock-seed-41 fail idelay_data_cntvaluein lane1 dq15 4 898.0 ps'
sdf-toolkit rank-paths /nix/store/cz155878nwxac4w2ril7cggakf4y39y0-ypcb-ddr3-cvc-sdf-seed-41/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 48: baseline-no-lock-seed-47 fail idelay_data_cntvaluein lane1 dq15 4 669.0 ps'
sdf-toolkit rank-paths /nix/store/6gb58ax36ic3afaws7pms8pp0f0w3l3d-ypcb-ddr3-cvc-sdf-seed-47/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.phy_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[15\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 49: baseline-no-lock-seed-40 fail idelay_ld lane0 dq5  2292.0 ps'
sdf-toolkit rank-paths /nix/store/xca418kd2l5z69rg3wdcy9xgyb5pml6r-ypcb-ddr3-cvc-sdf-seed-40/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 50: baseline-no-lock-seed-54 fail idelay_ld lane0 dq5  2098.0 ps'
sdf-toolkit rank-paths /nix/store/p097hkpi3wkaxflq65k6cvjzq2xqm088-ypcb-ddr3-cvc-sdf-seed-54/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 51: baseline-no-lock-seed-32 fail idelay_ld lane0 dq5  1851.0 ps'
sdf-toolkit rank-paths /nix/store/sdsvgyx8pf6m7fifnn98863wqrbiw4az-ypcb-ddr3-cvc-sdf-seed-32/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 52: baseline-no-lock-seed-58 fail idelay_ld lane0 dq5  1782.0 ps'
sdf-toolkit rank-paths /nix/store/7mcds2x62b81l2x3qxfxjgbwjjbwhjli-ypcb-ddr3-cvc-sdf-seed-58/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 53: baseline-no-lock-seed-38 fail idelay_ld lane0 dq5  1750.0 ps'
sdf-toolkit rank-paths /nix/store/9vqd2ipbcpi5lcm5a5wz0aql030kl867-ypcb-ddr3-cvc-sdf-seed-38/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 54: baseline-no-lock-seed-34 fail idelay_ld lane0 dq5  1725.0 ps'
sdf-toolkit rank-paths /nix/store/3560jfrb1q25gj4vpjl4673wnfddhyn4-ypcb-ddr3-cvc-sdf-seed-34/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 55: baseline-no-lock-seed-37 fail idelay_ld lane0 dq5  1720.0 ps'
sdf-toolkit rank-paths /nix/store/cbwvn8i0fc634rmr0c889a7cqr2dbvpr-ypcb-ddr3-cvc-sdf-seed-37/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 56: baseline-no-lock-seed-41 fail idelay_ld lane0 dq5  1707.0 ps'
sdf-toolkit rank-paths /nix/store/cz155878nwxac4w2ril7cggakf4y39y0-ypcb-ddr3-cvc-sdf-seed-41/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 57: baseline-no-lock-seed-31 fail idelay_ld lane0 dq5  1702.0 ps'
sdf-toolkit rank-paths /nix/store/rn6p13ihhvjbcn4pfs9wbcv975v23q64-ypcb-ddr3-cvc-sdf-seed-31/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 58: baseline-no-lock-seed-60 fail idelay_ld lane0 dq5  1577.0 ps'
sdf-toolkit rank-paths /nix/store/jsk4ysb3i05y30j8xkqi3v0cpsf2vq18-ypcb-ddr3-cvc-sdf-seed-60/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 59: baseline-no-lock-seed-44 fail idelay_ld lane0 dq5  1544.0 ps'
sdf-toolkit rank-paths /nix/store/23dggz43q3rvwz54ggnhn4vz4r555pd1-ypcb-ddr3-cvc-sdf-seed-44/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

echo '## 60: baseline-no-lock-seed-42 fail idelay_ld lane0 dq5  1506.0 ps'
sdf-toolkit rank-paths /nix/store/aqyx2vcnfini279smlmgii0azjg0vbm0-ypcb-ddr3-cvc-sdf-seed-42/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$40985.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.LD' --limit 10

#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Strict fail-slower candidate endpoints.

echo '## 1: baseline-no-lock-seed-6 fail idelay_data_cntvaluein lane0 dq5 4 2132.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rk60jv9g0grc00wfnry0g8dv0ldxapx7-ypcb-ddr3-cvc-sdf-seed-6/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 2: baseline-no-lock-seed-27 fail idelay_data_cntvaluein lane0 dq5 4 1995.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fmck9i7wn2im7ldyj5h27s4paph4z6xy-ypcb-ddr3-cvc-sdf-seed-27/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 3: baseline-no-lock-seed-12 fail idelay_data_cntvaluein lane0 dq5 4 1893.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/vs8bg3dvhsj7gy0djnk8h2310zm1dm69-ypcb-ddr3-cvc-sdf-seed-12/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 4: baseline-no-lock-seed-20 fail idelay_data_cntvaluein lane0 dq5 4 1868.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/lcxc5s8ddg4xd976wmzpwc1afk0h4kid-ypcb-ddr3-cvc-sdf-seed-20/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 5: baseline-no-lock-seed-16 fail idelay_data_cntvaluein lane0 dq5 4 1764.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ai4dzq0wdfff4sg63n36d4nw5nkxs7xg-ypcb-ddr3-cvc-sdf-seed-16/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 6: baseline-no-lock-seed-23 fail idelay_data_cntvaluein lane0 dq5 4 1717.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/kcc1vg7111008kbf688xb9bpfrwsdj86-ypcb-ddr3-cvc-sdf-seed-23/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 7: baseline-no-lock-seed-11 fail idelay_data_cntvaluein lane0 dq5 4 1546.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 8: baseline-no-lock-seed-2 fail idelay_data_cntvaluein lane0 dq5 4 990.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0kdbg5v141vafykf1nvgb36xf0dfnwh2-ypcb-ddr3-cvc-sdf-seed-2/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[5\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 9: baseline-no-lock-seed-27 fail idelay_data_cntvaluein lane0 dq7 4 2256.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fmck9i7wn2im7ldyj5h27s4paph4z6xy-ypcb-ddr3-cvc-sdf-seed-27/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 10: baseline-no-lock-seed-6 fail idelay_data_cntvaluein lane0 dq7 4 2186.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rk60jv9g0grc00wfnry0g8dv0ldxapx7-ypcb-ddr3-cvc-sdf-seed-6/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 11: baseline-no-lock-seed-12 fail idelay_data_cntvaluein lane0 dq7 4 2137.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/vs8bg3dvhsj7gy0djnk8h2310zm1dm69-ypcb-ddr3-cvc-sdf-seed-12/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 12: baseline-no-lock-seed-20 fail idelay_data_cntvaluein lane0 dq7 4 2092.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/lcxc5s8ddg4xd976wmzpwc1afk0h4kid-ypcb-ddr3-cvc-sdf-seed-20/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 13: baseline-no-lock-seed-16 fail idelay_data_cntvaluein lane0 dq7 4 2002.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ai4dzq0wdfff4sg63n36d4nw5nkxs7xg-ypcb-ddr3-cvc-sdf-seed-16/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 14: baseline-no-lock-seed-23 fail idelay_data_cntvaluein lane0 dq7 4 1664.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/kcc1vg7111008kbf688xb9bpfrwsdj86-ypcb-ddr3-cvc-sdf-seed-23/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 15: baseline-no-lock-seed-11 fail idelay_data_cntvaluein lane0 dq7 4 1419.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 16: baseline-no-lock-seed-2 fail idelay_data_cntvaluein lane0 dq7 4 1279.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0kdbg5v141vafykf1nvgb36xf0dfnwh2-ypcb-ddr3-cvc-sdf-seed-2/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[7\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 17: baseline-no-lock-seed-27 fail idelay_data_cntvaluein lane0 dq4 4 2161.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fmck9i7wn2im7ldyj5h27s4paph4z6xy-ypcb-ddr3-cvc-sdf-seed-27/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 18: baseline-no-lock-seed-20 fail idelay_data_cntvaluein lane0 dq4 4 2088.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/lcxc5s8ddg4xd976wmzpwc1afk0h4kid-ypcb-ddr3-cvc-sdf-seed-20/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 19: baseline-no-lock-seed-12 fail idelay_data_cntvaluein lane0 dq4 4 2042.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/vs8bg3dvhsj7gy0djnk8h2310zm1dm69-ypcb-ddr3-cvc-sdf-seed-12/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 20: baseline-no-lock-seed-6 fail idelay_data_cntvaluein lane0 dq4 4 2006.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rk60jv9g0grc00wfnry0g8dv0ldxapx7-ypcb-ddr3-cvc-sdf-seed-6/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 21: baseline-no-lock-seed-16 fail idelay_data_cntvaluein lane0 dq4 4 1917.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ai4dzq0wdfff4sg63n36d4nw5nkxs7xg-ypcb-ddr3-cvc-sdf-seed-16/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 22: baseline-no-lock-seed-23 fail idelay_data_cntvaluein lane0 dq4 4 1621.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/kcc1vg7111008kbf688xb9bpfrwsdj86-ypcb-ddr3-cvc-sdf-seed-23/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 23: baseline-no-lock-seed-11 fail idelay_data_cntvaluein lane0 dq4 4 1416.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 24: baseline-no-lock-seed-2 fail idelay_data_cntvaluein lane0 dq4 4 1184.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0kdbg5v141vafykf1nvgb36xf0dfnwh2-ypcb-ddr3-cvc-sdf-seed-2/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[4\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 25: baseline-no-lock-seed-27 fail idelay_data_cntvaluein lane0 dq0 4 2076.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fmck9i7wn2im7ldyj5h27s4paph4z6xy-ypcb-ddr3-cvc-sdf-seed-27/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 26: baseline-no-lock-seed-6 fail idelay_data_cntvaluein lane0 dq0 4 2023.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rk60jv9g0grc00wfnry0g8dv0ldxapx7-ypcb-ddr3-cvc-sdf-seed-6/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 27: baseline-no-lock-seed-20 fail idelay_data_cntvaluein lane0 dq0 4 2005.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/lcxc5s8ddg4xd976wmzpwc1afk0h4kid-ypcb-ddr3-cvc-sdf-seed-20/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 28: baseline-no-lock-seed-16 fail idelay_data_cntvaluein lane0 dq0 4 1978.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ai4dzq0wdfff4sg63n36d4nw5nkxs7xg-ypcb-ddr3-cvc-sdf-seed-16/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 29: baseline-no-lock-seed-12 fail idelay_data_cntvaluein lane0 dq0 4 1866.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/vs8bg3dvhsj7gy0djnk8h2310zm1dm69-ypcb-ddr3-cvc-sdf-seed-12/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 30: baseline-no-lock-seed-23 fail idelay_data_cntvaluein lane0 dq0 4 1526.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/kcc1vg7111008kbf688xb9bpfrwsdj86-ypcb-ddr3-cvc-sdf-seed-23/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 31: baseline-no-lock-seed-11 fail idelay_data_cntvaluein lane0 dq0 4 1279.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 32: baseline-no-lock-seed-2 fail idelay_data_cntvaluein lane0 dq0 4 1088.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0kdbg5v141vafykf1nvgb36xf0dfnwh2-ypcb-ddr3-cvc-sdf-seed-2/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[0\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 33: baseline-no-lock-seed-6 fail idelay_data_cntvaluein lane0 dq3 4 2134.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rk60jv9g0grc00wfnry0g8dv0ldxapx7-ypcb-ddr3-cvc-sdf-seed-6/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 34: baseline-no-lock-seed-27 fail idelay_data_cntvaluein lane0 dq3 4 2042.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fmck9i7wn2im7ldyj5h27s4paph4z6xy-ypcb-ddr3-cvc-sdf-seed-27/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 35: baseline-no-lock-seed-20 fail idelay_data_cntvaluein lane0 dq3 4 1955.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/lcxc5s8ddg4xd976wmzpwc1afk0h4kid-ypcb-ddr3-cvc-sdf-seed-20/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 36: baseline-no-lock-seed-12 fail idelay_data_cntvaluein lane0 dq3 4 1804.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/vs8bg3dvhsj7gy0djnk8h2310zm1dm69-ypcb-ddr3-cvc-sdf-seed-12/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 37: baseline-no-lock-seed-16 fail idelay_data_cntvaluein lane0 dq3 4 1675.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ai4dzq0wdfff4sg63n36d4nw5nkxs7xg-ypcb-ddr3-cvc-sdf-seed-16/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 38: baseline-no-lock-seed-23 fail idelay_data_cntvaluein lane0 dq3 4 1628.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/kcc1vg7111008kbf688xb9bpfrwsdj86-ypcb-ddr3-cvc-sdf-seed-23/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 39: baseline-no-lock-seed-11 fail idelay_data_cntvaluein lane0 dq3 4 1457.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 40: baseline-no-lock-seed-2 fail idelay_data_cntvaluein lane0 dq3 4 1077.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0kdbg5v141vafykf1nvgb36xf0dfnwh2-ypcb-ddr3-cvc-sdf-seed-2/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[3\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 41: baseline-no-lock-seed-16 fail idelay_data_cntvaluein lane1 dq8 4 1886.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ai4dzq0wdfff4sg63n36d4nw5nkxs7xg-ypcb-ddr3-cvc-sdf-seed-16/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 42: baseline-no-lock-seed-27 fail idelay_data_cntvaluein lane1 dq8 4 1768.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fmck9i7wn2im7ldyj5h27s4paph4z6xy-ypcb-ddr3-cvc-sdf-seed-27/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 43: baseline-no-lock-seed-6 fail idelay_data_cntvaluein lane1 dq8 4 1736.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rk60jv9g0grc00wfnry0g8dv0ldxapx7-ypcb-ddr3-cvc-sdf-seed-6/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 44: baseline-no-lock-seed-20 fail idelay_data_cntvaluein lane1 dq8 4 1728.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/lcxc5s8ddg4xd976wmzpwc1afk0h4kid-ypcb-ddr3-cvc-sdf-seed-20/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 45: baseline-no-lock-seed-12 fail idelay_data_cntvaluein lane1 dq8 4 1537.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/vs8bg3dvhsj7gy0djnk8h2310zm1dm69-ypcb-ddr3-cvc-sdf-seed-12/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 46: baseline-no-lock-seed-11 fail idelay_data_cntvaluein lane1 dq8 4 1384.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 47: baseline-no-lock-seed-23 fail idelay_data_cntvaluein lane1 dq8 4 1338.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/kcc1vg7111008kbf688xb9bpfrwsdj86-ypcb-ddr3-cvc-sdf-seed-23/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 48: baseline-no-lock-seed-2 fail idelay_data_cntvaluein lane1 dq8 4 1192.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0kdbg5v141vafykf1nvgb36xf0dfnwh2-ypcb-ddr3-cvc-sdf-seed-2/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[8\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 49: baseline-no-lock-seed-27 fail idelay_data_cntvaluein lane0 dq1 4 2135.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fmck9i7wn2im7ldyj5h27s4paph4z6xy-ypcb-ddr3-cvc-sdf-seed-27/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 50: baseline-no-lock-seed-16 fail idelay_data_cntvaluein lane0 dq1 4 2063.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ai4dzq0wdfff4sg63n36d4nw5nkxs7xg-ypcb-ddr3-cvc-sdf-seed-16/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 51: baseline-no-lock-seed-6 fail idelay_data_cntvaluein lane0 dq1 4 2022.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rk60jv9g0grc00wfnry0g8dv0ldxapx7-ypcb-ddr3-cvc-sdf-seed-6/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 52: baseline-no-lock-seed-12 fail idelay_data_cntvaluein lane0 dq1 4 1953.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/vs8bg3dvhsj7gy0djnk8h2310zm1dm69-ypcb-ddr3-cvc-sdf-seed-12/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 53: baseline-no-lock-seed-20 fail idelay_data_cntvaluein lane0 dq1 4 1924.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/lcxc5s8ddg4xd976wmzpwc1afk0h4kid-ypcb-ddr3-cvc-sdf-seed-20/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 54: baseline-no-lock-seed-23 fail idelay_data_cntvaluein lane0 dq1 4 1539.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/kcc1vg7111008kbf688xb9bpfrwsdj86-ypcb-ddr3-cvc-sdf-seed-23/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 55: baseline-no-lock-seed-11 fail idelay_data_cntvaluein lane0 dq1 4 1365.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 56: baseline-no-lock-seed-2 fail idelay_data_cntvaluein lane0 dq1 4 1095.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0kdbg5v141vafykf1nvgb36xf0dfnwh2-ypcb-ddr3-cvc-sdf-seed-2/ypcb_00338_1p1_ddr3.cvc.sdf '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_phy_inst\.i_controller_idelay_data_cntvaluein\[4\].O6' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[1\]\.IDELAYE2_data.CNTVALUEIN4' --limit 10

echo '## 57: baseline-no-lock-seed-16 fail dq_iologic lane1 dq11  3190.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ai4dzq0wdfff4sg63n36d4nw5nkxs7xg-ypcb-ddr3-cvc-sdf-seed-16/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46609.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.ISERDESE2_data.RST' --limit 10

echo '## 58: baseline-no-lock-seed-16 fail dq_iologic lane1 dq11  3190.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ai4dzq0wdfff4sg63n36d4nw5nkxs7xg-ypcb-ddr3-cvc-sdf-seed-16/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46609.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.genblk1\.OSERDESE2_data.RST' --limit 10

echo '## 59: baseline-no-lock-seed-20 fail dq_iologic lane1 dq11  2894.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/lcxc5s8ddg4xd976wmzpwc1afk0h4kid-ypcb-ddr3-cvc-sdf-seed-20/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46372.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.genblk1\.OSERDESE2_data.D2' --limit 10

echo '## 60: baseline-no-lock-seed-11 fail dq_iologic lane1 dq11  2842.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf '\$auto\$ff\.cc\:266\:slice\$46436.Q' 'ddr3_top_inst\.ddr3_phy_inst\.genblk5\[11\]\.genblk1\.OSERDESE2_data.D6' --limit 10

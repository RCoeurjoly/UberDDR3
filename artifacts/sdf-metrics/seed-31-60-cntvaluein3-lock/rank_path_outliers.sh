#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: cntvaluein3-skew-locked-seed-46 pass clocking all   7215.0 ps'
sdf-toolkit rank-paths /nix/store/czd4fc213sr572ciwza8d6ld6hsfk5ba-ypcb-ddr3-cvc-sdf-seed-46-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[2\]\[0\].A1' --limit 10

echo '## 2: cntvaluein3-skew-locked-seed-46 pass clocking all   7215.0 ps'
sdf-toolkit rank-paths /nix/store/czd4fc213sr572ciwza8d6ld6hsfk5ba-ypcb-ddr3-cvc-sdf-seed-46-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 3: cntvaluein3-skew-locked-seed-50 fail clocking all   7215.0 ps'
sdf-toolkit rank-paths /nix/store/i4ycx8wcp5rpxwi1y3qfmbzl6jcbldw7-ypcb-ddr3-cvc-sdf-seed-50-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197685.A4' --limit 10

echo '## 4: cntvaluein3-skew-locked-seed-50 fail clocking all   7215.0 ps'
sdf-toolkit rank-paths /nix/store/i4ycx8wcp5rpxwi1y3qfmbzl6jcbldw7-ypcb-ddr3-cvc-sdf-seed-50-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A2' --limit 10

echo '## 5: cntvaluein3-skew-locked-seed-50 fail clocking all   7184.0 ps'
sdf-toolkit rank-paths /nix/store/i4ycx8wcp5rpxwi1y3qfmbzl6jcbldw7-ypcb-ddr3-cvc-sdf-seed-50-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197683.A4' --limit 10

echo '## 6: cntvaluein3-skew-locked-seed-50 fail clocking all   7184.0 ps'
sdf-toolkit rank-paths /nix/store/i4ycx8wcp5rpxwi1y3qfmbzl6jcbldw7-ypcb-ddr3-cvc-sdf-seed-50-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A2' --limit 10

echo '## 7: cntvaluein3-skew-locked-seed-50 fail clocking all   7170.0 ps'
sdf-toolkit rank-paths /nix/store/i4ycx8wcp5rpxwi1y3qfmbzl6jcbldw7-ypcb-ddr3-cvc-sdf-seed-50-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A2' --limit 10

echo '## 8: cntvaluein3-skew-locked-seed-47 pass clocking all   7155.0 ps'
sdf-toolkit rank-paths /nix/store/h6ilrjp5m9sdgs3lx2ddc9g9pjqi054q-ypcb-ddr3-cvc-sdf-seed-47-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197683.A4' --limit 10

echo '## 9: cntvaluein3-skew-locked-seed-32 pass clocking all   7110.0 ps'
sdf-toolkit rank-paths /nix/store/2ik576xdlabgwahzcj14ivskzdhs9jy8-ypcb-ddr3-cvc-sdf-seed-32-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A3' --limit 10

echo '## 10: cntvaluein3-skew-locked-seed-50 fail clocking all   7110.0 ps'
sdf-toolkit rank-paths /nix/store/i4ycx8wcp5rpxwi1y3qfmbzl6jcbldw7-ypcb-ddr3-cvc-sdf-seed-50-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A1' --limit 10

echo '## 11: cntvaluein3-skew-locked-seed-33 fail clocking all   7094.0 ps'
sdf-toolkit rank-paths /nix/store/538193v05gkbxwyzvr8cya1cp9kvnkjj-ypcb-ddr3-cvc-sdf-seed-33-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A2' --limit 10

echo '## 12: cntvaluein3-skew-locked-seed-47 pass clocking all   7094.0 ps'
sdf-toolkit rank-paths /nix/store/h6ilrjp5m9sdgs3lx2ddc9g9pjqi054q-ypcb-ddr3-cvc-sdf-seed-47-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A5' --limit 10

echo '## 13: cntvaluein3-skew-locked-seed-38 pass clocking all   7079.0 ps'
sdf-toolkit rank-paths /nix/store/azq7j0rmrsqph9krzn23cj37vwz3nlx5-ypcb-ddr3-cvc-sdf-seed-38-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A1' --limit 10

echo '## 14: cntvaluein3-skew-locked-seed-52 fail clocking all   7079.0 ps'
sdf-toolkit rank-paths /nix/store/75crk0qx14mrym0ga217642ivkwsb0l2-ypcb-ddr3-cvc-sdf-seed-52-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A5' --limit 10

echo '## 15: cntvaluein3-skew-locked-seed-48 fail clocking all   7050.0 ps'
sdf-toolkit rank-paths /nix/store/dd201k6r0zw9qf2kiznrq6fidbw9qx45-ypcb-ddr3-cvc-sdf-seed-48-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A2' --limit 10

echo '## 16: cntvaluein3-skew-locked-seed-52 fail clocking all   7050.0 ps'
sdf-toolkit rank-paths /nix/store/75crk0qx14mrym0ga217642ivkwsb0l2-ypcb-ddr3-cvc-sdf-seed-52-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A3' --limit 10

echo '## 17: cntvaluein3-skew-locked-seed-38 pass clocking all   7034.0 ps'
sdf-toolkit rank-paths /nix/store/azq7j0rmrsqph9krzn23cj37vwz3nlx5-ypcb-ddr3-cvc-sdf-seed-38-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A2' --limit 10

echo '## 18: cntvaluein3-skew-locked-seed-33 fail clocking all   7019.0 ps'
sdf-toolkit rank-paths /nix/store/538193v05gkbxwyzvr8cya1cp9kvnkjj-ypcb-ddr3-cvc-sdf-seed-33-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A1' --limit 10

echo '## 19: cntvaluein3-skew-locked-seed-33 fail clocking all   7019.0 ps'
sdf-toolkit rank-paths /nix/store/538193v05gkbxwyzvr8cya1cp9kvnkjj-ypcb-ddr3-cvc-sdf-seed-33-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A1' --limit 10

echo '## 20: cntvaluein3-skew-locked-seed-38 pass clocking all   7019.0 ps'
sdf-toolkit rank-paths /nix/store/azq7j0rmrsqph9krzn23cj37vwz3nlx5-ypcb-ddr3-cvc-sdf-seed-38-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A2' --limit 10

echo '## 21: cntvaluein3-skew-locked-seed-32 pass clocking all   6989.0 ps'
sdf-toolkit rank-paths /nix/store/2ik576xdlabgwahzcj14ivskzdhs9jy8-ypcb-ddr3-cvc-sdf-seed-32-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A1' --limit 10

echo '## 22: cntvaluein3-skew-locked-seed-38 pass clocking all   6989.0 ps'
sdf-toolkit rank-paths /nix/store/azq7j0rmrsqph9krzn23cj37vwz3nlx5-ypcb-ddr3-cvc-sdf-seed-38-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A2' --limit 10

echo '## 23: cntvaluein3-skew-locked-seed-48 fail clocking all   6989.0 ps'
sdf-toolkit rank-paths /nix/store/dd201k6r0zw9qf2kiznrq6fidbw9qx45-ypcb-ddr3-cvc-sdf-seed-48-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A5' --limit 10

echo '## 24: cntvaluein3-skew-locked-seed-54 pass clocking all   6974.0 ps'
sdf-toolkit rank-paths /nix/store/1rrfiby8rarcbfjgq2x7cn3mqp964hrn-ypcb-ddr3-cvc-sdf-seed-54-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A4' --limit 10

echo '## 25: cntvaluein3-skew-locked-seed-55 pass clocking all   6945.0 ps'
sdf-toolkit rank-paths /nix/store/ffi53adc419phkjvbaw74rphyzsb1p96-ypcb-ddr3-cvc-sdf-seed-55-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 26: cntvaluein3-skew-locked-seed-55 pass clocking all   6945.0 ps'
sdf-toolkit rank-paths /nix/store/ffi53adc419phkjvbaw74rphyzsb1p96-ypcb-ddr3-cvc-sdf-seed-55-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$14733.A1' --limit 10

echo '## 27: cntvaluein3-skew-locked-seed-31 pass clocking all   6929.0 ps'
sdf-toolkit rank-paths /nix/store/xnp6a5a97258bm9n1knbvn20a4wrg6yw-ypcb-ddr3-cvc-sdf-seed-31-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A1' --limit 10

echo '## 28: cntvaluein3-skew-locked-seed-40 pass clocking all   6929.0 ps'
sdf-toolkit rank-paths /nix/store/8q45hiz5pp15bzcmi6wkqrljsc0c6k3f-ypcb-ddr3-cvc-sdf-seed-40-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A1' --limit 10

echo '## 29: cntvaluein3-skew-locked-seed-40 pass clocking all   6929.0 ps'
sdf-toolkit rank-paths /nix/store/8q45hiz5pp15bzcmi6wkqrljsc0c6k3f-ypcb-ddr3-cvc-sdf-seed-40-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A1' --limit 10

echo '## 30: cntvaluein3-skew-locked-seed-47 pass clocking all   6929.0 ps'
sdf-toolkit rank-paths /nix/store/h6ilrjp5m9sdgs3lx2ddc9g9pjqi054q-ypcb-ddr3-cvc-sdf-seed-47-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A1' --limit 10

echo '## 31: cntvaluein3-skew-locked-seed-54 pass clocking all   6914.0 ps'
sdf-toolkit rank-paths /nix/store/1rrfiby8rarcbfjgq2x7cn3mqp964hrn-ypcb-ddr3-cvc-sdf-seed-54-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A2' --limit 10

echo '## 32: cntvaluein3-skew-locked-seed-31 pass clocking all   6900.0 ps'
sdf-toolkit rank-paths /nix/store/xnp6a5a97258bm9n1knbvn20a4wrg6yw-ypcb-ddr3-cvc-sdf-seed-31-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A3' --limit 10

echo '## 33: cntvaluein3-skew-locked-seed-31 pass clocking all   6900.0 ps'
sdf-toolkit rank-paths /nix/store/xnp6a5a97258bm9n1knbvn20a4wrg6yw-ypcb-ddr3-cvc-sdf-seed-31-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192487.A4' --limit 10

echo '## 34: cntvaluein3-skew-locked-seed-32 pass clocking all   6900.0 ps'
sdf-toolkit rank-paths /nix/store/2ik576xdlabgwahzcj14ivskzdhs9jy8-ypcb-ddr3-cvc-sdf-seed-32-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A2' --limit 10

echo '## 35: cntvaluein3-skew-locked-seed-40 pass clocking all   6900.0 ps'
sdf-toolkit rank-paths /nix/store/8q45hiz5pp15bzcmi6wkqrljsc0c6k3f-ypcb-ddr3-cvc-sdf-seed-40-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A4' --limit 10

echo '## 36: cntvaluein3-skew-locked-seed-40 pass clocking all   6900.0 ps'
sdf-toolkit rank-paths /nix/store/8q45hiz5pp15bzcmi6wkqrljsc0c6k3f-ypcb-ddr3-cvc-sdf-seed-40-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A5' --limit 10

echo '## 37: cntvaluein3-skew-locked-seed-35 pass clocking all   6885.0 ps'
sdf-toolkit rank-paths /nix/store/yv02j7q5rwgm16f4pc4g1siq7r3m6bd8-ypcb-ddr3-cvc-sdf-seed-35-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A1' --limit 10

echo '## 38: cntvaluein3-skew-locked-seed-34 pass clocking all   6869.0 ps'
sdf-toolkit rank-paths /nix/store/kxvyljhsvj02r2jp2xwf7pz8lm62ip10-ypcb-ddr3-cvc-sdf-seed-34-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A2' --limit 10

echo '## 39: cntvaluein3-skew-locked-seed-34 pass clocking all   6869.0 ps'
sdf-toolkit rank-paths /nix/store/kxvyljhsvj02r2jp2xwf7pz8lm62ip10-ypcb-ddr3-cvc-sdf-seed-34-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A5' --limit 10

echo '## 40: cntvaluein3-skew-locked-seed-34 pass clocking all   6869.0 ps'
sdf-toolkit rank-paths /nix/store/kxvyljhsvj02r2jp2xwf7pz8lm62ip10-ypcb-ddr3-cvc-sdf-seed-34-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A5' --limit 10

echo '## 41: cntvaluein3-skew-locked-seed-45 fail clocking all   6869.0 ps'
sdf-toolkit rank-paths /nix/store/pw5xjdp03fqz5hrdl0v7x3fjh6ks9mcw-ypcb-ddr3-cvc-sdf-seed-45-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A5' --limit 10

echo '## 42: cntvaluein3-skew-locked-seed-35 pass clocking all   6855.0 ps'
sdf-toolkit rank-paths /nix/store/yv02j7q5rwgm16f4pc4g1siq7r3m6bd8-ypcb-ddr3-cvc-sdf-seed-35-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A3' --limit 10

echo '## 43: cntvaluein3-skew-locked-seed-35 pass clocking all   6855.0 ps'
sdf-toolkit rank-paths /nix/store/yv02j7q5rwgm16f4pc4g1siq7r3m6bd8-ypcb-ddr3-cvc-sdf-seed-35-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A5' --limit 10

echo '## 44: cntvaluein3-skew-locked-seed-36 fail clocking all   6855.0 ps'
sdf-toolkit rank-paths /nix/store/c1wfmvx1isa9rw92wsp919pgcrzk6pk7-ypcb-ddr3-cvc-sdf-seed-36-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A4' --limit 10

echo '## 45: cntvaluein3-skew-locked-seed-45 fail clocking all   6855.0 ps'
sdf-toolkit rank-paths /nix/store/pw5xjdp03fqz5hrdl0v7x3fjh6ks9mcw-ypcb-ddr3-cvc-sdf-seed-45-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A2' --limit 10

echo '## 46: cntvaluein3-skew-locked-seed-36 fail clocking all   6840.0 ps'
sdf-toolkit rank-paths /nix/store/c1wfmvx1isa9rw92wsp919pgcrzk6pk7-ypcb-ddr3-cvc-sdf-seed-36-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A1' --limit 10

echo '## 47: cntvaluein3-skew-locked-seed-54 pass clocking all   6840.0 ps'
sdf-toolkit rank-paths /nix/store/1rrfiby8rarcbfjgq2x7cn3mqp964hrn-ypcb-ddr3-cvc-sdf-seed-54-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A2' --limit 10

echo '## 48: cntvaluein3-skew-locked-seed-36 fail clocking all   6824.0 ps'
sdf-toolkit rank-paths /nix/store/c1wfmvx1isa9rw92wsp919pgcrzk6pk7-ypcb-ddr3-cvc-sdf-seed-36-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A2' --limit 10

echo '## 49: cntvaluein3-skew-locked-seed-49 pass clocking all   6824.0 ps'
sdf-toolkit rank-paths /nix/store/l9z7qnbsb96vblh2x0skw54zvx5pxc6h-ypcb-ddr3-cvc-sdf-seed-49-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A1' --limit 10

echo '## 50: cntvaluein3-skew-locked-seed-56 pass clocking all   6824.0 ps'
sdf-toolkit rank-paths /nix/store/91wzi8vlcxncj028cjf449il5ys4hc3f-ypcb-ddr3-cvc-sdf-seed-56-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 51: cntvaluein3-skew-locked-seed-56 pass clocking all   6824.0 ps'
sdf-toolkit rank-paths /nix/store/91wzi8vlcxncj028cjf449il5ys4hc3f-ypcb-ddr3-cvc-sdf-seed-56-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$20664.A1' --limit 10

echo '## 52: cntvaluein3-skew-locked-seed-53 fail clocking all   6809.0 ps'
sdf-toolkit rank-paths /nix/store/2zrnigv650jb8r39cgijw2ljb7wddp6s-ypcb-ddr3-cvc-sdf-seed-53-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A1' --limit 10

echo '## 53: cntvaluein3-skew-locked-seed-59 pass clocking all   6809.0 ps'
sdf-toolkit rank-paths /nix/store/gywjkqi7zrz42mmvqnbc2swx76wqxkw4-ypcb-ddr3-cvc-sdf-seed-59-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 54: cntvaluein3-skew-locked-seed-59 pass clocking all   6809.0 ps'
sdf-toolkit rank-paths /nix/store/gywjkqi7zrz42mmvqnbc2swx76wqxkw4-ypcb-ddr3-cvc-sdf-seed-59-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$8060.A1' --limit 10

echo '## 55: cntvaluein3-skew-locked-seed-33 fail clocking all   6795.0 ps'
sdf-toolkit rank-paths /nix/store/538193v05gkbxwyzvr8cya1cp9kvnkjj-ypcb-ddr3-cvc-sdf-seed-33-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 56: cntvaluein3-skew-locked-seed-33 fail clocking all   6795.0 ps'
sdf-toolkit rank-paths /nix/store/538193v05gkbxwyzvr8cya1cp9kvnkjj-ypcb-ddr3-cvc-sdf-seed-33-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192566.A1' --limit 10

echo '## 57: cntvaluein3-skew-locked-seed-51 fail clocking all   6780.0 ps'
sdf-toolkit rank-paths /nix/store/32xikh5z3vq5f910gylhgvxw2cnl1zwg-ypcb-ddr3-cvc-sdf-seed-51-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A5' --limit 10

echo '## 58: cntvaluein3-skew-locked-seed-53 fail clocking all   6780.0 ps'
sdf-toolkit rank-paths /nix/store/2zrnigv650jb8r39cgijw2ljb7wddp6s-ypcb-ddr3-cvc-sdf-seed-53-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A1' --limit 10

echo '## 59: cntvaluein3-skew-locked-seed-53 fail clocking all   6750.0 ps'
sdf-toolkit rank-paths /nix/store/2zrnigv650jb8r39cgijw2ljb7wddp6s-ypcb-ddr3-cvc-sdf-seed-53-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A2' --limit 10

echo '## 60: cntvaluein3-skew-locked-seed-37 pass clocking all   6735.0 ps'
sdf-toolkit rank-paths /nix/store/iy66pq0xfx23srdi51zlqaqv02qwyh16-ypcb-ddr3-cvc-sdf-seed-37-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

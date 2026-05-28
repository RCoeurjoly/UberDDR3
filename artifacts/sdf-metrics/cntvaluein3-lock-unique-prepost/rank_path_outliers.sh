#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: cntvaluein3-skew-locked-seed12-long-poll fail clocking all   7485.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$66.A1' --limit 10

echo '## 2: cntvaluein3-skew-locked-seed12-long-poll fail clocking all   7485.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[3\]\[5\].A1' --limit 10

echo '## 3: cntvaluein3-skew-locked-seed3 pass clocking all   7170.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rpm83nrx1myi4z04p7dkx968pd871g6f-ypcb-ddr3-cvc-sdf-seed-3-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198315.A1' --limit 10

echo '## 4: cntvaluein3-skew-locked-seed3 pass clocking all   7125.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rpm83nrx1myi4z04p7dkx968pd871g6f-ypcb-ddr3-cvc-sdf-seed-3-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198321.A1' --limit 10

echo '## 5: cntvaluein3-skew-locked-seed1 pass clocking all   7065.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/xpjjqdymdp9bs6im78shp4k572ycichb-ypcb-ddr3-cvc-sdf-seed-1-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A5' --limit 10

echo '## 6: cntvaluein3-skew-locked-seed2 pass clocking all   7050.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/8swni5hwgvg8fzs7maxjfs5snvwaj7lp-ypcb-ddr3-cvc-sdf-seed-2-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197617.A1' --limit 10

echo '## 7: cntvaluein3-skew-locked-seed6 pass clocking all   7050.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f7g861zxp8kaf0sl83yfqcw47x9fmi5b-ypcb-ddr3-cvc-sdf-seed-6-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A1' --limit 10

echo '## 8: cntvaluein3-skew-locked-seed20 pass clocking all   7050.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0aqbbz7kqf99ris141aakhr98bd670y3-ypcb-ddr3-cvc-sdf-seed-20-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197617.A2' --limit 10

echo '## 9: cntvaluein3-skew-locked-seed20 pass clocking all   7034.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0aqbbz7kqf99ris141aakhr98bd670y3-ypcb-ddr3-cvc-sdf-seed-20-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198321.A1' --limit 10

echo '## 10: cntvaluein3-skew-locked-seed2 pass clocking all   7019.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/8swni5hwgvg8fzs7maxjfs5snvwaj7lp-ypcb-ddr3-cvc-sdf-seed-2-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198315.A1' --limit 10

echo '## 11: cntvaluein3-skew-locked-seed3 pass clocking all   7019.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rpm83nrx1myi4z04p7dkx968pd871g6f-ypcb-ddr3-cvc-sdf-seed-3-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A1' --limit 10

echo '## 12: cntvaluein3-skew-locked-seed3 pass clocking all   7019.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rpm83nrx1myi4z04p7dkx968pd871g6f-ypcb-ddr3-cvc-sdf-seed-3-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197617.A1' --limit 10

echo '## 13: cntvaluein3-skew-locked-seed20 pass clocking all   7019.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0aqbbz7kqf99ris141aakhr98bd670y3-ypcb-ddr3-cvc-sdf-seed-20-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A5' --limit 10

echo '## 14: cntvaluein3-skew-locked-seed23-long-poll fail clocking all   7019.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198321.A1' --limit 10

echo '## 15: cntvaluein3-skew-locked-seed20 pass clocking all   7005.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0aqbbz7kqf99ris141aakhr98bd670y3-ypcb-ddr3-cvc-sdf-seed-20-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$66.A1' --limit 10

echo '## 16: cntvaluein3-skew-locked-seed20 pass clocking all   7005.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0aqbbz7kqf99ris141aakhr98bd670y3-ypcb-ddr3-cvc-sdf-seed-20-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[0\]\[24\].A1' --limit 10

echo '## 17: cntvaluein3-skew-locked-seed16-long-poll fail clocking all   6974.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[3\]\[15\].A1' --limit 10

echo '## 18: cntvaluein3-skew-locked-seed16-long-poll fail clocking all   6974.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$66.A1' --limit 10

echo '## 19: cntvaluein3-skew-locked-seed1 pass clocking all   6960.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/xpjjqdymdp9bs6im78shp4k572ycichb-ypcb-ddr3-cvc-sdf-seed-1-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198321.A2' --limit 10

echo '## 20: cntvaluein3-skew-locked-seed12-long-poll fail clocking all   6929.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A1' --limit 10

echo '## 21: cntvaluein3-skew-locked-seed23-long-poll fail clocking all   6929.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A1' --limit 10

echo '## 22: cntvaluein3-skew-locked-seed23-long-poll fail clocking all   6929.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197617.A1' --limit 10

echo '## 23: cntvaluein3-skew-locked-seed23-long-poll fail clocking all   6929.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198315.A2' --limit 10

echo '## 24: cntvaluein3-skew-locked-seed2 pass clocking all   6914.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/8swni5hwgvg8fzs7maxjfs5snvwaj7lp-ypcb-ddr3-cvc-sdf-seed-2-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A4' --limit 10

echo '## 25: cntvaluein3-skew-locked-seed12-long-poll fail clocking all   6914.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197617.A1' --limit 10

echo '## 26: cntvaluein3-skew-locked-seed12-long-poll fail clocking all   6900.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198315.A1' --limit 10

echo '## 27: cntvaluein3-skew-locked-seed16-long-poll fail clocking all   6885.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A4' --limit 10

echo '## 28: cntvaluein3-skew-locked-seed16-long-poll fail clocking all   6885.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197617.A4' --limit 10

echo '## 29: cntvaluein3-skew-locked-seed28-long-poll fail clocking all   6855.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$66.A1' --limit 10

echo '## 30: cntvaluein3-skew-locked-seed28-long-poll fail clocking all   6855.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[2\]\[14\].A1' --limit 10

echo '## 31: cntvaluein3-skew-locked-seed5 pass clocking all   6795.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ww6bm7ifb7plxdn8jh95zw9m6s9h6lzg-ypcb-ddr3-cvc-sdf-seed-5-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198321.A1' --limit 10

echo '## 32: cntvaluein3-skew-locked-seed11 pass clocking all   6764.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/xmf3y10hqakk8zrx1xiijx087yh4iqkc-ypcb-ddr3-cvc-sdf-seed-11-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$8033.A1' --limit 10

echo '## 33: cntvaluein3-skew-locked-seed11 pass clocking all   6764.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/xmf3y10hqakk8zrx1xiijx087yh4iqkc-ypcb-ddr3-cvc-sdf-seed-11-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$66.A1' --limit 10

echo '## 34: cntvaluein3-skew-locked-seed6 pass clocking all   6735.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f7g861zxp8kaf0sl83yfqcw47x9fmi5b-ypcb-ddr3-cvc-sdf-seed-6-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$17147.A1' --limit 10

echo '## 35: cntvaluein3-skew-locked-seed6 pass clocking all   6735.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f7g861zxp8kaf0sl83yfqcw47x9fmi5b-ypcb-ddr3-cvc-sdf-seed-6-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$66.A1' --limit 10

echo '## 36: cntvaluein3-skew-locked-seed27 pass clocking all   6735.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/84nf82p90zdhqqb0cpyhl7zm4fgagr95-ypcb-ddr3-cvc-sdf-seed-27-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A5' --limit 10

echo '## 37: cntvaluein3-skew-locked-seed5 pass clocking all   6719.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ww6bm7ifb7plxdn8jh95zw9m6s9h6lzg-ypcb-ddr3-cvc-sdf-seed-5-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A2' --limit 10

echo '## 38: cntvaluein3-skew-locked-seed28-long-poll fail clocking all   6719.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197617.A1' --limit 10

echo '## 39: cntvaluein3-skew-locked-seed5 pass clocking all   6690.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ww6bm7ifb7plxdn8jh95zw9m6s9h6lzg-ypcb-ddr3-cvc-sdf-seed-5-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198315.A1' --limit 10

echo '## 40: cntvaluein3-skew-locked-seed16-long-poll fail clocking all   6690.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198315.A2' --limit 10

echo '## 41: cntvaluein3-skew-locked-seed27 pass clocking all   6690.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/84nf82p90zdhqqb0cpyhl7zm4fgagr95-ypcb-ddr3-cvc-sdf-seed-27-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198321.A5' --limit 10

echo '## 42: cntvaluein3-skew-locked-seed1 pass clocking all   6675.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/xpjjqdymdp9bs6im78shp4k572ycichb-ypcb-ddr3-cvc-sdf-seed-1-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197623.A5' --limit 10

echo '## 43: cntvaluein3-skew-locked-seed1 pass clocking all   6675.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/xpjjqdymdp9bs6im78shp4k572ycichb-ypcb-ddr3-cvc-sdf-seed-1-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197621.A4' --limit 10

echo '## 44: cntvaluein3-skew-locked-seed5 pass clocking all   6675.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ww6bm7ifb7plxdn8jh95zw9m6s9h6lzg-ypcb-ddr3-cvc-sdf-seed-5-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197617.A4' --limit 10

echo '## 45: cntvaluein3-skew-locked-seed28-long-poll fail clocking all   6675.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A2' --limit 10

echo '## 46: cntvaluein3-skew-locked-seed6 pass clocking all   6644.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f7g861zxp8kaf0sl83yfqcw47x9fmi5b-ypcb-ddr3-cvc-sdf-seed-6-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198321.A2' --limit 10

echo '## 47: cntvaluein3-skew-locked-seed23-long-poll fail clocking all   6599.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197623.A1' --limit 10

echo '## 48: cntvaluein3-skew-locked-seed23-long-poll fail clocking all   6570.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197621.A2' --limit 10

echo '## 49: cntvaluein3-skew-locked-seed12-long-poll fail clocking all   6554.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197623.A2' --limit 10

echo '## 50: cntvaluein3-skew-locked-seed12-long-poll fail clocking all   6554.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197621.A4' --limit 10

echo '## 51: cntvaluein3-skew-locked-seed20 pass clocking all   6539.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0aqbbz7kqf99ris141aakhr98bd670y3-ypcb-ddr3-cvc-sdf-seed-20-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197623.A2' --limit 10

echo '## 52: cntvaluein3-skew-locked-seed20 pass clocking all   6539.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0aqbbz7kqf99ris141aakhr98bd670y3-ypcb-ddr3-cvc-sdf-seed-20-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197621.A2' --limit 10

echo '## 53: cntvaluein3-skew-locked-seed12-long-poll fail clocking all   6525.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198323.A3' --limit 10

echo '## 54: cntvaluein3-skew-locked-seed2 pass clocking all   6510.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/8swni5hwgvg8fzs7maxjfs5snvwaj7lp-ypcb-ddr3-cvc-sdf-seed-2-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197623.A2' --limit 10

echo '## 55: cntvaluein3-skew-locked-seed2 pass clocking all   6510.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/8swni5hwgvg8fzs7maxjfs5snvwaj7lp-ypcb-ddr3-cvc-sdf-seed-2-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197621.A2' --limit 10

echo '## 56: cntvaluein3-skew-locked-seed11 pass clocking all   6510.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/xmf3y10hqakk8zrx1xiijx087yh4iqkc-ypcb-ddr3-cvc-sdf-seed-11-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197619.A2' --limit 10

echo '## 57: cntvaluein3-skew-locked-seed27 pass clocking all   6510.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/84nf82p90zdhqqb0cpyhl7zm4fgagr95-ypcb-ddr3-cvc-sdf-seed-27-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198315.A2' --limit 10

echo '## 58: cntvaluein3-skew-locked-seed6 pass clocking all   6480.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f7g861zxp8kaf0sl83yfqcw47x9fmi5b-ypcb-ddr3-cvc-sdf-seed-6-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197623.A1' --limit 10

echo '## 59: cntvaluein3-skew-locked-seed6 pass clocking all   6480.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/f7g861zxp8kaf0sl83yfqcw47x9fmi5b-ypcb-ddr3-cvc-sdf-seed-6-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197621.A1' --limit 10

echo '## 60: cntvaluein3-skew-locked-seed11 pass clocking all   6465.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/xmf3y10hqakk8zrx1xiijx087yh4iqkc-ypcb-ddr3-cvc-sdf-seed-11-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198315.A5' --limit 10

#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: baseline-no-lock-seed-25 pass clocking all   7275.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fwzl2srsag12qr6h0axl0vh80sr6m63m-ypcb-ddr3-cvc-sdf-seed-25/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A1' --limit 10

echo '## 2: baseline-no-lock-seed-25 pass clocking all   7260.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fwzl2srsag12qr6h0axl0vh80sr6m63m-ypcb-ddr3-cvc-sdf-seed-25/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198391.A3' --limit 10

echo '## 3: baseline-no-lock-seed-25 pass clocking all   7244.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fwzl2srsag12qr6h0axl0vh80sr6m63m-ypcb-ddr3-cvc-sdf-seed-25/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A1' --limit 10

echo '## 4: baseline-no-lock-seed-25 pass clocking all   7215.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fwzl2srsag12qr6h0axl0vh80sr6m63m-ypcb-ddr3-cvc-sdf-seed-25/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A1' --limit 10

echo '## 5: baseline-no-lock-seed-24 pass clocking all   7184.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/h3nm4cvnibjskwfm3ndj9119fdgbsf9z-ypcb-ddr3-cvc-sdf-seed-24/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 6: baseline-no-lock-seed-24 pass clocking all   7184.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/h3nm4cvnibjskwfm3ndj9119fdgbsf9z-ypcb-ddr3-cvc-sdf-seed-24/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$8059.A1' --limit 10

echo '## 7: baseline-no-lock-seed-28 pass clocking all   7125.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/49lbl68shk0gb11npjnlinxs50cihmd1-ypcb-ddr3-cvc-sdf-seed-28/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A2' --limit 10

echo '## 8: baseline-no-lock-seed-2 fail clocking all   7079.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0kdbg5v141vafykf1nvgb36xf0dfnwh2-ypcb-ddr3-cvc-sdf-seed-2/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A5' --limit 10

echo '## 9: baseline-no-lock-seed-11 fail clocking all   7079.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A1' --limit 10

echo '## 10: baseline-no-lock-seed-10 pass clocking all   7065.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/whmcxhihnghr30i5b7pvdnmqawly7n1q-ypcb-ddr3-cvc-sdf-seed-10/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A2' --limit 10

echo '## 11: baseline-no-lock-seed-10 pass clocking all   7065.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/whmcxhihnghr30i5b7pvdnmqawly7n1q-ypcb-ddr3-cvc-sdf-seed-10/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A2' --limit 10

echo '## 12: baseline-no-lock-seed-28 pass clocking all   7065.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/49lbl68shk0gb11npjnlinxs50cihmd1-ypcb-ddr3-cvc-sdf-seed-28/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A2' --limit 10

echo '## 13: baseline-no-lock-seed-28 pass clocking all   7065.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/49lbl68shk0gb11npjnlinxs50cihmd1-ypcb-ddr3-cvc-sdf-seed-28/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A2' --limit 10

echo '## 14: baseline-no-lock-seed-11 fail clocking all   7050.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A2' --limit 10

echo '## 15: baseline-no-lock-seed-10 pass clocking all   7034.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/whmcxhihnghr30i5b7pvdnmqawly7n1q-ypcb-ddr3-cvc-sdf-seed-10/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A1' --limit 10

echo '## 16: baseline-no-lock-seed-11 fail clocking all   7034.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A3' --limit 10

echo '## 17: baseline-no-lock-seed-25 pass clocking all   7034.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/fwzl2srsag12qr6h0axl0vh80sr6m63m-ypcb-ddr3-cvc-sdf-seed-25/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A5' --limit 10

echo '## 18: baseline-no-lock-seed-30 pass clocking all   7034.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ky5m8jgf8d4860h28aj61rgzsg4pjhm9-ypcb-ddr3-cvc-sdf-seed-30/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A5' --limit 10

echo '## 19: baseline-no-lock-seed-30 pass clocking all   7034.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ky5m8jgf8d4860h28aj61rgzsg4pjhm9-ypcb-ddr3-cvc-sdf-seed-30/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A5' --limit 10

echo '## 20: baseline-no-lock-seed-30 pass clocking all   7005.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ky5m8jgf8d4860h28aj61rgzsg4pjhm9-ypcb-ddr3-cvc-sdf-seed-30/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A5' --limit 10

echo '## 21: baseline-no-lock-seed-10 pass clocking all   6989.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/whmcxhihnghr30i5b7pvdnmqawly7n1q-ypcb-ddr3-cvc-sdf-seed-10/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A1' --limit 10

echo '## 22: baseline-no-lock-seed-17 pass clocking all   6974.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ajv6adqn9qxdj01zy3zqf87ybzwkchhq-ypcb-ddr3-cvc-sdf-seed-17/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[2\]\[3\].A1' --limit 10

echo '## 23: baseline-no-lock-seed-17 pass clocking all   6974.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ajv6adqn9qxdj01zy3zqf87ybzwkchhq-ypcb-ddr3-cvc-sdf-seed-17/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 24: baseline-no-lock-seed-29 pass clocking all   6974.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/4bmgbm0b5ksq6hbnmqhlkyhih05afb6k-ypcb-ddr3-cvc-sdf-seed-29/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 25: baseline-no-lock-seed-29 pass clocking all   6974.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/4bmgbm0b5ksq6hbnmqhlkyhih05afb6k-ypcb-ddr3-cvc-sdf-seed-29/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192602.A1' --limit 10

echo '## 26: baseline-no-lock-seed-30 pass clocking all   6974.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ky5m8jgf8d4860h28aj61rgzsg4pjhm9-ypcb-ddr3-cvc-sdf-seed-30/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197697.A2' --limit 10

echo '## 27: baseline-no-lock-seed-28 pass clocking all   6960.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/49lbl68shk0gb11npjnlinxs50cihmd1-ypcb-ddr3-cvc-sdf-seed-28/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198391.A2' --limit 10

echo '## 28: baseline-no-lock-seed-13 pass clocking all   6945.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/xc7zfwa9n7hjfg133zxdfpqd1kpw2saq-ypcb-ddr3-cvc-sdf-seed-13/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 29: baseline-no-lock-seed-13 pass clocking all   6945.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/xc7zfwa9n7hjfg133zxdfpqd1kpw2saq-ypcb-ddr3-cvc-sdf-seed-13/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[0\]\[24\].A1' --limit 10

echo '## 30: baseline-no-lock-seed-11 fail clocking all   6914.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 31: baseline-no-lock-seed-11 fail clocking all   6914.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[0\]\[23\].A1' --limit 10

echo '## 32: baseline-no-lock-seed-5 pass clocking all   6885.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/43x6xad6wl41cf947x631mziwq3a5v7i-ypcb-ddr3-cvc-sdf-seed-5/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 33: baseline-no-lock-seed-5 pass clocking all   6885.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/43x6xad6wl41cf947x631mziwq3a5v7i-ypcb-ddr3-cvc-sdf-seed-5/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$20684.A1' --limit 10

echo '## 34: baseline-no-lock-seed-11 fail clocking all   6885.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/mg86zc7l1qrgdrwys429yh168ykmw6vz-ypcb-ddr3-cvc-sdf-seed-11/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A1' --limit 10

echo '## 35: baseline-no-lock-seed-6 fail clocking all   6869.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rk60jv9g0grc00wfnry0g8dv0ldxapx7-ypcb-ddr3-cvc-sdf-seed-6/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 36: baseline-no-lock-seed-6 fail clocking all   6869.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/rk60jv9g0grc00wfnry0g8dv0ldxapx7-ypcb-ddr3-cvc-sdf-seed-6/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$8052.A1' --limit 10

echo '## 37: baseline-no-lock-seed-4 pass clocking all   6855.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/86gcag1fsaib67npy9brsfjrwnlm84gh-ypcb-ddr3-cvc-sdf-seed-4/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A5' --limit 10

echo '## 38: baseline-no-lock-seed-4 pass clocking all   6824.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/86gcag1fsaib67npy9brsfjrwnlm84gh-ypcb-ddr3-cvc-sdf-seed-4/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A2' --limit 10

echo '## 39: baseline-no-lock-seed-4 pass clocking all   6824.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/86gcag1fsaib67npy9brsfjrwnlm84gh-ypcb-ddr3-cvc-sdf-seed-4/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A2' --limit 10

echo '## 40: baseline-no-lock-seed-21 pass clocking all   6824.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/adg5jq3sd5ajb1rqh9qhjqn6wgzvvlgh-ypcb-ddr3-cvc-sdf-seed-21/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 41: baseline-no-lock-seed-21 pass clocking all   6824.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/adg5jq3sd5ajb1rqh9qhjqn6wgzvvlgh-ypcb-ddr3-cvc-sdf-seed-21/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192792.A1' --limit 10

echo '## 42: baseline-no-lock-seed-18 pass clocking all   6809.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/l25jq5nlgvzf2b55v77lhf8v553jxzc8-ypcb-ddr3-cvc-sdf-seed-18/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A2' --limit 10

echo '## 43: baseline-no-lock-seed-12 fail clocking all   6795.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/vs8bg3dvhsj7gy0djnk8h2310zm1dm69-ypcb-ddr3-cvc-sdf-seed-12/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$16876.A1' --limit 10

echo '## 44: baseline-no-lock-seed-12 fail clocking all   6795.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/vs8bg3dvhsj7gy0djnk8h2310zm1dm69-ypcb-ddr3-cvc-sdf-seed-12/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 45: baseline-no-lock-seed-19 pass clocking all   6795.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7xy6kyq2p3kcaqvhq8cizmbf668qnc63-ypcb-ddr3-cvc-sdf-seed-19/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 46: baseline-no-lock-seed-19 pass clocking all   6795.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/7xy6kyq2p3kcaqvhq8cizmbf668qnc63-ypcb-ddr3-cvc-sdf-seed-19/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$flatten\\ddr3_top_inst\.\\ddr3_controller_inst\.\$procmux\$26853_Y\[63\].A1' --limit 10

echo '## 47: baseline-no-lock-seed-2 fail clocking all   6780.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/0kdbg5v141vafykf1nvgb36xf0dfnwh2-ypcb-ddr3-cvc-sdf-seed-2/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198391.A3' --limit 10

echo '## 48: baseline-no-lock-seed-5 pass clocking all   6780.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/43x6xad6wl41cf947x631mziwq3a5v7i-ypcb-ddr3-cvc-sdf-seed-5/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198397.A3' --limit 10

echo '## 49: baseline-no-lock-seed-5 pass clocking all   6780.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/43x6xad6wl41cf947x631mziwq3a5v7i-ypcb-ddr3-cvc-sdf-seed-5/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A2' --limit 10

echo '## 50: baseline-no-lock-seed-16 fail clocking all   6780.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/ai4dzq0wdfff4sg63n36d4nw5nkxs7xg-ypcb-ddr3-cvc-sdf-seed-16/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A2' --limit 10

echo '## 51: baseline-no-lock-seed-18 pass clocking all   6780.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/l25jq5nlgvzf2b55v77lhf8v553jxzc8-ypcb-ddr3-cvc-sdf-seed-18/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A1' --limit 10

echo '## 52: baseline-no-lock-seed-24 pass clocking all   6750.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/h3nm4cvnibjskwfm3ndj9119fdgbsf9z-ypcb-ddr3-cvc-sdf-seed-24/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197695.A5' --limit 10

echo '## 53: baseline-no-lock-seed-24 pass clocking all   6750.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/h3nm4cvnibjskwfm3ndj9119fdgbsf9z-ypcb-ddr3-cvc-sdf-seed-24/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197693.A5' --limit 10

echo '## 54: baseline-no-lock-seed-28 pass clocking all   6750.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/49lbl68shk0gb11npjnlinxs50cihmd1-ypcb-ddr3-cvc-sdf-seed-28/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A2' --limit 10

echo '## 55: baseline-no-lock-seed-8 pass clocking all   6735.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/y74b7x0nj8wskq9hia9vm8703m7bsg5a-ypcb-ddr3-cvc-sdf-seed-8/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 56: baseline-no-lock-seed-8 pass clocking all   6735.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/y74b7x0nj8wskq9hia9vm8703m7bsg5a-ypcb-ddr3-cvc-sdf-seed-8/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$8052.A1' --limit 10

echo '## 57: baseline-no-lock-seed-22 pass clocking all   6735.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/139i5v6kn2w9b8rfhvv1rwdyp7p9d377-ypcb-ddr3-cvc-sdf-seed-22/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$105.A1' --limit 10

echo '## 58: baseline-no-lock-seed-22 pass clocking all   6735.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/139i5v6kn2w9b8rfhvv1rwdyp7p9d377-ypcb-ddr3-cvc-sdf-seed-22/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$20552.A1' --limit 10

echo '## 59: baseline-no-lock-seed-5 pass clocking all   6719.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/43x6xad6wl41cf947x631mziwq3a5v7i-ypcb-ddr3-cvc-sdf-seed-5/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197699.A5' --limit 10

echo '## 60: baseline-no-lock-seed-28 pass clocking all   6719.0 ps'
/nix/store/zdxzm3nbpm2dvc4xr8wk1x1fy3cadzsz-python3.11-sdf-toolkit-0.1.1/bin/sdf-toolkit rank-paths /nix/store/49lbl68shk0gb11npjnlinxs50cihmd1-ypcb-ddr3-cvc-sdf-seed-28/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$373.A1' --limit 10

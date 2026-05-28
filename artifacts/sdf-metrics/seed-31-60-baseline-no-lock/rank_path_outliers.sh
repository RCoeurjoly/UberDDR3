#!/usr/bin/env bash
set -euo pipefail

# Generated from DDR-focused SDF query results.
# Highest-delay selected endpoint records.

echo '## 1: baseline-no-lock-seed-37 fail clocking all   7335.0 ps'
sdf-toolkit rank-paths /nix/store/cbwvn8i0fc634rmr0c889a7cqr2dbvpr-ypcb-ddr3-cvc-sdf-seed-37/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 2: baseline-no-lock-seed-37 fail clocking all   7335.0 ps'
sdf-toolkit rank-paths /nix/store/cbwvn8i0fc634rmr0c889a7cqr2dbvpr-ypcb-ddr3-cvc-sdf-seed-37/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[2\]\[8\].A1' --limit 10

echo '## 3: baseline-no-lock-seed-43 pass clocking all   7215.0 ps'
sdf-toolkit rank-paths /nix/store/z88p0gi9wxvnkg5kk1p4s0mq0c55s9a2-ypcb-ddr3-cvc-sdf-seed-43/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 4: baseline-no-lock-seed-43 pass clocking all   7215.0 ps'
sdf-toolkit rank-paths /nix/store/z88p0gi9wxvnkg5kk1p4s0mq0c55s9a2-ypcb-ddr3-cvc-sdf-seed-43/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192557.A1' --limit 10

echo '## 5: baseline-no-lock-seed-34 fail clocking all   7079.0 ps'
sdf-toolkit rank-paths /nix/store/3560jfrb1q25gj4vpjl4673wnfddhyn4-ypcb-ddr3-cvc-sdf-seed-34/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A5' --limit 10

echo '## 6: baseline-no-lock-seed-42 fail clocking all   7050.0 ps'
sdf-toolkit rank-paths /nix/store/aqyx2vcnfini279smlmgii0azjg0vbm0-ypcb-ddr3-cvc-sdf-seed-42/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$19142.A1' --limit 10

echo '## 7: baseline-no-lock-seed-42 fail clocking all   7050.0 ps'
sdf-toolkit rank-paths /nix/store/aqyx2vcnfini279smlmgii0azjg0vbm0-ypcb-ddr3-cvc-sdf-seed-42/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 8: baseline-no-lock-seed-34 fail clocking all   7034.0 ps'
sdf-toolkit rank-paths /nix/store/3560jfrb1q25gj4vpjl4673wnfddhyn4-ypcb-ddr3-cvc-sdf-seed-34/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A2' --limit 10

echo '## 9: baseline-no-lock-seed-52 pass clocking all   7019.0 ps'
sdf-toolkit rank-paths /nix/store/hdh6aq2zdva2j2ci7vp9j0bd98zrg6ni-ypcb-ddr3-cvc-sdf-seed-52/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A2' --limit 10

echo '## 10: baseline-no-lock-seed-37 fail clocking all   6989.0 ps'
sdf-toolkit rank-paths /nix/store/cbwvn8i0fc634rmr0c889a7cqr2dbvpr-ypcb-ddr3-cvc-sdf-seed-37/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A1' --limit 10

echo '## 11: baseline-no-lock-seed-34 fail clocking all   6974.0 ps'
sdf-toolkit rank-paths /nix/store/3560jfrb1q25gj4vpjl4673wnfddhyn4-ypcb-ddr3-cvc-sdf-seed-34/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197683.A1' --limit 10

echo '## 12: baseline-no-lock-seed-45 fail clocking all   6945.0 ps'
sdf-toolkit rank-paths /nix/store/864wdf9zvakrp6v8yibr5v3avkp04mxq-ypcb-ddr3-cvc-sdf-seed-45/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 13: baseline-no-lock-seed-45 fail clocking all   6945.0 ps'
sdf-toolkit rank-paths /nix/store/864wdf9zvakrp6v8yibr5v3avkp04mxq-ypcb-ddr3-cvc-sdf-seed-45/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\\ddr3_top_inst\.ddr3_controller_inst\.cmd_d\[0\]\[12\].A1' --limit 10

echo '## 14: baseline-no-lock-seed-37 fail clocking all   6900.0 ps'
sdf-toolkit rank-paths /nix/store/cbwvn8i0fc634rmr0c889a7cqr2dbvpr-ypcb-ddr3-cvc-sdf-seed-37/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A3' --limit 10

echo '## 15: baseline-no-lock-seed-50 pass clocking all   6900.0 ps'
sdf-toolkit rank-paths /nix/store/2l2dr0w6h38plqrsxz65srkqwsw2aynh-ypcb-ddr3-cvc-sdf-seed-50/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A1' --limit 10

echo '## 16: baseline-no-lock-seed-46 pass clocking all   6885.0 ps'
sdf-toolkit rank-paths /nix/store/0mrjbhwdqxk2xdf7ivj5c0ks5bb16rzi-ypcb-ddr3-cvc-sdf-seed-46/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 17: baseline-no-lock-seed-46 pass clocking all   6885.0 ps'
sdf-toolkit rank-paths /nix/store/0mrjbhwdqxk2xdf7ivj5c0ks5bb16rzi-ypcb-ddr3-cvc-sdf-seed-46/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$flatten\\ddr3_top_inst\.\\ddr3_controller_inst\.\$procmux\$26853_Y\[63\].A1' --limit 10

echo '## 18: baseline-no-lock-seed-50 pass clocking all   6869.0 ps'
sdf-toolkit rank-paths /nix/store/2l2dr0w6h38plqrsxz65srkqwsw2aynh-ypcb-ddr3-cvc-sdf-seed-50/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A4' --limit 10

echo '## 19: baseline-no-lock-seed-53 pass clocking all   6869.0 ps'
sdf-toolkit rank-paths /nix/store/rc736lk3zxp4y5y68nh1h9h98x9dgi7m-ypcb-ddr3-cvc-sdf-seed-53/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A5' --limit 10

echo '## 20: baseline-no-lock-seed-50 pass clocking all   6855.0 ps'
sdf-toolkit rank-paths /nix/store/2l2dr0w6h38plqrsxz65srkqwsw2aynh-ypcb-ddr3-cvc-sdf-seed-50/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A3' --limit 10

echo '## 21: baseline-no-lock-seed-55 fail clocking all   6855.0 ps'
sdf-toolkit rank-paths /nix/store/c5igzjqqpcyjvg0knvl8vi4qvvd7qp02-ypcb-ddr3-cvc-sdf-seed-55/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A5' --limit 10

echo '## 22: baseline-no-lock-seed-41 fail clocking all   6824.0 ps'
sdf-toolkit rank-paths /nix/store/cz155878nwxac4w2ril7cggakf4y39y0-ypcb-ddr3-cvc-sdf-seed-41/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A4' --limit 10

echo '## 23: baseline-no-lock-seed-41 fail clocking all   6824.0 ps'
sdf-toolkit rank-paths /nix/store/cz155878nwxac4w2ril7cggakf4y39y0-ypcb-ddr3-cvc-sdf-seed-41/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A4' --limit 10

echo '## 24: baseline-no-lock-seed-55 fail clocking all   6824.0 ps'
sdf-toolkit rank-paths /nix/store/c5igzjqqpcyjvg0knvl8vi4qvvd7qp02-ypcb-ddr3-cvc-sdf-seed-55/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A4' --limit 10

echo '## 25: baseline-no-lock-seed-37 fail clocking all   6795.0 ps'
sdf-toolkit rank-paths /nix/store/cbwvn8i0fc634rmr0c889a7cqr2dbvpr-ypcb-ddr3-cvc-sdf-seed-37/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A1' --limit 10

echo '## 26: baseline-no-lock-seed-53 pass clocking all   6764.0 ps'
sdf-toolkit rank-paths /nix/store/rc736lk3zxp4y5y68nh1h9h98x9dgi7m-ypcb-ddr3-cvc-sdf-seed-53/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 27: baseline-no-lock-seed-53 pass clocking all   6764.0 ps'
sdf-toolkit rank-paths /nix/store/rc736lk3zxp4y5y68nh1h9h98x9dgi7m-ypcb-ddr3-cvc-sdf-seed-53/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192637.A1' --limit 10

echo '## 28: baseline-no-lock-seed-60 fail clocking all   6735.0 ps'
sdf-toolkit rank-paths /nix/store/jsk4ysb3i05y30j8xkqi3v0cpsf2vq18-ypcb-ddr3-cvc-sdf-seed-60/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$8067.A1' --limit 10

echo '## 29: baseline-no-lock-seed-60 fail clocking all   6735.0 ps'
sdf-toolkit rank-paths /nix/store/jsk4ysb3i05y30j8xkqi3v0cpsf2vq18-ypcb-ddr3-cvc-sdf-seed-60/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 30: baseline-no-lock-seed-52 pass clocking all   6704.0 ps'
sdf-toolkit rank-paths /nix/store/hdh6aq2zdva2j2ci7vp9j0bd98zrg6ni-ypcb-ddr3-cvc-sdf-seed-52/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A4' --limit 10

echo '## 31: baseline-no-lock-seed-34 fail clocking all   6690.0 ps'
sdf-toolkit rank-paths /nix/store/3560jfrb1q25gj4vpjl4673wnfddhyn4-ypcb-ddr3-cvc-sdf-seed-34/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$12478.A1' --limit 10

echo '## 32: baseline-no-lock-seed-34 fail clocking all   6690.0 ps'
sdf-toolkit rank-paths /nix/store/3560jfrb1q25gj4vpjl4673wnfddhyn4-ypcb-ddr3-cvc-sdf-seed-34/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 33: baseline-no-lock-seed-56 pass clocking all   6690.0 ps'
sdf-toolkit rank-paths /nix/store/acjyav29iy1ymafb1d6nqiv6dxslivcf-ypcb-ddr3-cvc-sdf-seed-56/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$16864.A1' --limit 10

echo '## 34: baseline-no-lock-seed-56 pass clocking all   6690.0 ps'
sdf-toolkit rank-paths /nix/store/acjyav29iy1ymafb1d6nqiv6dxslivcf-ypcb-ddr3-cvc-sdf-seed-56/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 35: baseline-no-lock-seed-43 pass clocking all   6675.0 ps'
sdf-toolkit rank-paths /nix/store/z88p0gi9wxvnkg5kk1p4s0mq0c55s9a2-ypcb-ddr3-cvc-sdf-seed-43/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A4' --limit 10

echo '## 36: baseline-no-lock-seed-47 fail clocking all   6675.0 ps'
sdf-toolkit rank-paths /nix/store/6gb58ax36ic3afaws7pms8pp0f0w3l3d-ypcb-ddr3-cvc-sdf-seed-47/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A5' --limit 10

echo '## 37: baseline-no-lock-seed-49 pass clocking all   6675.0 ps'
sdf-toolkit rank-paths /nix/store/z0bi7iq6rkisi8l95jr2mq3d9lqpbax0-ypcb-ddr3-cvc-sdf-seed-49/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 38: baseline-no-lock-seed-49 pass clocking all   6675.0 ps'
sdf-toolkit rank-paths /nix/store/z0bi7iq6rkisi8l95jr2mq3d9lqpbax0-ypcb-ddr3-cvc-sdf-seed-49/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192557.A1' --limit 10

echo '## 39: baseline-no-lock-seed-53 pass clocking all   6675.0 ps'
sdf-toolkit rank-paths /nix/store/rc736lk3zxp4y5y68nh1h9h98x9dgi7m-ypcb-ddr3-cvc-sdf-seed-53/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A5' --limit 10

echo '## 40: baseline-no-lock-seed-47 fail clocking all   6659.0 ps'
sdf-toolkit rank-paths /nix/store/6gb58ax36ic3afaws7pms8pp0f0w3l3d-ypcb-ddr3-cvc-sdf-seed-47/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A1' --limit 10

echo '## 41: baseline-no-lock-seed-53 pass clocking all   6659.0 ps'
sdf-toolkit rank-paths /nix/store/rc736lk3zxp4y5y68nh1h9h98x9dgi7m-ypcb-ddr3-cvc-sdf-seed-53/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198377.A1' --limit 10

echo '## 42: baseline-no-lock-seed-43 pass clocking all   6644.0 ps'
sdf-toolkit rank-paths /nix/store/z88p0gi9wxvnkg5kk1p4s0mq0c55s9a2-ypcb-ddr3-cvc-sdf-seed-43/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A2' --limit 10

echo '## 43: baseline-no-lock-seed-45 fail clocking all   6630.0 ps'
sdf-toolkit rank-paths /nix/store/864wdf9zvakrp6v8yibr5v3avkp04mxq-ypcb-ddr3-cvc-sdf-seed-45/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A2' --limit 10

echo '## 44: baseline-no-lock-seed-45 fail clocking all   6630.0 ps'
sdf-toolkit rank-paths /nix/store/864wdf9zvakrp6v8yibr5v3avkp04mxq-ypcb-ddr3-cvc-sdf-seed-45/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:338\:execute\$198383.A2' --limit 10

echo '## 45: baseline-no-lock-seed-51 pass clocking all   6630.0 ps'
sdf-toolkit rank-paths /nix/store/3ayr5vz4y1z2rsmqpsz676gj2kpycdyq-ypcb-ddr3-cvc-sdf-seed-51/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A1' --limit 10

echo '## 46: baseline-no-lock-seed-51 pass clocking all   6630.0 ps'
sdf-toolkit rank-paths /nix/store/3ayr5vz4y1z2rsmqpsz676gj2kpycdyq-ypcb-ddr3-cvc-sdf-seed-51/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A1' --limit 10

echo '## 47: baseline-no-lock-seed-49 pass clocking all   6614.0 ps'
sdf-toolkit rank-paths /nix/store/z0bi7iq6rkisi8l95jr2mq3d9lqpbax0-ypcb-ddr3-cvc-sdf-seed-49/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A4' --limit 10

echo '## 48: baseline-no-lock-seed-49 pass clocking all   6614.0 ps'
sdf-toolkit rank-paths /nix/store/z0bi7iq6rkisi8l95jr2mq3d9lqpbax0-ypcb-ddr3-cvc-sdf-seed-49/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A4' --limit 10

echo '## 49: baseline-no-lock-seed-34 fail clocking all   6599.0 ps'
sdf-toolkit rank-paths /nix/store/3560jfrb1q25gj4vpjl4673wnfddhyn4-ypcb-ddr3-cvc-sdf-seed-34/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$abc9_ops\.cc\:1550\:reintegrate\$192487.A3' --limit 10

echo '## 50: baseline-no-lock-seed-45 fail clocking all   6599.0 ps'
sdf-toolkit rank-paths /nix/store/864wdf9zvakrp6v8yibr5v3avkp04mxq-ypcb-ddr3-cvc-sdf-seed-45/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A2' --limit 10

echo '## 51: baseline-no-lock-seed-39 pass clocking all   6585.0 ps'
sdf-toolkit rank-paths /nix/store/9bsvw1xn90d3jbbbjl8crirfc86g4b64-ypcb-ddr3-cvc-sdf-seed-39/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$aiger192399\$20402.A1' --limit 10

echo '## 52: baseline-no-lock-seed-39 pass clocking all   6585.0 ps'
sdf-toolkit rank-paths /nix/store/9bsvw1xn90d3jbbbjl8crirfc86g4b64-ypcb-ddr3-cvc-sdf-seed-39/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.clkout2_buf.O' '\$abc\$192400\$lut\$not\$aiger192399\$74.A1' --limit 10

echo '## 53: baseline-no-lock-seed-31 fail clocking all   6554.0 ps'
sdf-toolkit rank-paths /nix/store/rn6p13ihhvjbcn4pfs9wbcv975v23q64-ypcb-ddr3-cvc-sdf-seed-31/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A2' --limit 10

echo '## 54: baseline-no-lock-seed-31 fail clocking all   6554.0 ps'
sdf-toolkit rank-paths /nix/store/rn6p13ihhvjbcn4pfs9wbcv975v23q64-ypcb-ddr3-cvc-sdf-seed-31/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A2' --limit 10

echo '## 55: baseline-no-lock-seed-39 pass clocking all   6554.0 ps'
sdf-toolkit rank-paths /nix/store/9bsvw1xn90d3jbbbjl8crirfc86g4b64-ypcb-ddr3-cvc-sdf-seed-39/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A1' --limit 10

echo '## 56: baseline-no-lock-seed-55 fail clocking all   6554.0 ps'
sdf-toolkit rank-paths /nix/store/c5igzjqqpcyjvg0knvl8vi4qvvd7qp02-ypcb-ddr3-cvc-sdf-seed-55/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197685.A4' --limit 10

echo '## 57: baseline-no-lock-seed-57 fail clocking all   6554.0 ps'
sdf-toolkit rank-paths /nix/store/27apxni2g0baf04xz784588543k6j5xn-ypcb-ddr3-cvc-sdf-seed-57/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A1' --limit 10

echo '## 58: baseline-no-lock-seed-32 fail clocking all   6525.0 ps'
sdf-toolkit rank-paths /nix/store/sdsvgyx8pf6m7fifnn98863wqrbiw4az-ypcb-ddr3-cvc-sdf-seed-32/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A1' --limit 10

echo '## 59: baseline-no-lock-seed-36 pass clocking all   6525.0 ps'
sdf-toolkit rank-paths /nix/store/b27dx3iv5dbhlfiqmw033i48972rmi00-ypcb-ddr3-cvc-sdf-seed-36/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197679.A1' --limit 10

echo '## 60: baseline-no-lock-seed-39 pass clocking all   6525.0 ps'
sdf-toolkit rank-paths /nix/store/9bsvw1xn90d3jbbbjl8crirfc86g4b64-ypcb-ddr3-cvc-sdf-seed-39/ypcb_00338_1p1_ddr3.cvc.sdf 'clk_wiz_inst\.plle2_adv_inst.LOCKED' '\$auto\$xilinx_dffopt\.cc\:335\:execute\$197681.A4' --limit 10

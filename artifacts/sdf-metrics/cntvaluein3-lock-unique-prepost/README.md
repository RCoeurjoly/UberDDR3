# UberDDR3 SDF Metrics

This report is generated from `sdf-toolkit query` output, not raw full-file SDF diffs.

## Inputs

- `cntvaluein3-skew-locked-seed1` status `pass`: `/nix/store/xpjjqdymdp9bs6im78shp4k572ycichb-ypcb-ddr3-cvc-sdf-seed-1-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed2` status `pass`: `/nix/store/8swni5hwgvg8fzs7maxjfs5snvwaj7lp-ypcb-ddr3-cvc-sdf-seed-2-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed3` status `pass`: `/nix/store/rpm83nrx1myi4z04p7dkx968pd871g6f-ypcb-ddr3-cvc-sdf-seed-3-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed5` status `pass`: `/nix/store/ww6bm7ifb7plxdn8jh95zw9m6s9h6lzg-ypcb-ddr3-cvc-sdf-seed-5-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed6` status `pass`: `/nix/store/f7g861zxp8kaf0sl83yfqcw47x9fmi5b-ypcb-ddr3-cvc-sdf-seed-6-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed11` status `pass`: `/nix/store/xmf3y10hqakk8zrx1xiijx087yh4iqkc-ypcb-ddr3-cvc-sdf-seed-11-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed12-long-poll` status `fail`: `/nix/store/7n5rpw3554b7gwybn7dny5a31yavm28w-ypcb-ddr3-cvc-sdf-seed-12-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed16-long-poll` status `fail`: `/nix/store/sya4zl6f89bcdrif52g2gm8xwnymslpr-ypcb-ddr3-cvc-sdf-seed-16-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed20` status `pass`: `/nix/store/0aqbbz7kqf99ris141aakhr98bd670y3-ypcb-ddr3-cvc-sdf-seed-20-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed23-long-poll` status `fail`: `/nix/store/n6z627lni9wgm7651pbpfg1nb0c7pzwc-ypcb-ddr3-cvc-sdf-seed-23-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed27` status `pass`: `/nix/store/84nf82p90zdhqqb0cpyhl7zm4fgagr95-ypcb-ddr3-cvc-sdf-seed-27-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed28-long-poll` status `fail`: `/nix/store/6p2hfqii4cbk0hx76xg254vhds4lyr02-ypcb-ddr3-cvc-sdf-seed-28-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `cntvaluein3-skew-locked-seed30-long-poll` status `fail`: `/nix/store/f5n5mh496vjaajj5nbdqgni64xyjqjp7-ypcb-ddr3-cvc-sdf-seed-30-cntvaluein3-skew-locked/ypcb_00338_1p1_ddr3.cvc.sdf`

## Outputs

- `query-json/`: raw first-stage `sdf-toolkit query` JSON per sample/family.
- `direct_entries.csv`: normalized DDR-relevant interconnect entries.
- `semantic_metrics.csv`: per-sample endpoint, lane, fanout, and bus-skew metrics.
- `population_summary.csv`: pass/fail/robust population comparison by semantic metric key.
- `candidate_separators.csv`: population rows with both fail and pass samples, sorted by separation.
- `candidate_fail_slower.csv`: candidates where failing seeds have higher median delay/skew than passing seeds.
- `candidate_strict_fail_slower.csv`: fail-slower candidates where every failing value is above every passing value.
- `rank_path_outliers.sh`: exact `sdf-toolkit rank-paths` commands for the highest-delay selected endpoints.
- `rank_path_fail_slower.sh`: exact `sdf-toolkit rank-paths` commands for strict fail-slower endpoint candidates.

Normalized direct entries: `42794`

## Top Fail-Slower Candidate Separators

- `direct_max` `dq_iologic` `lane0` `dq1` `ctrl=` fail-pass median `566.0` ps
- `direct_max` `dq_iologic` `lane0` `dq6` `ctrl=` fail-pass median `432.0` ps
- `direct_max` `dqs_iologic` `lane0` `dqs0` `ctrl=` fail-pass median `412.5` ps
- `lane_spread` `dqs_iologic` `lane0` `` `ctrl=` fail-pass median `412.5` ps
- `direct_max` `dq_iologic` `lane1` `dq12` `ctrl=` fail-pass median `380.5` ps
- `direct_max` `dq_iologic` `lane0` `dq3` `ctrl=` fail-pass median `377.0` ps
- `direct_max` `dq_iologic` `lane0` `dq5` `ctrl=` fail-pass median `361.5` ps
- `direct_max` `dq_iologic` `lane0` `dq2` `ctrl=` fail-pass median `334.5` ps
- `lane_spread` `dq_iologic` `lane0` `` `ctrl=` fail-pass median `333.5` ps
- `direct_max` `dq_iologic` `lane1` `dq11` `ctrl=` fail-pass median `332.5` ps
- `direct_max` `dq_iologic` `lane1` `dq8` `ctrl=` fail-pass median `317.5` ps
- `direct_max` `dqs_iologic` `lane1` `dqs1` `ctrl=` fail-pass median `299.5` ps
- `lane_spread` `dqs_iologic` `lane1` `` `ctrl=` fail-pass median `299.5` ps
- `cntvaluein_bus_skew` `idelay_data_cntvaluein` `lane1` `dq9` `ctrl=` fail-pass median `268.0` ps
- `cntvaluein_bus_skew` `idelay_data_cntvaluein` `lane1` `dq15` `ctrl=` fail-pass median `252.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq10` `ctrl=1` fail-pass median `230.5` ps
- `direct_max` `idelay_ld` `lane1` `dq13` `ctrl=` fail-pass median `224.5` ps
- `direct_max` `idelay_ld` `lane1` `dq11` `ctrl=` fail-pass median `224.0` ps
- `direct_max` `dq_iologic` `lane0` `dq0` `ctrl=` fail-pass median `216.0` ps
- `direct_max` `dq_iologic` `lane0` `dq7` `ctrl=` fail-pass median `198.5` ps

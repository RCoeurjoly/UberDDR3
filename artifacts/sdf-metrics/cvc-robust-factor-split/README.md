# UberDDR3 SDF Metrics

This report is generated from `sdf-toolkit query` output, not raw full-file SDF diffs.

## Inputs

- `seed1-fail` status `fail`: `result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed2-fail` status `fail`: `result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed3-pass` status `pass`: `result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed4-pass` status `pass`: `result-sdf-seed4-pass/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed5-pass` status `pass`: `result-sdf-seed5-pass/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed1-no-tmdriv` status `no_tmdriv`: `result-sdf-seed1-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed2-no-tmdriv` status `no_tmdriv`: `result-sdf-seed2-no-tmdriv/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed1-reset-locks-only` status `reset_locks_only`: `result-sdf-seed1-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed2-reset-locks-only` status `reset_locks_only`: `result-sdf-seed2-reset-locks-only/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed1-robust` status `robust`: `result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed2-robust` status `robust`: `result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf`

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

Normalized direct entries: `31380`

## Top Fail-Slower Candidate Separators

- `direct_max` `idelay_dqs_cntvaluein` `lane0` `dqs0` `ctrl=4` fail-pass median `742.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq14` `ctrl=3` fail-pass median `685.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq8` `ctrl=2` fail-pass median `668.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq10` `ctrl=2` fail-pass median `592.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq12` `ctrl=2` fail-pass median `514.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq4` `ctrl=3` fail-pass median `498.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq1` `ctrl=3` fail-pass median `491.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq12` `ctrl=3` fail-pass median `481.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq8` `ctrl=3` fail-pass median `481.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq14` `ctrl=2` fail-pass median `475.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq4` `ctrl=2` fail-pass median `470.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq0` `ctrl=3` fail-pass median `467.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq7` `ctrl=2` fail-pass median `456.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq1` `ctrl=2` fail-pass median `447.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq2` `ctrl=2` fail-pass median `442.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq5` `ctrl=2` fail-pass median `441.0` ps
- `direct_max` `idelay_dqs_cntvaluein` `lane0` `dqs0` `ctrl=2` fail-pass median `436.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq10` `ctrl=3` fail-pass median `435.0` ps
- `direct_max` `idelay_dqs_cntvaluein` `lane1` `dqs1` `ctrl=2` fail-pass median `414.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq6` `ctrl=2` fail-pass median `412.0` ps

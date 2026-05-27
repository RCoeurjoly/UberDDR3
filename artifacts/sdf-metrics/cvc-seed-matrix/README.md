# UberDDR3 SDF Metrics

This report is generated from `sdf-toolkit query` output, not raw full-file SDF diffs.

## Inputs

- `seed1-fail` status `fail`: `result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed2-fail` status `fail`: `result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf`
- `seed3-pass` status `pass`: `result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf`
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

Normalized direct entries: `14264`

## Top Fail-Slower Candidate Separators

- `direct_max` `idelay_dqs_cntvaluein` `lane0` `dqs0` `ctrl=4` fail-pass median `742.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq4` `ctrl=3` fail-pass median `692.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq14` `ctrl=3` fail-pass median `685.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq8` `ctrl=2` fail-pass median `668.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq1` `ctrl=3` fail-pass median `644.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq8` `ctrl=3` fail-pass median `560.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq2` `ctrl=3` fail-pass median `557.0` ps
- `direct_max` `idelay_ld` `lane0` `dq7` `ctrl=` fail-pass median `531.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq12` `ctrl=3` fail-pass median `511.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq5` `ctrl=3` fail-pass median `501.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq6` `ctrl=3` fail-pass median `495.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq7` `ctrl=3` fail-pass median `488.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq3` `ctrl=3` fail-pass median `468.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq0` `ctrl=3` fail-pass median `467.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq14` `ctrl=2` fail-pass median `456.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq5` `ctrl=4` fail-pass median `451.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq10` `ctrl=3` fail-pass median `437.0` ps
- `direct_max` `idelay_dqs_cntvaluein` `lane0` `dqs0` `ctrl=2` fail-pass median `436.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq11` `ctrl=3` fail-pass median `429.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq4` `ctrl=1` fail-pass median `424.0` ps

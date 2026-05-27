# UberDDR3 SDF Metrics

This report is generated from `sdf-toolkit query` output, not raw full-file SDF diffs.

## Inputs

- `exact-abort-seed3-baseline` status `pass`: `result-cvc-sdf-seed3-exact-abort-baseline/ypcb_00338_1p1_ddr3.cvc.sdf`
- `exact-abort-seed3-idelay-control-locked` status `pass`: `result-cvc-sdf-seed3-exact-abort-idelay-control-locked/ypcb_00338_1p1_ddr3.cvc.sdf`
- `exact-abort-seed3-idelay-control-full-locked` status `fail`: `result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/ypcb_00338_1p1_ddr3.cvc.sdf`

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

Normalized direct entries: `9852`

## Top Fail-Slower Candidate Separators

- `direct_max` `idelay_dqs_cntvaluein` `lane1` `dqs1` `ctrl=4` fail-pass median `514.0` ps
- `direct_max` `idelay_dqs_cntvaluein` `lane0` `dqs0` `ctrl=4` fail-pass median `467.0` ps
- `direct_max` `clocking` `all` `` `ctrl=` fail-pass median `464.5` ps
- `lane_spread` `clocking` `all` `` `ctrl=` fail-pass median `464.5` ps
- `direct_max` `idelay_dqs_cntvaluein` `lane0` `dqs0` `ctrl=2` fail-pass median `435.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq9` `ctrl=3` fail-pass median `408.0` ps
- `direct_max` `reset_release` `all` `` `ctrl=` fail-pass median `406.0` ps
- `lane_spread` `reset_release` `all` `` `ctrl=` fail-pass median `406.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq15` `ctrl=3` fail-pass median `397.5` ps
- `direct_max` `idelay_ld` `lane0` `dqs0` `ctrl=` fail-pass median `347.0` ps
- `direct_max` `dq_iologic` `lane0` `dq5` `ctrl=` fail-pass median `291.5` ps
- `direct_max` `dq_iologic` `lane0` `dq2` `ctrl=` fail-pass median `289.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq8` `ctrl=4` fail-pass median `271.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq5` `ctrl=3` fail-pass median `243.5` ps
- `control_fanout_spread` `idelay_data_cntvaluein` `lane1` `` `ctrl=1` fail-pass median `221.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq9` `ctrl=4` fail-pass median `214.5` ps
- `cntvaluein_bus_skew` `idelay_data_cntvaluein` `lane0` `dq2` `ctrl=` fail-pass median `197.0` ps
- `lane_spread` `idelay_ld` `lane1` `` `ctrl=` fail-pass median `196.5` ps
- `direct_max` `idelay_data_cntvaluein` `lane1` `dq15` `ctrl=4` fail-pass median `194.0` ps
- `direct_max` `idelay_data_cntvaluein` `lane0` `dq3` `ctrl=3` fail-pass median `192.0` ps

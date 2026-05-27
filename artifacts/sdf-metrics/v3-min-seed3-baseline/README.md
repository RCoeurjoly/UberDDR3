# UberDDR3 SDF Metrics

This report is generated from `sdf-toolkit query` output, not raw full-file SDF diffs.

## Inputs

- `seed3-pass` status `pass`: `result-cvc-sdf-seed3-v3-min-baseline/ypcb_00338_1p1_ddr3.cvc.sdf`

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

Normalized direct entries: `3279`

## Top Fail-Slower Candidate Separators


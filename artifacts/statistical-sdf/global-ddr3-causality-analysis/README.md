# Global UberDDR3 SDF/HIL Causality Analysis

This no-rebuild analysis joins existing HIL outcomes with existing SDF/JSON-derived feature tables.

## Inventory

- feature observations: `49628`
- comparisons ranked: `7`
- baseline seed 1..30 pass/fail check: pass `22`, fail `8`
- plot scripts/data generated: `30`
- plot PNGs rendered: `30`

Pass points are green and fail points are red in every gnuplot graph.

## Top Baseline Seed 1..30 Features

| rank | layer | direction | AUC | effect ps | feature |
|---:|---|---|---:|---:|---|
| 1 | skew | fail_higher | 0.840909 | 221.0 | `abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq14__ctrl_3__dqs_vs_dq_bit__value_ps` |
| 2 | skew | fail_higher | 0.78125 | 103.25 | `abs_ld_minus_cntvaluein_dq_median__idelay_ld_cntvaluein_skew__lane1__no_bit__ctrl_0__ld_vs_cntvaluein_dq_lane__value_ps` |
| 3 | skew | fail_lower | 0.778409 | -219.75 | `abs_dqs_minus_dq_median__idelay_cntvaluein_skew__lane1__dqs1__ctrl_4__dqs_vs_dq_lane__value_ps` |
| 4 | skew | fail_higher | 0.772727 | 164.5 | `abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq12__ctrl_3__dqs_vs_dq_bit__value_ps` |
| 5 | skew | fail_higher | 0.764205 | 229.5 | `abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq7__ctrl_3__dqs_vs_dq_bit__value_ps` |
| 6 | skew | fail_higher | 0.761364 | 245.5 | `abs_ld_minus_cntvaluein_dqs__idelay_ld_cntvaluein_skew__lane0__dqs0__ctrl_0__ld_vs_cntvaluein_dqs__value_ps` |
| 7 | skew | fail_higher | 0.761364 | 167.0 | `abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq5__ctrl_2__dqs_vs_dq_bit__value_ps` |
| 8 | skew | fail_lower | 0.755682 | -268.0 | `abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq0__ctrl_1__dqs_vs_dq_bit__value_ps` |
| 9 | direct | fail_higher | 0.75 | 305.0 | `cntvaluein_bus_skew__idelay_dqs_cntvaluein__lane0__dqs0__ctrl_none__dqs0__value_ps` |
| 10 | direct | fail_higher | 0.75 | 305.0 | `lane_spread__idelay_dqs_cntvaluein__lane0__no_bit__ctrl_none__lane__value_ps` |

## Files

- `ranked_features.csv`: all univariate feature rankings across strata.
- `cross_stratum_validation.csv`: whether seed1..30 top features repeat in seed31..60 and lock strata.
- `feature_source_inventory.csv`: existing feature tables consumed.
- `experiment_inventory.csv`: pass/fail/failure-class counts by layer/run group/variant.
- `plots/*.dat`: auditable plot data.
- `plots/*.gp`: gnuplot scripts.
- `plots/*.png`: rendered graphs when gnuplot was available.

This is hypothesis-generation evidence. A feature is not causal until a controlled intervention moves it and shifts held-out hardware outcomes.

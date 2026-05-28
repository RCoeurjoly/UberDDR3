# Global UberDDR3 SDF/HIL Causality Analysis

This no-rebuild analysis joins existing HIL outcomes with existing SDF/JSON-derived feature tables.

## Inventory

- feature observations: `49628`
- comparisons ranked: `7`
- baseline seed 1..30 pass/fail check: pass `22`, fail `8`
- index plot scripts/data generated: `30`
- index plot PNGs rendered: `30`
- distribution plot scripts/data generated: `30`
- distribution plot PNGs rendered: `30`
- focused signed-skew distribution plots generated: `30`
- focused signed-skew distribution PNGs rendered: `30`
- focused signed-skew threshold reports generated: `30`

Pass points are green and fail points are red in every gnuplot graph. Distribution plots group points by `pass`, `fail-reason-2`, `no-abort`, and `fail-other`, with median + IQR overlays. Focused signed-skew plots intentionally exclude absolute-value metrics and show only signed skew/order hypotheses. The threshold report tests one-sided signed-skew rules and reports the least-error threshold, false-pass/false-fail counts, and the largest observed failure-free interval.

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

## Signed-Skew Threshold Highlights

| errors | plot | rule | threshold ps | false fail | false pass | no-fail interval | pass pts | feature |
|---:|---|---|---:|---:|---:|---|---:|---|
| 31 | `signed_baseline_abort2_vs_pass_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane0_dq5_ctrl_0_dqs_vs_dq_` | fail_le_threshold | -85.0 | 14 | 17 | internal_gap [490.0, 903.0] | 11 | `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq5__ctrl_0__dqs_vs_dq_bit__value_ps` |
| 31 | `signed_baseline_seed_31_60_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane0_dq5_ctrl_0_dqs_vs_dq_bit_` | fail_le_threshold | -85.0 | 14 | 17 | internal_gap [490.0, 903.0] | 11 | `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq5__ctrl_0__dqs_vs_dq_bit__value_ps` |
| 31 | `signed_baseline_abort2_vs_pass_skew_signed_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_no_bit_ctrl_4_lane` | fail_ge_threshold | -202.0 | 10 | 21 | high_tail [103.0, 342.0] | 1 | `signed_lane1_minus_lane0_dqs__idelay_cntvaluein_skew__all__no_bit__ctrl_4__lane1_vs_lane0_dqs__value_ps` |
| 31 | `signed_baseline_seed_31_60_skew_signed_lane1_minus_lane0_dqs_idelay_cntvaluein_skew_all_no_bit_ctrl_4_lane1_vs` | fail_ge_threshold | -202.0 | 10 | 21 | high_tail [103.0, 342.0] | 1 | `signed_lane1_minus_lane0_dqs__idelay_cntvaluein_skew__all__no_bit__ctrl_4__lane1_vs_lane0_dqs__value_ps` |
| 34 | `signed_baseline_seed_31_60_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane0_dq3_ctrl_0_dqs_vs_dq_bit_` | fail_le_threshold | -19.0 | 17 | 17 | internal_gap [573.0, 990.0] | 13 | `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq3__ctrl_0__dqs_vs_dq_bit__value_ps` |
| 35 | `signed_baseline_seed_1_30_skew_signed_ld_minus_cntvaluein_dqs_idelay_ld_cntvaluein_skew_lane0_dqs0_ctrl_0_ld_v` | fail_le_threshold | -721.0 | 0 | 35 | internal_gap [897.0, 1149.0] | 1 | `signed_ld_minus_cntvaluein_dqs__idelay_ld_cntvaluein_skew__lane0__dqs0__ctrl_0__ld_vs_cntvaluein_dqs__value_ps` |
| 36 | `signed_baseline_seed_1_30_skew_signed_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq9_ctrl_3_dqs_vs_dq_bit_v` | fail_ge_threshold | 607.5 | 2 | 34 | internal_gap [-764.0, -299.0] | 5 | `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq9__ctrl_3__dqs_vs_dq_bit__value_ps` |
| 36 | `signed_baseline_seed_1_30_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cntvaluein_skew_lane1_dqs1_ctrl_none` | fail_ge_threshold | 211.5 | 8 | 28 | low_tail [-955.0, -642.0] | 3 | `signed_dqs_bus_skew_minus_dq_median__idelay_cntvaluein_skew__lane1__dqs1__ctrl_none__dqs_vs_dq_bus_skew__value_ps` |
| 36 | `signed_baseline_abort2_vs_pass_skew_signed_dqs_bus_skew_minus_dq_median_idelay_cntvaluein_skew_lane1_dqs1_ctrl` | fail_ge_threshold | 211.5 | 8 | 28 | low_tail [-955.0, -642.0] | 3 | `signed_dqs_bus_skew_minus_dq_median__idelay_cntvaluein_skew__lane1__dqs1__ctrl_none__dqs_vs_dq_bus_skew__value_ps` |
| 36 | `signed_baseline_seed_1_30_skew_signed_lane1_minus_lane0_dq_median_idelay_cntvaluein_skew_all_no_bit_ctrl_0_lan` | fail_ge_threshold | -65.5 | 2 | 34 | internal_gap [-724.5, -624.0] | 1 | `signed_lane1_minus_lane0_dq_median__idelay_cntvaluein_skew__all__no_bit__ctrl_0__lane1_vs_lane0_dq__value_ps` |

## Files

- `ranked_features.csv`: all univariate feature rankings across strata.
- `cross_stratum_validation.csv`: whether seed1..30 top features repeat in seed31..60 and lock strata.
- `feature_source_inventory.csv`: existing feature tables consumed.
- `experiment_inventory.csv`: pass/fail/failure-class counts by layer/run group/variant.
- `plots/*.dat`: auditable index-plot data.
- `plots/*.gp`: index gnuplot scripts.
- `plots/*.png`: rendered index graphs when gnuplot was available.
- `distribution-plots/*.dat`: auditable pass/fail distribution point data.
- `distribution-plots/*.summary.dat`: per-class median and IQR data.
- `distribution-plots/*.gp`: distribution gnuplot scripts.
- `distribution-plots/*.png`: rendered pass/fail distribution graphs.
- `signed-skew-distribution-plots/*.dat`: auditable focused signed-skew point data.
- `signed-skew-distribution-plots/*.summary.dat`: median and IQR data for focused signed-skew plots.
- `signed-skew-distribution-plots/*.gp`: focused signed-skew gnuplot scripts.
- `signed-skew-distribution-plots/*.png`: focused signed-skew/order hypothesis graphs; these exclude absolute-value metrics.
- `signed_skew_threshold_report.csv`: pass/fail ranges, largest failure-free interval, and best one-sided threshold per focused signed-skew plot.

This is hypothesis-generation evidence. A feature is not causal until a controlled intervention moves it and shifts held-out hardware outcomes.

# Multivariate DDR3 SDF/HIL Causality Analysis

This no-rebuild analysis collapses SDF-derived feature tables to one row per hardware-tested bitstream, then runs small multivariate models. It is hypothesis generation, not proof of causality.

## Inventory

- bitstream rows: `106`
- selected semantic SDF features: `72`
- logistic model rows: `3`
- logistic coefficient rows: `30`
- logistic permutation importance rows: `30`
- pairwise threshold rules evaluated: `378`
- pairwise validation rows: `250`
- pairwise scatter plots generated: `12`
- pairwise scatter PNGs rendered: `12`

## Outcome Counts

| variant | hardware_pass | experiments |
|---|---:|---:|
| baseline | True | 1 |
| baseline-no-lock | False | 24 |
| baseline-no-lock | True | 36 |
| cntvaluein3-skew-locked | False | 16 |
| cntvaluein3-skew-locked | True | 27 |
| cntvaluein_only | True | 1 |
| cntvaluein_plus_ld_parent | False | 1 |

## Logistic Models

| model | train fail/samples | test fail/samples | train AUC | test AUC | test acc |
|---|---:|---:|---:|---:|---:|
| train_baseline_1_30_test_baseline_31_60 | 8/30 | 16/30 | 0.886364 | 0.40625 | 0.4 |
| train_baseline_31_60_test_baseline_1_30 | 16/30 | 8/30 | 0.808036 | 0.375 | 0.433333 |
| train_baseline_all_test_locked_all | 24/60 | 16/43 | 0.725694 | 0.62963 | 0.55814 |

## Top Pairwise Threshold Rules

| rank | balanced acc | errors | rule | feature x | feature y |
|---:|---:|---:|---|---|---|
| 1 | 0.72364 | 33 | `x ge -441.85 and y le 73.35 => fail` | `signed_lane1_minus_lane0_dq_median__idelay_cntvaluein_skew__all__no_bit__ctrl_2__lane1_vs_lane0_dq__value_ps` | `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq13__ctrl_0__dqs_vs_dq_bit__value_ps` |
| 2 | 0.721013 | 31 | `x le 421.823913 and y le 381.917391 => fail` | `abs_ld_minus_cntvaluein_dq_median__idelay_ld_cntvaluein_skew__lane0__no_bit__ctrl_1__ld_vs_cntvaluein_dq_lane__value_ps` | `control_fanout_spread__idelay_data_cntvaluein__lane0__no_bit__ctrl_2__lane_control_bit__value_ps` |
| 3 | 0.72045 | 34 | `x ge -406.092391 and y le 589.342391 => fail` | `signed_lane1_minus_lane0_dq_median__idelay_cntvaluein_skew__all__no_bit__ctrl_2__lane1_vs_lane0_dq__value_ps` | `control_fanout_spread__idelay_data_cntvaluein__lane1__no_bit__ctrl_4__lane_control_bit__value_ps` |
| 4 | 0.71651 | 31 | `x le 381.917391 and y le 73.35 => fail` | `control_fanout_spread__idelay_data_cntvaluein__lane0__no_bit__ctrl_2__lane_control_bit__value_ps` | `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq13__ctrl_0__dqs_vs_dq_bit__value_ps` |
| 5 | 0.71576 | 27 | `x ge -441.85 and y ge 321.880435 => fail` | `signed_lane1_minus_lane0_dq_median__idelay_cntvaluein_skew__all__no_bit__ctrl_2__lane1_vs_lane0_dq__value_ps` | `abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq14__ctrl_3__dqs_vs_dq_bit__value_ps` |
| 6 | 0.714634 | 33 | `x le 73.35 and y le 589.342391 => fail` | `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq13__ctrl_0__dqs_vs_dq_bit__value_ps` | `control_fanout_spread__idelay_data_cntvaluein__lane1__no_bit__ctrl_4__lane_control_bit__value_ps` |
| 7 | 0.713884 | 29 | `x le 87.656522 or y le 201.143478 => fail` | `abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq11__ctrl_1__dqs_vs_dq_bit__value_ps` | `abs_lane1_minus_lane0_dqs__idelay_cntvaluein_skew__all__no_bit__ctrl_4__lane1_vs_lane0_dqs__value_ps` |
| 8 | 0.712758 | 35 | `x ge -406.092391 and y le 592.027174 => fail` | `signed_lane1_minus_lane0_dq_median__idelay_cntvaluein_skew__all__no_bit__ctrl_2__lane1_vs_lane0_dq__value_ps` | `dq_lane_range__idelay_cntvaluein_skew__lane1__no_bit__ctrl_4__dq_lane__value_ps` |
| 9 | 0.712008 | 31 | `x le 493.408696 or y le 201.143478 => fail` | `cntvaluein_bus_skew__idelay_data_cntvaluein__lane1__dq10__ctrl_none__dq10__value_ps` | `abs_lane1_minus_lane0_dqs__idelay_cntvaluein_skew__all__no_bit__ctrl_4__lane1_vs_lane0_dqs__value_ps` |
| 10 | 0.710131 | 33 | `x le 458.193478 and y le 388.778261 => fail` | `abs_ld_minus_cntvaluein_dq_median__idelay_ld_cntvaluein_skew__lane0__no_bit__ctrl_1__ld_vs_cntvaluein_dq_lane__value_ps` | `abs_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq12__ctrl_4__dqs_vs_dq_bit__value_ps` |

## Files

- `bitstream_feature_matrix.csv`: one row per hardware-tested bitstream with selected SDF features as columns.
- `selected_features.csv`: semantic features selected for multivariate analysis and their coverage.
- `logistic_report.csv`: regularized logistic model train/test metrics.
- `logistic_coefficients.csv`: standardized logistic coefficients for inspecting feature direction.
- `logistic_permutation_importance.csv`: test-set permutation importance for the logistic models.
- `pairwise_threshold_rules.csv`: exhaustive two-feature threshold rules ranked by balanced accuracy.
- `pairwise_rule_validation.csv`: top rule performance split by all, baseline seed groups, baseline-all, and locked-all subsets.
- `pairwise-scatter-plots/*.png`: 2D pass/fail scatter plots for top threshold-rule pairs.

Interpretation rule: a multivariate pattern is useful only if it generalizes across held-out seed groups and then survives intervention. High in-sample pairwise accuracy alone is not causal evidence.

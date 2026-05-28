# Matched Delta Causality Analysis

This analysis matches same-seed baseline bitstreams against intervention variants and compares SDF/skew/JSON physical features in delta space.

## Samples

| transition | pairs |
|---|---:|
| fail_to_pass | 18 |
| pass_to_fail | 11 |
| fail_to_fail | 6 |
| pass_to_pass | 10 |
| total | 45 |

## Outputs

- `matched_pairs.csv`: one row per same-seed baseline/intervention pair.
- `matched_feature_deltas_long.csv`: one row per pair and common feature.
- `transition_delta_summary.csv`: per-feature transition deltas.
- `failure_class_delta_summary.csv`: per-feature deltas grouped by after-failure class.
- `delta_threshold_rules.csv`: one-feature delta thresholds for fail->pass vs pass->fail.
- `root_cause_hypothesis_ledger.csv`: ranked generated hypotheses with recommended interventions.
- `delta-plots/*.png`: transition-separated delta distributions.

Hypotheses generated: `105`.

## Top Transition Delta Contrasts

| feature | layer | contrast | fail->pass median | pass->fail median |
|---|---|---:|---:|---:|
| `abs_idelayctrl_minus_reset_release__startup_relative_skew__all__no_bit__ctrl_none__idelayctrl_vs_reset__value_ps` | skew | -462.5 | -51.5 | -514.0 |
| `signed_idelayctrl_minus_reset_release__startup_relative_skew__all__no_bit__ctrl_none__idelayctrl_vs_reset__value_ps` | skew | -462.5 | -51.5 | -514.0 |
| `direct_max__idelay_data_cntvaluein__lane1__dq10__ctrl_0__endpoint__value_ps` | sdf | 459.5 | -362.5 | 97.0 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq7__ctrl_2__dqs_vs_dq_bit__value_ps` | skew | 543.5 | 8.0 | 551.5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq10__ctrl_0__dqs_vs_dq_bit__value_ps` | skew | -620.5 | 145.5 | -475.0 |
| `direct_max__dq_iologic__lane0__dq5__ctrl_none__endpoint__value_ps` | sdf | -430.5 | 305.0 | -125.5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq7__ctrl_0__dqs_vs_dq_bit__value_ps` | skew | -530.0 | 232.0 | -298.0 |
| `direct_max__dq_iologic__lane1__dq9__ctrl_none__endpoint__value_ps` | sdf | -385.5 | -166.0 | -551.5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq11__ctrl_0__dqs_vs_dq_bit__value_ps` | skew | -526.0 | 134.5 | -391.5 |
| `direct_max__idelay_data_cntvaluein__lane1__dq10__ctrl_4__endpoint__value_ps` | sdf | 383.5 | -163.0 | 220.5 |
| `signed_dqs_minus_dq_median__idelay_cntvaluein_skew__lane1__dqs1__ctrl_0__dqs_vs_dq_lane__value_ps` | skew | -552.5 | 147.75 | -404.75 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq3__ctrl_0__dqs_vs_dq_bit__value_ps` | skew | -512.5 | 285.5 | -227.0 |

Plots rendered: `16`.

Interpretation: features here are matched-pair hypotheses. They become causal only if a later intervention intentionally moves the delta and held-out hardware outcomes move with it.

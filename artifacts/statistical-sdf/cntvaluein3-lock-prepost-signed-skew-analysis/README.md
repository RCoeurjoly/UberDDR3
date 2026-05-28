# Pre/Post Signed Skew Analysis

This analysis joins `baseline-no-lock` and `cntvaluein3-skew-locked` by seed, then compares signed derived skew features for IDELAY CNTVALUEIN, IDELAY LD, and LD-vs-CNTVALUEIN timing.

The sample unit is the paired bitstream seed. Feature count does not increase the statistical sample count.

## Samples

| transition | samples |
| --- | ---: |
| fail_to_pass | 5 |
| fail_to_fail | 3 |
| pass_to_fail | 2 |
| pass_to_pass | 3 |
| total | 13 |

## Outputs

- `paired_signed_skew_long.csv`: one row per seed-pair and signed feature.
- `feature_transition_summary.csv`: per-feature medians and sign-flip counts by transition.
- `top_transition_contrasts.csv`: top features where pass-to-fail differs from fail-to-pass.
- `seed_transition_summary.csv`: aggregate sign-flip and absolute-change counts by seed.

## Top Pass-To-Fail Versus Fail-To-Pass Contrasts

| feature | pass_to_fail median delta ps | fail_to_pass median delta ps | pass_to_fail flips | fail_to_pass flips |
| --- | ---: | ---: | ---: | ---: |
| `signed_dqs_bus_skew_minus_dq_median__idelay_cntvaluein_skew__lane0__dqs0__ctrl_none__dqs_vs_dq_bus_skew__value_ps` | 608 | -358.5 | 2/2 | 3/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq13__ctrl_4__dqs_vs_dq_bit__value_ps` | -204 | 771 | 2/2 | 4/5 |
| `signed_ld_minus_cntvaluein_dqs__idelay_ld_cntvaluein_skew__lane0__dqs0__ctrl_1__ld_vs_cntvaluein_dqs__value_ps` | -1111 | -198 | 2/2 | 2/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq13__ctrl_3__dqs_vs_dq_bit__value_ps` | 459.5 | -380 | 2/2 | 2/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq15__ctrl_4__dqs_vs_dq_bit__value_ps` | -210.5 | 577 | 0/2 | 2/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq11__ctrl_4__dqs_vs_dq_bit__value_ps` | -165 | 632 | 1/2 | 4/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq11__ctrl_3__dqs_vs_dq_bit__value_ps` | 545 | -268 | 1/2 | 2/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq10__ctrl_3__dqs_vs_dq_bit__value_ps` | 561.5 | -237 | 1/2 | 3/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq9__ctrl_4__dqs_vs_dq_bit__value_ps` | -209.5 | 573 | 0/2 | 1/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq12__ctrl_3__dqs_vs_dq_bit__value_ps` | 517.5 | -232 | 2/2 | 3/5 |
| `signed_dqs_minus_dq_median__idelay_cntvaluein_skew__lane1__dqs1__ctrl_3__dqs_vs_dq_lane__value_ps` | 478.5 | -259.5 | 1/2 | 1/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq1__ctrl_3__dqs_vs_dq_bit__value_ps` | 765 | 90 | 2/2 | 1/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq14__ctrl_3__dqs_vs_dq_bit__value_ps` | 464.5 | -229 | 2/2 | 2/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq10__ctrl_1__dqs_vs_dq_bit__value_ps` | 775 | 32 | 1/2 | 2/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq8__ctrl_4__dqs_vs_dq_bit__value_ps` | -397 | 344 | 1/2 | 3/5 |
| `signed_ld_minus_cntvaluein_dq_median__idelay_ld_cntvaluein_skew__lane0__no_bit__ctrl_4__ld_vs_cntvaluein_dq_lane__value_ps` | -1097.5 | -391 | 2/2 | 4/5 |
| `signed_ld_minus_cntvaluein_dq_median__idelay_ld_cntvaluein_skew__lane1__no_bit__ctrl_4__ld_vs_cntvaluein_dq_lane__value_ps` | -519.75 | 181 | 0/2 | 1/5 |
| `signed_dqs_minus_dq_median__idelay_cntvaluein_skew__lane1__dqs1__ctrl_4__dqs_vs_dq_lane__value_ps` | -293.5 | 370 | 1/2 | 4/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq3__ctrl_3__dqs_vs_dq_bit__value_ps` | 562 | -109 | 1/2 | 2/5 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq0__ctrl_4__dqs_vs_dq_bit__value_ps` | -147.5 | 466 | 0/2 | 3/5 |

Interpretation rule: this is hypothesis refinement. A feature becomes causal only if a later intervention intentionally moves that signed timing relation and hardware pass rate moves with it.

# Pre/Post Signed Skew Analysis

This analysis joins `baseline-no-lock` and `cntvaluein3-skew-locked` by seed, then compares signed derived skew features for IDELAY CNTVALUEIN, IDELAY LD, and LD-vs-CNTVALUEIN timing.

The sample unit is the paired bitstream seed. Feature count does not increase the statistical sample count.

## Samples

| transition | samples |
| --- | ---: |
| fail_to_pass | 13 |
| fail_to_fail | 3 |
| pass_to_fail | 8 |
| pass_to_pass | 6 |
| total | 30 |

## Outputs

- `paired_signed_skew_long.csv`: one row per seed-pair and signed feature.
- `feature_transition_summary.csv`: per-feature medians and sign-flip counts by transition.
- `top_transition_contrasts.csv`: top features where pass-to-fail differs from fail-to-pass.
- `seed_transition_summary.csv`: aggregate sign-flip and absolute-change counts by seed.

## Top Pass-To-Fail Versus Fail-To-Pass Contrasts

| feature | pass_to_fail median delta ps | fail_to_pass median delta ps | pass_to_fail flips | fail_to_pass flips |
| --- | ---: | ---: | ---: | ---: |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq7__ctrl_0__dqs_vs_dq_bit__value_ps` | -576.5 | 240 | 3/8 | 6/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq7__ctrl_2__dqs_vs_dq_bit__value_ps` | 551.5 | -229 | 2/8 | 7/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq3__ctrl_0__dqs_vs_dq_bit__value_ps` | -462 | 323 | 4/8 | 8/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq1__ctrl_2__dqs_vs_dq_bit__value_ps` | 448.5 | -292 | 3/8 | 7/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq4__ctrl_2__dqs_vs_dq_bit__value_ps` | 374 | -318 | 2/8 | 7/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq5__ctrl_0__dqs_vs_dq_bit__value_ps` | -505.5 | 208 | 4/8 | 7/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq2__ctrl_0__dqs_vs_dq_bit__value_ps` | -480 | 190 | 3/8 | 3/13 |
| `signed_dqs_minus_dq_median__idelay_cntvaluein_skew__lane0__dqs0__ctrl_2__dqs_vs_dq_lane__value_ps` | 378.75 | -241 | 2/8 | 7/13 |
| `signed_dqs_minus_dq_median__idelay_cntvaluein_skew__lane1__dqs1__ctrl_0__dqs_vs_dq_lane__value_ps` | -453.25 | 161 | 2/8 | 7/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq13__ctrl_0__dqs_vs_dq_bit__value_ps` | -490.5 | 131 | 2/8 | 5/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq6__ctrl_0__dqs_vs_dq_bit__value_ps` | -488 | 134 | 3/8 | 5/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq12__ctrl_0__dqs_vs_dq_bit__value_ps` | -435 | 159 | 4/8 | 5/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq10__ctrl_0__dqs_vs_dq_bit__value_ps` | -475 | 116 | 3/8 | 3/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq2__ctrl_2__dqs_vs_dq_bit__value_ps` | 429.5 | -147 | 2/8 | 6/13 |
| `signed_dqs_minus_dq_median__idelay_cntvaluein_skew__lane0__dqs0__ctrl_0__dqs_vs_dq_lane__value_ps` | -451.25 | 135 | 3/8 | 5/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq4__ctrl_0__dqs_vs_dq_bit__value_ps` | -387.5 | 134 | 4/8 | 4/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq11__ctrl_0__dqs_vs_dq_bit__value_ps` | -396 | 126 | 3/8 | 6/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq0__ctrl_0__dqs_vs_dq_bit__value_ps` | -361.5 | 139 | 3/8 | 5/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane1__dq14__ctrl_0__dqs_vs_dq_bit__value_ps` | -328 | 159 | 4/8 | 5/13 |
| `signed_dqs_minus_dq_bit__idelay_cntvaluein_skew__lane0__dq0__ctrl_2__dqs_vs_dq_bit__value_ps` | 360.5 | -120 | 3/8 | 7/13 |

Interpretation rule: this is hypothesis refinement. A feature becomes causal only if a later intervention intentionally moves that signed timing relation and hardware pass rate moves with it.

# UberDDR3 Root-Cause Hypothesis Plots

Hypothesis visualized here: DDR3 failures are caused by combined IDELAY programming/capture margin loss: CNTVALUEIN/LD timing quality plus DQS/DQ skew plus lane-to-lane mismatch.

## Features

- DQS/DQ skew: `skew_abs_dqs_minus_dq_bit_idelay_cntvaluein_skew_lane1_dq14_ctrl_3_dqs_vs_dq_bit_value_ps`
- LD/CNTVALUEIN skew: `skew_abs_ld_minus_cntvaluein_dq_median_idelay_ld_cntvaluein_skew_lane1_no_bit_ctrl_0_ld_vs_cntvaluein_dq_lane_value_ps`
- lane mismatch: `skew_signed_lane1_minus_lane0_dq_median_idelay_cntvaluein_skew_all_no_bit_ctrl_2_lane1_vs_lane0_dq_value_ps`

## Combined Score

The combined score is `z(DQS/DQ skew) + z(LD-CNTVALUEIN skew) + z(lane mismatch)`, with signs chosen from the current strongest failure-direction hypotheses. Higher is interpreted as worse combined margin.

- pass median score: `-0.679`
- fail median score: `0.274`
- samples: `103`

## Plots

- `root_cause_raw_3factor.png`
- `root_cause_combined_score.png`
- `root_cause_score_distribution.png`

Interpretation: these plots visualize the current root-cause hypothesis. They are not causal proof; the proof requires an intervention that moves these features and changes held-out hardware outcomes.

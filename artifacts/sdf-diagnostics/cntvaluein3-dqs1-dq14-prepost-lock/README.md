# CNTVALUEIN3 Pre/Post Lock Comparison

This compares the same seed before and after the exact two-cell `CNTVALUEIN3` source-LUT BEL lock for the lane1 DQS1-vs-DQ14 `CNTVALUEIN3` SDF feature.

Positive `delta_abs_dqs1_minus_dq14_ps` means the lock made the intended SDF skew worse; negative means it improved the skew.

## Summary By Hardware Transition

| transition | rows | median baseline abs ps | median locked abs ps | median delta abs ps | improved abs count | worsened abs count | median source manhattan delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| fail_to_fail | 3 | 230.0 | 419.0 | 189.0 | 0 | 3 | -10.0 |
| fail_to_pass | 5 | 400.0 | 163.0 | -155.0 | 3 | 2 | -14.0 |
| pass_to_fail | 2 | 161.0 | 303.5 | 142.5 | 1 | 1 | -8.5 |
| pass_to_pass | 3 | 139.0 | 355.0 | 216.0 | 0 | 3 | -4.0 |

## Per-Seed Table

| seed | transition | baseline abs ps | locked abs ps | delta abs ps | baseline signed ps | locked signed ps | baseline source manhattan | locked source manhattan |
| ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | pass_to_pass | 141 | 325 | 184 | -141 | 325 | 16 | 3 |
| 2 | fail_to_pass | 707 | 163 | -544 | 707 | 163 | 21 | 3 |
| 3 | pass_to_pass | 53 | 533 | 480 | 53 | -533 | 3 | 3 |
| 5 | pass_to_pass | 139 | 355 | 216 | 139 | -355 | 7 | 3 |
| 6 | fail_to_pass | 326 | 522 | 196 | -326 | -522 | 17 | 3 |
| 11 | fail_to_pass | 301 | 146 | -155 | 301 | -146 | 9 | 3 |
| 12 | fail_to_fail | 117 | 350 | 233 | 117 | -350 | 15 | 3 |
| 16 | fail_to_fail | 480 | 508 | 28 | -480 | -508 | 3 | 3 |
| 20 | fail_to_pass | 421 | 69 | -352 | -421 | 69 | 22 | 3 |
| 23 | fail_to_fail | 230 | 419 | 189 | -230 | -419 | 13 | 3 |
| 27 | fail_to_pass | 400 | 629 | 229 | -400 | -629 | 12 | 3 |
| 28 | pass_to_fail | 179 | 538 | 359 | -179 | 538 | 9 | 3 |
| 30 | pass_to_fail | 143 | 69 | -74 | -143 | 69 | 14 | 3 |

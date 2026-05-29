# CHECK_STARTING_DATA Invalid-Phase-Escape Held-Out Gate

This directory contains one board-test JSON result and log per manifest row.

- manifest: `artifacts/hardware/check-starting-invalid-phase-escape-heldout-gate1/manifest.csv`
- poll count: `200`
- poll interval seconds: `0.1`
- rows attempted: `9`

## Result

This RTL change is a mixed result and should not be promoted to a larger sweep.
It fixes the seed5 regression from the previous CHECK_STARTING_DATA valid-window
gate, but regresses seeds 6 and 27 back into the reason-6 invalid-window class.

| seed | result | note |
| --- | --- | --- |
| 5 | pass | Fixes the SO-008 seed5 reason-6 regression. |
| 2 | pass | Historical failing baseline control remains fixed. |
| 6 | fail | Reason 6, lane0, `dq_target_index=61`, `data_start_index=8`, all-ones window. |
| 11 | pass | Historical failing baseline control remains fixed. |
| 12 | pass | Historical failing baseline control remains fixed. |
| 16 | pass | Historical failing baseline control remains fixed. |
| 20 | pass | Historical failing baseline control remains fixed. |
| 27 | fail | Reason 6, lane0, `dq_target_index=48`, `data_start_index=8`, all-ones window. |
| 3 | pass | Known-pass control remains passing. |

Conclusion: keep the valid-window-gate idea, but do not use this broad phase
escape as the general recovery policy. The next fix should be a clamped or
neutral invalid-only resample/candidate search that does not push the read target
as far as this branch did for seeds 6 and 27.

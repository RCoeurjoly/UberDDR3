# Analyze-Data Invalid-Window Recenter State Gate

This directory records the first hardware gate for RTL commit `da9e638`, which moves the ANALYZE_DATA all-ones/all-zero invalid-window recovery into an explicit bounded state.

- manifest: `artifacts/hardware/analyze-data-invalid-window-recenter-state-gate1/manifest.csv`
- matrix: `artifacts/hardware/analyze-data-invalid-window-recenter-state-gate1/matrix.csv`
- poll count: `200`
- poll interval seconds: `0.1`
- rows attempted: `3`

## Result

| seed | role | result | key signature |
| --- | --- | --- | --- |
| 27 | heldout former fail | fail | reason 6, lane0, all-ones window, start_index_check=0, dq_target_index=12, data_start_index=8 |
| 3 | known pass control | fail | regression to reason 6, lane0, all-ones window, start_index_check=0, dq_target_index=14, data_start_index=8 |
| 23 | heldout former fail control | pass | calibration and BIST pass |

Conclusion: this explicit-state recovery is not a general fix. It rescues seed23 but still fails seed27 and regresses a known-pass seed3 control, so branch-local invalid-window retries are not the right final direction unless paired with a more precise valid-window policy.

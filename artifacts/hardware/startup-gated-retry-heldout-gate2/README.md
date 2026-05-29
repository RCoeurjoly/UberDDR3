# Startup Gated Retry Held-out Hardware Sweep (Current HEAD)

- `git rev-parse` commit: `7211f66c7a2cf99f054ea077fe2ae8720ff1a602`
- Seeds: `2,3,5,6,11,12,16,20,27`
- Variant: `startup-state-gated-retry` (no lock)
- Bitstream artifacts: baseline seed builds from current commit
- Poll settings:
  - `--poll-count 300`
  - `--poll-interval 0.1`

## Result Summary

- **Pass:** 0/9
- **Fail:** 9/9

## Key failure signatures

| seed | pass | fail_reasons | abort_reason_name | state_calibrate | wrong_read_data | reset_from_calibrate_ever | reset_from_test_ever | wrong_read_seen |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2 | False | calib_incomplete,calib_state_not_done,bist_not_done | none | 19 | 0 | False | False | False |
| 3 | False | calib_incomplete,calib_state_not_done,bist_not_done | none | 19 | 0 | False | False | False |
| 5 | False | calib_incomplete,calib_state_not_done,bist_not_done | analyze_data_both_assumptions_failed | 0 | 0 | True | False | True |
| 6 | False | calib_incomplete,calib_state_not_done,bist_not_done | none | 19 | 0 | False | False | False |
| 11 | False | calib_incomplete,calib_state_not_done,bist_not_done | none | 19 | 0 | False | False | False |
| 12 | False | calib_incomplete,calib_state_not_done,bist_not_done,wrong_read_data_nonzero | none | 18 | 5121190 | False | False | True |
| 16 | False | calib_incomplete,calib_state_not_done,bist_not_done | none | 19 | 0 | False | False | False |
| 20 | False | calib_incomplete,calib_state_not_done,bist_not_done | none | 19 | 0 | False | False | False |
| 27 | False | calib_incomplete,calib_state_not_done,bist_not_done | analyze_data_both_assumptions_failed | 0 | 0 | True | False | True |

Artifacts: `manifest.csv`, `sweep_status.csv`, `matrix.csv`, `matrix.json`, and per-seed logs/JSON under this directory.

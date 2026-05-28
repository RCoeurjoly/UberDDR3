# Abort Detail Reuse Summary

Derived from the committed `baseline-seed*-abort-detail-reuse.json` HIL rows. This observer reuses the existing 64-bit `debug_calib_abort` payload and does not export a new trace bus.

| Seed | Result | Class | State | Instr | Abort | Reason | Lane | start_index | dq_target | data_start | write_late | shifted | xor | data taps L0/L1 | DQS taps | SHA12 |
| ---: | --- | --- | ---: | ---: | --- | --- | ---: | ---: | ---: | ---: | --- | --- | --- | --- | --- | --- |
| 2 | pass | pass | 23 | 22 | false | none | 0 | 0 | 0 | 0 | false | 0x00000000 | 0xd0ad51c1 | 25/26 | 2/3 | 88d9eff7db65 |
| 3 | fail | abort_reason_2 | 0 | 2 | true | check_starting_data_search_exhausted | 0 | 48 | 33 | 0 | true | 0x2c912c91 | 0xfc3c7d50 | 26/26 | 3/3 | 99a1210948c0 |
| 6 | fail | no_abort_hang | 4 | 13 | false | none | 0 | 0 | 0 | 0 | false | 0x00000000 | 0xd0ad51c1 | 23/15 | 0/24 | 3817f7c01e06 |
| 11 | fail | abort_reason_2 | 0 | 2 | true | check_starting_data_search_exhausted | 0 | 48 | 33 | 0 | true | 0x3d913d91 | 0xed3c6c50 | 23/23 | 0/0 | a1e2fd73d1a7 |
| 12 | pass | pass | 23 | 22 | false | none | 0 | 0 | 0 | 0 | false | 0x00000000 | 0xd0ad51c1 | 25/26 | 2/3 | b9280c6b5857 |

Immediate interpretation:

- Two distinct reproduced failure classes are present: explicit reason-2 CHECK_STARTING_DATA aborts and a no-abort instruction-13/state-4 calibration hang.
- The reason-2 class is consistent across seeds 3 and 11 in lane 0 with `start_index_check=48`, `dq_target_index=33`, `data_start_index=0`, and `lane_write_dq_late=true`; only the shifted read word differs.
- Seeds 2 and 12 pass under this observer, so this observer is lower perturbation than the wider trace but still changes some outcomes.
- Seed 3 was a known baseline pass but fails under this observer, so future causal claims must compare SDF/JSON for this exact observer variant separately from baseline.

# CNTVALUEIN3 lock held-out long-poll retest

Purpose: reprogram the five failed rows from `cntvaluein3-lock-heldout-seeds` with a longer board-test polling window to check whether the previous failures were short-timeout artifacts.

Test command used the same exact bitstreams with `--poll-count 500 --poll-interval 0.1`, about 50 seconds of polling after programming completes.

| Seed | Baseline status | Prior 100-poll result | 500-poll result | Attempts | Failure signature |
| ---: | --- | --- | --- | ---: | --- |
| 12 | baseline-fail-reason2 | False | False | 500 | long-poll retest still fails without abort; final state 3 instruction 13 |
| 16 | baseline-fail-startup | False | False | 500 | long-poll retest still fails with check_starting_data_search_exhausted lane 0 start_index_check=48 dq_target_index=33 |
| 23 | baseline-fail-reason2 | False | False | 500 | long-poll retest still fails with check_starting_data_search_exhausted lane 0 start_index_check=48 dq_target_index=33 |
| 28 | baseline-pass-control | False | False | 500 | long-poll retest still fails with check_starting_data_search_exhausted lane 0 start_index_check=48 dq_target_index=33 |
| 30 | baseline-pass-control | False | False | 500 | long-poll retest still fails with check_starting_data_search_exhausted lane 0 start_index_check=48 dq_target_index=33 |

Summary: all five previously failed locked rows still fail after 500 polls. The prior failures were not caused by the 100-poll timeout. Seed 12 remains a no-abort instruction-13/stalled-calibration case; seeds 16, 23, 28, and 30 remain reason-2 CHECK_STARTING_DATA exhaustion cases on lane 0.

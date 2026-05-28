# Calibration Trace Logical Matrix

Rows in this directory are hardware-in-the-loop tests for trace-instrumented DDR3 calibration builds. Each row records the exact bitstream path/hash, poll settings, decoded calibration status, abort snapshot, and compact calibration trace snapshot.

| Row | RTL variant | Seed | Lock set | Result | Notes |
| --- | --- | ---: | --- | --- | --- |
| baseline-seed2.json | trace observer baseline | 2 | none | pass | Previously failing seed2 passes after observer perturbation; no abort, trace valid=false because calibration completed. |
| baseline-seed6.json | trace observer baseline | 6 | none | pass | Previously failing seed6 passes after observer perturbation; no abort, trace valid=false because calibration completed. |
| baseline-seed11.json | trace observer baseline | 11 | none | fail | Reproduces reason-2 CHECK_STARTING_DATA lane0 failure; abort snapshot valid, but new trace payload stayed valid=false and needs persistence fix. |
| baseline-seed11-sticky-trace.json | sticky trace observer baseline | 11 | none | pass | Sticky trace payload is valid; seed11 no longer reproduces the failure after the persistence fix, so this is a perturbation/pass control. |
| baseline-seed12-sticky-trace.json | sticky trace observer baseline | 12 | none | pass | Previously failing/no-abort-class seed12 passes with valid sticky trace; observer perturbation remains too strong for failure reproduction. |
| baseline-seed11-compact-fail-snapshot.json | compact fail snapshot baseline | 11 | none | pass | Compact 128-bit failure-only snapshot is much smaller than the 320-bit trace, but seed11 still passes; no abort occurred, so fail_snapshot valid=false. |
| baseline-seed12-compact-fail-snapshot.json | compact fail snapshot baseline | 12 | none | pass | Original no-abort/instruction-13-class failing seed also passes with compact snapshot; fail_snapshot valid=false. This suggests even the reduced new payload can still perturb placement/routing enough to mask failures. |
| baseline-seed11-abort-detail-reuse.json | abort-detail reuse baseline | 11 | none | fail | Reuses existing 64-bit debug_calib_abort route, so no new JTAG payload bits are exported. Failure reproduces: reason 2 CHECK_STARTING_DATA lane0, start_index_check=48, dq_target_index=33, lane_write_dq_late=true, read_lane_data_shifted=0x3d913d91 vs expected 0xd0ad51c1. |
| baseline-seed2-abort-detail-reuse.json | abort-detail reuse baseline | 2 | none | pass | Original failing seed2 passes under abort-detail reuse; no abort snapshot, final data taps lane0=25 lane1=26, DQS taps 2/3. |
| baseline-seed6-abort-detail-reuse.json | abort-detail reuse baseline | 6 | none | fail | No-abort calibration hang bucket: calib incomplete, state_calibrate=4, instruction_address=13, abort seen=false. Final observed taps data lane0=23 lane1=15, DQS 0/24. |
| baseline-seed12-abort-detail-reuse.json | abort-detail reuse baseline | 12 | none | pass | Original failing/no-abort-class seed12 passes under abort-detail reuse; no abort snapshot, final data taps lane0=25 lane1=26, DQS taps 2/3. |
| baseline-seed3-abort-detail-reuse.json | abort-detail reuse baseline | 3 | none | fail | Known baseline pass control flips to reason-2 CHECK_STARTING_DATA lane0 failure under abort-detail reuse: start_index_check=48, dq_target_index=33, lane_write_dq_late=true, read_lane_data_shifted=0x2c912c91 vs expected 0xd0ad51c1. |
| half-step-retry-seed3.json | half-step CHECK_STARTING_DATA retry | 3 | none | pass | Fixes observer-induced reason-2 seed3 failure; no abort snapshot, final data taps lane0=24 lane1=25, DQS taps 1/2. |
| half-step-retry-seed11.json | half-step CHECK_STARTING_DATA retry | 11 | none | pass | Fixes reproduced reason-2 seed11 failure; no abort snapshot, final data taps lane0=27 lane1=26, DQS taps 4/3. |

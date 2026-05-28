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

# Calibration Trace Logical Matrix

Rows in this directory are hardware-in-the-loop tests for trace-instrumented DDR3 calibration builds. Each row records the exact bitstream path/hash, poll settings, decoded calibration status, abort snapshot, and compact calibration trace snapshot.

| Row | RTL variant | Seed | Lock set | Result | Notes |
| --- | --- | ---: | --- | --- | --- |
| baseline-seed2.json | trace observer baseline | 2 | none | pass | Previously failing seed2 passes after observer perturbation; no abort, trace valid=false because calibration completed. |
| baseline-seed6.json | trace observer baseline | 6 | none | pass | Previously failing seed6 passes after observer perturbation; no abort, trace valid=false because calibration completed. |

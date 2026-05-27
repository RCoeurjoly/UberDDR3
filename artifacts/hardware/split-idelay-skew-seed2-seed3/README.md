# Split IDELAY skew seed2/seed3 hardware results

This directory records one hardware trial for each separated intervention built from the committed `d3a8074` source tree and build-manifest commit `099ecb0`.

| Experiment | Seed | Result | Failure detail |
| --- | ---: | --- | --- |
| `idelay-stable-before-ld-seed2` | 2 | pass | none |
| `idelay-stable-before-ld-seed3` | 3 | fail | reason 2, lane 1, CHECK_STARTING_DATA exhaustion, tap mismatch |
| `cntvaluein3-skew-locked-seed2` | 2 | pass | none |
| `cntvaluein3-skew-locked-seed3` | 3 | pass | none |

The matching focused SDF/placement audit is in `artifacts/sdf-diagnostics/cntvaluein3-dqs1-dq14-split-idelay-skew-seed2-seed3/`.

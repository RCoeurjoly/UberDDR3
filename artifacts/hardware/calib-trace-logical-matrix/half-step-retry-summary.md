# Half-Step Retry Summary

This experiment adds one bounded half-step retry to `CHECK_STARTING_DATA`: after the normal `0,16,32,48` scan exhausts under the second assumption, calibration tries `8,24,40,56` before asserting `reset_from_calibrate`.

| Seed | Previous abort-detail-reuse result | Half-step retry result | Notes |
| ---: | --- | --- | --- |
| 3 | fail, reason-2 lane0, start_index=48, dq_target=33, shifted=0x2c912c91 | pass | Observer-induced reason-2 failure eliminated. |
| 11 | fail, reason-2 lane0, start_index=48, dq_target=33, shifted=0x3d913d91 | pass | Original reason-2 failure eliminated. |

Interpretation: this is strong evidence that the reason-2 class is caused by the calibration search being too coarse for marginal placements/routes. It does not address the separate no-abort instruction-13/state-4 hang class seen on seed6.

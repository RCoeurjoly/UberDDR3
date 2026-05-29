# Phased Classified Invalid-Recovery Held-Out Gate

This directory contains the HIL gate for RTL commit `16beffe`, which separates
`CHECK_STARTING_DATA` into pure classification plus explicit match,
valid-nonmatch, and invalid-sample handler states. The invalid-sample handler
uses a deterministic phased recovery sequence:

- phase 0: coarse scan at the current `dq_target_index`
- phase 1: half-step scan at the current `dq_target_index`
- phase 2: coarse scan at `dq_target_index - 2`
- terminal: abort with reason 6 if the shifted target scan still has no valid
  sample

HIL ran with poll-count `200` and poll-interval `0.1`.

- manifest: `artifacts/hardware/phased-invalid-recovery-classified-heldout-gate1/manifest.csv`
- status: `artifacts/hardware/phased-invalid-recovery-classified-heldout-gate1/sweep_status.csv`
- matrix: `artifacts/hardware/phased-invalid-recovery-classified-heldout-gate1/matrix.csv`
- rows attempted: `7`

| seed | role | result | signature |
| ---: | --- | --- | --- |
| 12 | explicit-state reason-6 shared bucket | pass | calibration and BIST complete |
| 16 | explicit-state reason-6 shared bucket | fail | reason 6, lane0, state17, instruction22, `start_index_check=0`, `dq_target_index=4`, `data_start_index=8` |
| 20 | explicit-state reason-6 shared bucket | pass | calibration and BIST complete |
| 5 | known-pass regression control | pass | calibration and BIST complete |
| 6 | SO-009 regression control | pass | calibration and BIST complete |
| 27 | SO-009 regression control | pass | calibration and BIST complete |
| 3 | known-pass control | pass | calibration and BIST complete |

Conclusion: pure classification plus phased invalid recovery is a clear
improvement over the explicit-state-only policy. It rescues seeds 12 and 20 and
keeps all controls passing. It is still not final because seed16 fails after the
phase-2 shifted-target recovery, now at `dq_target_index=4` rather than the
previous shared `dq_target_index=48` bucket.

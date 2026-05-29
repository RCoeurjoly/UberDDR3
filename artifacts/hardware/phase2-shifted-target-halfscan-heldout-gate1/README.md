# Phase-2 Shifted-Target Half-Scan Held-Out Gate

RTL commit: `f3e0093`

Variant: `phase2-shifted-target-halfscan`

Change under test: keep the pure CHECK_STARTING_DATA classifier and explicit invalid-sample state, but extend phase 2 so `dq_target_index - 2` scans both coarse indices and half-step indices before terminal abort.

HIL settings: `--poll-count 200 --poll-interval 0.1`.

| seed | role | result | signature |
| ---: | --- | --- | --- |
| 12 | prior reason-6 rescued control | pass | calibration and BIST complete |
| 16 | phase-2 target-minus-2 failure target | fail | reason 6, lane0, `dq_target_index=48`, `data_start_index=8` |
| 20 | prior reason-6 rescued control | pass | calibration and BIST complete |
| 5 | known-pass regression control | fail | reason 6, lane0, `dq_target_index=4`, `data_start_index=8` |
| 6 | SO-009 regression control | fail | reason 6, lane0, `dq_target_index=4`, `data_start_index=8`, wrong read seen |
| 27 | SO-009 regression control | pass | calibration and BIST complete |
| 3 | known-pass control | fail | reason 6, lane0, `dq_target_index=61`, `data_start_index=8` |

Conclusion: this patch is rejected as a general fix. It preserves the seed12/20 rescues and seed27 pass, but it does not fix seed16 and it regresses three controls. The useful lesson is negative: broadening phase 2 by adding half-step scans at `dq_target_index - 2` perturbs the recovery trajectory enough to create new terminal invalid-window states. The next patch should keep the pure classifier/explicit invalid state but add more precise polarity/trajectory evidence or a less perturbing candidate selector.

# Explicit Invalid-Sample State Held-Out Gate 1

This run tests RTL commit `7bd3125`, which separates invalid sample detection from invalid sample recovery in `CHECK_STARTING_DATA`:

- detection/classification remains in `CHECK_STARTING_DATA`
- policy/recovery is handled by the sibling FSM state `CHECK_STARTING_DATA_INVALID_SAMPLE`

Build/checks before HIL:

- `nix build .#checks.x86_64-linux.icarus-compile .#checks.x86_64-linux.formal-calibration-failures -L`
- `nix build --no-link --print-out-paths` for seeds `5,6,27,2,11,12,16,20,3`

HIL settings:

- poll count: `200`
- poll interval seconds: `0.1`
- rows attempted: `9`

Summary:

| seed | result | interpretation |
| --- | --- | --- |
| 5 | pass | fixes the prior SO-008 seed5 known-pass regression |
| 6 | pass | avoids the SO-009 seed6 regression |
| 27 | pass | avoids the SO-009 seed27 regression |
| 2 | pass | historical failing seed remains rescued |
| 11 | pass | historical failing seed remains rescued |
| 12 | fail | reason 6 `analyze_data_invalid_window_exhausted`, lane0, `dq_target_index=48`, `data_start_index=8` |
| 16 | fail | reason 6 `analyze_data_invalid_window_exhausted`, lane0, `dq_target_index=48`, `data_start_index=8` |
| 20 | fail | reason 6 `analyze_data_invalid_window_exhausted`, lane0, `dq_target_index=48`, `data_start_index=8` |
| 3 | pass | known-pass control remains passing |

Conclusion:

The explicit state split is the correct structure and fixes the seed5/seed6/seed27 policy conflict, but it is not yet the final fix. Seeds 12/16/20 now form a clean shared failure bucket: lane0 reason-6 invalid-window exhaustion at `dq_target_index=48`, `data_start_index=8`, followed by reset back to state 0. The next RTL change should keep the state split and refine the recovery policy for that bucket rather than adding another branch-local escape.

Artifacts:

- manifest: `manifest.csv`
- per-row HIL JSON/logs: `explicit-invalid-sample-state-heldout-seed*.json`, `*.log`
- matrix: `matrix.csv`, `matrix.json`
- sweep status: `sweep_status.csv`

# Baseline No-Lock Seed 1-30 Repeatability

Generated at: `2026-05-27T20:02:14.875953+00:00`

Purpose: check whether the baseline/no-lock hardware labels are deterministic enough to use as SDF/statistical labels. The repeat trial reprogrammed each exact same bitstream and used a longer board-test polling window: `--poll-count 300 --poll-interval 0.1`, about 30 seconds after programming.

Result over the full 30-seed matrix, comparing the original committed sweep to repeat trial 2:

- seeds compared: `30`
- pass/fail flips: `0`
- stable passes: `22`
- stable reason-2 failures: `7`
- other stable failures: `1`
- failing seeds: `2, 6, 11, 12, 16, 20, 23, 27`

Interpretation: within this same board/session, repeated reprogramming did not change any pass/fail labels. The longer poll window also did not rescue any failing seeds. The repeated reason-2 failures kept the same `start_index_check=48` and `dq_target_index=33`; seed 16 remained a no-abort early calibration failure, although its final visible state changed from 3 to 2.

A third trial was started accidentally before the stop request was processed. It completed seeds 1, 2, 3, 4, 5 and was stopped while seed 6 was in progress; those complete partial rows are preserved in `partial_trial3_status.csv` but excluded from the full-matrix repeatability conclusion.

Files:

- `repeatability_observations.csv`: trial 1 plus completed trial 2 observations.
- `repeatability_summary.csv`: per-seed stability classification.
- `repeat_trials_status.csv`: raw wrapper status from completed trial 2.
- `partial_trial3_status.csv`: completed rows from the stopped partial trial.
- `trial-02/`: raw JSON/log files for the completed repeat trial.

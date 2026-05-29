# Scalar ANALYZE_DATA Contradiction Retry Held-Out Gate 1

HIL settings: `--poll-count 200 --poll-interval 0.1`.

Rows: held-out former failing seeds 2, 6, 12, 16, 23, 27 plus known-pass controls 1 and 3.

Files:

- `manifest.csv`: bitstream inputs and roles.
- `sweep_status.csv`: board-test subprocess status per row.
- `summary.csv`: normalized HIL outcome and calibration/debug signature per row.
- `scalar-contradiction-retry-seed-*.json`: raw board-test snapshots.
- `scalar-contradiction-retry-seed-*.log`: board-test stdout logs.

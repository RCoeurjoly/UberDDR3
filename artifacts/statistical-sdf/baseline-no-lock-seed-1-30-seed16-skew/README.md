# UberDDR3 Derived Skew Features

This artifact derives signed and absolute DDR skew/composite features from an existing joined semantic SDF feature table.

- source feature table: `artifacts/statistical-sdf/baseline-no-lock-seed-1-30-seed16/features_long.csv`
- experiments: `23`
- derived feature observations: `6348`
- derived feature columns: `276`

The rows are intentionally semantic: DQS-vs-DQ, lane-vs-lane, LD-vs-CNTVALUEIN, IOLOGIC DQS-vs-DQ, clocking DQS-vs-DQ, and IDELAYCTRL-vs-reset relative timing.

# UberDDR3 Derived Skew Features

This artifact derives signed and absolute DDR skew/composite features from an existing joined semantic SDF feature table.

- source feature table: `artifacts/statistical-sdf/cntvaluein3-lock-unique-prepost/features_long.csv`
- experiments: `13`
- derived feature observations: `3588`
- derived feature columns: `276`

The rows are intentionally semantic: DQS-vs-DQ, lane-vs-lane, LD-vs-CNTVALUEIN, IOLOGIC DQS-vs-DQ, clocking DQS-vs-DQ, and IDELAYCTRL-vs-reset relative timing.

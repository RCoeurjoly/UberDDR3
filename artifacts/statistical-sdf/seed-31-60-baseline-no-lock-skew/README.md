# UberDDR3 Derived Skew Features

This artifact derives signed and absolute DDR skew/composite features from an existing joined semantic SDF feature table.

- source feature table: `artifacts/statistical-sdf/seed-31-60-baseline-no-lock/features_long.csv`
- experiments: `30`
- derived feature observations: `8280`
- derived feature columns: `276`

The rows are intentionally semantic: DQS-vs-DQ, lane-vs-lane, LD-vs-CNTVALUEIN, IOLOGIC DQS-vs-DQ, clocking DQS-vs-DQ, and IDELAYCTRL-vs-reset relative timing.

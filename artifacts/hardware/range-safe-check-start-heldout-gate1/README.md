# Range-Safe Check-Start Held-Out Gate 1

RTL commit: `2c87dbe` (`Make check-start windows range-safe`)

Board test command:

```sh
python3 scripts/uberddr3_run_board_manifest.py \
  --manifest artifacts/builds/range-safe-check-start-heldout-gate1/build_manifest.csv \
  --out-dir artifacts/hardware/range-safe-check-start-heldout-gate1 \
  --poll-count 200 \
  --poll-interval 0.1
```

Result: 4 pass, 5 fail.

Passing seeds: 3, 5, 11, 20.

Failing seeds:

- 2, 12, 16: reset-from-calibrate return to state 0 before initial calibration completes.
- 6: initial calibration completes, then BIST/read-test fails at state 17 with `wrong_read_data=1`.
- 27: calibration/test failure with state 4, `wrong_read_data=2`, and both reset-from-calibrate/test evidence.

The range-safe window cleanup did not solve the previous held-out failure set. It preserves the seed5 pass but still leaves two distinct buckets: early calibration reset and post/near-calibration wrong-read failures.

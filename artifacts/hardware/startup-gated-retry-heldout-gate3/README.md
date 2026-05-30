# Startup State Gated Retry Held-out Hardware Sweep (Post-Fix)

- `git rev-parse` commit: `b636f9ce04991bef6415836cf7edc60a3c034851`
- Seeds: `2,3,5,6,11,12,16,20,27`
- Variant: `startup-state-gated-retry` (no lock)
- Bitstream artifacts: baseline seed builds from current commit
- Poll settings:
  - `--poll-count 300`
  - `--poll-interval 0.1`

## Result Summary

- **Pass:** 9/9
- **Fail:** 0/9

## Key signature

All entries now pass calibration and BIST:
`state_calibrate = 23`, `pass=true`, `wrong_read_data = 0`.

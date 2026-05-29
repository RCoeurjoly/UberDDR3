# Calibration Startup Watchdog Gate 1

RTL commit: `883a2e6 Add calibration startup watchdog`

HIL settings: `--poll-count 200 --poll-interval 0.1`.

Seeds tested:

- `2`: historical failing seed, now passes.
- `6`: historical failing seed, now passes.
- `3`: pass control, still passes.
- `5`: pass control, fails with `analyze_data_both_assumptions_failed`.

Seed 5 failure details:

- lane `0`
- `start_index_check=8`
- `dq_target_index=36`
- `data_start_index=8`
- shifted word `0xffffffff`
- window `0x51ffffffffffffff`
- data taps `24/25`, DQS taps `1/2`

Interpretation: the watchdog did not fire. The regression is the existing ANALYZE_DATA all-ones / both-assumptions class, so the startup watchdog is useful observability for silent hangs but is not sufficient as a general RTL robustness fix.

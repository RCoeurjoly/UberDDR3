# Invalid-only recovery guard held-out gate 1

RTL source commit: `7c3a065`

Board-test command used `--poll-count 200 --poll-interval 0.1`.

| seed | result | abort reason | lane | dq_target | data_start | shifted |
| ---: | --- | --- | ---: | ---: | ---: | --- |
| 16 | pass | none | 0 | 0 | 0 | 0x00000000 |
| 5 | fail | 1 analyze_data_both_assumptions_failed | 0 | 58 | 32 | 0x3d917729 |
| 6 | fail | 6 analyze_data_invalid_window_exhausted | 1 | 48 | 8 | 0xffffffff |
| 3 | pass | none | 0 | 0 | 0 | 0x00000000 |
| 12 | fail | 6 analyze_data_invalid_window_exhausted | 0 | 63 | 8 | 0xffffffff |
| 20 | pass | none | 0 | 0 | 0 | 0x00000000 |
| 27 | pass | none | 0 | 0 | 0 | 0x00000000 |

Conclusion: this variant is not a final fix. It rescues seed16 and preserves
seeds 3, 20, and 27, but regresses seed5/6 and does not rescue seed12.

The new split is still useful: seed5 is now a reason-1 contradictory-assumption
failure, while seeds 6/12 are reason-6 all-ones invalid-window failures. The
next RTL policy should preserve pure classification and explicit invalid state,
but add deterministic transition-seeking recovery before accepting assumptions or
terminally aborting on invalid-only evidence.

# IDELAY Load Handshake Smoke Test

Tested the committed `UBERDDR3_IDELAY_LOAD_HANDSHAKE` RTL variant on YPCB seed 2.

- source commit: `ae3310e`
- bitstream attr: `.#ypcb-ddr3-bitstream-seed-2-idelay-load-handshake`
- bitstream sha256: `595a9704ca51db290c1db5108c1078a889338b53327935cbfff3465b1e8177ba`
- poll window: `500` attempts at `0.1 s` after programming
- hardware pass: `false`
- fail reasons: `calib_incomplete, calib_state_not_done, bist_not_done`
- abort reason: `2` `check_starting_data_search_exhausted`
- abort lane: `0`
- abort state: `14`
- abort instruction: `22`
- start_index_check: `48`
- lane_write_dq_late: `true`
- lane_read_dq_early: `false`
- dq_target_index: `33`
- data_start_index: `0`
- IDELAY data tap mismatch seen: `false`
- IDELAY DQS tap mismatch seen: `false`
- data CNTVALUEOUT: `[25, 25, 25, 25, 25, 25, 25, 25, 26, 26, 26, 26, 26, 26, 26, 26]`
- DQS CNTVALUEOUT: `[2, 3]`

Conclusion: the stronger PHY-side load/readback handshake did not rescue known-failing seed 2. It also did not report tap-load corruption. This moves the immediate root-cause focus away from simple CNTVALUEIN-not-stable-before-LD corruption and toward the lane-0 `CHECK_STARTING_DATA` calibration search/window failure, or toward DQ/DQS capture margin that remains after taps load correctly.

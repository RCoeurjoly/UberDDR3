# Baseline No-Lock Seed 1-30 Hardware Sweep

Generated at: `2026-05-27T19:18:36.158287+00:00`

This directory contains one board-test JSON and one log per baseline/no-lock seed. Each bitstream was programmed with `ypcb_ddr3_board_test.py`, then classified from the JTAG debug payload.

- total seeds tested: `30`
- pass: `22`
- fail: `8`
- failing seeds: `2, 6, 11, 12, 16, 20, 23, 27`
- failure final states: `{'0': 7, '3': 1}`
- failure abort reasons: `{'check_starting_data_search_exhausted': 7, 'none': 1}`
- reason-2 abort lanes: `{'1': 1, '0': 6}`

The dominant failing signature is `check_starting_data_search_exhausted`: those rows capture `abort_state=14`, `abort_instruction=22`, `abort_start_index_check=48`, `abort_dq_target_index=33`, `abort_data_start_index=0`, `abort_lane_write_dq_late=True`, and no IDELAY tap mismatch. Their final visible state is often 0 because the calibration abort reset has already fired.

Derived tables:

- `sweep_status.csv`: raw wrapper status for each subprocess run.
- `../baseline_no_lock_seed_1_30.csv`: flattened hardware rows for this sweep.
- `../ddr3_causality_matrix.csv`: canonical matrix with this run group appended.

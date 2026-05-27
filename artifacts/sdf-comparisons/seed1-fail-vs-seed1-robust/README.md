# UberDDR3 SDF Comparison

- good SDF: `result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.cvc.sdf`
- bad SDF: `result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf`
- common normalized keys: `3769`
- good-only keys: `626`
- bad-only keys: `602`

## Highest-Signal Tables

- `family_lane_metrics.csv`: per DDR family/lane max, spread, and bad-minus-good deltas.
- `largest_bad_slower_deltas.csv`: normalized paths where the bad seed is slowest relative to the good seed.
- `summary.json`: full machine-readable report, including optional placement summaries.

## Largest Bad-Slower Deltas

- 5981.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.check_test_address_counter[5]$LUT$N.A1`
- 5755.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.dqs_count_repeat[2]$LUT$N.A1`
- 5658.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.dqs_start_index_stored[1]$LUT$N.A1`
- 4927.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[20]$LUT$N.A1`
- 4905.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[10]$LUT$N.A1`
- 4876.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[14]$LUT$N.A1`
- 4876.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[15]$LUT$N.A1`
- 4795.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[21]$LUT$N.A1`
- 4778.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[19]$LUT$N.A1`
- 4636.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[22]$LUT$N.A1`
- 4623.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[67].A6`
- 4531.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.o_debug_calib_gate[7]$LUT$N.A1`
- 4531.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.o_debug_calib_gate[8]$LUT$N.A1`
- 4488.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.read_test_address_counter[16]$LUT$N.A1`
- 4455.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.read_test_address_counter[20]$LUT$N.A1`
- 4443.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[34].A6`
- 4436.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.read_test_address_counter[5]$LUT$N.A1`
- 4233.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$procmux$N_Y[4].A6`
- 4083.0 ps all other: `INTERCONNECT:$abc$$lut$not$aiger179447$N.A6`
- 4052.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[19].A6`

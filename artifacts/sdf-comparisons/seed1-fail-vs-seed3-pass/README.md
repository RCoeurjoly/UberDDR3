# UberDDR3 SDF Comparison

- good SDF: `result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf`
- bad SDF: `result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf`
- common normalized keys: `3729`
- good-only keys: `580`
- bad-only keys: `642`

## Highest-Signal Tables

- `family_lane_metrics.csv`: per DDR family/lane max, spread, and bad-minus-good deltas.
- `largest_bad_slower_deltas.csv`: normalized paths where the bad seed is slowest relative to the good seed.
- `summary.json`: full machine-readable report, including optional placement summaries.

## Largest Bad-Slower Deltas

- 5848.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.dqs_start_index_stored[1]$LUT$N.A1`
- 5789.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.dqs_start_index_stored[2]$LUT$N.A1`
- 5166.0 ps all idelay_control: `INTERCONNECT:ddr3_top_inst.idelay_data_cntvaluein[2]$LUT$N.A1`
- 4954.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[14]$LUT$N.A1`
- 4888.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[24]$LUT$N.A1`
- 4849.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[13]$LUT$N.A1`
- 4847.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_data_randomized[103]$LUT$N.A1`
- 4844.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[12]$LUT$N.A1`
- 4843.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[20]$LUT$N.A1`
- 4842.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[15]$LUT$N.A1`
- 4841.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[4]$LUT$N.A1`
- 4826.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_data_randomized[123]$LUT$N.A1`
- 4811.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[10]$LUT$N.A1`
- 4802.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[38].A6`
- 4593.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.read_test_address_counter[3]$LUT$N.A1`
- 4353.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.o_debug_calib_gate[8]$LUT$N.A1`
- 4344.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.read_test_address_counter[10]$LUT$N.A1`
- 4322.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[85].A6`
- 4233.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$procmux$N_Y[4].A6`
- 4083.0 ps all other: `INTERCONNECT:$abc$$lut$not$aiger179447$N.A6`

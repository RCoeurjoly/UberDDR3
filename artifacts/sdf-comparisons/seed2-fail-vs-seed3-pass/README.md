# UberDDR3 SDF Comparison

- good SDF: `result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf`
- bad SDF: `result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf`
- common normalized keys: `3748`
- good-only keys: `561`
- bad-only keys: `643`

## Highest-Signal Tables

- `family_lane_metrics.csv`: per DDR family/lane max, spread, and bad-minus-good deltas.
- `largest_bad_slower_deltas.csv`: normalized paths where the bad seed is slowest relative to the good seed.
- `summary.json`: full machine-readable report, including optional placement summaries.

## Largest Bad-Slower Deltas

- 12306.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.dqs_start_index[4]$LUT$N.A1`
- 11994.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.dqs_start_index_stored[5]$LUT$N.A1`
- 11969.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.dqs_start_index_stored[2]$LUT$N.A1`
- 11437.0 ps all idelay_control: `INTERCONNECT:ddr3_top_inst.idelay_data_cntvaluein[2]$LUT$N.A1`
- 10871.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[13]$LUT$N.A1`
- 10804.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[20]$LUT$N.A1`
- 10769.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[24]$LUT$N.A1`
- 10729.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[13]$LUT$N.A1`
- 10726.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_data_randomized[103]$LUT$N.A1`
- 10724.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[12]$LUT$N.A1`
- 10722.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[4]$LUT$N.A1`
- 10722.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[15]$LUT$N.A1`
- 10721.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[6]$LUT$N.A1`
- 10706.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_data_randomized[123]$LUT$N.A1`
- 10674.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[7]$LUT$N.A1`
- 10263.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.o_debug_calib_gate[8]$LUT$N.A1`
- 10164.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.read_test_address_counter[22]$LUT$N.A1`
- 8417.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$procmux$N_Y[0].A6`
- 8222.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[85].A6`
- 8207.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$procmux$N.Y[51].A6`

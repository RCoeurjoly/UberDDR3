# UberDDR3 SDF Comparison

- good SDF: `result-sdf-seed2-robust/ypcb_00338_1p1_ddr3.cvc.sdf`
- bad SDF: `result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf`
- common normalized keys: `3752`
- good-only keys: `597`
- bad-only keys: `639`

## Highest-Signal Tables

- `family_lane_metrics.csv`: per DDR family/lane max, spread, and bad-minus-good deltas.
- `largest_bad_slower_deltas.csv`: normalized paths where the bad seed is slowest relative to the good seed.
- `summary.json`: full machine-readable report, including optional placement summaries.

## Largest Bad-Slower Deltas

- 12077.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.dqs_start_index_stored[4]$LUT$N.A1`
- 12023.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.check_test_address_counter[4]$LUT$N.A1`
- 11953.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.check_test_address_counter[5]$LUT$N.A1`
- 11641.0 ps all other: `INTERCONNECT:$techmap180493$abc$$lut$aiger179447$N.A[1]$LUT$N.A3`
- 10885.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_addr[6]$LUT$N.A1`
- 10683.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[12]$LUT$N.A1`
- 10636.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.calib_data_randomized[101]$LUT$N.A3`
- 10568.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.read_test_address_counter[6]$LUT$N.A1`
- 10486.0 ps all other: `INTERCONNECT:ddr3_top_inst.ddr3_controller_inst.write_test_address_counter[14]$LUT$N.A1`
- 10346.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.o_debug_calib_gate[7]$LUT$N.A1`
- 10181.0 ps all calibration_fsm: `INTERCONNECT:ddr3_top_inst.o_debug_calib_gate[8]$LUT$N.A1`
- 8613.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$procmux$N_Y[3].A6`
- 8613.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[64].A6`
- 8417.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$procmux$N_Y[0].A6`
- 8297.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[20].A6`
- 8268.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[86].A6`
- 8207.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[5].A6`
- 8148.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[21].A6`
- 8132.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_controller_inst.$shiftx$rtl/ddr3_controller.v:0$N.buffer[103].A6`
- 8103.0 ps all other: `INTERCONNECT:$abc$$lut$flattenddr3_top_inst.ddr3_phy_inst.$ternary$rtl/ddr3_phy.v:1304$N_Y[2].A6`

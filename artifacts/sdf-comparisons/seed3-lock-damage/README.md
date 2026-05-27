# Seed3 Lock-Damage Comparison

Baseline is the known-passing seed3 build. Variants are the hardware-failing seed3 lock builds.

## cntvaluein_lock_fail

- lock cells matching expected BEL: `10/10`
- lock cells also matching baseline BEL: `10/10`

| family | dynamic SDF common | constant SDF common | median delta ps | p95 delta ps | max delta ps | >=500 ps slower | moved cells | max move |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| idelayctrl_ready | 2 | 0 | -739.5 | 0.0 | 0.0 | 0 | 0 | None |
| phy_reset_release | 0 | 0 | None | None | None | 0 | 4 | 26.0 |
| controller_reset_release | 0 | 0 | None | None | None | 0 | 0 | None |
| calib_state_release | 1 | 0 | 237.0 | 237.0 | 237.0 | 0 | 1 | 11.0 |
| idelay_programming | 108 | 36 | 122.5 | 755.0 | 824.0 | 25 | 11 | 6.0 |
| read_bist_state17 | 18 | 0 | -97.5 | 330.0 | 330.0 | 0 | 137 | 27.0 |
| dq_dqs_input | 392 | 186 | 0.0 | 534.0 | 824.0 | 25 | 0 | None |

- dynamic SDF details: `cntvaluein_lock_fail/focused_sdf_top_deltas.csv`
- constant-edge SDF details: `cntvaluein_lock_fail/focused_sdf_constant_top_deltas.csv`
- placement details: `cntvaluein_lock_fail/focused_placement_moves.csv`

## cntvaluein_ld_lock_fail

- lock cells matching expected BEL: `12/12`
- lock cells also matching baseline BEL: `12/12`

| family | dynamic SDF common | constant SDF common | median delta ps | p95 delta ps | max delta ps | >=500 ps slower | moved cells | max move |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| idelayctrl_ready | 2 | 0 | -474.5 | 0.0 | 0.0 | 0 | 0 | None |
| phy_reset_release | 0 | 0 | None | None | None | 0 | 4 | 17.0 |
| controller_reset_release | 0 | 0 | None | None | None | 0 | 0 | None |
| calib_state_release | 1 | 0 | 110.0 | 110.0 | 110.0 | 0 | 1 | 9.0 |
| idelay_programming | 108 | 36 | -209.5 | 296.0 | 464.0 | 0 | 11 | 28.0 |
| read_bist_state17 | 18 | 0 | -667.5 | -490.0 | -480.0 | 0 | 137 | 51.0 |
| dq_dqs_input | 392 | 186 | 0.0 | 25.0 | 464.0 | 0 | 0 | None |

- dynamic SDF details: `cntvaluein_ld_lock_fail/focused_sdf_top_deltas.csv`
- constant-edge SDF details: `cntvaluein_ld_lock_fail/focused_sdf_constant_top_deltas.csv`
- placement details: `cntvaluein_ld_lock_fail/focused_placement_moves.csv`

# Baseline Seed1 IDELAY Pin Coverage Diagnostic

This diagnostic uses `sdf-toolkit query` on the seed1 baseline CVC SDF with `--entry-type interconnect --pin-pattern IDELAYE2`.

Input SDF: `/nix/store/7x1d974s848wf73zrj1zdinfqji2pm0p-ypcb-ddr3-cvc-sdf-seed-1/ypcb_00338_1p1_ddr3.cvc.sdf`

Result: CE, INC, and REGRST are present in the SDF, but in this baseline design they are all driven by `PACKER_GND_DRV`. The current DDR metrics script filters constant-driver edges, which is why the dynamic `idelay_ce_inc` family produced zero entries. LD and CNTVALUEIN remain dynamic DDR-relevant query surfaces.

See `pin_coverage.csv` for counts and example pins.

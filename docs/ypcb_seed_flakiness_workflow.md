# YPCB DDR3 seed-flakiness workflow

This branch keeps seed-flakiness work scoped to reproducible builds, passive debug instrumentation, and local hardware sweep tooling. Generated bitstreams, logs, JSON results, and plots stay out of git.

## Build seeded bitstreams

Build a production bitstream for a specific seed:

```sh
nix build .#ypcb-ddr3-bitstream-seed-1
```

The flake exposes seed packages for seeds 1 through 10:

```sh
nix build .#ypcb-ddr3-bitstream-seed-10
nix build .#ypcb-ddr3-nextpnr-json-seed-10
nix build .#ypcb-ddr3-sdf-seed-10
```

The default production bitstream does not define `UBERDDR3_DEBUG_JTAG`, so the YPCB top does not instantiate the BSCAN debug path.

## Build a debug bitstream

Build the opt-in JTAG debug bitstream:

```sh
nix build .#ypcb-ddr3-bitstream-debug-jtag
```

That package synthesizes with `-DUBERDDR3_DEBUG_JTAG`. The debug payload currently reports reset/clock state, calibration complete, BIST done, controller `debug1`, a magic/version word, and BIST correct/wrong read counters.

## Poll one bitstream on hardware

```sh
example_demo/ypcb_00338_1p1/scripts/ypcb_ddr3_board_test.py \
  --bitstream result/ypcb_00338_1p1_ddr3_openxc7.bit \
  --output local-artifacts/board-tests/seed-1.json
```

The script programs the board with `openFPGALoader`, reads the USER1 JTAG payload, and fails on programming failure, bad payload magic/version, clock unlock, incomplete calibration, non-terminal calibration state, incomplete BIST, or nonzero wrong-read count.

## Run a manifest sweep

Create a local CSV with these columns:

```csv
experiment_id,seed,variant,bitstream_file
seed-1,1,debug,result-seed-1/ypcb_00338_1p1_ddr3_openxc7.bit
```

Run the sweep:

```sh
scripts/uberddr3_run_board_manifest.py \
  --manifest local-artifacts/manifests/seeds-1-10.csv \
  --out-dir local-artifacts/board-sweeps/seeds-1-10
```

The runner aborts on the first failing row by default. Use `--continue-on-fail` only when intentionally collecting a full failure matrix.

## Checks

`nix flake check` is intended for lightweight RTL quality gates: Icarus elaboration, existing formal targets, and Verilator lint. Hardware bitstream builds are exposed as packages and are not part of the default check set.

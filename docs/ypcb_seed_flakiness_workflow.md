# YPCB DDR3 seed-flakiness workflow

This branch keeps seed-flakiness work scoped to reproducible builds, passive debug instrumentation, and local hardware sweep tooling. Generated bitstreams, logs, JSON results, and plots stay out of git.

The fixed target is the standalone YPCB DDR3 design at 2 byte lanes and 333 MHz DDR3 clock. Do not expand width or frequency while closing the seed-dependent failures.

## Build seeded bitstreams

Build a debug bitstream for a specific seed:

```sh
nix build .#ypcb-ddr3-bitstream-seed-1
```

The seed packages named `ypcb-ddr3-bitstream-seed-N` synthesize with `-DUBERDDR3_DEBUG_JTAG` and currently include calibration, init/reset, and BIST first-failure payloads. They are intentionally useful for hardware diagnosis, but they perturb placement.

The flake exposes debug seed packages for seeds 1 through 60:

```sh
nix build .#ypcb-ddr3-bitstream-seed-60
nix build .#ypcb-ddr3-nextpnr-json-seed-60
nix build .#ypcb-ddr3-sdf-seed-60
```

Build a production bitstream for a specific seed:

```sh
nix build .#ypcb-ddr3-bitstream-prod-seed-1
```

Production seed packages do not define `UBERDDR3_DEBUG_JTAG`, so the YPCB top does not instantiate the BSCAN debug path. Use these only after a candidate passes the debug-stage hardware gate.

## Build a debug bitstream

Build the opt-in JTAG debug bitstream:

```sh
nix build .#ypcb-ddr3-bitstream-debug-jtag
```

That package synthesizes with `-DUBERDDR3_DEBUG_JTAG`. The debug payload currently reports reset/clock state, calibration complete, BIST done, controller `debug1`, a magic/version word, BIST correct/wrong read counters, calibration internals, init sequencing, reset-path fields, and the first BIST mismatch.

## Poll one bitstream on hardware

```sh
example_demo/ypcb_00338_1p1/scripts/ypcb_ddr3_board_test.py \
  --bitstream result/ypcb_00338_1p1_ddr3_openxc7.bit \
  --output local-artifacts/board-tests/seed-1.json
```

The script programs the board with `openFPGALoader`, reads the USER1 JTAG payload, and fails on programming failure, bad payload magic/version, clock unlock, incomplete calibration, non-terminal calibration state, incomplete BIST, or nonzero wrong-read count.

## Run a manifest sweep

Use the Nix-generated stage manifests when possible:

```sh
nix build .#ypcb-ddr3-board-manifest-debug-stage1 -o result-manifest-debug-stage1
nix build .#ypcb-ddr3-board-manifest-debug-heldout -o result-manifest-debug-heldout
```

Or create a local CSV with these columns:

```csv
experiment_id,seed,repeat,variant,bitstream_file
debug-calib-bist-seed-1-repeat-1,1,1,debug-calib-bist,result-seed-1/ypcb_00338_1p1_ddr3_openxc7.bit
```

Run the sweep:

```sh
scripts/uberddr3_run_board_manifest.py \
  --manifest result-manifest-debug-stage1 \
  --out-dir local-artifacts/board-sweeps/debug-stage1 \
  --poll-count 200
```

The runner aborts on the first failing row by default. Use `--continue-on-fail` only when intentionally collecting a full failure matrix. The generated `sweep_status.csv` records the bitstream hash, failure class, fail reasons, attempts, state, and BIST counters.

## Promotion gate

A candidate change is not stable until it passes:

1. debug stage 1: seeds 1 through 30, 3 reprograms each, `--poll-count 200`
2. debug held-out: seeds 31 through 60, 1 reprogram each, `--poll-count 200`
3. production build matrix: build production seeds 1 through 60 with debug disabled
4. integration soak in `~/LLM2FPGA`

The current JTAG board-test runner requires the debug BSCAN payload, so it cannot validate true production bitstreams directly. Direct production hardware validation needs either a separate system-level checker or a future low-perturbation status-only debug variant.

Treat every observability change as a new RTL/debug variant. Do not compare pass/fail results across variants as if they were the same design.

## Checks

`nix flake check` is intended for lightweight RTL quality gates: Icarus elaboration, existing formal targets, and Verilator lint. Hardware bitstream builds are exposed as packages and are not part of the default check set.

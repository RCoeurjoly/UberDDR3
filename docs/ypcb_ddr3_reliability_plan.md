# YPCB DDR3 reliability plan

## Goal

Make the standalone YPCB DDR3 driver consistently pass at the fixed low target: 2 byte lanes and 333 MHz DDR3 clock. Do not expand width, frequency, or integration scope until this target is stable.

## Working rules

- Use `ypcb-seed-infra-clean` as the clean implementation branch.
- Use `ypcb-fixes` only as reference material for prior evidence and candidate fixes.
- Keep generated bitstreams, board logs, JSON poll traces, and plots out of git.
- Commit experiment definitions before interpreting results.
- Treat each debug payload as a separate design variant because instrumentation changes placement and can change pass/fail behavior.

## Variants

- `prod`: no `UBERDDR3_DEBUG_JTAG`; intended production bitstream.
- `debug-calib-bist`: current BSCAN payload with calibration, init/reset, and BIST first-failure observability.
- `debug-min`: desired later low-perturbation status-only payload; not implemented yet.

## Hardware gate

Promotion requires the staged gate:

- debug stage 1: seeds 1 through 30, 3 reprograms each
- debug held-out: seeds 31 through 60, 1 reprogram each
- production build matrix: build seeds 1 through 60 with debug disabled
- LLM2FPGA integration soak

Use `--poll-count 200` for debug hardware sweeps unless explicitly recording a different experiment. The current board-test runner requires BSCAN debug and cannot directly validate true production bitstreams.

## Fix strategy

Port logical calibration fixes from `ypcb-fixes` only when the current hardware signature matches the old evidence. Start with small changes around invalid ANALYZE/read-window classification, bounded invalid-window retry, and CHECK_STARTING_DATA range safety.

Keep physical mitigation separate. Evaluate `--no-tmdriv`, small IDELAY/control placement constraints, and reset/IDELAYCTRL locks as independent experiment variants. Do not combine physical constraints with logical recovery until each has its own hardware matrix.

Use SDF and statistical scripts as hypothesis generators, not as signoff. Prioritize IDELAY `CNTVALUEIN`, `LD`, control fanout, DQS/DQ skew, and reset/IDELAYCTRL release paths, but promote only changes that improve the hardware gate.

## Commands

Build the debug stage-1 manifest:

```sh
nix build .#ypcb-ddr3-board-manifest-debug-stage1 -o result-manifest-debug-stage1
```

Run the debug stage-1 sweep:

```sh
scripts/uberddr3_run_board_manifest.py \
  --manifest result-manifest-debug-stage1 \
  --out-dir local-artifacts/board-sweeps/debug-stage1 \
  --poll-count 200
```

Continue after failures only for matrix collection:

```sh
scripts/uberddr3_run_board_manifest.py \
  --manifest result-manifest-debug-stage1 \
  --out-dir local-artifacts/board-sweeps/debug-stage1-full \
  --poll-count 200 \
  --continue-on-fail
```

Inspect `sweep_status.csv` first. It records bitstream hash, failure class, fail reasons, attempts, calibration state, and BIST counters.

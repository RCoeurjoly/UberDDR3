# YPCB DDR3 reliability plan

## Goal

Keep the standalone YPCB DDR3 driver fixed on the proven LLM2FPGA baseline: 15 row bits, 10 column bits, 3 bank bits, 1 byte lane, 4-bit AUX, BIST mode 2, no datamask BIST, no ECC, no second Wishbone, 83.333 MHz controller clock, 333 MHz DDR3 clock, and nextpnr `--freq 100`. Defer wider UberDDR3 exploration until LLM2FPGA rowstream/readback/inference passes on this profile.

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
- debug held-out: seeds 31 through 60, 3 reprograms each
- production build matrix: build seeds 1 through 60 with debug disabled
- LLM2FPGA packed full-beat rowstream write/read, followed by inference selftest

Do not use byte-mask or low-byte rowstream validation as acceptance gates on YPCB; the board has no byte mask routed.

Use `--poll-count 200` for debug hardware sweeps unless explicitly recording a different experiment. The current board-test runner requires BSCAN debug and cannot directly validate true production bitstreams.

## Fix strategy

Port logical calibration fixes from `ypcb-fixes` only when the current hardware signature matches the old evidence. Start with small changes around invalid ANALYZE/read-window classification, bounded invalid-window retry, and CHECK_STARTING_DATA range safety.

Keep physical mitigation separate. Evaluate `--no-tmdriv`, small IDELAY/control placement constraints, and reset/IDELAYCTRL locks as independent experiment variants. Do not combine physical constraints with logical recovery until each has its own hardware matrix.

Use SDF and statistical scripts as hypothesis generators, not as signoff. Prioritize IDELAY `CNTVALUEIN`, `LD`, control fanout, DQS/DQ skew, and reset/IDELAYCTRL release paths, but promote only changes that improve the hardware gate.

## Commands

Build the generic debug stage-1 manifest:

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

Build the LLM2FPGA 1-lane stage-1 package manifest:

```sh
nix build .#ypcb-ddr3-board-package-manifest-llm2fpga-min-bist2-stage1 -o result-manifest-llm2fpga-min-bist2-stage1
```

Run it progressively, stopping on the first failure:

```sh
scripts/uberddr3_run_seed_gate.py \
  --package-template '.#ypcb-ddr3-bitstream-llm2fpga-min-bist2-seed-{seed}' \
  --variant llm2fpga-min-bist2 \
  --seeds 1-30 \
  --repeats 3 \
  --byte-lanes 1 \
  --poll-count 200 \
  --out-dir local-artifacts/board-sweeps/llm2fpga-min-bist2-stage1
```

Run the held-out 1-lane gate after stage 1 passes:

```sh
scripts/uberddr3_run_seed_gate.py \
  --package-template '.#ypcb-ddr3-bitstream-llm2fpga-min-bist2-seed-{seed}' \
  --variant llm2fpga-min-bist2 \
  --seeds 31-60 \
  --repeats 3 \
  --byte-lanes 1 \
  --poll-count 200 \
  --out-dir local-artifacts/board-sweeps/llm2fpga-min-bist2-heldout
```

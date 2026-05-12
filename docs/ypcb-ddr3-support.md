# YPCB DDR3 support

This repo now contains two YPCB DDR3 targets:

- `.#ypcb-uberddr3-bist-bitstream`: default diagnostic target, routed with seed 16.
- `.#ypcb-ddr3-selftest-bitstream`: original 16-bit selftest target.

The diagnostic target is based on the Task6 v23 YPCB/UberDDR3 bring-up path. It
uses channel 0, a 64-bit DDR3 data bus, no DM pins, direct BSCANE2 JTAG status,
and a USER2 JTAG command register for same-bitstream byte-pattern reruns.

## Build and program

Build the default diagnostic bitstream:

```sh
nix build .#ypcb-uberddr3-bist-bitstream --print-out-paths -L
```

Program with the full store path:

```sh
openFPGALoader -c digilent_hs3 --ftdi-serial 210299BF3824 /nix/store/...-ypcb-uberddr3-bist-seed16.bit
```

Run the scripted board/JTAG flow:

```sh
python3 scripts/task6/task6_ddr3_experiment_runner.py \
  --label ypcb-uberddr3-v23-a5 \
  --variant v23-seed16-auto-a5
```

Run a same-bitstream byte-pattern probe:

```sh
python3 scripts/task6/task6_ddr3_experiment_runner.py \
  --label ypcb-uberddr3-v23-ff \
  --variant v23-seed16-command-ff \
  --command-byte 0xff
```

## JTAG payload

The diagnostic target reports:

- calibration status and cycle.
- controller debug state.
- Wishbone ACK/error/stall counters.
- active command byte and command/run counters.
- low read word.
- full 512-bit returned read beat.
- command/integrity status.

Decoded run results are appended to:

```text
artifacts/task6/ddr3-run-results.jsonl
```

## Current status

The imported Task6 evidence showed calibration and command liveness on the seed
16 route, but full data integrity was not yet passing. The current diagnostic
target is intended to classify the remaining byte-lane/packing/timing issue
without requiring LED reads or a new routed bitstream per byte pattern.

The current default remains a low-rate diagnostic path from prior hardware
evidence. The original 400 MHz selftest is still present as
`.#ypcb-ddr3-selftest-bitstream`; the next implementation step is to move the
successful diagnostic behavior to the 400 MHz operating point after deterministic
read/write integrity passes.

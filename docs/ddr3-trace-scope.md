# YPCB DDR3 internal trace scope

This debug variant captures short init-sequencer transitions inside the FPGA and
reads them back over a USER2 BSCAN addressed word reader. It is meant to compare the
passing RTL init simulation against a failing hardware-in-the-loop run.

## Why this exists

The existing 2048-bit BSCAN payload is a live snapshot. It is useful for polling,
but it cannot show transitions that occurred between polls. The trace scope is a
frozen ring buffer: it records init events in the controller clock domain and
JTAG reads the history after programming.

## Build

```sh
nix build .#ypcb-ddr3-bitstream-trace-scope-seed-10
```

The trace-scope variant defines:

```text
UBERDDR3_DEBUG_JTAG
UBERDDR3_PANOPTICON
UBERDDR3_TRACE_SCOPE
```

It keeps the existing USER1 2048-bit payload unchanged. Trace words are read one 64-bit word at a time over USER2, avoiding a giant debug shift register.

## Read on hardware

```sh
example_demo/ypcb_00338_1p1/scripts/ypcb_ddr3_board_test.py \
  --bitstream result/ypcb_00338_1p1_ddr3_openxc7.bit \
  --trace-scope \
  --output local-artifacts/board-tests/trace-scope-seed-10.json
```

`--trace-scope` reads USER2 trace words and decodes `fields.trace_scope.events`.

## Event format

Each event is 64 bits and records a transition in the init sequencer:

- cycle delta since the previous event
- `instruction_address` and `instruction_address_d`
- `state_calibrate`
- `delay_counter`
- `init_timer_phase`
- `delay_counter_is_zero`
- `init_advance_now`, `init_advance_pending`, `init_advance_ready_q`
- `init_calib_start_now`, `init_calib_start_q`
- `reset_done`, `sync_rst_controller`, `o_phy_reset`, `i_phy_idelayctrl_rdy`
- `pause_counter`
- `instruction[USE_TIMER]`, `instruction[RST_DONE]`
- `init_prefetch_ready`, `init_timed_counter_active`
- `init_counter_reaches_one`, `init_counter_reaches_two`

The RTL init simulation prints the same packed `event_word=` field in
`result/init_trace.log`.

## Comparison workflow

1. Build `ypcb-ddr3-rtl-init-icarus` and save `result/init_trace.log`.
2. Build and run a trace-scope bitstream for a known failing seed.
3. Compare the simulation `event_word` stream against
   `fields.trace_scope.events[*].raw` in the HIL JSON.
4. The first divergent event is the behavior delta to debug.

If the hardware event stream matches RTL up to instruction 13, the early init
failure was not reproduced for that bitstream. If it diverges before instruction
13, the divergent field identifies the next RTL/timing cone to inspect.

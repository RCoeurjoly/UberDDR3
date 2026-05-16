# YPCB LiteDRAM OpenXC7 Raw-BSCAN Bring-Up

This note records the current open-flow LiteDRAM hardware loop for the
YPCB-00338-1P1 board.

## Build

The raw-BSCAN design bypasses LiteX JTAGBone and exposes a direct USER1/USER2
BSCAN status/control bridge to the LiteDRAM BIST generator/checker.

```sh
OUT=/home/roland/UberDDR3/artifacts/task6/litedram-reference/ypcb-bist-bscan-openxc7-build-4lane-ignore-lock \
  nix develop .#default --command \
  scripts/task6/generate_ypcb_litedram_bist_reference.sh \
  --toolchain openxc7 \
  --byte-groups 0,1,2,3 \
  --with-raw-bscan \
  --ignore-pll-lock-reset \
  --no-bist \
  --build
```

The `--ignore-pll-lock-reset` option is diagnostic. The OpenXC7 bitstream has
working input and derived clock counters, but the MMCM `LOCKED` output reads
low in hardware. If LiteX keeps clock domains reset from `~LOCKED`, the sys
domain never runs.

## Program

```sh
nix develop .#default --command openocd \
  -f interface/ftdi/digilent_jtag_hs3.cfg \
  -c "adapter serial 210299BF3824" \
  -f cpld/xilinx-xc7.cfg \
  -c "adapter speed 6000" \
  -c "init" \
  -c "pld load 0 artifacts/task6/litedram-reference/ypcb-bist-bscan-openxc7-build-4lane-ignore-lock/gateware/ypcb_00338_1p1.bit" \
  -c "exit"
```

## Current Hardware Result

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py read --json-only
```

Observed status after programming the lock-bypass diagnostic bitstream:

- `magic_ok=true`
- `rst_n_raw=true`
- `clkin_counter` advances
- `idelay_counter` advances
- `sys_reset_deasserted=true`
- sys-domain `counter` advances
- `pll_locked=false`

The scratch command path also works:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py write-scratch --json-only
```

Observed:

- `command_count` increments
- `last_opcode=0x01`
- `scratch=0x5a17c0de`

A small BIST run executes both sides but does not pass yet:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py memtest \
  --length 0x100 \
  --timeout-s 10 \
  --json-only
```

Observed:

- `generator_done=true`
- `checker_done=true`
- `generator_ticks=9`
- `checker_ticks=27`
- `checker_errors=7`
- `pass=false`

## Interpretation

This proves the OpenXC7 raw-BSCAN hardware loop is usable and that LiteDRAM
BIST traffic can be launched and observed without JTAGBone. It does not prove
working DDR3 yet.

The next blockers are:

1. Understand why the OpenXC7 MMCM `LOCKED` output is low even though clock
   counters are advancing.
2. Restore the missing `INTERNAL_VREF` handling in the open-flow bitstream or
   prove it is not needed for the tested path.
3. Add LiteDRAM init/calibration status to the raw-BSCAN payload, then separate
   "controller is not initialized" from lane mapping or data-integrity errors.

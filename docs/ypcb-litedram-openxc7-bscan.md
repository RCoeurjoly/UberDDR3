# YPCB LiteDRAM OpenXC7 Raw-BSCAN Bring-Up

This note records the current open-flow LiteDRAM hardware loop for the
YPCB-00338-1P1 board.

## Build

The raw-BSCAN design bypasses LiteX JTAGBone and exposes a direct USER1/USER2
BSCAN status/control bridge to the LiteDRAM BIST generator/checker. It also
exposes a diagnostic Wishbone master for CSR access.

```sh
OUT=/home/roland/UberDDR3/artifacts/task6/litedram-reference/ypcb-bist-bscan-openxc7-wb-4lane-ignore-lock \
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
  -c "pld load 0 artifacts/task6/litedram-reference/ypcb-bist-bscan-openxc7-wb-4lane-ignore-lock/gateware/ypcb_00338_1p1.bit" \
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

The raw Wishbone/CSR command path works. This writes and reads back the LiteX
`ctrl_scratch` CSR at byte address `0x4`:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py wb-write \
  --addr 0x4 \
  --data 0x12345678 \
  --json-only

nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py wb-read \
  --addr 0x4 \
  --json-only
```

Observed:

- write command returns `wb_done=true`
- read command returns `wb_done=true`
- `wb_timeout=false`
- `wb_error=false`
- readback `wb_rdata=0x12345678`

The host can also run the generated LiteDRAM DDR3 DFII initialization sequence
through raw Wishbone:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py init-ddr3 \
  --json-only \
  --timeout-s 2
```

Observed:

- `ddrphy_rdphase` is set to `1`
- `ddrphy_wrphase` is set to `2`
- `ddrphy_rst` is pulsed
- DFII software control is enabled
- DDR3 reset release, CKE, MR2, MR3, MR1, MR0, and ZQ calibration commands all
  complete through CSR writes
- final `sdram_dfii_control` is set back to hardware control, `0x1`

After this sequence, a small BIST still fails:

- `generator_done=true`
- `checker_done=true`
- `checker_errors=8`
- `pass=false`

This means raw CSR initialization is now working, but LiteDRAM leveling /
calibration is still missing or the open-flow bitstream is still electrically
wrong.

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

1. Port LiteDRAM read-leveling/calibration over the raw Wishbone CSR path.
2. Understand why the OpenXC7 MMCM `LOCKED` output is low even though clock
   counters are advancing.
3. Restore the missing `INTERNAL_VREF` handling in the open-flow bitstream or
   prove it is not needed for the tested path.
4. Add LiteDRAM init/calibration status to the raw-BSCAN payload, then separate
   "controller is not initialized" from lane mapping or data-integrity errors.

# YPCB LiteDRAM OpenXC7 Raw-BSCAN Bring-Up

This note records the current open-flow LiteDRAM hardware loop for the
YPCB-00338-1P1 board.

## Build

The raw-BSCAN design bypasses LiteX JTAGBone and exposes a direct USER1/USER2
BSCAN status/control bridge to the LiteDRAM BIST generator/checker. It also
exposes a diagnostic Wishbone master for CSR and main-RAM access. USER2 uses a
128-bit command frame so full 32-bit Wishbone byte addresses are available.

```sh
OUT=/home/roland/UberDDR3/artifacts/task6/litedram-reference/ypcb-bist-bscan-openxc7-wb32-4lane-ignore-lock \
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
  -c "pld load 0 artifacts/task6/litedram-reference/ypcb-bist-bscan-openxc7-wb32-4lane-ignore-lock/gateware/ypcb_00338_1p1.bit" \
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

The full 32-bit raw Wishbone address path reaches the main RAM window, but the
DDR3 data path is not valid yet:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py wb-write \
  --addr 0x40000000 \
  --data 0xa5a55a5a \
  --json-only \
  --timeout-s 5

nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py wb-read \
  --addr 0x40000000 \
  --expected-data 0xa5a55a5a \
  --json-only \
  --timeout-s 5
```

Observed:

- write command returns `wb_done=true`
- read command returns `wb_done=true`
- `wb_timeout=false`
- `wb_error=false`
- readback is `wb_rdata=0xffffffff`, not `0xa5a55a5a`
- `data_match=false`

That result separates transport from DDR correctness: the raw BSCAN Wishbone
master can issue transactions to the SDRAM address window, but the initialized
LiteDRAM PHY/controller path is not returning valid memory data.

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
2. Implement the BIOS-style DFII read-leveling scan, not just a coarse global
   read-delay sweep, and capture per-module windows.
3. Understand why the OpenXC7 MMCM `LOCKED` output is low even though clock
   counters are advancing.
4. Verify the OpenXC7 bitstream uses the same 0.750 V internal VREF setting as
   the Vivado/LiteX oracle.
5. Add LiteDRAM init/calibration status to the raw-BSCAN payload, then separate
   "controller is not initialized" from lane mapping or data-integrity errors.

## Vivado/LiteDRAM Oracle Mismatches

Two host/tooling mismatches were found while comparing the OpenXC7 LiteDRAM
path against the generated LiteDRAM headers and the Vivado/LiteX electrical
oracle:

- The raw-BSCAN host DDR3 init sequence was hard-coded for the 125 MHz LiteDRAM
  build. The 100 MHz build generates `CL=7`, `CWL=5`, `RDPHASE=2`,
  `WRPHASE=3`, MR0 `0x0930`, and MR2 `0x0200`; the old host sequence used the
  125 MHz `CL=8`, `CWL=6`, `RDPHASE=1`, `WRPHASE=2`, MR0 `0x0940`, and MR2
  `0x0208` settings.
- The OpenXC7 FASM for the LiteDRAM build contained `VREF.V_675_MV` features
  for DDR banks even though the board oracle uses 0.750 V internal VREF on
  banks 11 through 18. The generator now patches the final FASM with
  `example_demo/ypcb_00338_1p1/ypcb_vref.features` and regenerates
  `ypcb_00338_1p1.frames` / `ypcb_00338_1p1.bit` after OpenXC7 builds.

The host script now also exposes `--tdqs`, which sets DDR3 MR1 bit 11 and lets
us test the MIG-style TDQS setting without rebuilding the FPGA bitstream.

## DFII Read-Leveling Diagnostic

The host script has a partial port of LiteDRAM BIOS read leveling. It uses the
raw Wishbone bridge to:

- switch DFII to software control
- write LiteDRAM's pseudo-random training pattern through DFII write-data CSRs
- issue ACT/WRITE/READ/PRECHARGE commands
- read DFII read-data CSRs
- score each selected module/bitslip/delay setting

Minimal hardware smoke test:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py dfii-read-leveling \
  --init-first \
  --module-mask 0x1 \
  --max-bitslip 0 \
  --max-delay 1 \
  --json-only \
  --timeout-s 5
```

Observed on the OpenXC7 4-lane diagnostic bitstream:

- DFII init completes first
- module 0 / bitslip 0 / delay 0 reports `errors=91`
- module 0 / bitslip 0 / delay 1 reports `errors=91`
- no valid read window is found in this tiny scan

This is not a full read-leveling sweep yet. It proves the raw-BSCAN host can
drive the same DFII pattern path used by LiteDRAM BIOS and can collect
per-module/per-delay error counts. Full sweeps are slow over JTAG, so the next
engineering step is to reduce the scan cost or move the inner pattern loop into
fabric before sweeping all modules, bitslips, and delays.

## Bridge-Local Diagnostics

The raw-BSCAN bridge now exposes a wider 768-bit status payload with bridge
diagnostic fields and two hardware-side helper commands:

- `bridge-apply-rdly`: apply `ddrphy_dly_sel`, read bitslip, and read-delay
  settings through the bridge's Wishbone master.
- `bridge-mem32-check`: apply the same read-delay settings, write one 32-bit
  word to a Wishbone byte address, read it back, and compare in fabric.
- `bridge-mem32-sweep`: repeat `bridge-mem32-check` over each selected byte
  group, bitslip, and delay tap, returning a compact JSON table of all points
  and any passing windows.

The command parameters are:

- `--module-mask`: selected DDRPHY byte-group mask
- `--bitslip`: read bitslip count
- `--delay`: read delay tap count
- `--addr`: byte address for `bridge-mem32-check`
- `--data`: expected write/read value for `bridge-mem32-check`

Example:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py bridge-mem32-check \
  --module-mask 0x1 \
  --bitslip 0 \
  --delay 0 \
  --addr 0x40000000 \
  --data 0xa5a55a5a \
  --json-only \
  --timeout-s 5
```

This does not replace BIOS-style DFII read leveling, but it reduces the cost of
coarse hardware sweeps by moving DDRPHY delay application and a direct memory
compare into fabric. Use it to quickly reject delay/bitslip points before
running slower DFII pattern scans.

Example one-byte-group sweep:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py bridge-mem32-sweep \
  --module-mask 0x1 \
  --max-bitslip 7 \
  --max-delay 31 \
  --addr 0x40000000 \
  --data 0xa5a55a5a \
  --json-only \
  --timeout-s 5
```

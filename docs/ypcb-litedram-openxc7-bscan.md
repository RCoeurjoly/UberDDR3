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

Hardware result after patching the existing 100 MHz OpenXC7 artifact:

- FASM patch removed the stray `VREF.V_675_MV` lines and appended the eight
  expected `VREF.V_750_MV` features.
- The patched bitstream programs and the raw-BSCAN bridge remains alive:
  `magic_ok=true`, `sys_reset_deasserted=true`, `rst_n_raw=true`, Wishbone
  commands complete without timeout/error.
- Corrected 100 MHz init with TDQS disabled completes, but
  `bridge-mem32-check` still fails: expected `0xa5a55a5a`, actual
  `0x00000000`, `wb_status=0x02`, `diag_status=0x03`.
- Corrected 100 MHz init with `--tdqs` also fails with the same `0x00000000`
  readback.

This is different from the pre-VREF-patch all-ones readback. The VREF patch is
therefore materially changing the hardware behavior, but it is not sufficient
for a passing DDR write/read path.

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

## 2026-05-17 DFII Pattern Result

The bridge-local DFII pattern diagnostic now has a SIM-only Icarus testbench:

```sh
nix develop .#default --command \
  iverilog -g2012 -DYPCB_BRIDGE_SIM \
  -o /tmp/ypcb_litedram_bscan_bridge_dfii_tb.vvp \
  example_demo/ypcb_00338_1p1/ypcb_litedram_bscan_bridge.v \
  tests/task6/ypcb_litedram_bscan_bridge_dfii_tb.sv

nix develop .#default --command \
  vvp /tmp/ypcb_litedram_bscan_bridge_dfii_tb.vvp
```

Expected result:

```text
PASS: bridge-local DFII pattern diagnostic sequence
```

This proves the bridge-local command sequence itself enters DFII software
control, issues ACT/WRITE/READ/PRECHARGE through the DFII CSRs, compares the
training pattern, and restores DFII hardware control in a mock Wishbone/DFII
environment.

On hardware, the 4-lane OpenXC7 diagnostic bitstream still fails a module-0
bridge-local sweep:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py bridge-dfii-pattern-sweep \
  --module-mask 0x1 \
  --max-bitslip 7 \
  --max-delay 31 \
  --json-only \
  --timeout-s 5 \
  --poll-s 0.005 \
  --settle-s 0.005 \
  --stop-on-zero
```

Observed result:

- `pass=false`
- no passing windows
- every bitslip/delay point reports `diag_error_count=129`
- the DFII initialization command stream completes first

`129` is the Hamming weight of the expected 8 x 32-bit training-pattern words,
so this is consistent with the DFII read-data path returning all zeroes. Since
the bridge sequence is now simulated, the next question is no longer the host
protocol. The next question is whether OpenXC7's LiteDRAM PHY implementation is
electrically/timing valid on YPCB.

The current full diagnostic shell is not timing-clean enough to answer that
cleanly; post-route `main_clkout_buf0` was around 80 MHz for a 100 MHz `sys`
target. The next OpenXC7 experiment should therefore use the reduced DFII-only
shell.

## DFII-Only Shell

`scripts/task6/ypcb_litedram_bist.py` supports `--dfii-only`. This keeps:

- CRG/MMCM/IDELAYCTRL
- `A7DDRPHY`
- LiteDRAM `DFIInjector` and DFII CSRs
- raw-BSCAN bridge

It removes the LiteDRAM controller/crossbar/main-RAM path and BIST ports from
the diagnostic build. The CSR map is deliberately kept compatible with the
existing bridge and host constants:

- `ddrphy` at `0x0800`
- `sdram_dfii_control` at `0x1800`
- `sdram_dfii_pi0_*` starting at `0x1804`

Generate only:

```sh
OUT=/tmp/ypcb-dfii-only-generate \
nix develop .#default --command \
  scripts/task6/generate_ypcb_litedram_bist_reference.sh \
  --toolchain openxc7 \
  --sys-clk-freq 100e6 \
  --byte-groups 0,1,2,3 \
  --with-raw-bscan \
  --ignore-pll-lock-reset \
  --no-bist \
  --dfii-only
```

Build for hardware:

```sh
OUT=artifacts/task6/litedram-reference/ypcb-raw-bscan-openxc7-dfii-only-4lane-100mhz-ignore-lock \
nix develop .#default --command \
  scripts/task6/generate_ypcb_litedram_bist_reference.sh \
  --toolchain openxc7 \
  --sys-clk-freq 100e6 \
  --byte-groups 0,1,2,3 \
  --with-raw-bscan \
  --ignore-pll-lock-reset \
  --no-bist \
  --dfii-only \
  --build
```

Observed 2026-05-17 hardware result after the bridge diagnostic FSM was made
tolerant of level-style Wishbone completion:

- The bridge-local DFII diagnostic simulation still passes:
  `PASS: bridge-local DFII pattern diagnostic sequence`.
- The DFII-only OpenXC7 build completes and the final bitstream is VREF-patched
  with `ypcb_vref.features`.
- Post-route `main_clkout_buf0` reports about `105 MHz`. The generator still
  asks nextpnr to report against a broad `200 MHz` target, so nextpnr prints a
  global FAIL, but the reduced shell is now above the intended `100 MHz` sys
  clock.
- Programming succeeds with OpenOCD.
- `init-ddr3 --json-only` succeeds: `magic_ok=true`, `rst_n_raw=true`,
  `sys_reset_deasserted=true`, `command_count=28`, `wb_status=0x02`, and the
  sys/idelay counters advance.
- `pll_locked=false` still reads low, but this shell deliberately ignores PLL
  lock for reset; the advancing counters and completed command stream are the
  fabric-liveness signal.

Important correction: the first `init-ddr3 --json-only` run used the host
default `--sys-clk-freq 125e6`, while this DFII-only artifact was generated for
`--sys-clk-freq 100e6`. The corrected initialization command is:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py init-ddr3 \
  --sys-clk-freq 100e6 \
  --json-only
```

That corrected run programs the expected LiteDRAM 100 MHz values:

- `CL=7`
- `CWL=5`
- `RDPHASE=2`
- `WRPHASE=3`
- MR0 `0x0930`
- MR2 `0x0200`

After corrected 100 MHz init, the lane-0 8 x 32-point DFII pattern sweep still
returns no passing windows; all 256 bitslip/delay points return
`diag_error_count=129`.

The MIG-style TDQS setting is also not sufficient:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py init-ddr3 \
  --sys-clk-freq 100e6 \
  --tdqs \
  --json-only
```

This programs MR1 `0x0806`, but the same lane-0 sweep still reports
`diag_error_count=129` at every point. So the uniform all-zero DFII readback is
not explained by the earlier host timing default mismatch or by TDQS being
disabled.

Single-point DFII pattern check:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py bridge-dfii-pattern-check \
  --module-mask 0x1 \
  --bitslip 0 \
  --delay 0 \
  --json-only \
  --timeout-s 5 \
  --poll-s 0.005 \
  --settle-s 0.005
```

Observed:

- `pass=false`
- `diag_status=0x03`
- `diag_state=72`
- `diag_count=1`
- `diag_error_count=129`
- `wb_status=0x02`

Full lane-0 sweep:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py bridge-dfii-pattern-sweep \
  --module-mask 0x1 \
  --max-bitslip 7 \
  --max-delay 31 \
  --json-only \
  --timeout-s 5 \
  --poll-s 0.005 \
  --settle-s 0.005 \
  --stop-on-zero
```

Observed:

- `pass=false`
- `passes=[]`
- all 256 bitslip/delay points return `diag_error_count=129`
- all sampled points complete with `diag_status=0x03`, not the old bridge abort
  value `0xe0`

This is now a stronger result than the earlier full-shell failure. The reduced
shell can execute the DFII command sequence in hardware, and the diagnostic FSM
no longer falls through a missed one-cycle `wb_done_pulse`. Since every
bitslip/delay point returns exactly the Hamming weight of the expected training
pattern, the current failure is consistent with all-zero DFII readback, not a
read-window alignment miss.

The next debugging target is therefore below the bridge protocol:

- confirm that the OpenXC7 bitstream drives DDR3 DQS/CK/command pins as the
  LiteDRAM PHY expects;
- compare LiteDRAM's generated MR/ODT/termination/TDQS settings with the Vivado
  MIG oracle;
- inspect the generated FASM for the relevant IO standards, VREF, IDELAY,
  ISERDES, OSERDES, and tri-state features;
- if the FASM is missing required 7-series DDR PHY features, reduce that to a
  nextpnr-xilinx/OpenXC7 test case and fix the open toolchain.

## Clean Reduced-Port DFII-Only Shell

The first `--byte-groups 0,1,2,3 --dfii-only` shell still exposed the full
72-bit DDR3 top-level port. Only the lower four byte groups were logically
connected, but Yosys/OpenXC7 still mapped the unused upper DQ/DQS top-level
ports into IOBUFs and the generated XDC still constrained the full channel.
That made the reduced experiment less clean than intended.

The generator now creates a reduced local DDRAM resource when fewer than all
nine YPCB channel byte groups are requested. For the four-lane DFII-only test,
the generated top now exposes only:

- `ddram_reduced0_dq[31:0]`
- `ddram_reduced0_dqs_p[3:0]`
- `ddram_reduced0_dqs_n[3:0]`

and the generated XDC contains no upper-lane DQ/DQS constraints.

Clean-port hardware build:

```sh
OUT=artifacts/task6/litedram-reference/ypcb-raw-bscan-openxc7-dfii-only-4lane-100mhz-cleanports-ignore-lock \
nix develop .#default --command \
  scripts/task6/generate_ypcb_litedram_bist_reference.sh \
  --toolchain openxc7 \
  --sys-clk-freq 100e6 \
  --byte-groups 0,1,2,3 \
  --with-raw-bscan \
  --ignore-pll-lock-reset \
  --no-bist \
  --dfii-only \
  --build
```

Observed 2026-05-17 result:

- the build completed and the final bitstream was patched with
  `ypcb_vref.features`;
- the generated top/XDC/report confirm only the lower four byte groups are
  present;
- programming the bitstream with OpenOCD succeeds;
- corrected `init-ddr3 --sys-clk-freq 100e6 --json-only` succeeds with
  `command_count=28`, `wb_status=0x02`, `magic_ok=true`,
  `sys_reset_deasserted=true`, and byte-group mask `0x0f`;
- lane-0 `bridge-dfii-pattern-sweep` still reports no passing windows;
- all 256 bitslip/delay points still return `diag_error_count=129`.

So the accidental upper-lane ports were a real reduction bug, but they were not
the cause of the uniform all-zero DFII readback. This pushes the next work
toward the actual PHY/electrical/open-bitstream boundary: DQ/DQS output-enable
features, ISERDES/OSERDES/IDELAY programming, LiteDRAM MR/ODT settings versus
MIG, and OpenXC7 support gaps.

## Write-Leveling Feedback Probe

The raw-BSCAN host now has a `write-leveling-sample` action. It uses the
generated LiteDRAM write-leveling CSRs:

- `ddrphy_wlevel_en` at `0x080c`
- `ddrphy_wlevel_strobe` at `0x0810`

The probe:

1. optionally runs `init-ddr3`;
2. switches DFII to software control;
3. writes MR1 with write-leveling enabled;
4. asserts LiteDRAM `wlevel_en`;
5. pulses `wlevel_strobe`;
6. reads all four DFII phase read-data words;
7. restores MR1 and hardware control.

Command:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py write-leveling-sample \
  --init-first \
  --sys-clk-freq 100e6 \
  --count 8 \
  --json-only \
  --timeout-s 5 \
  --poll-s 0.005 \
  --settle-s 0.005
```

Observed 2026-05-17 result:

- corrected 100 MHz initialization still completes;
- MR1 write-leveling value is `0x0086`;
- all eight samples return `0x0000000000000000` on phases 0, 1, 2, and 3;
- `pass=false`, meaning no sampled DFII read-data byte was nonzero.

TDQS does not change that result:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py write-leveling-sample \
  --init-first \
  --sys-clk-freq 100e6 \
  --tdqs \
  --count 8 \
  --json-only \
  --timeout-s 5 \
  --poll-s 0.005 \
  --settle-s 0.005
```

Observed:

- MR1 write-leveling value is `0x0886`;
- all sampled phase words are still zero.

This is a stronger failure signature than a missing read-leveling window. In
write-leveling mode, the controller should be able to strobe DQS and observe
some feedback from the memory. Seeing no high bits with and without TDQS points
earlier in the path: command/MR acceptance, DQS output-enable/drive, DQ input
capture, or an OpenXC7 feature mismatch in the 7-series DDR I/O primitives.

## Kintex-7 LiteDRAM PHY Attempt

The first reduced LiteDRAM shells used `A7DDRPHY`, which is the Artix-7
no-ODELAY path. That was useful as a minimal raw-BSCAN/DFII smoke test, but it
is not the right long-term PHY class for this Kintex-7 board. The generator now
has a `--s7-phy a7|k7` option so the same YPCB shell can be built with
`K7DDRPHY`.

Command:

```sh
OUT=artifacts/task6/litedram-reference/ypcb-raw-bscan-openxc7-dfii-only-4lane-100mhz-k7-cleanports-ignore-lock \
nix develop .#default --command \
  scripts/task6/generate_ypcb_litedram_bist_reference.sh \
  --toolchain openxc7 \
  --s7-phy k7 \
  --sys-clk-freq 100e6 \
  --byte-groups 0,1,2,3 \
  --with-raw-bscan \
  --ignore-pll-lock-reset \
  --no-bist \
  --dfii-only \
  --build
```

Observed 2026-05-17 result:

- LiteDRAM generation succeeds and instantiates the intended Kintex-7 path:
  `K7DDRPHY`, `IDELAYCTRL`, `IDELAYE2`, `ODELAYE2`, `ISERDESE2`, and
  `OSERDESE2`;
- Yosys synthesis reaches nextpnr packing;
- nextpnr/OpenXC7 aborts during I/O packing:

```text
ERROR: ODELAYE2 'ODELAYE2' has DATAOUT connected to unsupported cell type IOB33M_OUTBUF
```

This is now the highest-priority fully-open-flow blocker. The A7/no-ODELAY
shell proves raw-BSCAN/CSR plumbing and DDR command sequencing are alive but
returns all-zero DDR feedback. The K7/ODELAY shell is the more appropriate
electrical/PHY experiment, and it currently cannot reach bitstream generation
because nextpnr rejects an `ODELAYE2 -> IOB33M_OUTBUF` topology.

The adjacent nextpnr-xilinx XC7 packer code already recognizes direct
`IOB33_OUTBUF`/`IOB33M_OUTBUF` cells in related output-buffer discovery logic,
so the immediate tooling task is to make the `ODELAYE2.DATAOUT` legality check
accept those direct output-buffer cell types as well, then rebuild nextpnr and
rerun this K7 LiteDRAM shell.

That nextpnr-xilinx patch was implemented locally in
`~/nextpnr-xilinx` on branch `stable-backports` as commit `5624552d`:

```text
Allow ODELAYE2 to feed direct XC7 outbufs
```

Rebuilding nextpnr-xilinx inside a compatible Nix shell and rerunning the same
K7/ODELAY LiteDRAM shell moved the build past the original unsupported-cell
check, but exposed the next architectural constraint:

```text
ERROR: BEL IOB_X0Y94/IOB33M/OUTBUF is located on a high range bank. High range banks do not have ODELAY
```

This is a materially different result. The first error was a nextpnr packing
legality gap. The second says the requested K7DDRPHY topology is physically
incompatible with at least one YPCB DDR output site because that site is in a
7-series HR bank, and HR banks do not contain ODELAY resources.

Current implication:

- the direct `ODELAYE2 -> IOB33M_OUTBUF` nextpnr patch is still useful and
  upstreamable because it lets nextpnr reach the real device legality check;
- a blanket LiteDRAM `K7DDRPHY` is not a valid drop-in for this YPCB channel
  when the DDR pins are on HR-bank I/O;
- the fastest fully-open path goes back to an HR-compatible no-ODELAY PHY
  strategy and must explain why the current A7/no-ODELAY shell has all-zero
  read/write-leveling feedback.

## MIG-Style MR1 Retest on the HR-Compatible Shell

The raw-BSCAN host now accepts `--mr1 <value>` so manual DFII initialization can
test exact mode-register settings without regenerating the bitstream. This lets
the no-ODELAY HR-compatible shell test the Vivado/MIG channel-0 MR1 settings:

- TDQS enabled;
- DIC = `RZQ/7`;
- RTT_NOM = `RZQ/4`.

Command:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py init-ddr3 \
  --sys-clk-freq 100e6 \
  --mr1 0x0004 \
  --tdqs \
  --json-only
```

Observed 2026-05-17 result:

- command/CSR-level initialization still passes;
- the host records MR1 as `0x0804`.

Write-leveling probe:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py write-leveling-sample \
  --init-first \
  --sys-clk-freq 100e6 \
  --mr1 0x0004 \
  --tdqs \
  --count 8 \
  --json-only \
  --timeout-s 5 \
  --poll-s 0.005 \
  --settle-s 0.005
```

Observed:

- MR1 during write leveling is `0x0884`;
- restore MR1 is `0x0804`;
- all eight samples still return zero on all four DFII phases;
- `pass=false`.

So the all-zero feedback is not explained by the obvious MIG MR1/TDQS
mismatch. The remaining fast path is to instrument the no-ODELAY shell closer
to the I/O boundary: prove DQS toggles, prove DQ input capture can see board
levels, and compare OpenXC7 generated IOB/SERDES/FASM features against the
Vivado/MIG oracle for the same HR-bank pins.

## Direct DDR Pin Sampler

A minimal raw-BSCAN sampler now bypasses LiteDRAM, DFII, IDELAY, ISERDES, and
OSERDES entirely. It places only input buffers on the lower four byte groups:

- `ddr3_dq[31:0]`
- `ddr3_dqs_p[3:0]`
- `ddr3_dqs_n[3:0]`

The sampler uses the same YPCB DDR pin LOCs, `SSTL15` / `DIFF_SSTL15`, input
termination, and `ypcb_vref.features` append as the DDR experiments. USER1
returns a 256-bit payload containing current, sticky-high, sticky-low, and
toggle-seen state for the sampled pins.

Build and program:

```sh
nix develop .#default --command \
  make -C example_demo/ypcb_00338_1p1 bscan-ddr-pins \
  SYNTH_XILINX_FLAGS="-flatten -arch xc7" \
  PNR_ARGS="--seed 3" \
  PNR_DEBUG=

nix develop .#default --command \
  make -C example_demo/ypcb_00338_1p1 program-bscan-ddr-pins-openocd \
  SYNTH_XILINX_FLAGS="-flatten -arch xc7" \
  PNR_ARGS="--seed 3" \
  PNR_DEBUG=
```

Read:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_bscan_ddr_pins.py \
  --serial 210299BF3824 \
  --tdo-bit 7
```

Observed 2026-05-17 result:

```json
{
  "magic_ok": true,
  "counter": "0x14561975",
  "dq_now": "0xffffffff",
  "dq_seen_high": "0xffffffff",
  "dq_seen_low": "0xffffffff",
  "dq_toggle_seen": "0xffffffff",
  "dqs_p_now": "0x3",
  "dqs_n_now": "0xc",
  "dqs_p_seen_high": "0x3",
  "dqs_n_seen_high": "0xc",
  "dqs_p_seen_low": "0xf",
  "dqs_n_seen_low": "0xf",
  "dqs_p_toggle_seen": "0x3",
  "dqs_n_toggle_seen": "0xc"
}
```

This is a decisive boundary check. The lower DDR pins are electrically visible
to an OpenXC7 bitstream with the same VREF and input-standard assumptions. DQ
is not stuck low: all 32 sampled DQ bits have been seen high, seen low, and
seen toggling. The LiteDRAM all-zero DFII/write-leveling result is therefore
above the raw input-buffer boundary. Remaining suspects are DQS/CK/command
drive, reset/CKE/ODT/MR command acceptance, OSERDES/ISERDES/IDELAY feature
generation, or LiteDRAM PHY sequencing for this HR-bank YPCB topology.

## LiteDRAM PHY Read Sampler

The next diagnostic attempt was to add raw DQ/DQS pad sampling to the
LiteDRAM-integrated shell. That is not legal from outside the PHY: tapping the
top-level DDR pads in the wrapper makes Yosys/OpenXC7 see the same DDR pad net
as connected to both the LiteDRAM I/O buffer and an extra sampler path.
nextpnr rejects that structure with errors such as:

```text
ERROR: IO buffer 'IOBUFDS' is connected to more than a single top level IO pin.
ERROR: IO buffer 'IOBUF' is connected to more than a single top level IO pin.
```

The bridge now uses a legal internal probe instead. In the LiteDRAM-integrated
build, the raw-BSCAN status payload samples
`phy.dfi.phases[rdphase].rddata[31:0]`. DQS status fields are intentionally
tied to zero in this build; the standalone DDR pin sampler above remains the
pad-level DQS/DQ evidence source.

Build:

```sh
OUT=artifacts/task6/litedram-reference/ypcb-raw-bscan-openxc7-dfii-only-4lane-100mhz-cleanports-phy-read-sampler-ignore-lock \
nix develop .#default --command \
  scripts/task6/generate_ypcb_litedram_bist_reference.sh \
  --toolchain openxc7 \
  --sys-clk-freq 100e6 \
  --byte-groups 0,1,2,3 \
  --with-raw-bscan \
  --ignore-pll-lock-reset \
  --no-bist \
  --dfii-only \
  --build
```

The generator now canonicalizes `OUT` before invoking LiteX. This avoids a
previous relative-path bug where a relative `OUT=artifacts/...` caused the
generated gateware build script to look for the chip database relative to the
`gateware/` subdirectory.

Program:

```sh
nix develop .#default --command openocd \
  -f interface/ftdi/digilent_jtag_hs3.cfg \
  -c "adapter serial 210299BF3824" \
  -f cpld/xilinx-xc7.cfg \
  -c "adapter speed 6000" \
  -c "init" \
  -c "pld load 0 artifacts/task6/litedram-reference/ypcb-raw-bscan-openxc7-dfii-only-4lane-100mhz-cleanports-phy-read-sampler-ignore-lock/gateware/ypcb_00338_1p1.bit" \
  -c "exit"
```

Initial read after programming:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py read \
  --serial 210299BF3824 \
  --tdo-bit 7 \
  --json-only
```

Observed 2026-05-17 result:

- `pass=true`
- `magic_ok=true`
- alignment is still `right-shift-1`
- `rst_n_raw=true`
- `sys_reset_deasserted=true`
- counters advance
- `pll_locked=false`
- `ddr_dq_now=0x00000000`
- `ddr_dq_seen_high=0x00001000`
- `ddr_dq_seen_low=0xffffffff`
- `ddr_dq_toggle_seen=0x00001000`

MIG-style initialization still completes:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py init-ddr3 \
  --serial 210299BF3824 \
  --tdo-bit 7 \
  --sys-clk-freq 100e6 \
  --mr1 0x0004 \
  --tdqs \
  --json-only
```

Observed:

- `pass=true`
- MR1 is `0x0804`
- `CL=7`
- `CWL=5`
- `RDPHASE=2`
- `WRPHASE=3`
- `command_count=28`
- `wb_done=true`
- no timeout or Wishbone error

Write-leveling with the PHY read sampler gives the most useful new boundary
result:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py write-leveling-sample \
  --serial 210299BF3824 \
  --tdo-bit 7 \
  --init-first \
  --sys-clk-freq 100e6 \
  --mr1 0x0004 \
  --tdqs \
  --count 8 \
  --json-only \
  --timeout-s 5 \
  --poll-s 0.005 \
  --settle-s 0.005
```

Observed:

- `pass=false`
- all eight DFII readback samples are still all-zero on phases 0 through 3
- final PHY-read sampler state has `ddr_dq_seen_high=0x00421000`
- final PHY-read sampler state has `ddr_dq_toggle_seen=0x00421000`
- final `ddr_dq_now=0x00000000`

This narrows the failure. The standalone pin sampler proves the lower DDR pads
are visible to OpenXC7, and the integrated PHY-read sampler now sees sticky
activity on a few read-data bits during write leveling. But the LiteDRAM DFII
CSR readback path still returns all zeroes. The next target is therefore
inside or immediately around the LiteDRAM 7-series no-ODELAY PHY read-capture
and DFI propagation path, plus the still-unexplained MMCM `LOCKED=false`
status. It is no longer credible to blame only the raw BSCAN transport or
basic pad input visibility.

Follow-up diagnostic:

- commit `aaf5542` exposes a compact all-phase DFI read-data summary in the
  top 96 bits of the existing 1024-bit USER1 payload;
- commit `21e6b81` adds `clear-phy-sample`, and the host now clears the sticky
  PHY sample registers immediately before write-leveling strobes.

Clean hardware build:

```sh
OUT=artifacts/task6/litedram-reference/ypcb-raw-bscan-openxc7-dfii-only-4lane-100mhz-cleanports-allphase-clear-sampler-ignore-lock \
nix develop .#default --command \
  scripts/task6/generate_ypcb_litedram_bist_reference.sh \
  --toolchain openxc7 \
  --sys-clk-freq 100e6 \
  --byte-groups 0,1,2,3 \
  --with-raw-bscan \
  --ignore-pll-lock-reset \
  --no-bist \
  --dfii-only \
  --build
```

This build completed, was patched with `ypcb_vref.features`, and routed with
post-route `main_clkout_buf0` around `103.53 MHz`. nextpnr still prints a
global FAIL because the generated command asks it to report against `200 MHz`,
but this artifact is timing-clean enough for the intended `100 MHz` diagnostic
clock.

Program:

```sh
nix develop .#default --command openocd \
  -f interface/ftdi/digilent_jtag_hs3.cfg \
  -c "adapter serial 210299BF3824" \
  -f cpld/xilinx-xc7.cfg \
  -c "adapter speed 6000" \
  -c "init" \
  -c "pld load 0 artifacts/task6/litedram-reference/ypcb-raw-bscan-openxc7-dfii-only-4lane-100mhz-cleanports-allphase-clear-sampler-ignore-lock/gateware/ypcb_00338_1p1.bit" \
  -c "exit"
```

Clean write-leveling probe:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py write-leveling-sample \
  --serial 210299BF3824 \
  --tdo-bit 7 \
  --init-first \
  --sys-clk-freq 100e6 \
  --mr1 0x0004 \
  --tdqs \
  --count 8 \
  --json-only \
  --timeout-s 5 \
  --poll-s 0.005 \
  --settle-s 0.005
```

Observed 2026-05-17 result after the sticky clear:

- `pass=false`
- all eight DFII CSR samples are still all-zero on phases 0 through 3
- final `ddr_dq_seen_high=0x00000000`
- final `ddr_phase_nonzero_seen=0x2`
- final `ddr_phase_nonzero_toggle_seen=0x2`
- final `ddr_phase_seen_high=0x00020000`
- final `ddr_phase_toggle_seen=0x00020000`
- DQS status fields remain zero in this integrated build because DQS is not
  legally tapped outside the LiteDRAM PHY

This is the cleanest boundary result so far. During the write-leveling window,
the integrated PHY-facing DFI read-data signal sees a transient high on phase
1, bit 17, but the DFII CSR readback path never returns a nonzero byte. That
means there is some feedback activity inside the no-ODELAY A7DDRPHY read path,
but the current host-side CSR sampling method is missing it. The next target
is a fabric-side write-leveling/read-window sampler that latches the DFI
read-data bus at strobe time, rather than relying on slow JTAG CSR reads after
the event.

First-hit sampler follow-up:

```sh
OUT=artifacts/task6/litedram-reference/ypcb-raw-bscan-openxc7-dfii-only-4lane-100mhz-cleanports-firsthit-sampler-ignore-lock \
  nix develop .#default --command \
  scripts/task6/generate_ypcb_litedram_bist_reference.sh \
    --toolchain openxc7 \
    --sys-clk-freq 100e6 \
    --byte-groups 0,1,2,3 \
    --with-raw-bscan \
    --ignore-pll-lock-reset \
    --no-bist \
    --dfii-only \
    --build
```

The first-hit artifact routed and produced:

- `gateware/ypcb_00338_1p1.bit`
- OpenXC7 VREF feature patch applied
- `main_clkout_buf0` maximum frequency reported as 95.68 MHz in the broad
  nextpnr timing report

Programmed bitstream:

```sh
nix develop .#default --command openocd \
  -f interface/ftdi/digilent_jtag_hs3.cfg \
  -c "adapter serial 210299BF3824" \
  -f cpld/xilinx-xc7.cfg \
  -c "adapter speed 6000" \
  -c "init" \
  -c "pld load 0 artifacts/task6/litedram-reference/ypcb-raw-bscan-openxc7-dfii-only-4lane-100mhz-cleanports-firsthit-sampler-ignore-lock/gateware/ypcb_00338_1p1.bit" \
  -c "exit"
```

Observed 2026-05-17 result with the same write-leveling probe:

- `pass=false`
- all eight DFII CSR samples remain all-zero on phases 0 through 3
- final `ddr_phase_first_valid=true`
- final `ddr_phase_first_mask=0x2`
- final `ddr_phase_first_word=0x00020000`
- final `ddr_phase_nonzero_seen=0x2`
- final `ddr_phase_seen_high=0x00020000`

This confirms the previous sticky-only observation without relying on a
post-event CSR read: the first nonzero internal DFI read event captured after
the write-leveling sticky clear is phase 1, bit 17. The event is narrow or not
connected to the DFII CSR readback window, so the next sampler should record
per-strobe or per-delay first-hit data in fabric and expose that summary over
BSCAN.

Write-leveling delay sweep follow-up:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py write-leveling-sweep \
    --serial 210299BF3824 \
    --tdo-bit 7 \
    --init-first \
    --sys-clk-freq 100e6 \
    --mr1 0x0004 \
    --tdqs \
    --module-mask 0x4 \
    --max-bitslip 0 \
    --max-delay 31 \
    --count 4 \
    --json-only \
    --summary-only \
    --timeout-s 5 \
    --poll-s 0.005 \
    --settle-s 0.005
```

Observed 2026-05-17 focused result for module mask `0x4`, bitslip `0`:

- `pass=true` because at least one fabric-side first-hit was captured
- early hits at delays `0,1,2` with `first_mask=0x2`,
  `first_word=0x00020000`
- main delayed hit region at delays `21,23,25,26,27,28,29,30,31` with
  `first_mask=0x4`, `first_word=0x00020000`
- final sticky status remained `ddr_phase_first_mask=0x4`,
  `ddr_phase_first_word=0x00020000`

This is the first evidence that the LiteDRAM no-ODELAY write-leveling feedback
is sensitive to DQ IDELAY setting instead of being only a constant stuck
artifact. It still is not full calibration: DQS fields remain unavailable in
this legal integrated build, and DFII CSR readback remains all-zero in the
older sampler. The useful next step is to convert this first-hit sweep into a
byte-lane calibration selector, then use the selected delays for a controlled
read/write BIST attempt.

Selector follow-up:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py write-leveling-calibrate \
    --serial 210299BF3824 \
    --tdo-bit 7 \
    --init-first \
    --sys-clk-freq 100e6 \
    --mr1 0x0004 \
    --tdqs \
    --module-mask 0xf \
    --max-bitslip 0 \
    --max-delay 31 \
    --count 4 \
    --json-only \
    --summary-only \
    --timeout-s 5 \
    --poll-s 0.005 \
    --settle-s 0.005
```

Observed 2026-05-17 selected windows:

| module mask | hit count | selected bitslip | selected delay | window |
|---:|---:|---:|---:|---:|
| `0x1` | 28 | 0 | 8 | 0..17 |
| `0x2` | 26 | 0 | 17 | 12..23 |
| `0x4` | 31 | 0 | 11 | 0..22 |
| `0x8` | 32 | 0 | 15 | 0..31 |

The selector returned `pass=true` and applied these per-byte-group delays via
the LiteDRAM DDRPHY read-delay CSRs. This is still too slow as a host-side
calibration primitive because it runs many JTAG Wishbone transactions; if the
approach continues to work, the sweep/selection should move into fabric.

DFII pattern check caveat:

```sh
nix develop .#default --command \
  python3 scripts/task6/ypcb_litedram_bscan.py bridge-dfii-pattern-check \
    --serial 210299BF3824 \
    --tdo-bit 7 \
    --sys-clk-freq 100e6 \
    --mr1 0x0004 \
    --tdqs \
    --module-mask 0xf \
    --bitslip 0 \
    --delay 0 \
    --json-only \
    --timeout-s 5 \
    --poll-s 0.005 \
    --settle-s 0.005
```

Observed result:

- `pass=false`
- `diag_status=0x03`
- `diag_error_count=129`
- `ddr_phase_nonzero_seen=0xf`
- `ddr_phase_seen_high=0xffffffff`

This command is not a valid test of the per-byte selected delay set above,
because `bridge-dfii-pattern-check` applies its own single `--delay` to the
selected `--module-mask` before running the pattern. With `--module-mask 0xf`
and `--delay 0`, it overwrote the selector's per-byte delays. A valid next
test needs either a combined calibrate-and-BIST action or a BIST-capable
bitstream plus a command path that does not collapse all byte groups to one
delay.

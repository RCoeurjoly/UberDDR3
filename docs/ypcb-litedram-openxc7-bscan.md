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

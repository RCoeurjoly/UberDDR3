# YPCB DDR3 Frozen Shell Strategy

## Goal

Make DDR3 development deterministic enough to continue from a known-good
hardware-calibrating design while new functionality is added around it.

The open nextpnr-xilinx flow does not currently provide a Vivado-style routed
checkpoint that can be reopened, preserved, and incrementally routed around.
The practical substitute is a frozen DDR3 shell:

1. preserve a known-good synthesized DDR3/JTAG rowstream design artifact,
2. extract BEL locks from the routed JSON that calibrated on hardware,
3. keep the DDR3 shell interface stable,
4. add new RTL outside that boundary,
5. apply shell locks during PNR,
6. hardware-test calibration and rowstream read/write after every change.

## Clock Discipline

The RTL PLL and nextpnr timing constraints must describe the same clocks.

For the AMD/Xilinx Kintex-7 DDR3 external-memory-interface guidance, the DDR3
memory clock must be at least 400 MHz so the Phaser block is used in 1:1 mode.
The exact-400 MHz experiment was built and tested as a clean baseline, but it
failed before calibration started. Because the AMD/Xilinx note permits 400 MHz
or higher, the frozen shell uses the known hardware-passing 500 MHz operating
point:

| Clock | Frequency | Period |
| --- | ---: | ---: |
| `ddr3_clk` | 500 MHz | 2 ns |
| `ddr3_clk_90` | 500 MHz | 2 ns |
| `controller_clk` | 125 MHz | 8 ns |
| `ref_clk` | 200 MHz | 5 ns |

With the 50 MHz board clock, the frozen-shell PLL is:

| PLL output | Divide | Frequency |
| --- | ---: | ---: |
| VCO | `50 MHz * 20` | 1000 MHz |
| `CLKOUT0` | 2 | 500 MHz |
| `CLKOUT1` | 2 | 500 MHz, 90 deg |
| `CLKOUT2` | 8 | 125 MHz |
| `CLKOUT3` | 5 | 200 MHz |

Any build whose RTL PLL and `addClock` constraints disagree is not a valid
timing experiment.

## Frozen Boundary

The initial shell boundary is the current rowstream top:

`task6_ypcb_uberddr3_bist_rowstream_loader_top`

It contains:

- PLL and BUFGs,
- `ddr3_top` / UberDDR3 PHY and controller,
- the boot/readback probe,
- JTAG command and debug scan chains,
- the low-byte and dense-byte rowstream command interface.

The external, stable development interface is the rowstream command protocol:

| Opcode | Meaning |
| ---: | --- |
| `0x03` | write one low byte |
| `0x04` | read one low byte |
| `0x05` | write one dense byte into a 512-bit beat |
| `0x06` | read one dense 512-bit beat |

New test and application logic should first talk to DDR3 through this command
surface. Only after this path is stable should we split out a wider local bus.

The currently preserved passing shell exposes the old 512-bit JTAG debug scan.
That scan includes a 128-bit readback window at debug bit 336, so it can
hardware-validate dense byte lanes 0 through 15 without regenerating the DDR3
shell. A later frozen-shell revision must expose either four selectable
128-bit chunks or the full 512-bit beat before the full 64-byte readback
contract can be accepted.

Rowstream USER2 commands must be sent with `--command-repeats 2`. The loader
accepts every other command event; using one repeat can make alternating
write/read commands look like data-lane failures.

The preserved-shell dense-byte experiment showed that one-hot byte writes are
not a sound contract for this YPCB configuration. With repeated commands and
calibration passing, lanes 0, 2, 3, 4, 6, 7, 8, 10, 11, 12, 14, and 15 in the
first 128-bit window can read back correctly, but lanes 1, 5, 9, and 13 remain
at the existing pattern bytes. This matches the earlier no-DM board evidence:
partial byte-write masking cannot be the foundation for 64-byte correctness.

The 2026-05-14 hardware run confirmed the same conclusion on the preserved
seed-3 v44 artifact:

- `write-lowbyte` followed by `read-lowbyte` still reaches `DONE_CALIBRATE` and
  round-trips the low byte.
- dense-byte `memtest64` now uses the correct legacy dense-read opcode `0x06`;
  the command gate passes and `ack_count` advances, but the 64-byte data compare
  fails because one-hot byte writes are not a valid no-DM memory contract.
- fresh v64 fullbeat RTL builds, both loader-only and BIST-shell variants, fail
  before calibration even with `--timing-allow-fail`. The failure happens before
  any host fullbeat command is issued, so this is a placement/timing/calibration
  perturbation from the fresh RTL shape, not a fullbeat command semantics
  failure.

The minimal v45 fullbeat rowstream shell implements the intended command
contract directly in the historically calibrating v44 top:

| Opcode | Meaning |
| ---: | --- |
| `0x01` | stage one 128-bit write chunk; chunk 3 commits all 64 byte lanes |
| `0x02` | read one complete 512-bit beat |
| `0x03` | legacy low-byte write |
| `0x04` | legacy low-byte read |
| `0x05` | diagnostic dense-byte write |
| `0x06` | diagnostic dense-beat read |

The hardware implementation is intentionally full-beat only at commit time:
`LOADER_OP_WRITE_CHUNK` updates a 512-bit staging register for chunks 0..3 and
only chunk 3 issues the Wishbone write with `loader_sel_q = {WB_SEL_BITS{1'b1}}`.
This is the correct YPCB memory contract because it does not rely on absent or
unproven DDR3 DM byte masks.

However, the v45 shell is not yet a usable hardware base. A PNR-only sweep from
one v45 synth JSON, with the 411-lock v40 physical pre-place constraints and
`--timing-allow-fail`, failed calibration for all historically useful seeds:

| Seed | Version | Calibration State | `ack_count` | Result |
| ---: | ---: | --- | ---: | --- |
| 0 | 45 | `IDLE` | 0 | fail before command gate |
| 3 | 45 | `IDLE` | 0 | fail before command gate |
| 16 | 45 | `IDLE` | 0 | fail before command gate |
| 40 | 45 | `IDLE` | 0 | fail before command gate |
| 44 | 45 | `IDLE` | 0 | fail before command gate |

The control test immediately after the sweep reprogrammed the preserved v44
artifact and reached `DONE_CALIBRATE` with `calibration=pass` and `ack_count=9`.
That isolates the regression to the new RTL shape and resulting placement, not
to board state, JTAG programming, or the hardware session.

The full 64-byte path must therefore be full-beat based:

1. stage a 512-bit write beat through JTAG or a local producer,
2. commit it to DDR3 with `i_wb_sel = {64{1'b1}}`,
3. read back the 512-bit beat,
4. expose the beat as four 128-bit chunks or one 512-bit debug payload,
5. compare all 64 bytes in software.

The v53 diagnostic shell narrowed the current failure. Hardware with the
calibrating seed-0 bitstream reaches `DONE_CALIBRATE`, accepts rowstream
commands, and the debug window proves that a host write-chunk payload is staged
correctly in FPGA fabric. A direct staged write of bytes `00..0f` reports the
same `00..0f` in the diagnostic `read_window128_bytes`. The transport and JTAG
command packing are therefore not the immediate blocker.

The same v53 shell still fails real memory writes:

| Test | Address | Result |
| --- | ---: | --- |
| fullbeat `memtest64` | `0x0` | command ack passes, readback is existing DDR3/test pattern |
| fullbeat `memtest64` | `0x40` | command ack passes, readback is unrelated memory contents |
| dense-byte `memtest64` | `0x40` | command ack passes, many lanes become `0x00`; nonzero byte values do not reliably stick |
| low-byte write/read `0x5a` | `0x40` | write command reports ack, read returns existing pattern byte |

This means the next bug is at or below the rowstream-to-Wishbone DDR3 command
boundary: write data, write strobes, stale acknowledgements, or the
BIST-mode/user-port interaction. It is not a host packing problem.

The v54 command-pulse experiment changed the wrapper to register commands for
one controller cycle and drop `cyc` after command completion. That is a cleaner
Wishbone contract, but it perturbed placement enough that both seed 0 and seed
3 failed calibration in `READ_DATA`. A direct all-BEL transplant from the
calibrating v53 seed-0 routed JSON matched only 9,266 of 34,097 locks against
the v54 netlist; 24,831 locks were missing, mostly unstable generated packer
cell names. The partial over-lock also produced post-placement validity errors
and a stalled route. Full-cell locks are therefore only useful when the
synthesis identity is preserved; they are not a general cross-RTL transplant.

The v55 accepted-request diagnostic narrowed the failure further. With the same
RTL build, seeds 0 and 3 still fail calibration in `READ_DATA`, but seed 16
reaches `DONE_CALIBRATE` with `ack_count=9`. On that seed, a fresh hardware
programming run shows low-byte DDR3 writes are real: writing and reading `0xa5`
at beat addresses `0, 64, 128, 192, 256, 512, 1024` returns `0xa5` at each
address. Some of those reads still trip the older command-gate/integrity
decoder, so the observed byte and decoded calibration state are the decisive
signals for this diagnostic shell.

The same v55 seed-16 hardware run does not make the 64-byte contract pass:

| Test | Address | Accepted Request | Result |
| --- | ---: | --- | --- |
| low-byte write/read `0x5a` | `0x40` | `we=1`, `sel[0]=1`, low data `0x005a` | pass |
| fullbeat `memtest64 increment` | `0x0` | `we=1`, low 15 `sel` bits set, low data `0x0100` | fail |
| dense-byte `memtest64 increment` | `0x80` | one-hot commands accepted | fail |
| dense-byte lane 0 direct `0x5a` | `0x180` | accepted low data becomes `0x002d` | fail |
| dense-byte lane 0 direct `0xb4` | `0x180` | accepted low data becomes `0x005a` | fail |

That evidence changes the active hypothesis: the low-byte rowstream user port
is capable of writing and reading DDR3 on the seed-16 shell, but dense one-hot
byte writes and full 64-byte writes are not correct. Dense-byte remains a
diagnostic path only. The next useful RTL diagnostics should expose complete
fullbeat accepted fields and readback chunks, then isolate whether the
fullbeat failure is staging, byte-lane/select handling, or controller write
semantics.

The v63 opt-in debug experiments showed that controller-side instrumentation is
not a neutral diagnostic on this shell. The default v63 seed-16 bitstream, with
WB2 debug disabled and controller BIST disabled, reaches `DONE_CALIBRATE`,
advances `ack_count`, and still passes low-byte write/read. Its fullbeat
`memtest64` accepts commands but reads back calibration-pattern-like data
instead of the written `00..3f` byte stream.

Two v63 diagnostic variants failed before useful fullbeat evidence:

| Variant | Build knobs | Hardware result |
| --- | --- | --- |
| WB2 + bounded BIST | `ENABLE_WB2_DEBUG=1`, `CONTROLLER_BIST_ADDR_BITS=8` | fails calibration in `READ_DATA` / `ANALYZE_DATA_LOW_FREQ`, `ack_count=0` |
| bounded BIST only | `CONTROLLER_BIST_ADDR_BITS=8` | fails calibration in `READ_DATA`, `ack_count=0`, BIST counters remain zero |

The bounded-BIST-only bitstream was:

```sh
artifacts/manual-seed/fullbeat-v63-bist-debug1/seed16/rowstream-v63-bist-debug1-seed16.bit
```

Its routed JSON was:

```sh
artifacts/manual-seed/fullbeat-v63-bist-debug1/seed16/nextpnr-routed.json
```

The diagnostic conclusion is that adding the controller BIST datapath, even
without WB2 debug, perturbs the calibrated shell enough to fail before BIST
traffic starts. Until placement stability improves, higher-level DDR3
diagnostics should stay outside the controller shell or use the default
calibrating rowstream path.

## Artifact Policy

There are two different artifact classes:

- **Matching synth artifact**: a Yosys JSON whose cell names match a known-good
  routed placement.
- **Placement oracle**: routed JSON / extracted BEL-lock JSON from a
  hardware-passing build.

`oracle-all` is only meaningful when the synth artifact matches the extracted
lock names. Fresh synthesis can rename generated packer cells; this caused only
5,935 of 26,697 oracle locks to apply in a fresh build. For maximal-lock
experiments, use PNR-only from the matching synth JSON.

Current known matching synth JSON:

```sh
artifacts/task6/calibration-sweeps/ypcb-rowstream-oracle-all-seed0/2026-05-14T08-03-04+0200-oracle-all-seed0/build-artifacts/ypcb_00338_1p1_uberddr3_rowstream_loader.json
```

Current full placement oracle:

```sh
artifacts/task6/lock-experiments/seed3-all-bel-locks.json
```

## Execution Plan

Current priority: implement the DDR3 driver contract even while calibration
work remains unstable. The driver must make the desired memory semantics clear
and testable, so calibration and placement work can be treated as the transport
problem underneath it rather than mixed into the API definition.

1. Align RTL PLL, DDR3 timing parameters, and nextpnr `addClock` constraints to
   the frozen-shell 500/125/200 MHz clocks.
2. Rebuild a rowstream bitstream from current RTL and test hardware with no
   global `--freq`.
3. If fresh synthesis is unstable, create a preserved shell artifact and use
   PNR-only for placement/timing experiments. This is now the active path:
   fresh synthesis with only the physical locks does not reproduce calibration.
4. Find the smallest lock set that both:
   - reaches `DONE_CALIBRATE`, `integrity_pass`, `ack_count` advances, `err_count=0`,
   - meets nextpnr timing without `--timing-allow-fail`.
5. The v45 fullbeat command path exists, but it must not replace the preserved
   v44 calibration base until a seed or lock set reaches `DONE_CALIBRATE`.
6. Next implementation direction: keep the v44 shell intact and move the
   additional fullbeat staging/producer logic outside the calibration-critical
   region, or create a new full placement oracle from a v45 seed that
   calibrates. A fresh fullbeat shell with only the 411 physical locks is not
   enough.
7. Only after the 64-byte contract is deterministic, add higher-level DDR3
   functionality outside the frozen shell.

Immediate next strategy:

1. Keep the v53 calibrating diagnostic shell as the hardware base while
   investigating the rowstream-to-Wishbone contract.
2. Add the smallest possible diagnostics to observe the controller-side
   accepted request: accepted `we`, `sel`, `addr`, low data bytes, and whether
   the ack being consumed belongs to the issued command.
3. Build those diagnostics as PNR-only seed sweeps from one synth JSON. Do not
   treat a new RTL result as meaningful until at least one seed reaches
   `DONE_CALIBRATE`.
4. Once the accepted-request trace proves the bad field, fix that field with
   the smallest RTL change and immediately hardware-test low-byte, dense-byte,
   and fullbeat paths.
5. After one seed passes fullbeat read/write, extract a matching placement
   oracle from that exact routed JSON before attempting any seed-stability work.

## Driver Contract

The host-side driver lives at:

```sh
scripts/task6/ypcb_ddr3_driver.py
```

It is the explicit software contract for the YPCB DDR3 rowstream shell. It
assumes the FPGA has already been programmed with a rowstream bitstream and
that the DDR3 shell is calibrated. Calibration is still mandatory for hardware
success, but the driver implementation is intentionally separated from the
calibration search.

Primary contract:

1. `write-beat --method fullbeat` writes one complete 64-byte DDR3 beat using
   four 128-bit chunk commands and all byte lanes active in the hardware path.
2. `read-beat` reads one complete 64-byte beat when the debug payload exposes
   the full 512-bit readback. Older shells expose only the first 128-bit window,
   which the driver reports without pretending it is a full pass.
3. `memtest64` writes a 64-byte pattern, reads it back, and compares all
   reported bytes.

Diagnostic-only contract:

`write-beat --method dense-byte` issues 64 one-hot dense byte writes. This mode
is useful for probing lanes and command decoding, but it is not the target DDR3
driver semantics for YPCB because the board path has no reliable byte-mask
foundation. A dense-byte memtest failure is expected on YPCB unless the design
is changed to perform read-modify-write internally or the board exposes working
DM pins.

Useful dry-run command encoding:

```sh
nix develop .#default --command python3 scripts/task6/ypcb_ddr3_driver.py \
  encode --opcode 0x01 --addr 0 --chunk 0 --data128 0x0

nix develop .#default --command python3 scripts/task6/ypcb_ddr3_driver.py \
  --dry-run memtest64 --addr 0 --pattern increment --write-method fullbeat
```

Hardware examples, after programming a calibrated bitstream:

```sh
nix develop .#default --command python3 scripts/task6/ypcb_ddr3_driver.py status

nix develop .#default --command python3 scripts/task6/ypcb_ddr3_driver.py \
  memtest64 --addr 0 --pattern increment --write-method fullbeat
```

## Acceptance Criteria

A candidate is not considered usable for further DDR3 work unless hardware
reports:

- decoded state `DONE_CALIBRATE`,
- `calibration=pass`,
- `command_gate=pass`,
- `integrity=pass`,
- `ack_count` advances,
- `err_count=0`,
- readback matches expected data.

For the next milestone, the same criteria must pass for the dense 64-byte
write/readback path, not only low-byte rowstream commands. On YPCB this means a
full-beat write/readback test, not a byte-enable test.

## Current Evidence

- Exact-400 MHz RTL and constraints were tested and failed before calibration,
  even when hard DDR3 primitives were locked.
- The 500/125 MHz frozen-shell clock point remains compliant with the AMD/Xilinx
  guidance because it is above the 400 MHz minimum.
- Fresh 500/125 MHz synthesis with the 437-lock physical oracle is not enough:
  seed 3 fails timing at 125 MHz without `--timing-allow-fail`, and the
  diagnostic `--timing-allow-fail` dense-byte build still fails before
  calibration starts.
- Fresh v64 fullbeat command RTL was hardware-tested in two forms:
  `ypcb-rowstream-fullbeat-seed-3-freq-25-timing-allow-fail` and
  `ypcb-rowstream-seed-3-freq-25-timing-allow-fail`. Both programmed
  successfully but reported `state=IDLE`, `calibration=fail`, and
  `ack_count=0`.
- Minimal v45 fullbeat rowstream RTL was committed and hardware-tested through a
  PNR-only seed sweep over `0, 3, 16, 40, 44`. All five bitstreams programmed
  successfully and all five reported `state=IDLE`, `calibration=fail`, and
  `ack_count=0`.
- The preserved seed-3 v44 artifact from
  `artifacts/task6/calibration-sweeps/ypcb-rowstream-ffx-addback-pnr-only-build/2026-05-14T10-21-35+0200-oracle-all-seed3/`
  still reports `DONE_CALIBRATE`, `calibration=pass`, and advancing `ack_count`
  on the same hardware.
- The known hardware-passing path is the PNR-only frozen artifact family derived
  from the matching synth JSON and extracted placement oracle. Further DDR3
  functionality must preserve that shell instead of relying on fresh synthesis.
- The v53 staged-data diagnostic proves host-to-FPGA rowstream packing is
  correct, but DDR3 user writes still do not stick. This is now the active
  functional blocker.
- The v54 command-pulse fix is logically attractive but is not yet a usable
  hardware base: seeds 0 and 3 both fail calibration in `READ_DATA`.
- All-cell BEL locks extracted from v53 are not portable across v54 synthesis:
  generated cell names changed too much, and the partial 9,266-lock application
  created an invalid/stalled placement.
- The v58 aux-contract fix restored the active rowstream wrapper to the
  controller contract: write commands use `i_aux[0]=0` and read commands use
  `i_aux[0]=1`. Hardware with seed 16 reached `DONE_CALIBRATE`, advanced
  `ack_count`, and passed the low-byte write/read smoke test.
- The v59 fullbeat staging fix latched the complete 512-bit write payload before
  issuing the final bus write. Hardware still failed `memtest64` fullbeat:
  commands were accepted, but readback remained calibration-pattern data. This
  proves the remaining issue is below host command packing.
- The v60 bounded controller BIST experiment enabled an internal all-lane BIST
  by setting `BIST_ADDR_BITS=8`. It did not reach `DONE_CALIBRATE`, which is
  useful evidence: the controller's own BIST catches the same full-lane failure
  that host `memtest64` sees.
- The default rowstream shell now keeps bounded BIST opt-in. With
  `BIST_ADDR_BITS=0`, the controller skips the post-calibration BIST and keeps
  the calibrated rowstream foothold usable for further hardware iteration.
- The v62 always-on WB2 debug attempt exposed the controller's second Wishbone
  debug path but broke calibration (`state=ISSUE_WRITE_1`, `ack_count=0`).
  Therefore WB2 debug is not part of the default shell.
- The v63 shell makes WB2/BIST debug build-time opt-in through
  `ENABLE_WB2_DEBUG` and `CONTROLLER_BIST_ADDR_BITS`. The default seed-16 v63
  bitstream reached `DONE_CALIBRATE` with `ack_count=9`; low-byte readback at
  address `0x40` returned `0x5a`; fullbeat `memtest64` still failed with
  calibration-pattern readback.

## WB2/BIST Diagnostic Variant

The default shell must keep `ENABLE_WB2_DEBUG=0` and
`CONTROLLER_BIST_ADDR_BITS=0` so it remains a calibrated foothold. For a
diagnostic build that intentionally runs bounded BIST and exposes the
controller's WB2 debug registers, synthesize the rowstream target with:

```sh
ROWSTREAM_SYNTH_PRELUDE="chparam -set ENABLE_WB2_DEBUG 1 ypcb_00338_1p1_uberddr3_rowstream_loader; chparam -set CONTROLLER_BIST_ADDR_BITS 8 ypcb_00338_1p1_uberddr3_rowstream_loader;"
```

Then query WB2 registers with:

```sh
python3 scripts/task6/ypcb_ddr3_driver.py --timeout 20 --command-repeats 2 debug-wb2 --addr 15
python3 scripts/task6/ypcb_ddr3_driver.py --timeout 20 --command-repeats 2 debug-wb2 --addr 16
```

Addresses `15` and `16` expose `correct_read_data` and `wrong_read_data`.
Additional controller debug words are available through the WB2 register map in
`rtl/ddr3_controller.v`.

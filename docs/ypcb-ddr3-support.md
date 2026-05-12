# YPCB DDR3 Hardware Bring-Up

This repo targets the YPCB-00338-1P1 channel-0 DDR3 interface with OpenXC7.
The first hardware milestone is the 64-bit non-ECC path. The board also has a
9th byte lane in the MIG metadata; that lane is intentionally left for a later
ECC/full-72-bit milestone.

## Execution Plan

The goal is a repeatable OpenXC7 hardware-in-the-loop flow that proves
UberDDR3 works on the connected YPCB board without relying on visual LED
inspection. Vivado may be used as an oracle, but only to extract facts that
make the open flow correct.

### Phase 1: Lock Down the Fast Loop

- Keep a single command for the main smoke test:
  `make -C example_demo/ypcb_00338_1p1 hil-smoke`.
- Build, program, read JTAG, decode the payload, and write a run artifact every
  time.
- Treat a valid JTAG magic/version, released reset, advancing counters, and
  `IDELAYCTRL` ready as the minimum board-access gate.
- Keep generated bitstreams and run logs under ignored artifact paths.

Acceptance gate: a fresh clone with the documented dev shell can run the smoke
test and produce a decoded JSON verdict from the board.

### Phase 2: Reproduce Known-Good Evidence

- Compare this repo's BIST RTL, DDR parameters, constraints, and build flags
  against the successful historical runs in `~/LLM2FPGA/artifacts/task6/runs/`.
- Rebuild the closest known-good source and confirm whether it still calibrates
  on the currently connected board.
- If the known-good build passes, reduce the difference set until the local repo
  matches the passing behavior.
- If the known-good build now fails, focus first on board setup, programming
  speed, reset timing, and power/clock assumptions.

Acceptance gate: either the local repo reaches the same passing calibration
signature as the historical run, or there is a written explanation for why the
historical evidence is no longer reproducible.

### Phase 3: Isolate Calibration Failure

The current failure signature is `state=12 READ_DATA`,
`debug1=0x000006cc`, `instruction=22`, `idelay_ready=true`, and
`calib_seen_cycle=0`.

Before changing the controller, check whether the board is populated with an
XC7K480T CES9937 engineering-sample part. AMD/Xilinx EN179 has two directly
relevant external-memory notes for these devices:

- DDR3/DDR2 Phaser divide-by-two mode is not operational from 303-399 MHz
  memory clock. A Vivado/MIG oracle build must select a 400 MHz or higher DDR3
  memory clock so the Phaser runs 1:1.
- DDR3 designs above 800 Mb/s must include external VREF. The current YPCB XDC
  sets SSTL15/DIFF_SSTL15 I/O standards but does not declare `INTERNAL_VREF`,
  so the bring-up must verify the board-level VREF wiring rather than assuming
  Vivado or OpenXC7 is supplying it.

The same errata also notes that `STARTUP_WAIT` is unsupported for MMCM/PLL
blocks and must be false. These are oracle facts to account for when comparing
Vivado/MIG behavior against the OpenXC7/UberDDR3 flow.

Debug in this order:

1. Clocking: verify the generated clock path, CK forwarding, phase assumptions,
   and all clock constraints used by nextpnr/OpenXC7.
2. Reset: verify reset polarity, release sequencing, and controller/PHY reset
   domain crossings.
3. DDR parameters: verify `MT41K256M8XX-125` timing, low-speed `DLL_OFF`
   assumptions, mode registers, burst length, and read latency.
4. Pin/byte-lane mapping: verify DQ/DQS lane order, DM handling, ODT, CKE, CS,
   VREF, IOSTANDARD, and termination against the YPCB constraints.
5. Delay path: verify `ODELAY_SUPPORTED`, IDELAY tap behavior, and whether
   OpenXC7 placement/routing is preserving the required I/O timing structure.
6. Silicon errata: verify whether the installed FPGA is an affected CES9937
   engineering sample, avoid Vivado/MIG settings that rely on the broken DDR3
   Phaser divide-by-two operating range, and verify external VREF before
   testing above 800 Mb/s.

Acceptance gate: calibration reaches `DONE_CALIBRATE` and the decoded payload
records a nonzero `calib_seen_cycle`.

### Phase 3A: Constrain Known-Good Placement

Known-good placement is part of the debug surface, not a last resort. Previous
YPCB work found passing seeds, including v40/v44-era designs. Use those passing
runs as placement oracles:

- Rebuild the passing source/seed and archive the post-route JSON/FASM/logs.
- Extract placements for PLL/MMCM, BUFG/BUFIO/BUFR, IDELAYCTRL, IODELAY,
  ISERDES, OSERDES, OBUFDS/IBUFDS, and the train-path IOSERDES cells.
- Convert stable placements into nextpnr-xilinx absolute constraints only after
  confirming they are not accidental seed artifacts.
- Run A/B HIL tests with and without each placement group so the constraint
  file records cause and effect.
- Keep board pin LOC constraints separate from experimental BEL placement
  constraints, so upstreamable board support is not mixed with seed-specific
  debug data.

There is upstream precedent for this. In AngeloJacobo/UberDDR3 commit
`19bfab3a6084d658274e46aa789b68036f73d7c3` from 2024-06-09, the Nexys Video
OpenXC7 example had `example_demo/nexys_video/constraints.py` and
`show_bels.py`. The linked files are gone from current `main`, but that commit
matches the issue-comment timeframe. Its OpenXC7 Makefile invoked nextpnr with:

```sh
nextpnr-xilinx ... --pre-place constraints.py --pre-route show_bels.py ...
```

The historical `constraints.py` manually placed the train-path
`ISERDESE2_train` and `OSERDESE2_train` cells using `setAttr('BEL', ...)`.
The comment in that script says nextpnr would otherwise choose a location with
missing prjxray PIPs on `_SING` tiles, so the workaround moved those cells to a
non-SING tile. That is directly relevant to YPCB because a calibration failure
at `READ_DATA` can be caused by legal-looking but electrically/timing-bad I/O
placement.

Acceptance gate: a placement-constraint experiment either reproduces a known
passing calibration signature, or produces a written negative result showing
that IOSERDES/BEL placement is not the current blocker.

### Phase 3B: Evolutionary Calibration-Consistency Sweep

Calibration consistency is the immediate engineering target. Treat the passing
v40/v44-era placement as an empirical oracle, then mutate seeds and shrink the
absolute constraints until the minimum useful lock set is clear.

The current v40 lock oracle contains 437 packed-cell BEL locks:

| Scope | Locks | Purpose |
| --- | ---: | --- |
| `ddr3_clocks` | 5 | PLL and global clock spine stability |
| `ddr3_board_pins` | 25 | board-level DDR3 address/control/pin output buffers |
| `uberddr3_phy` | 407 | IDELAY, IDELAYCTRL, ISERDES, OSERDES, I/O buffers, and PHY-local cells |

Run the sweep in layers:

| Lock set | Generator scopes | Question |
| --- | --- | --- |
| `none` | none | How often does unconstrained nextpnr calibrate? |
| `clocks` | `ddr3_clocks` | Are clocking placements sufficient? |
| `phy` | `uberddr3_phy` | Is the PHY by itself the stabilizer? |
| `clocks-phy` | `ddr3_clocks`, `uberddr3_phy` | Current practical baseline, excluding board-pin locks |
| `full` | all scopes | Can the captured placement make seed mostly irrelevant? |

For each `(source commit, seed, lock set)` row, record:

| Field | Meaning |
| --- | --- |
| `source_commit` | exact Git commit under test |
| `seed` | nextpnr seed mutation |
| `lock_set` | named lock-set label above |
| `lock_scopes` | scopes passed to the lock generator |
| `applied_locks`, `missing_locks` | parsed from nextpnr pre-place output |
| `build_status` | bitstream build success/failure |
| `program_status` | OpenOCD/openFPGALoader success/failure |
| `calib_seen`, `calib_complete`, `state`, `debug1` | decoded DDR3 calibration signature |
| `loader_ready`, `ack_count`, `err_count` | wrapper/probe readiness and liveness |
| `bitstream_sha256` | artifact identity |
| `notes` | manual classification such as `boot-clean`, `stuck-state-1`, or `route-fail` |

Promotion rules:

- A lock set is only useful if the same bitstream passes repeated
  program/calibration cycles.
- A seed-stable lock set must pass across a seed sweep, not just one lucky
  build.
- Prefer the smallest lock set with a high pass rate. If `full` passes but
  `clocks-phy` fails, shrink within `uberddr3_phy` by type next
  (`IDELAYCTRL`, `IDELAYE2`, `ISERDESE2`, `OSERDESE2`, I/O buffers).
- Do not mix board LOC constraints and experimental BEL constraints in an
  upstream patch. The sweep output should justify each group independently.

The first automation target is a CSV/Markdown table generator that can build a
single row, program the board, poll JTAG, and append a machine-readable JSONL
record. Once one-row execution is reliable, sweep seeds `0..31` for
`full`, `clocks-phy`, `phy`, `clocks`, and `none`.

Initial calibration-sweep record:

| Date | Source commit | Seed | Lock set | Build | Program | Calib seen | Calib complete | Loader ready | State | Ack | Err | Notes |
| --- | --- | ---: | --- | --- | --- | --- | --- | --- | ---: | ---: | ---: | --- |
| 2026-05-12 | `dea36618` | 16 | `full` metadata, supplied v44 control bitstream | supplied | pass | true | true | true | 23 | 9 | 0 | `debug1=0x000006d7`, `DONE_CALIBRATE`; table artifacts in `artifacts/task6/calibration-sweeps/ypcb-rowstream-calibration/` |
| 2026-05-12 | `26abee0` | 16 | `full` generated locks | built | pass | true | true | true | 23 | 9 | 0 | `debug1=0x000006d7`, bitstream `f95e20be...`; 411 locks applied, 25 packed board-pin locks recorded as missing |
| 2026-05-12 | `dbfae28` | 0 | `full` generated locks | built | pass | false | false | true | 12 | 0 | 0 | `debug1=0x000006cc`, bitstream `017c7ccd...`; first seed mutation failed calibration, so the full lock set is not yet sufficient |
| 2026-05-12 | `4291544` | 40 | `full` generated locks | built | pass | true | true | true | 23 | 9 | 0 | `debug1=0x000006d7`, bitstream `4dd36aa2...`; seed 40 passes, matching the v40/v44 empirical signal |
| 2026-05-13 | `9e3a7eb` | 0 | `full` + `ddr3_idelayctrl_soft` | built | pass | false | false | true | 12 | 0 | 0 | `debug1=0x000006cc`, bitstream `e00fc0db...`; locking only the two IDELAYCTRL RDY LUTs does not fix seed 0 |
| 2026-05-13 | `32d18b5` | 0 | `full` + `ddr3_controller_soft` | built | pass | true | true | true | 23 | 9 | 0 | `debug1=0x000006d7`, bitstream `e2ae478b...`; first positive result for seed 0, 626 locks applied |
| 2026-05-13 | `3b22acd` | 1 | `full` + `ddr3_controller_soft` | built | pass | false | false | true | 12 | 0 | 0 | `debug1=0x000026cc`, bitstream `b8664062...`; controller soft locks alone are not seed-stable |
| 2026-05-13 | `76d05d1` | 1 | `full` + all `uberddr3` soft locks | built | pass | false | false | true | 9 | 0 | 0 | `debug1=0x000006c9`, bitstream `a571580c...`; broader seed-16 soft locking still does not fix seed 1 |
| 2026-05-13 | `635934c` | 1 | `full` + `ddr3_controller_soft`, nextpnr `--freq 50` | built | pass | true | true | true | 23 | 9 | 0 | `debug1=0x000006d7`, bitstream `3750b5d1...`; timing-pressure knob rescues seed 1 |

Routed placement comparison:

To compare the passing seed-16/seed-40 placements against failing seed 0,
build-only sweep rows were regenerated at `2f40194` with nextpnr `--write`
enabled. The comparison command was:

```sh
python3 scripts/task6/compare_routed_placements.py \
  --seed-json 16:artifacts/task6/calibration-sweeps/ypcb-placement-compare-routed/2026-05-13T00-02-01+0200-full-seed16/build-artifacts/nextpnr-routed.json \
  --seed-json 40:artifacts/task6/calibration-sweeps/ypcb-placement-compare-routed/2026-05-13T00-08-16+0200-full-seed40/build-artifacts/nextpnr-routed.json \
  --seed-json 0:artifacts/task6/calibration-sweeps/ypcb-placement-compare-routed/2026-05-13T00-14-34+0200-full-seed0/build-artifacts/nextpnr-routed.json \
  --pass-seed 16 --pass-seed 40 --fail-seed 0
```

The key result is that the high-risk DDR3 physical primitives are not the
remaining seed-sensitive group. Across all three seeds, the following placements
are identical: 3/3 `IDELAYCTRL`, 72/72 `IDELAYE2`, 72/72 `ISERDESE2`, 97/97
`OSERDESE2`, 109/109 `PAD`, 181/181 DDR3 input/output buffer cells, and the
single PLL. Four of seven `BUFGCTRL` cells are identical across all seeds; the
three moving BUFGs are the auto-inserted JTAG `drck`/`tck` buffers, not
`ddr3_clk`, `ddr3_clk_90`, `ref_clk`, or `controller_clk`.

No DDR3 controller, DDR3 PHY, JTAG, or `uberddr3`-named soft-logic cell has the
pattern "seed 16 and seed 40 agree, seed 0 differs". The only pass-consensus
versus fail-different cells are 245 unrelated soft-logic cells
(`SLICE_LUTX`/`SLICE_FFX`/`SELMUX2_1`/`CARRY4`). The DDR3 controller soft logic
moves in all three seeds, and seed 0 also places the general soft logic in a
much shorter Y range than the passing seed-40 build.

Working conclusion: locking more IDELAY/IOSERDES/PAD resources is unlikely to
fix seed 0. The first follow-up experiment confirmed that locking only the small
`ddr3_phy_inst.IDELAYCTRL_inst` RDY combine LUTs still failed with the same
state-12 signature. The broader `ddr3_controller_soft` scope made seed 0 pass,
so the reliability work should now shrink that scope toward the minimum
calibration/control subset while sweeping additional seeds. Keep this
experimental lock group separate from the upstreamable board LOC and PHY
primitive constraints.

### Phase 4: Prove Memory Access

- Run a deterministic low-byte write/read command through the JTAG command
  register.
- Require ACK liveness, no Wishbone errors, and expected read data.
- Expand from a single byte probe to short walking-bit and address-pattern
  probes once the low-byte path is stable.
- Only after the 64-bit channel is reliable, add ECC/full-72-bit coverage.

Acceptance gate: the BIST verdict passes calibration, command liveness, and
data integrity checks on repeated runs.

### Phase 5: Make Patches Upstreamable

Every tooling or database fix must stay small enough to upstream separately:

- prjxray-db fixes carry source/origin notes and target the missing feature
  only.
- openFPGALoader fixes add the `xc7k480t` IDCODE without depending on this repo.
- nextpnr/OpenXC7 fixes include a minimized reproducer or clear device rule.
- UberDDR3 changes keep the YPCB board support, BIST harness, and docs separate
  from generic controller changes.

Acceptance gate: local changes can be split into reviewable commits with clear
ownership and no generated artifacts.

## Fast Hardware Loop

Enter the dev shell, build the JTAG-readable BIST bitstream, program the board,
and read back a decoded verdict:

```sh
nix develop
make -C example_demo/ypcb_00338_1p1 hil-smoke
```

The flow uses OpenOCD for programming because the connected `xc7k480t` reports
IDCODE `0x23751093`, which is accepted by OpenOCD's `xilinx-xc7.cfg` but is not
currently recognized by the installed `openFPGALoader`.

The current passing hardware integrity target is the BIST-derived 64-address
low-byte stream:

```sh
nix develop --command make -C example_demo/ypcb_00338_1p1 \
  hil-lowbyte-stream-v40-locked \
  SYNTH_XILINX_FLAGS="-flatten -family xc7"
```

This builds with the v40 physical lock oracle, programs through OpenOCD, and
runs `scripts/task6/validate_uberddr3_lowbyte_stream.py`.

The equivalent explicit programming command is:

```sh
openocd \
  -f interface/ftdi/digilent_jtag_hs3.cfg \
  -c "adapter serial 210299BF3824" \
  -f cpld/xilinx-xc7.cfg \
  -c "adapter speed 6000" \
  -c "init" \
  -c "pld load 0 example_demo/ypcb_00338_1p1/ypcb_00338_1p1_uberddr3_bist_openxc7.bit" \
  -c "exit"
```

Run directories are written under `artifacts/task6/runs/`, with board verdicts
in `verdict.json` and decoded JTAG readback in `readback/decoded-tdo7.json`.
These are generated artifacts and should not be committed.

## Diagnostic Bitstream

`ypcb_00338_1p1_uberddr3_bist` wraps the reusable
`task6_ypcb_uberddr3_bist_top` diagnostic RTL behind the current YPCB example
pin names. The diagnostic path exposes a BSCANE2 USER1 readback payload and a
USER2 command register, so pass/fail does not depend on LEDs.

The decoded payload reports:

- JTAG magic/version.
- reset, PLL lock, clock counter, and cycle counter.
- `calib_complete`, `calib_seen`, and `calib_seen_cycle`.
- UberDDR3 `debug1`, including calibration state.
- Wishbone ACK/error/stall counters.
- deterministic write/read probe state and observed data.

The initial acceptance target is:

- JTAG magic/version decode succeeds.
- reset is released and the clock counter advances.
- calibration is seen and reaches `DONE_CALIBRATE`.
- the write/read probe sees ACKs and no Wishbone errors.
- the observed low byte matches the requested byte.

## Current Hardware Observation

The HIL path is confirmed working: OpenOCD programs the board, USER1/USER2 JTAG
readback and command writes work, reset is released, counters advance, and
`IDELAYCTRL` reports ready.

As of 2026-05-12, the local repo reproduces the known-good BIST-derived DDR3
integrity result on the connected board:

```text
target: hil-lowbyte-stream-v40-locked
rtl: fpga/rtl/ypcb_uberddr3_bist_top.sv
debug version: 32
synthesis: SYNTH_XILINX_FLAGS="-flatten -family xc7"
physical constraints: v40 clock/PHY BEL lock oracle, applied=411 missing=0
programmer: OpenOCD, Digilent HS3 serial 210299BF3824
result: PASS
windows: 16
bases: 0, 4, 8, ..., 60
valid mask: 0xf for every window
mismatch mask: 0x0 for every window
Wishbone errors: 0
calibration: complete and seen
```

The final validator window read back `0xe1,0xe2,0xe3,0xe4` at stream base 60,
matching the expected pattern. The JSON artifact is written to
`artifacts/task6/ypcb-uberddr3-lowbyte-stream-v40-locked-latest.json`.

The rowstream-loader experiment is not yet the passing DDR3 acceptance target.
An exact v44 rowstream-loader reconstruction builds and reaches a boot-clean
calibrated state, but its host dense/low-byte loader commands still fail data
integrity:

```text
v44 boot-only: PASS, calib_seen=True, state=1, err=0
v44 dense 16-byte diagnostic: FAIL, 13/16 mismatches
v44 low-byte diagnostic: FAIL, 15/16 mismatches
v44 low-byte after write-drain and sel[0] fixes: FAIL, 16/16 mismatches
```

The post-fix rowstream low-byte readback returns the calibrated BIST boot
pattern rather than the commanded `0x00..0x0f` pattern. ACKs and errors remain
clean. That points at the rowstream command read/write contract or read-pipeline
semantics, not DDR3 calibration or board access. The calibrated BIST-derived
DDR3 path is therefore the stable acceptance baseline, while rowstream/dense
packing remains the next debug surface.

### Rowstream Read/Write Contract

The rowstream loader exposes byte addresses to the host, but the low-byte DDR3
read path has a one-command read-ahead semantic. A clean control bitstream was
able to read the boot pattern correctly only when the host issued
`OP_READ_LOWBYTE` at `stream_addr + 1` while reporting the public byte address
as `stream_addr`.

The remaining contract fix should be symmetric for low-byte writes: the host
API should keep public byte address `N`, but issue both `OP_WRITE_LOWBYTE` and
`OP_READ_LOWBYTE` to the controller at `N + 1`. The attempted RTL-side
write-hold fix, including a registered loader-bus hold through
`LOADER_WRITE_DRAIN`, built and routed but repeatedly broke DDR3 calibration on
the YPCB board (`calib_seen=False`, `state=1`) with seeds 16 and 40. That makes
it the wrong upstreamable fix: it perturbs an already fragile calibrated
placement and does not address the observed one-address command pipeline.

Until the host loader is patched, rowstream diagnostics must be interpreted as
controller-issue-address tests, not public byte-address tests. The next HIL
gate is to patch the LLM2FPGA rowstream loader so `write_lowbyte()` and
`read_lowbyte()` both issue `stream_addr + 1`, then rerun the low-byte
diagnostic on the known-calibrating v40/v44 physical-lock bitstream.

## Development Strategy

Keep OpenXC7 as the acceptance toolchain. If the BIST flow regresses, compare
against known-good prior hardware evidence before changing the DDR controller:

1. Clock source and constraints: 50 MHz `AA28` versus MIG's differential
   200 MHz `AH27/AH28` reference.
2. Reset polarity and reset release timing.
3. DDR3 pin grouping, byte-lane ordering, VREF, IOSTANDARD, and termination.
4. Memory parameters for `MT41K256M8XX-125`.
5. XC7K480T CES9937 errata impact: no MIG Phaser divide-by-two mode at
   303-399 MHz, external VREF required above 800 Mb/s, and MMCM/PLL
   `STARTUP_WAIT` must be false.
6. `ODELAY_SUPPORTED` behavior and any required nextpnr/OpenXC7 patches.

Vivado Enterprise can be useful as a temporary oracle through AMD's 30-day
evaluation license, but it is not the production flow. If used, extract reports
and checkpoints rather than treating the proprietary bitstream as the result:

- `report_io`
- `report_drc`
- `report_timing_summary`
- `report_clock_utilization`
- post-route `.dcp` queries for IOB, IDELAY, ODELAY, ISERDES, OSERDES, BUFIO,
  BUFR, BUFG, and IDELAYCTRL placement/properties

Use any findings to make the OpenXC7 flow correct and upstreamable.

Relevant AMD/Xilinx references:

- EN179, Kintex-7 FPGA XC7K480T CES9937 Errata:
  <https://docs.amd.com/api/khub/documents/bFOej1CxDOaUQtExyJBpYw/content>

## Upstream Patch Queue

Keep local patches small and ready to split out:

- prjxray-db: missing Kintex-7 `LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1`
  feature and origin metadata.
- openFPGALoader: add `xc7k480t` IDCODE support for this board.
- nextpnr-xilinx/openXC7: ODELAY/HR output-buffer fixes if required for the
  final DDR PHY.
- UberDDR3: YPCB example, JTAG-readable BIST wrapper, and HIL documentation.

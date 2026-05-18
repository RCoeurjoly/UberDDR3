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
  memory clock. The active YPCB BIST/rowstream RTL therefore uses a 500 MHz
  DDR3 clock with a 125 MHz controller clock so the Phaser runs 1:1.
- DDR3 designs above 800 Mb/s must include external VREF. The current YPCB XDC
  sets SSTL15/DIFF_SSTL15 I/O standards but does not declare `INTERNAL_VREF`,
  so the bring-up must verify the board-level VREF wiring rather than assuming
  Vivado or OpenXC7 is supplying it.

The same errata also notes that `STARTUP_WAIT` is unsupported for MMCM/PLL
blocks and must be false. These are oracle facts to account for when comparing
Vivado/MIG behavior against the OpenXC7/UberDDR3 flow.

#### UberDDR3 OpenXC7 333 MHz Experiment

The EN179 303-399 MHz warning is specific to the Kintex-7 DDR3/DDR2 PHASER
divide-by-two path used by MIG. The active OpenXC7 UberDDR3 YPCB path does not
instantiate PHASER blocks; it uses the UberDDR3 no-PHASER PHY with fabric
clocking, IDELAY/ISERDES/OSERDES primitives, and `ODELAY_SUPPORTED=0` for the
YPCB HR-bank pinout. That means the PHASER divide-by-two erratum is not a
direct ban on testing UberDDR3 at 333.333 MHz, although any result still has to
be proven on hardware.

Angelo's Kintex-7 OpenXC7 demos provide the current positive evidence for this
class of no-PHASER UberDDR3 build: 333.333 MHz DDR3, 83.333333 MHz controller,
200 MHz reference clock, `CONTROLLER_CLK_PERIOD=12_000`,
`DDR3_CLK_PERIOD=3_000`, `DLL_OFF=0`, and `ODELAY_SUPPORTED=0`. The first YPCB
experiment now mirrors that profile as `openxc7-333`, because it stays below
the previously brittle 400 MHz YPCB path while preserving DLL-on high-speed
calibration.

Debug in this order:

1. Clocking: verify the generated clock path, CK forwarding, phase assumptions,
   and all clock constraints used by nextpnr/OpenXC7.
2. Reset: verify reset polarity, release sequencing, and controller/PHY reset
   domain crossings.
3. DDR parameters: verify `MT41K256M8XX-125` timing, `DLL_OFF=0`, mode
   registers, burst length, and read latency.
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
| 2026-05-13 | `6070b7a` | 0 | `full` + `ddr3_controller_soft`, nextpnr `--freq 50` | built | pass | false | false | true | 12 | 0 | 0 | `debug1=0x000006cc`, bitstream `9eba3b18...`; freq 50 is not a global recipe, seed 0 regresses |
| 2026-05-13 | `284da13` | 1 | `full` + `ddr3_controller_soft`, nextpnr `--placer sa` | build-failed | - | - | - | - | - | - | - | SA placer failed post-placement validity after ~700s: `SLICE_X62Y397/A5FF` no-cell BEL |
| 2026-05-13 | `ea37382` | 1 | `full` + `ddr3_controller_soft`, nextpnr `--router router1` | built | pass | false | false | true | 9 | 0 | 0 | `debug1=0x000006c9`, bitstream `eb33d8f6...`; router1 does not fix seed 1 |
| 2026-05-13 | `8fc18f4` | 0 | `full` + `ddr3_controller_soft` from seed-1/freq-50 oracle | built | pass | true | true | true | 23 | 9 | 0 | `debug1=0x000006d7`, bitstream `db20b583...`; candidate soft-placement oracle passes seed 0 at default freq |
| 2026-05-13 | `8fc18f4` | 1 | `full` + `ddr3_controller_soft` from seed-1/freq-50 oracle | built | pass | true | true | true | 23 | 9 | 0 | `debug1=0x000006d7`, bitstream `90c65550...`; candidate soft-placement oracle also passes seed 1 at default freq |
| 2026-05-13 | `c2f7703` | 2 | `full` + `ddr3_controller_soft` from seed-1/freq-50 oracle | built | pass | false | false | true | 12 | 0 | 0 | `debug1=0x000026cc`, bitstream `b6a0f433...`; seed 2 still fails, so this oracle is not yet a complete stability recipe |
| 2026-05-13 | `275166c` | 2 | `full` + root-only constrained-cluster oracle from seed-1/freq-50 | build-failed | - | - | - | - | - | - | - | 445 locks applied; heap placer aborts with `unordered_map::at` after placing 584 constrained cells |
| 2026-05-13 | `275166c` | 2 | `full` + all constrained-cluster oracle from seed-1/freq-50 | build-failed | - | - | - | - | - | - | - | 1014 locks applied; heap placer aborts with `map::at` after placing 1153 constrained cells |
| 2026-05-13 | `6728592` | 2 | `full` + root-only constrained-cluster oracle from seed-1/freq-50, nextpnr `--placer sa` | build-failed | - | - | - | - | - | - | - | 445 locks applied; SA runs ~680s then fails post-placement validity at `SLICE_X58Y395/A5FF` |
| 2026-05-13 | `f5eb48e` | 2 | `full` + `ddr3_controller_soft` from seed-1/freq-50 oracle, nextpnr `--freq 50` | built | pass | false | false | true | 12 | 0 | 0 | `debug1=0x000006cc`, bitstream `fda76e0b...`; freq 50 does not rescue seed 2 |
| 2026-05-13 | `e87dec3` | 2 | `full` + one constrained CARRY root from seed-1/freq-50 oracle | build-failed | - | - | - | - | - | - | - | 412 locks applied; one `CARRY4` root (`SLICE_X20Y100/CARRY4`) is enough to trigger heap placer `unordered_map::at` |
| 2026-05-13 | `5e8a3a1` | 2 | `full` + `ddr3_controller_soft` from seed-1/freq-50 oracle, nextpnr `--router router1` | built | pass | false | false | true | 24 | 0 | 0 | `debug1=0x000006d8`, bitstream `30b73711...`; router1 changes the failure state but does not calibrate |
| 2026-05-13 | `da776a7` | 2 | `full` + `ddr3_controller_soft` from seed-1/freq-50 oracle, nextpnr `--freq 50 --router router1` | built | pass | false | false | true | 12 | 0 | 0 | `debug1=0x000006cc`, bitstream `262888f3...`; combined router/timing knob still misses |
| 2026-05-13 | `914058e` | 3 | `full` + `ddr3_controller_soft` from seed-1/freq-50 oracle | built | pass | true | true | true | 23 | 9 | 0 | `debug1=0x000006d7`, bitstream `1c143204...`; seed 3 passes, so seed 2 is not representative of the whole neighborhood |
| 2026-05-13 | `ca2ef87` | 4 | `full` + `ddr3_controller_soft` from seed-1/freq-50 oracle | built | pass | false | false | true | 12 | 0 | 0 | `debug1=0x000026cc`, bitstream `3d6f90e8...`; seed 4 misses like seed 2 |
| 2026-05-13 | `6aa1d9a` | 5 | `full` + `ddr3_controller_soft` from seed-1/freq-50 oracle | built | pass | false | false | true | 12 | 0 | 0 | `debug1=0x000026cc`, bitstream `e9466ea0...`; sampled pass rate is 3/6 for seeds 0..5 |

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

Current execution split:

- Move functional rowstream work forward with a seed-pinned calibrating
  artifact. The best buildable rowstream recipe currently calibrates with seeds
  0, 1, and 3, and misses with seeds 2, 4, and 5. Seed 3 is the working
  functional candidate because it calibrated immediately with
  `debug1=0x000006d7`, state 23, and nine ACKs.
- **Interim policy (important):** rowstream currently uses a pinned seed-3 work
  path and is considered brittle. Other sampled seeds are not equivalent yet, so
  we must label this as a provisional single-seed baseline until a
  seed-stable variant is proven.
- Treat calibration consistency as a separate nextpnr/constraint problem. The
  constrained-cluster extractor can identify CARRY roots, but even one
  user-constrained CARRY4 root (`SLICE_X20Y100/CARRY4`) plus the hard DDR3 lock
  set triggers a nextpnr heap placer `unordered_map::at` abort. That is now a
  minimized nextpnr-xilinx bug signal, not a blocker for proving rowstream
  function on a known-calibrating seed.
- The immediate HIL loop is: repeatedly program the seed-3 rowstream artifact
  to confirm artifact-level calibration stability, then run rowstream
  read/write diagnostics against that artifact. In parallel, reduce the
  single-CARRY-root crash to a standalone nextpnr repro with a debug backtrace
  and patch nextpnr only after the failure site is clear.

## Interim Seed-Pinned Baseline

- `seed=3` is the current rowstream baseline for progress.
- `full-controller-soft` with existing v40/v44 physical lock sets is still the
  fastest reproducible rowstream path.
- This is explicitly **not** "any-seed stable" and must stay marked as
  brittle in commit notes, artifacts, and test tables.
- Run command contract checks against this artifact with:
  - `--rowstream-lowbyte-addr-offset 1`
  - `--rowstream-readback-after-write`
  - `--rowstream-poll-timeout 4`
  - `--rowstream-min-ack-delta 1`
- Followed-by detailed run plan is in [docs/seed-stability-plan.md](docs/seed-stability-plan.md).

Progress plan from this point:

1. Keep repeating seed-3 rowstream HIL runs to validate artifact stability.
2. Run targeted seed sweeps (`2..5` then `0..31`) on the same lock set, using
   `scripts/task6/task6_calibration_sweep.py`, and append outcomes to
   `artifacts/task6/calibration-sweeps/ypcb-rowstream-calibration/results.jsonl`.
3. Minimize constraints only after we have a seed-agnostic candidate to avoid baking in seed-specific placement debt.

## Seed-stability Matrix (current priority)

Use this matrix run command for deterministic seed exploration:

```sh
# Build scoped lock variants from an extracted soft BEL payload:
python3 scripts/task6/task6_lock_subset_generator.py \
  --locks-json artifacts/task6/baselines/ypcb-controller-soft-locks.json \
  --out-dir artifacts/task6/lock-subsets/<timestamp> \
  --split-by-scope --split-by-type

python3 scripts/task6/task6_seed_stability_matrix.py \
  --sweep ypcb-rowstream-seed-stability \
  --seeds 0-5 \
  --lock-sets full-controller-soft,full,clocks-phy,phy,none \
  --freqs 25,50 \
  --pnr-extra-args "" \
  --pnr-extra-args "--no-tmdriv" \
  --extra-locks-manifest artifacts/task6/lock-subsets/<timestamp>/task6-lock-variants.json \
  --build-only
```

Outputs:

- `artifacts/task6/calibration-sweeps/ypcb-rowstream-seed-stability/results.jsonl`
- `artifacts/task6/calibration-sweeps/ypcb-rowstream-seed-stability/stability-scorecard.md`

Pass criteria for each row:

- `build_status == "built"`
- `program_status == "pass"` (unless `--build-only`)
- `calib_seen == true`
- `calib_complete == true`
- `state == 23` (`DONE_CALIBRATE`)
- `loader_ready == true`
- `err_count == 0`
- `ack_count > 0`

When comparing candidates, choose the lowest-cost tuple that:

1. is fully stable across the tested seed set.
2. keeps seed3 pass as a monotonic baseline check.
3. minimizes added knobs/constraints: start with timing knobs (`--no-tmdriv`, freq),
   then shrink lock scope (`full-controller-soft` -> `clocks-phy` -> `phy` ->
   `none`).

Keep each candidate’s summary row in the scorecard and mark the chosen default in
the source tree only after it clears the full seed range target.

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

Build the seed-specific rowstream bitstream as a flake derivation (defaults to a
reproducible pinned `seed=3` build if you use `.#default`):

```sh
nix build .#ypcb-rowstream-seed-3-freq-25
cp result/rowstream_seed3_freq25.bit /tmp/rowstream_seed3.bit
```

To build another tracked seed explicitly:

```sh
nix build .#ypcb-rowstream-seed-16-freq-25
```

Supported seed packages are currently:
`ypcb-rowstream-seed-0-freq-25`, `ypcb-rowstream-seed-3-freq-25`,
`ypcb-rowstream-seed-16-freq-25`, `ypcb-rowstream-seed-40-freq-25`,
`ypcb-rowstream-seed-44-freq-25`.

Program the artifact with OpenOCD and read back a verdict:

```sh
openFPGALoader -c digilent_hs3 --ftdi-serial 210299BF3824 \
  /tmp/rowstream_seed3.bit
```

or (current OpenOCD-compatible flow):

```sh
openocd \
  -f interface/ftdi/digilent_jtag_hs3.cfg \
  -c "adapter serial 210299BF3824" \
  -f cpld/xilinx-xc7.cfg \
  -c "adapter speed 6000" \
  -c "init" \
  -c "pld load 0 result/rowstream_seed3_freq25.bit" \
  -c "exit"
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

As of 2026-05-13, the local repo reproduces the known-good BIST-derived DDR3
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

The 2026-05-13 revalidation again passed all 16 windows. The final validator
window read back `0xe1,0xe2,0xe3,0xe4` at stream base 60,
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

## Active Rowstream Execution Plan

Current priority is to finish the host-side rowstream contract validation and use
it as the control path for seed/placement experiments.

1. Use a known-calibrating rowstream control bitstream (currently the seed-3 rowstream
   artifact from the v40/v44 lock family) as the baseline.
2. Run deterministic host-command loops using:
   - `--command-protocol rowstream192`
   - `--rowstream-lowbyte-addr-offset 1`
   - `--rowstream-readback-after-write`
   - `--rowstream-poll-timeout 4`
   - `--rowstream-min-ack-delta 1`
3. For each run, capture:
   - `decoded.loader_state`
   - `decoded.loader_ready`
   - `decoded.ack_count`
   - `decoded.loader_error`
   - `decoded.read_byte`
   - `decoded.command_count`
   - `decoded.active_addr`
4. Compare passing seed-16/seed-40/seed-0 artifacts using BEL locks and lock
   deltas; keep the table in `artifacts/task6/calibration-sweeps/ypcb-rowstream-calibration`
   as the migration point if seed-0 remains the outlier.
5. If rowstream low-byte readback still returns boot data with clean acks, treat
   it as remaining command contract or rowstream-state semantics and do not touch
   BIST calibration-path timing until the contract is resolved.

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

## PHASER Open-Flow Status

The Vivado MIG oracle proves that the YPCB channel-0 DDR3 implementation uses
Kintex-7 PHASER hard macros, not only IDELAY/ISERDES/OSERDES soft-facing I/O
primitives. The open-flow support is now split into explicit gates:

| Gate | Status | Evidence |
| --- | --- | --- |
| Vivado placement extraction | pass | `scripts/task6/extract_ypcb_phaser_oracle.py` extracts `PHASER_IN_PHY`, `PHASER_OUT_PHY`, `PHASER_REF`, `PHY_CONTROL`, `IN_FIFO`, and `OUT_FIFO` placements from `artifacts/task6/vivado-oracle/ypcb-systest/implemented.xdc`. |
| Yosys primitive preservation | pass | The YPCB `phaser-smoke` target instantiates PHASER/FIFO/PHY_CONTROL primitives and `synth_xilinx` preserves them. |
| nextpnr chipdb visibility | locally patched | `/home/roland/nextpnr-xilinx` commit `a92b97e2` adds a prjxray `site_type_*.json` fallback so hard-macro sites missing from `nextpnr-xilinx-meta` become BELs. |
| nextpnr place/route smoke | pass with patched chipdb | `make -C example_demo/ypcb_00338_1p1 phaser-smoke CHIPDB=/tmp/xc7k480tffg1156-phaser4.bin NEXTPNR_XILINX_PYTHON_DIR=/home/roland/nextpnr-xilinx/xilinx/python` builds `ypcb_phaser_smoke_openxc7.bit`. |
| PHASER bitstream feature emission | not proven | The generated `ypcb_phaser_smoke.fasm` contains no `PHASER`, `PHY_CONTROL`, `IN_FIFO`, or `OUT_FIFO` feature lines. The pinned prjxray-db exposes site pins for these sites, but no obvious PHASER/FIFO/PHY_CONTROL `segbits` entries were found. |

This means PHASER support is no longer blocked at synthesis or placement. The
remaining hard blocker is configuration semantics: we need to know which FASM
features program the PHASER/FIFO/PHY_CONTROL hard macros and how those features
map to primitive parameters.

The next upstreamable work item is a minimal PHASER bitstream oracle:

1. Build two tiny Vivado designs that differ by one PHASER/FIFO/PHY_CONTROL
   parameter or by one hard macro instance.
2. Convert both bitstreams to frames and compare frame deltas.
3. Name each discovered bit using the same FASM convention expected by
   prjxray-db.
4. Add the feature rows to the database or add a nextpnr FASM emitter only when
   the database already has stable feature names.
5. Extend `phaser-smoke` from disconnected hard-macro preservation to connected
   PHY-control routing only after those features are encodable.

Do not treat the current PHASER smoke bitstream as a working DDR3 PHY. It is a
toolchain support regression test: hard macro instances survive Yosys, appear in
the chipdb, can be BEL-locked to Vivado-oracle sites, and do not crash nextpnr
PNR or bitstream generation.

### PHASER Feature-Delta Oracle

The first minimal Vivado bitstream oracle is now in place:

- `scripts/task6/ypcb_phaser_feature_oracle.tcl` generates tiny Vivado designs
  for PHASER/FIFO/PHY_CONTROL feature discovery.
- `scripts/task6/run_ypcb_phaser_feature_oracle.sh <variant>` runs the oracle
  under Vivado 2025.2.1.
- `scripts/task6/summarize_bitstream_feature_delta.py` summarizes `bitread`
  `.bits` files, decoded FASM unknowns, and pairwise frame deltas.

Two initial variants were built:

```sh
scripts/task6/run_ypcb_phaser_feature_oracle.sh none
scripts/task6/run_ypcb_phaser_feature_oracle.sh phaser_ref
```

Artifacts:

- `artifacts/task6/phaser-feature-oracle/vivado-mini/none/top_none.bit`
- `artifacts/task6/phaser-feature-oracle/vivado-mini/phaser_ref/top_phaser_ref.bit`
- `artifacts/task6/phaser-feature-oracle/vivado-mini/none-vs-phaser_ref.delta.json`
- `artifacts/task6/phaser-feature-oracle/vivado-mini/phaser_ref/top_phaser_ref.verbose.fasm`

The `phaser_ref` run preserved one `PHASER_REF` instance and Vivado placed it at
`PHASER_REF_X0Y0`. The bitstream delta versus the `none` baseline is small and
clean: 69 added bits, 0 removed bits. All added bits are in frames `0046009c`
and `0046009d`; verbose FASM leaves them undecoded under segment `0x00460080`.
That is the first concrete PHASER database target: add or verify the segbits for
the `PHASER_REF_X0Y0` configuration region before moving on to
`PHASER_IN_PHY`, `PHASER_OUT_PHY`, `PHY_CONTROL`, `IN_FIFO`, and `OUT_FIFO`.

The full Vivado MIG bitstream was also decoded for comparison:

```sh
bit2fasm --db-root "$PRJXRAY_DB_DIR/kintex7" \
  --part xc7k480tffg1156-2 \
  --bits-file artifacts/task6/phaser-feature-oracle/ypcb-mig/top_wrapper.bits \
  --verbose artifacts/task6/vivado-oracle/ypcb-systest/top_wrapper.bit \
  > artifacts/task6/phaser-feature-oracle/ypcb-mig/top_wrapper.verbose.fasm
```

The decoded MIG FASM contains no `PHASER`, `PHY_CONTROL`, `IN_FIFO`, or
`OUT_FIFO` feature names. Its verbose decode reports 3,923 unknown bits across
106 frames, including the same `0x00460080` PHASER_REF segment family exposed by
the minimal oracle.

The remaining disconnected hard-macro variants also build in Vivado and produce
small positive deltas when compared against the `phaser_ref` baseline:

| Variant | Added bits | Removed bits | Provisional row |
| --- | ---: | ---: | --- |
| `phy_control` | 38 | 0 | `artifacts/task6/phaser-feature-oracle/vivado-mini/phy_control/provisional-segbits-phy_control.db` |
| `phaser_in_div4` | 48 | 0 | `artifacts/task6/phaser-feature-oracle/vivado-mini/phaser_in_div4/provisional-segbits-phaser_in_div4.db` |
| `phaser_in_div2` | 47 | 0 | `artifacts/task6/phaser-feature-oracle/vivado-mini/phaser_in_div2/provisional-segbits-phaser_in_div2.db` |
| `phaser_out_div4` | 46 | 0 | `artifacts/task6/phaser-feature-oracle/vivado-mini/phaser_out_div4/provisional-segbits-phaser_out_div4.db` |
| `in_fifo` | 17 | 0 | `artifacts/task6/phaser-feature-oracle/vivado-mini/in_fifo/provisional-segbits-in_fifo.db` |
| `out_fifo` | 17 | 0 | `artifacts/task6/phaser-feature-oracle/vivado-mini/out_fifo/provisional-segbits-out_fifo.db` |

The PHASER_REF provisional row is:

```text
artifacts/task6/phaser-feature-oracle/vivado-mini/phaser_ref/provisional-segbits-phaser-ref.db
```

All provisional rows use segment base `0x00460080` and are intentionally marked
with `origin:task6-phaser-feature-oracle`. Treat the feature names as labels for
review, not final prjxray naming. The site-to-tile mapping from `tilegrid.json`
is:

| Site | Site type | Tile | Tile type |
| --- | --- | --- | --- |
| `PHASER_REF_X0Y0` | `PHASER_REF` | `CMT_TOP_R_UPPER_B_X8Y31` | `CMT_TOP_R_UPPER_B` |
| `PHY_CONTROL_X0Y0` | `PHY_CONTROL` | `CMT_TOP_R_UPPER_B_X8Y31` | `CMT_TOP_R_UPPER_B` |
| `PHASER_IN_PHY_X0Y0` | `PHASER_IN_PHY` | `CMT_TOP_R_LOWER_T_X8Y18` | `CMT_TOP_R_LOWER_T` |
| `PHASER_OUT_PHY_X0Y0` | `PHASER_OUT_PHY` | `CMT_TOP_R_LOWER_T_X8Y18` | `CMT_TOP_R_LOWER_T` |
| `IN_FIFO_X0Y0` | `IN_FIFO` | `CMT_FIFO_R_X7Y8` | `CMT_FIFO_R` |
| `OUT_FIFO_X0Y0` | `OUT_FIFO` | `CMT_FIFO_R_X7Y8` | `CMT_FIFO_R` |

The `PHASER_IN_PHY` `CLKOUT_DIV` parameter is not just a positive `IN_USE`
delta. Comparing `phaser_in_div4` to `phaser_in_div2` adds one bit
(`bit_0046009d_039_24`) and removes two bits (`bit_0046009c_038_25`,
`bit_0046009c_039_25`). Keep that as a parameter-specific diff rather than
folding it into the provisional `IN_USE` rows.

### PHASER DB Overlay Milestone

`scripts/task6/build_phaser_prjxray_db_overlay.py` builds a local, provisional
prjxray-db overlay at:

```text
artifacts/task6/phaser-feature-oracle/db-overlay/kintex7
```

The first simple overlay, which only added missing `segbits` files for
`CMT_TOP_R_UPPER_B`, `CMT_TOP_R_LOWER_T`, and `CMT_FIFO_R`, did not decode
`PHASER_REF`: `bit2fasm` still reported the same 69 unknown bits. The reason is
that the xc7k480t `tilegrid.json` has empty `bits` maps for the PHASER/FIFO site
tiles. The working overlay therefore also adds provisional `CLB_IO_CLK`
ownership windows:

| Tile | Offset | Words |
| --- | ---: | ---: |
| `CMT_TOP_R_UPPER_B_X8Y31` | 53 | 22 |
| `CMT_TOP_R_LOWER_T_X8Y18` | 34 | 7 |
| `CMT_FIFO_R_X7Y8` | 14 | 4 |

With those windows, the provisional segment-relative rows are rebased to
tile-local segbits and all mini-oracle bitstreams decode without `unknown_bit`
lines through `bit2fasm --db-root artifacts/task6/phaser-feature-oracle/db-overlay/kintex7`.
`fasm2frames` also accepts the decoded feature lines for `PHASER_REF`,
`PHY_CONTROL`, `PHASER_IN_PHY`, `PHASER_OUT_PHY`, `IN_FIFO`, and `OUT_FIFO`.

A local `nextpnr-xilinx` patch adds direct FASM emission for the smoke primitive
set in `xilinx/fasm.cc`: `PHASER_REF`, `PHY_CONTROL`, `PHASER_IN_PHY`,
`PHASER_OUT_PHY`, `IN_FIFO`, and `OUT_FIFO`. Built with the patched PHASER
chipdb, the patched nextpnr binary, and the DB overlay, the YPCB `phaser-smoke`
target emits these six PHASER/FIFO/PHY_CONTROL features without any post-FASM
append step:

```text
CMT_FIFO_R_X7Y8.IN_FIFO_X0Y0.IN_USE
CMT_FIFO_R_X7Y8.OUT_FIFO_X0Y0.IN_USE
CMT_TOP_R_LOWER_T_X8Y18.PHASER_IN_PHY_X0Y0.CLKOUT_DIV_4_IN_USE
CMT_TOP_R_LOWER_T_X8Y18.PHASER_OUT_PHY_X0Y0.CLKOUT_DIV_4_IN_USE
CMT_TOP_R_UPPER_B_X8Y31.PHASER_REF_X0Y0.IN_USE
CMT_TOP_R_UPPER_B_X8Y31.PHY_CONTROL_X0Y0.IN_USE
```

That smoke bitstream round-trips through `bit2fasm` back to the same six
features with no PHASER `unknown_bit` lines. This proves provisional prjxray
decode/encode plus direct nextpnr FASM emission for the current smoke primitive
set. The remaining gap is coverage, not the basic emission path: the feature DB
still needs a broader Vivado oracle matrix for non-default PHASER/FIFO/PHY
parameters before this can be called full MIG-class PHASER support.

### PHASER Byte-Lane Skeleton Milestone

`example_demo/ypcb_00338_1p1` now has a staged byte-lane diagnostic target:

```text
make -C example_demo/ypcb_00338_1p1 phaser-byte-lane-diag
```

The default mode is intentionally a hard-macro presence/configuration skeleton.
It instantiates and pre-places one `PHASER_REF`, one `PHY_CONTROL`, one
`PHASER_IN_PHY`, one `PHASER_OUT_PHY`, one `IN_FIFO`, and one `OUT_FIFO`, while
leaving their hard-macro data/status/clock pins disconnected. With the patched
PHASER chipdb, patched nextpnr FASM emitter, and provisional prjxray-db overlay,
the target routes and emits a bitstream containing the same six known PHASER
features. A seed-3, 25 MHz run produced:

```text
8971bf065d49e30eb3803cc0ac588412994c94ffc000950c33d717cba078075a  ypcb_phaser_byte_lane_diag_openxc7.bit
```

`PHASER_BYTE_LANE_DIAG_CLOCKED=1` or the `phaser-byte-lane-diag-clocked` target
is the next support probe, not a passing target yet. It connects PHASER/FIFO
clock, reset, data, and status pins to fabric so hardware can eventually report
PHASER lock/status and FIFO activity. Current nextpnr routing support is not
there yet: the first connected attempts exposed unroutable arcs from a BUFG
clock into `PHASER_IN_PHY.FREQREFCLK`, and from `PHASER_OUT_PHY.RDENABLE` back
to fabric. The corresponding Vivado oracle variants are
`phaser_in_div4_clocked` and `phaser_out_div4_clocked` in
`scripts/task6/ypcb_phaser_feature_oracle.tcl`; use those to extract the
dedicated clock/status routing and any extra configuration bits before expanding
the diagnostic to byte-lane read/write.

## Upstream Patch Queue

Keep local patches small and ready to split out:

- prjxray-db: missing Kintex-7 `LIOI3_TBYTESRC.IOI_OCLKM_0.IOI_IMUX31_1`
  feature and origin metadata.
- prjxray-db / nextpnr-xilinx: broaden PHASER/FIFO/PHY_CONTROL feature
  discovery beyond the current smoke parameters and upstream the provisional
  direct nextpnr FASM emitter.
- nextpnr-xilinx: upstream the prjxray site-pin fallback for hard macro BELs
  once it is narrowed to the site families needed by Kintex-7 DDR PHY.
- openFPGALoader: add `xc7k480t` IDCODE support for this board.
- nextpnr-xilinx/openXC7: ODELAY/HR output-buffer fixes if required for the
  final DDR PHY.
- UberDDR3: YPCB example, JTAG-readable BIST wrapper, and HIL documentation.

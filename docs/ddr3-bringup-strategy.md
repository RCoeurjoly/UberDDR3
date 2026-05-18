# DDR3 Bring-Up Strategy

This is the active strategy for YPCB-00338-1P1 DDR3 bring-up. The durable
NLNet-facing deliverable is an open-source-built bitstream: RTL plus Yosys,
nextpnr-xilinx/OpenXC7, prjxray/fasm2frames, and the local open toolchain
equivalent. Vivado is allowed only as an oracle for facts that make that open
flow correct.

## Strategic Split

Run two engineering tracks offline, but serialize board access.

### Primary: PHASER Open-Source Path

PHASER is the main path. It matches the architecture used by the Vivado/MIG
oracle for this board class and gives a deterministic reverse-engineering loop:
Vivado oracle, feature or route delta, OpenXC7/nextpnr/prjxray patch, then a
small diagnostic bitstream.

Work in this order:

1. Close PHASER oracle coverage for `PHASER_REF`, `PHASER_IN_PHY`,
   `PHASER_OUT_PHY`, `PHY_CONTROL`, `IN_FIFO`, and `OUT_FIFO`.
2. Compare frame/FASM deltas against the provisional PHASER overlay.
3. Patch missing segbits, tile ownership, chipdb visibility, nextpnr routing,
   or FASM emission in small reviewable changes.
4. Build diagnostics before controllers: `phaser-ref-diag`, then one byte lane
   with only known-supported PHASER/FIFO/PHY_CONTROL features.
5. Expand toward byte-lane DDR3 read/write primitives only after reset,
   clocking, PHASER lock/status, and FIFO activity are visible from an
   open-built bitstream.

Acceptance for the current PHASER stage:

- Open-source builds emit the expected PHASER/FIFO/PHY_CONTROL FASM features.
- `fasm2frames` accepts those features without manually appending Vivado-built
  artifacts.
- Hardware diagnostics report PLL lock, PHASER lock/status, reset release, and
  expected FIFO or lane activity.

### Secondary: Bounded UberDDR3 333 MHz No-PHASER Path

Keep the no-PHASER UberDDR3 path active as a tactical hedge, but do not let it
consume the main strategy. Use only the `openxc7-333` profile for this track:
83.333 MHz controller clock, 333.333 MHz DDR3 clock, 200 MHz reference clock,
`DLL_OFF=0`, and `ODELAY_SUPPORTED=0`.

Use the known calibrating seed/profile as evidence, not as a default answer.
Run only small placement or timing experiments tied to a named hypothesis:
clocks, IDELAYCTRL, IOSERDES, RDY LUTs, or minimal combinations. Broad seed
grinding is paused unless a nextpnr/tooling fix or a new minimal lock
hypothesis materially changes the expected result.

Acceptance for the tactical path:

- Calibration reaches `DONE_CALIBRATE` repeatably across multiple programming
  cycles for the exact same bitstream.
- Low-byte rowstream passes.
- 64-byte fullbeat integrity passes.
- Any promoted recipe is reproducible from exact source and artifacts, not just
  a lucky seed.

## Vivado Oracle Policy

Allowed Vivado outputs:

- routed designs, checkpoints, implemented XDC, placement/routing reports
- frame/FASM deltas and undecoded-bit evidence
- ILA or status observations used to identify missing open-flow support

Not acceptable as final deliverables:

- Vivado-built DDR3 bitstreams
- Vivado-only DDR3 driver or board flow
- undocumented post-processing that cannot be reproduced from the open flow

## Board Access Policy

Build and analyze both tracks offline. Only one hardware candidate may own the
board at a time. Use `scripts/task6/task6_board_run.py with-lock` or the
existing experiment runners so board-facing commands take the shared
`artifacts/task6/board.lock`.

Every board run must record:

- exact source commit and dirty status
- build command, program command, and readback command
- bitstream path and SHA256
- expected debug signature
- pass/fail JSON or log artifact

Default board priority is PHASER diagnostics first. The no-PHASER track may
take priority only when it has a newly fixed build/tooling blocker and one
high-value calibration candidate.

## Milestones

1. **PHASER Oracle Closure**
   - Run clocked Vivado oracle variants for the PHASER/FIFO/PHY_CONTROL
     primitive set.
   - Keep a mini oracle delta for every feature patch.
   - Confirm `fasm2frames` accepts the patched feature database.

2. **PHASER Diagnostic Hardware**
   - Build and test `phaser-ref-diag`.
   - Build one byte-lane diagnostic using only known-supported features.
   - Add new oracle variants only when hardware or `fasm2frames` exposes a
     specific missing feature or route.

3. **PHASER Byte-Lane DDR3 Primitive Path**
   - Add minimal byte-lane read/write primitives after clock/reset/status are
     proven.
   - Keep debug visibility ahead of full memory traffic.

4. **Bounded UberDDR3 333 Track**
   - Resolve nextpnr legality/tooling blockers exposed by targeted pre-place
     experiments.
   - Test only named lock groups and promote from calibration to rowstream to
     fullbeat integrity in that order.

## Current Pointers

- PHASER status and commands: `docs/ypcb-ddr3-support.md`
- no-PHASER seed-stability limits: `docs/seed-stability-plan.md`
- YPCB PHASER diagnostics: `example_demo/ypcb_00338_1p1/Makefile`
- board-run artifact helper: `scripts/task6/task6_board_run.py`

## Current Execution Status

As of 2026-05-18, the PHASER track remains the active priority, but the primary
blocker has shifted from PHASER_REF route support to byte-lane sequencing:

- `phaser-ref-diag` is no longer the blocker. Open-built and Vivado-routed
  byte-lane diagnostics both reach `phaser_pll_locked=true` and
  `phaser_ref_locked=true`.
- The byte-lane `PHYCTL_STIMULUS` probe failed identically in open flow and
  Vivado. That ruled out "one more missing open-only feature bit" as the next
  critical-path hypothesis.
- The clocked byte-lane diagnostic is now sequence-driven from
  `example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_sequence.vh`,
  generated from JSON. The checked-in default sequence is an observe-only
  placeholder that preserves the proven post-reset parity state without adding
  new speculative `PHYCTLWD` traffic.
- The checked-in Vivado ILA CSV under
  `artifacts/task6/vivado-oracle/ypcb-systest/` records only top-level
  calibration and MMCM/reset signals, so it is insufficient to derive the
  byte-lane sequence required for `PHY_CONTROL.READY` / `PHASER_IN_PHY.LOCKED`.

Next action: re-run the larger working Vivado/MIG oracle with byte-lane probes
on `RESET`, `PWRDWN`, `SYNCIN`, `READCALIBENABLE`, `WRITECALIBENABLE`,
`PHYCTLWRENABLE`, `PHYCTLWD`, `PHYCTLREADY`, `PHASER_IN` lock/status, and the
direct MIG init gates that feed them. Reduce that capture into a sequence JSON
with `scripts/task6/extract_ypcb_phaser_sequence.py`, regenerate the step ROM,
then rebuild both open and Vivado byte-lane diagnostics against the same
captured sequence.

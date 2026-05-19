# UberDDR3 status and completion plan

## Goal

UberDDR3 is the project to produce a fully functioning open-source DDR3 stack for YPCB.

The end state is:

- Open-built bitstream: RTL -> Yosys -> nextpnr/OpenXC7 -> FASM -> frames -> bitstream.
- PHASER-backed x8 DDR3 PHY path, not a no-PHASER-only rowstream demo.
- Repeatable hardware bring-up across program cycles.
- Host-side driver that can issue real memory operations and pass integrity checks.
- No Vivado-built intermediates in the final bitstream path.

Vivado is allowed as an oracle for sequence capture, placement, routing, properties, ILA waveforms, and parameter comparison. It is not the final build path.

## Current status

### Board and debug infrastructure

Working:

- YPCB board access works.
- JTAG programming works.
- BSCAN/JTAG readback works.
- Host-side debug readback can decode diagnostic payloads.
- Preserved no-PHASER and PHASER_REF baselines can be used to distinguish board/debug failures from PHASER bring-up failures.

Current policy:

- Use the no-PHASER path only as a regression oracle for board access, JTAG transport, and host UX reference.
- Do not spend main-roadmap effort on no-PHASER rowstream unless PHASER work is blocked by infrastructure ambiguity.

### no-PHASER rowstream path

Status:

- Existing no-PHASER rowstream/BIST path is a useful baseline and fallback.
- Existing host driver is for the no-PHASER shell and is not the PHASER end-state driver.

Role going forward:

- Board sanity check.
- Host-driver UX reference.
- Infrastructure regression oracle.

It is not the main deliverable.

### PHASER path

Status:

- Open-source `PHASER_REF` has been proven on hardware in a preserved baseline.
- Open-source byte-lane PHASER designs can synthesize, place, route, assemble, program, and expose JTAG status.
- Vivado oracle capture from the larger working YPCB/MIG design succeeded.
- A v4 open diagnostic now uses a sequence generated from the Vivado oracle rather than speculative free-running PHYCTL stimulus.

Known-good PHASER_REF baseline still reports:

- JTAG magic valid
- `phaser_pll_locked=true`
- `phaser_ref_locked=true`

Current v4 open sequence diagnostic reports:

- JTAG magic valid
- `phaser_pll_locked=true`
- `sequence_done=true`
- `sequence_step=4095`
- `phaser_ref_locked=false`
- `in_phase_locked=false`
- `phyctl_ready=false`

Recent v4 candidate bitstream:

- `example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_openxc7.bit`
- SHA256 `f129997d533729abc91f1b8d4c6731b10112519755b3b811629c739a23baae67`

## What has failed and what it means

### Speculative PHYCTL stimulus failed

Earlier byte-lane `PHYCTL_STIMULUS=1` probing failed the same way in both open flow and Vivado.

Conclusion:

- The blocker is not simply an open-only bitstream delta in that old probe.
- The probe was missing MIG/PHASER sequencing.
- The correct path is oracle-captured sequencing, not inventing new `PHYCTLWD` patterns.

### PHASER_REF lock regressed in v4 sequence diagnostic

The preserved v1 PHASER_REF baseline still locks, but the v4 sequence diagnostic does not.

Ruled out:

- Board drift: v1 baseline still locks.
- JTAG/host decode bug: RTL status bit layout and decoder agree.
- Delayed lock: longer polling kept `phaser_ref_locked=false`.
- PHASER_REF reset/powerdown sequencing: holding PHASER_REF under simple reset/powerdown did not fix it.
- PHY_CONTROL command fanout: tying sequencer-driven PHY_CONTROL inputs inactive did not restore PHASER_REF lock.
- Obvious CMT `PREF_IN2` versus `PREF_IN3` mismatch alone.
- Blind HCLK mux forcing: forcing `HCLK_CMT_X8Y182.HCLK_CMT_MUX_CLK_5.HCLK_CMT_CCIO3` broke PLL lock.

Conclusion:

- The remaining blocker is likely a lower-level frame/FASM/tooling delta around CMT/PHASER support, a bad provisional row, an extra conflicting feature, or incomplete topology modeling.
- More blind FASM route forcing is risky and should be avoided unless backed by frame/tile evidence.

### Wrong PLL site assumptions failed

`PLLE2_ADV_X0Y7` looked plausible but mapped to the wrong CMT region.

Known mapping:

- `PLLE2_ADV_X0Y1` corresponds to the known-good `CMT_TOP_R_UPPER_T_X8Y96` PLL tile when matching the preserved oracle.

Conclusion:

- nextpnr/OpenXC7 needs explicit PHASER/CMT topology knowledge.
- Site locks must be oracle-derived, not guessed.

### PHASER hard-output fabric observation failed

Routing `PHASER_IN_PHY.WRENABLE` into fabric failed.

Conclusion:

- Do not make route-hostile PHASER hard outputs part of diagnostic acceptance unless Vivado proves the route and nextpnr models it.
- Debug visibility should prioritize stable local status paths and avoid perturbing dedicated hard-macro routing.

### Frame collision was found

Known collision:

- Keep: `CMT_TOP_R_LOWER_T_X8Y18.PHASER_IN_PHY_X0Y0.CLKOUT_DIV_4_IN_USE`
- Exclude: `INT_R_X1Y19.IMUX11.BYP_BOUNCE_N3_7`

Current state:

- The local FASM patch script now handles this repeatably.
- This is still a workaround, not final database correctness.

Conclusion:

- Some open database rows or provisional aliases are still wrong/incomplete.
- Full support requires collision-free segbits and documented exclusions.

## Current tooling gaps

### Database and FASM support

Needed:

- Verified segbits for PHASER/CMT features.
- No unresolved frame collisions.
- No hand-edited FASM in the final path.
- Every provisional row or exclusion documented with routed-oracle evidence.

Current local patch:

- `scripts/task6/patch_ypcb_phaser_byte_lane_cmt_route.py`

This currently makes some CMT route and collision handling reproducible, but it is not the final upstream-quality solution.

### nextpnr/OpenXC7 topology

Needed:

- Legal co-placement modeling for `PHASER_REF`, `PHY_CONTROL`, `PHASER_IN_PHY`, `PHASER_OUT_PHY`, and associated PLLs.
- Correct CMT frequency backbone routing choices.
- Dedicated PHASER control/clock route modeling.
- Better handling of byte-lane replication constraints.

### PHASER parameter coverage

Needed oracle-backed coverage for:

- `PHASER_IN_PHY.CLKOUT_DIV`
- `PHASER_OUT_PHY.CLKOUT_DIV`
- `OUTPUT_CLK_SRC`
- `MEMREFCLK_PERIOD`
- `PHASEREFCLK_PERIOD`
- `PHY_CONTROL.CLK_RATIO`
- `PHY_CONTROL.SYNC_MODE`
- `PHY_CONTROL.BURST_MODE`

### Driver contract

Needed:

- A new PHASER shell command/status contract.
- Host transport/debug layer for JTAG exchange.
- PHASER memory-operation layer for low-byte and full-beat DDR3 operations.

The current no-PHASER driver is a reference, not the destination.

## Key artifacts

Top-level PHASER plan:

- `docs/phaser.md`
- `docs/ypcb-phaser-bringup-to-open-source-x8-driver.md`

Vivado oracle capture:

- `artifacts/task6/vivado-oracle/ypcb-systest-phaser-byte-lane-2026-05-18`

Generated v4 sequence:

- `example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_sequence_observed.json`
- `example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_sequence.vh`

Known-good PHASER_REF-locking baseline:

- `artifacts/task6/phaser-feature-oracle/vivado-ypcb-phaser-byte-lane-diag/ypcb_phaser_byte_lane_diag_openxc7.vivado-cmt-lanes.bit`

Frame/FASM analysis:

- `artifacts/task6/phaser-feature-oracle/current-vs-good-phaser-cmt-diff.txt`
- `artifacts/task6/phaser-frame-diff/good-v1.frames`
- `artifacts/task6/phaser-frame-diff/current-v4.frames`
- `artifacts/task6/phaser-frame-diff/good-v1-vs-current-v4-frame-diff.txt`
- `artifacts/task6/phaser-frame-diff/good-v1-vs-current-v4-frame-clusters.txt`

## Plan to fully functioning UberDDR3

### Phase 1: stabilize open single-byte-lane PHASER bring-up

Immediate blocker:

- Current v4 sequence diagnostic must recover `phaser_ref_locked=true` in open-built hardware.

Steps:

1. Map frame-diff clusters back to tile names and tile types.
2. Separate normal fabric/readback differences from CMT/PHASER hard-macro differences.
3. Classify each remaining CMT/PHASER delta as:
   - expected v4 logic difference
   - missing required feature
   - extra conflicting feature
   - bad provisional overlay alias
   - wrong nextpnr topology choice
4. Patch only oracle-proven rows or exclusions.
5. Rebuild from RTL through bitstream.
6. Program hardware and read JTAG status.
7. Revalidate the preserved v1 baseline when results are ambiguous.

Acceptance:

- JTAG magic valid.
- `phaser_pll_locked=true`
- `phaser_ref_locked=true`
- 3 consecutive successful program/readback cycles.

### Phase 2: reach PHASER_IN lock and PHY_CONTROL ready

After PHASER_REF lock is restored:

1. Continue using the Vivado-captured sequence as the acceptance oracle.
2. Restore only the required hard-macro input routes.
3. Avoid route-hostile hard-output fabric observation.
4. Keep the diagnostic payload stable and versioned.
5. Add only debug signals that do not perturb hard macro routing.

Acceptance:

- `phaser_ref_locked=true`
- `PHASER_IN_PHY.PHASELOCKED=true`
- `PHY_CONTROL.READY=true`
- deterministic sequencer progress
- 3 consecutive successful program/readback cycles

### Phase 3: clean open-flow PHASER support

Turn local bring-up hacks into maintainable support:

1. Replace provisional overlay aliases with verified segbits.
2. Remove one-off manual FASM edits.
3. Keep scripted local patching only while rows are being validated.
4. Document every exclusion and added row with evidence.
5. Teach nextpnr/OpenXC7 legal PHASER/CMT placement and routing constraints.
6. Keep upstream queue active, but do not block hardware progress on upstream merges.

Acceptance:

- Single-lane PHASER diagnostic is reproducible from clean source/artifacts without Vivado-built intermediates.
- `fasm2frames` accepts generated FASM without manual edits.
- Hardware gates from Phase 2 still pass.

### Phase 4: build x8 PHASER PHY shell

Build up in this order:

1. Single-lane controlled traffic.
2. Replicated lanes for one x8 byte group.
3. DQS/DM handling.
4. Shared clock/reset/control distribution.
5. Lane aggregation.
6. Minimal memory transaction shell above the PHY.

Debug visibility required until stable:

- per-lane lock
- per-lane ready/status
- calibration state
- command state
- traffic counters
- error counters

Acceptance:

- x8 shell comes up repeatably.
- Lock/ready survive multiple program cycles.
- Deterministic read/write traffic works without unexplained lock loss.

### Phase 5: define and implement PHASER driver contract

Build a new contract rather than inheriting rowstream assumptions.

Driver layers:

- JTAG transport/debug layer.
- PHASER memory-operation layer.

Required operations:

- status read
- debug dump
- low-byte write/read
- full-beat write/read
- integrity loop

Acceptance:

- Low-byte writes/reads pass.
- Full-beat writes/reads pass.
- 5 consecutive driver-level integrity runs pass on hardware.

### Phase 6: regression and release criteria

Before declaring UberDDR3 fully functioning:

- Preserve no-PHASER baseline as infrastructure oracle.
- Preserve PHASER_REF baseline as hard-macro oracle.
- Record every accepted milestone with:
  - commit
  - commands
  - routed JSON
  - nextpnr log
  - FASM
  - frames
  - bitstream SHA256
  - hardware readback JSON
  - run directory
- Require repeatability, not single-pass success.

Final acceptance:

- Clean open build produces a PHASER-backed x8 DDR3 bitstream.
- Hardware bring-up is repeatable.
- Driver performs low-byte and full-beat reads/writes.
- Integrity loops pass repeatedly.
- Vivado is absent from the final bitstream path.

## Working rules

- Treat Vivado as oracle, not final implementation.
- Do not invent new PHYCTL sequences without oracle evidence.
- Do not blindly force HCLK/CMT routes after the failed HCLK mux patch.
- Do not route PHASER hard outputs into fabric unless oracle-proven.
- Do not accept debug-only shells as the final driver milestone.
- Keep no-PHASER work subordinate to PHASER bring-up.

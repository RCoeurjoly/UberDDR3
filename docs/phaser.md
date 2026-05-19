# PHASER DDR3 open-source bring-up status

## Goal

Deliver a PHASER-based, open-built x8 DDR3 path for YPCB, ending in a usable host-side driver.

Final success means:

- RTL builds through the open flow: Yosys -> nextpnr/OpenXC7 -> FASM -> frames -> bitstream.
- The bitstream uses PHASER hard macros, not the current no-PHASER rowstream fallback.
- Hardware bring-up is repeatable across program cycles.
- A host driver can perform low-byte and full-beat DDR3 reads/writes through the PHASER shell and pass integrity checks.

The no-PHASER rowstream/BIST path remains useful only as a regression oracle for board access, JTAG transport, and host UX shape.

## Current status

### Proven

- Open-source `PHASER_REF` has been proven on hardware in a preserved baseline bitstream.
- Open-source byte-lane PHASER designs can synthesize, place, route, assemble, program, and expose JTAG readback.
- The preserved known-good byte-lane baseline still reports:
  - JTAG magic valid
  - `phaser_pll_locked=true`
  - `phaser_ref_locked=true`
- The current v4 sequence diagnostic reports valid JTAG magic and deterministic sequencer progress.
- The v4 diagnostic sequence is generated from the Vivado oracle capture, not from speculative free-running PHYCTL stimulus.
- The current open-flow failure reproduces as a hardware behavior issue, not as a board/JTAG failure.

### Current open-flow v4 diagnostic behavior

Recent candidate:

- Bitstream SHA256: `f129997d533729abc91f1b8d4c6731b10112519755b3b811629c739a23baae67`
- JTAG magic valid.
- `phaser_pll_locked=true`
- `sequence_done=true`
- `sequence_step=4095`
- `phaser_ref_locked=false`
- `in_phase_locked=false`
- `phyctl_ready=false`

Longer polling confirms `phaser_ref_locked=false` is stable, not a delayed-lock issue.

### Ruled out

The current `phaser_ref_locked=false` blocker is not explained by:

- Board drift: the preserved v1 baseline still locks PHASER_REF.
- Host decode: RTL status bit layout and Python decoder agree.
- PHASER_REF reset/powerdown sequencing: holding PHASER_REF reset/powerdown under simple reset did not fix it.
- PHY_CONTROL command fanout: tying sequencer-driven PHY_CONTROL inputs inactive did not restore PHASER_REF lock.
- The obvious CMT `PREF_IN2` versus `PREF_IN3` mismatch alone.
- Forcing `HCLK_CMT_X8Y182.HCLK_CMT_MUX_CLK_5.HCLK_CMT_CCIO3`; that broke PLL lock and is not a valid fix.

## Current tooling gaps

The primitives exist, but MIG-class PHASER support is not complete. The missing support is mostly around dedicated CMT/PHASER clock and control routing.

### 1. CMT/PHASER dedicated route database

Needed for routes feeding:

- `PHASER_REF.CLKIN`
- `PHY_CONTROL.MEMREFCLK`
- `PHY_CONTROL.SYNCIN`
- `PHASER_IN_PHY.FREQREFCLK`
- `PHASER_IN_PHY.MEMREFCLK`
- `PHASER_IN_PHY.SYNCIN`
- `PHASER_OUT_PHY.FREQREFCLK`
- `PHASER_OUT_PHY.MEMREFCLK`
- `PHASER_OUT_PHY.SYNCIN`

Current local support still depends on overlay rows and scripted FASM patching.

Known collision now handled repeatably in the local patch script:

- Keep: `CMT_TOP_R_LOWER_T_X8Y18.PHASER_IN_PHY_X0Y0.CLKOUT_DIV_4_IN_USE`
- Exclude: `INT_R_X1Y19.IMUX11.BYP_BOUNCE_N3_7`

This is a local workaround until the database row or conflicting INT segbit is corrected properly.

### 2. nextpnr/OpenXC7 topology knowledge

The tools need better knowledge of legal PHASER/CMT co-placement:

- `PHASER_REF`
- `PHY_CONTROL`
- `PHASER_IN_PHY`
- `PHASER_OUT_PHY`
- associated `PLLE2_ADV`

Known-good lane-0 placement class:

- `PHASER_REF_X0Y0`
- `PHY_CONTROL_X0Y0`
- `PHASER_IN_PHY_X0Y0`
- `PHASER_OUT_PHY_X0Y0`
- `PLLE2_ADV_X0Y1` corresponds to the known-good `CMT_TOP_R_UPPER_T_X8Y96` PLL tile when matching the preserved oracle.

Avoid guessed locks such as `PLLE2_ADV_X0Y7`; that mapped to the wrong CMT region in testing.

### 3. Hard-macro output routing

Some PHASER hard outputs are not safely routable into fabric with current modeling.

Known example:

- Routing `PHASER_IN_PHY.WRENABLE` into fabric failed.

Until a Vivado route oracle proves the relevant arcs and nextpnr can model them, these outputs should not be required for diagnostic acceptance.

### 4. Parameter coverage

Need oracle-backed coverage for non-default parameters used by MIG-class byte-lane designs:

- `PHASER_IN_PHY.CLKOUT_DIV`
- `PHASER_OUT_PHY.CLKOUT_DIV`
- `OUTPUT_CLK_SRC`
- `MEMREFCLK_PERIOD`
- `PHASEREFCLK_PERIOD`
- `PHY_CONTROL.CLK_RATIO`
- `PHY_CONTROL.SYNC_MODE`
- `PHY_CONTROL.BURST_MODE`

## Current artifacts

Primary planning log:

- `docs/ypcb-phaser-bringup-to-open-source-x8-driver.md`

Vivado sequencing oracle:

- `artifacts/task6/vivado-oracle/ypcb-systest-phaser-byte-lane-2026-05-18`

Generated sequence files:

- `example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_sequence_observed.json`
- `example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_sequence.vh`

Preserved PHASER_REF-locking baseline:

- `artifacts/task6/phaser-feature-oracle/vivado-ypcb-phaser-byte-lane-diag/ypcb_phaser_byte_lane_diag_openxc7.vivado-cmt-lanes.bit`

Current local support patch:

- `scripts/task6/patch_ypcb_phaser_byte_lane_cmt_route.py`

Frame/FASM analysis artifacts:

- `artifacts/task6/phaser-feature-oracle/current-vs-good-phaser-cmt-diff.txt`
- `artifacts/task6/phaser-frame-diff/good-v1.frames`
- `artifacts/task6/phaser-frame-diff/current-v4.frames`
- `artifacts/task6/phaser-frame-diff/good-v1-vs-current-v4-frame-diff.txt`
- `artifacts/task6/phaser-frame-diff/good-v1-vs-current-v4-frame-clusters.txt`

## Plan to reach a PHASER-backed x8 DDR3 driver

### Phase 1: close single-byte-lane PHASER_REF lock

Immediate target: current v4 sequence diagnostic must reach `phaser_ref_locked=true` in open-built hardware.

Steps:

1. Map reduced frame-diff clusters back to tile names and tile types.
2. Separate ordinary fabric/readback deltas from CMT/PHASER hard-macro frame deltas.
3. For every remaining CMT/PHASER delta, classify it as:
   - expected v4 logic difference
   - missing required PHASER feature
   - extra conflicting feature
   - bad provisional overlay alias
4. Patch only oracle-proven rows or exclusions.
5. Rebuild from RTL through bitstream, program hardware, and read status.
6. Preserve the v1 baseline as a recovery check before and after candidate tests.

Acceptance:

- JTAG magic valid.
- `phaser_pll_locked=true`
- `phaser_ref_locked=true`
- Repeat for at least 3 consecutive program/readback cycles.

### Phase 2: close PHASER_IN lock and PHY_CONTROL ready

After PHASER_REF lock is restored:

1. Use the Vivado captured sequence as the only accepted sequencing oracle.
2. Keep the byte-lane diagnostic limited to one lane and required hard macros.
3. Restore only required hard-macro input routes.
4. Avoid fabric observation of route-hostile hard outputs unless an oracle proves the route.
5. Add minimal status bits only when they do not perturb the hard route topology.

Acceptance:

- `phaser_ref_locked=true`
- `PHASER_IN_PHY.PHASELOCKED=true`
- `PHY_CONTROL.READY=true`
- deterministic sequencer progress
- at least 3 consecutive successful program/readback cycles

### Phase 3: make open-flow support clean

Convert local patches into clean tool/database support:

1. Replace provisional overlay aliases with verified segbits.
2. Remove manual one-off FASM surgery.
3. Keep a documented list of every exclusion and its oracle proof.
4. Teach nextpnr/OpenXC7 enough topology to choose legal PHASER/CMT routes reproducibly.
5. Keep upstreaming active, but do not block local bring-up on upstream merges.

Acceptance:

- Clean source/artifacts reproduce the single-lane diagnostic bitstream without Vivado-built intermediates.
- `fasm2frames` accepts the generated FASM without manual edits.
- Hardware gates from Phase 2 still pass.

### Phase 4: expand to x8 PHASER PHY shell

Build up from the working byte-lane diagnostic:

1. Single-lane controlled traffic.
2. Replicate lanes for one x8 byte group.
3. Add DQS/DM handling and shared reset/clock/control distribution.
4. Add minimal memory transaction shell above the PHY.
5. Keep debug-visible per-lane lock, ready, calibration state, command state, and traffic counters.

Acceptance:

- Open-built x8 shell comes up repeatably.
- Per-lane lock/ready remains stable across program cycles.
- Deterministic read/write traffic works without unexplained lock loss.

### Phase 5: build PHASER host driver contract

Do not reuse rowstream assumptions blindly. Define a PHASER shell contract and bind the host driver to it.

Driver layers:

- Transport/debug layer for JTAG command/status exchange.
- PHASER memory-operation layer for the x8 shell command contract.

Required host operations:

- status read
- debug dump
- low-byte write/read
- beat write/read
- integrity loop

Acceptance:

- Low-byte read/write passes against hardware.
- Full-beat read/write passes against hardware.
- At least 5 consecutive driver-level integrity runs pass on the x8 shell.

## Working rules

- Vivado is allowed as an oracle for sequencing, placement, routing, parameters, and waveform capture.
- Vivado is not allowed in the final bitstream path.
- Do not invent new PHYCTLWD patterns without oracle evidence.
- Do not accept a single successful program cycle as a milestone.
- Do not let the no-PHASER rowstream path compete with the PHASER deliverable.
- Use the no-PHASER path only to prove board/debug infrastructure when PHASER results are ambiguous.

# PHASER: YPCB Bring-Up to Open-Source x8 Driver

## Summary

Primary goal: deliver an open-built PHASER-based x8 DDR3 path for YPCB, with a
usable host-side driver and repeatable hardware evidence, while keeping the current
no-PHASER rowstream path as a regression oracle and fallback baseline.

Current state:

- Open-source PHASER_REF is proven on hardware.
- Open-source byte-lane PHASER builds, routes, assembles, and programs.
- The current byte-lane `PHYCTL_STIMULUS=1` probe fails the same way in both open
  flow and Vivado, so the blocker is now missing MIG/PHASER sequencing, not an
  open-only bitstream delta.
- The existing host driver is for the no-PHASER rowstream shell and is not the
  PHASER end-state driver.

End-state deliverable:

- Open-built RTL + Yosys + nextpnr/OpenXC7 + fasm2frames flow that produces a
  PHASER-based x8 DDR3 bitstream for YPCB.
- A host-side driver contract that can issue reads/writes against that PHASER
  design.
- Repeated hardware proof: calibration/bring-up succeeds and data integrity passes
  across program cycles.

## Implementation Changes

### 1. Promote Vivado from “feature oracle” to “sequencing oracle”

- Use the existing larger Vivado YPCB/MIG design as the authoritative source for the
  byte-lane bring-up sequence.
- Insert ILA probes on the exact byte-lane control path needed to explain
  `PHY_CONTROL.READY` and `PHASER_IN_PHY.LOCKED`:
  `RESET`, `PWRDWN`, `SYNCIN`, `READCALIBENABLE`, `WRITECALIBENABLE`,
  `PHYCTLWRENABLE`, `PHYCTLWD`, `PHYCTLREADY`, `PHASER_IN` lock/status,
  `PHASER_OUT` status, and any MIG local “init calib” gates that directly fan
  into those primitives.
- Capture one successful bring-up waveform from the larger working Vivado reference
  and reduce it to deterministic sequencing spec:
  signal values, ordering, pulse widths, clock domain, and release
  conditions.
- Treat this sequencing spec as the next PHASER acceptance oracle. Do not keep
  inventing new minimal PHYCTLWD patterns without oracle evidence.

### 2. Rebuild the minimal open PHASER diagnostic around the captured sequence

- Replace the current free-running write-stimulus probe with a scripted
  byte-lane sequencer that exactly reproduces the Vivado-observed control
  sequence.
- Keep the minimal diagnostic limited to one byte lane and only the
  already-supported hard macros:
  PHASER_REF, PHY_CONTROL, PHASER_IN_PHY, PHASER_OUT_PHY, and FIFOs only if the
  Vivado sequence proves they are required before READY.
- Make the diagnostic payload explicit and stable:
  versioned readback, step/state ID, stimulus counter, lock bits, ready bit, last
  command word, and any byte-lane-local status needed to localize failure.
- Acceptance for this stage:
  the same open-built bitstream repeatedly reaches `PHY_CONTROL.READY=true` and
  `PHASER_IN_PHY` lock/asserted status on hardware.

### 3. Close remaining PHASER open-flow support to “MIG-class byte-lane capable”

- Keep using small Vivado/open diffs to patch only proven missing support in:
  prjxray overlay rows, nextpnr-xilinx CMT/chipdb behavior, and FASM emission.
- Continue the current policy for provisional rows:
  every exclusion or added row must be justified by a routed-oracle frame
  collision or missing feature delta, and recorded in docs.
- Extend oracle coverage from current primitive presence/config to exact non-default
  parameters and route features exercised by the working byte-lane sequence.
- Upstream queue remains active, but local progress should not wait on upstream
  merges.
- Acceptance for this stage:
  all PHASER byte-lane support needed by the working diagnostic is emitted by open
  flow, accepted by fasm2frames, and reproducible from clean source/artifacts
  without Vivado-built intermediates in the final bitstream path.

### 4. Expand from one working byte lane to an x8 PHASER PHY shell

- After single-byte-lane ready/lock is stable, build an x8 PHASER PHY shell in this
  order:
  1. single-lane write/read primitives with controlled traffic
  2. replicated lanes for one full x8 byte group
  3. lane aggregation, DQS/DM handling, and shared control/reset/clock
     distribution
  4. minimal memory transaction shell above the PHY
- Reuse the captured Vivado sequencing model across lanes; do not redesign the
  control model independently.
- Keep the shell debug-visible:
  per-lane lock/ready, command progress, calibration state, and traffic counters
  must remain readable through JTAG or equivalent debug path until data integrity is
  stable.
- Acceptance for this stage:
  open-built x8 shell comes up repeatably, maintains PHASER lock/ready across
  multiple program cycles, and supports deterministic read/write traffic without
  unexplained lock loss.

### 5. Replace the no-PHASER rowstream driver with a PHASER-backed driver contract

- Build the PHASER user-facing shell to expose a clear host contract rather than
  inheriting current rowstream assumptions blindly.
- Keep the host-side UX close to the existing YPCB driver shape where practical:
  status read, low-byte read/write, beat read/write, integrity checks, and
  debug dumps.
- Split driver work into two layers:
  - transport/debug layer for JTAG command/status exchange
  - PHASER memory-operation layer bound to the new PHASER shell command contract
- Do not declare success with a debug-only shell; the plan ends at a usable
  PHASER-backed x8 driver path.
- Acceptance for this stage:
  the host driver can perform low-byte and full-beat memory operations against the
  PHASER shell, and those operations pass integrity checks on hardware.

### 6. Keep the no-PHASER track as a regression oracle, not as the main roadmap

- Preserve the current no-PHASER rowstream/BIST path as:
  - board-access sanity baseline
  - host-driver behavior reference
  - fallback proof that the HIL environment and board are functioning
- Do not spend active engineering time there unless:
  - PHASER work is blocked on board/debug uncertainty, or
  - a no-PHASER artifact is needed to validate infrastructure, command transport,
    or acceptance tooling.
- Use it to prevent false negatives while PHASER is being brought up, not to
  compete for the main deliverable.

## Test Plan

### Open-source build gates

- Every PHASER milestone must be buildable from the open flow end-to-end:
  RTL -> Yosys -> nextpnr/OpenXC7 -> FASM -> frames -> bitstream.
- Record for every candidate:
  - commit
  - command
  - routed JSON
  - nextpnr log
  - FASM
  - frames
  - bitstream SHA256
  - run directory

### Vivado oracle gates

- For each new sequencing or feature hypothesis, keep one oracle artifact:
  implemented XDC/DCP, route/property extraction, and reduced conclusion in docs.
- Do not accept “it worked once in Vivado” without a captured sequence or explicit
  config delta tied to the open change.

### Hardware gates

- PHASER_REF gate:
  already passed; preserve as regression.
- Single-byte-lane gate:
  `phaser_pll_locked=true`, `phaser_ref_locked=true`,
  `PHY_CONTROL.READY=true`, `PHASER_IN` lock/status asserted, and deterministic
  sequencer progress.
- x8 shell gate:
  repeated program cycles preserve bring-up success and do not regress
  lock/ready.
- Driver gate:
  low-byte writes/reads pass, then full-beat writes/reads pass, then repeated
  integrity loops pass.

### Stability gates

- No milestone is accepted on a single successful program cycle.
- Required repeatability:
  - at least 3 consecutive successful reprogram/readback cycles for
    diagnostics
  - then at least 5 consecutive successful driver-level integrity runs for the x8
    shell.

## Assumptions and Defaults

- Deliverable target is full x8 PHASER-backed driver, not a one-byte-lane
  proof-only endpoint.
- The no-PHASER path remains in the plan only as a baseline/oracle, not as a
  co-equal implementation track.
- Vivado is allowed as an oracle for sequence capture, placement, routing,
  parameters, and ILA observations, but not as the final bitstream path.
- The next concrete blocker is sequence capture from the larger working Vivado
  reference; no more speculative minimal-stimulus iterations should be treated as
  primary work until that capture is done.
- Board access remains serialized; offline oracle analysis, driver design, and
  open-flow patching can proceed in parallel, but only one candidate owns hardware
  at a time.

## Live Execution Log

2026-05-18 active run:

- Stage 1 sequencing oracle completed.
- Vivado oracle run directory:
  `artifacts/task6/vivado-oracle/ypcb-systest-phaser-byte-lane-2026-05-18`.
- Vivado oracle artifacts:
  `top_wrapper_debug.bit`, `top_wrapper_debug.ltx`, `post-route-debug.dcp`,
  `calibration-ila-readback.csv`, `calibration-ila-readback-normalized.csv`,
  and `calibration-ila-probes.txt`.
- Probe map:
  `scripts/task6/ypcb_phaser_byte_lane_oracle_probes.tcl`.
- Resolver:
  `scripts/task6/build_vivado_ypcb_phaser_byte_lane_oracle.tcl` accepts
  explicit bit-by-bit multi-bit probes for `PHYCTLWD[31:0]` and filters
  route-hostile direct hard-macro pins that Vivado cannot legally route to ILA.
- Capture scope:
  channel-0 `ddr_phy_4lanes_0`, byte lane A; includes `PLLLOCK`,
  `REFDLLLOCK`, `PHYCTLREADY`, `PHYCTLWRENABLE`, `PHYCTLWD`, resets, calib
  enables, `SYNCIN`, `PHASELOCKED`, `DQSFOUND`, and lane FIFO enables.
- Observed successful steady state:
  PLL lock, PHASER_REF lock, PHASER_IN phase lock, `PHYCTLREADY`, and
  `DQSFOUND` all asserted in the captured Vivado waveform.
- Direct `PHASER_IN_PHY.WRENABLE` and `PHASER_OUT_PHY.RDENABLE` probes are not
  usable ILA probes in the large Vivado design; Vivado proves those paths are
  route-hostile, so they are not sequencing-oracle requirements.
- Reduced sequence artifacts:
  `example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_sequence_observed.json`
  and
  `example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_sequence.vh`.
- The generated diagnostic sequence is 4096 steps wide and uses
  `PHASER_SEQUENCE_STEP_BITS = 12`.
- Current open-flow build command requires the local PHASER-capable
  nextpnr/chipdb:
  `PATH=/home/roland/nextpnr-xilinx:$PATH nix develop -c make -B -C example_demo/ypcb_00338_1p1 phaser-byte-lane-diag-clocked CHIPDB=../../artifacts/task6/chipdb-local-phaser NEXTPNR_XILINX_PYTHON_DIR=/home/roland/nextpnr-xilinx/xilinx/python PHASER_BYTE_LANE_DIAG_SEQUENCE_SPEC=ypcb_phaser_byte_lane_diag_sequence_observed.json`.
- The over-reduced open diagnostic routed and assembled only after
  disconnecting hard arcs for `WRENABLE`, `RDENABLE`, FIFO full/empty status,
  `RANKSELPHY`, `BURSTPENDINGPHY`, `MEMREFCLK`, and `SYNCIN`.
- That over-reduced bitstream programmed, but PHASER diagnostic readback was
  invalid:
  TDO7 returned all zeroes, TDO0 returned only `0x7f`, and `magic_ok=false`.
- The no-PHASER BSCAN smoke test passed immediately afterward, including magic
  `0x42535244`, scratch write/read, command counter advance, and free-running
  counter advance. Therefore the board, JTAG chain, and BSCAN transport are
  healthy; the failing item is the reduced PHASER bitstream/user-logic endpoint.
- Current blocker:
  recover the last PHASER byte-lane diagnostic variant that still had valid
  BSCAN plus PLL/PHASER_REF lock, then reapply the captured Vivado sequence
  without stripping essential CMT/PHASER route features.
- Useful recovery baselines:
  `artifacts/task6/runs/2026-05-18T17-01-21+0200-phaser-byte-lane-clocked-openxc7-integrated-vivado-cmt-lanes`
  and
  `artifacts/task6/runs/2026-05-18T17-23-55+0200-phaser-byte-lane-clocked-openxc7-phyctl-gnd-enables`.

## Execution Queue (Immediate)

1. Capture the byte-lane sequence from the large Vivado reference with the
   full control-signal set.
2. Commit deterministic sequence JSON and update open diagnostic ROM.
3. Rebuild minimal PHASER byte-lane diagnostics against the captured sequence.
4. Expand to one-lane x8 fragment and then full x8 shell only after one-lane gate
   passes.
5. Wire PHASER-backed transport and memory-operation host contract.

### 2026-05-18 resumed execution notes: v4 sequence diagnostic PHASER_REF regression

Hardware baseline rechecked after several v4 candidates:

- Preserved bitstream `artifacts/task6/phaser-feature-oracle/vivado-ypcb-phaser-byte-lane-diag/ypcb_phaser_byte_lane_diag_openxc7.vivado-cmt-lanes.bit` still reports valid JTAG magic, `phaser_pll_locked=true`, and `phaser_ref_locked=true`.
- Therefore board access, JTAG readback, and the PHASER_REF hard macro baseline are still good.

Open v4 sequence diagnostic candidates built and programmed successfully, but all still reported `phaser_ref_locked=false` while preserving valid JTAG magic and usually `phaser_pll_locked=true`:

- Reconnected MEMREFCLK/SYNCIN/RANK/BURST routes to match the successful byte-lane oracle class.
- Left PHASER_IN `WRENABLE` and PHASER_OUT `RDENABLE` unobserved because routing those hard-macro outputs into fabric failed.
- Removed sequencer control from PHASER_REF reset/powerdown; no change.
- Tried PLL pre-place at `PLLE2_ADV_X0Y7`, which mapped to the wrong CMT (`X8Y408`); no PHASER_REF lock.
- Corrected PLL pre-place to `PLLE2_ADV_X0Y1`, matching the known-good `CMT_TOP_R_UPPER_T_X8Y96` PLL tile; this exposed a justified frame collision with `INT_R_X1Y19.IMUX11.BYP_BOUNCE_N3_7`, which was manually excluded for the test.
- Patched CMT frequency muxes from current `PREF_IN2` to oracle `PREF_IN3`; no PHASER_REF lock.
- Forced the remaining HCLK mux delta to the oracle value; this broke `phaser_pll_locked`, so that patch is not a valid fix.
- Isolated PHY_CONTROL by tying its sequencer-driven command inputs inactive while leaving the v4 sequencer/readback alive; no PHASER_REF lock.
- Long poll (`50 x 100 ms`) confirmed the v4 false lock is stable, not delayed.

Current blocker conclusion:

- The failure is not hardware drift, not host decode, not PHASER_REF reset/powerdown sequencing, not PHYCTLWD/control fanout, and not simply the obvious CMT frequency mux row.
- The next useful step is a lower-level frame/FASM comparison focused on the PHASER_REF lock path and any non-obvious frame interactions between the v4 logic placement and the known-good v1 PHASER_REF frames. Treat the v1 preserved bitstream as the recovery baseline before each new candidate.

## Open-source PHASER support closure plan

Goal: make PHASER byte-lane support real open-source tooling support, not a pile of local FASM edits. A milestone only counts when it is reproducible from source through Yosys, nextpnr/OpenXC7, FASM, frames, bitstream, and hardware readback.

### Support gaps to close

1. PHASER/CMT dedicated-route database

- Replace provisional PHASER/CMT overlay aliases with oracle-verified rows.
- For every row, record the Vivado/open source of truth, frame address, bit position, and whether the row is a positive feature or an exclusion of a false conflicting INT feature.
- Current known collision requiring proof/cleanup:
  - `CMT_TOP_R_LOWER_T_X8Y18.PHASER_IN_PHY_X0Y0.CLKOUT_DIV_4_IN_USE`
  - `INT_R_X1Y19.IMUX11.BYP_BOUNCE_N3_7`

Acceptance:

- `fasm2frames` accepts the diagnostic FASM without hand-edited one-off removals.
- No unresolved FASM inconsistent-bit collision remains for the single-byte-lane diagnostic.

2. CMT/PHASER topology model in nextpnr/OpenXC7

- Encode legal co-placement relationships for:
  - `PHASER_REF`
  - `PHY_CONTROL`
  - `PHASER_IN_PHY`
  - `PHASER_OUT_PHY`
  - associated `PLLE2_ADV`
- Stop relying on guessed site locks such as `PLLE2_ADV_X0Y7`; use oracle-confirmed mappings.
- Current known-good mapping to preserve for lane-0 diagnostic:
  - `PHASER_REF_X0Y0`
  - `PHY_CONTROL_X0Y0`
  - `PHASER_IN_PHY_X0Y0`
  - `PHASER_OUT_PHY_X0Y0`
  - `PLLE2_ADV_X0Y1` when matching the preserved v1 oracle PLL tile `CMT_TOP_R_UPPER_T_X8Y96`, unless a route-oracle proves another legal placement.

Acceptance:

- nextpnr places the byte-lane diagnostic without manual post-route site guessing.
- The generated FASM uses the same CMT/PHASER backbone class as the hardware-good oracle.

3. Dedicated hard-macro route support

- Model dedicated local routes for:
  - `PHASER_REF.CLKIN`
  - `PHY_CONTROL.MEMREFCLK`
  - `PHY_CONTROL.SYNCIN`
  - `PHASER_IN_PHY.FREQREFCLK`
  - `PHASER_IN_PHY.MEMREFCLK`
  - `PHASER_IN_PHY.SYNCIN`
  - `PHASER_IN_PHY.RANKSELPHY`
  - `PHASER_IN_PHY.BURSTPENDINGPHY`
  - `PHASER_OUT_PHY.FREQREFCLK`
  - `PHASER_OUT_PHY.MEMREFCLK`
  - `PHASER_OUT_PHY.SYNCIN`
  - `PHASER_OUT_PHY.BURSTPENDINGPHY`
- Do not route hard-macro outputs into fabric unless an oracle shows the arc is legal. `PHASER_IN_PHY.WRENABLE` to fabric currently fails route and must remain excluded from required acceptance.

Acceptance:

- The diagnostic routes without disconnected required input pins and without illegal fabric observation of hard-output pins.

4. Parameter emission coverage

- Verify and document FASM coverage for all non-default parameters exercised by the byte-lane diagnostic and MIG oracle:
  - `PHASER_IN_PHY.CLKOUT_DIV`
  - `PHASER_OUT_PHY.CLKOUT_DIV`
  - `OUTPUT_CLK_SRC`
  - `MEMREFCLK_PERIOD`
  - `PHASEREFCLK_PERIOD`
  - `PHY_CONTROL.CLK_RATIO`
  - `PHY_CONTROL.SYNC_MODE`
  - `PHY_CONTROL.BURST_MODE`
- Every parameter conclusion needs a Vivado/open FASM diff or frame comparison.

Acceptance:

- Parameter mismatches are not a plausible explanation for `PHASER_REF_LOCKED=false`, `PHASER_IN_PHY.PHASELOCKED=false`, or `PHY_CONTROL.READY=false`.

5. Hardware proof gates

- Recovery gate: preserved v1 bitstream must keep reporting `phaser_ref_locked=true` before testing new candidates.
- Single-byte-lane open diagnostic gate:
  - JTAG magic valid
  - `phaser_pll_locked=true`
  - `phaser_ref_locked=true`
  - sequencer advances deterministically
  - `PHASER_IN_PHY.PHASELOCKED=true` or a documented next blocker after PHASER_REF lock
  - `PHY_CONTROL.READY=true` or a documented next blocker after PHASER_IN lock
- Repeatability gate: at least 3 consecutive program/readback cycles for the accepted single-byte-lane diagnostic.

### Immediate execution order

1. Generate focused v1-vs-v4 frame/FASM evidence for PHASER_REF and CMT tiles.
2. Turn the known `PHASER_IN_PHY.CLKOUT_DIV_4_IN_USE` versus `INT_R_X1Y19.IMUX11.BYP_BOUNCE_N3_7` collision into a documented overlay exclusion or corrected segbit row.
3. Restore a clean candidate from the last healthy v4 shape, avoiding the failed HCLK mux forcing and avoiding PHASER hard-output fabric observation.
4. Build, assemble, program, and read hardware.
5. If `phaser_ref_locked=false` persists after CMT/PHASER frame parity, compare raw frame words for the PHASER_REF lock-path tiles against the preserved v1 oracle and patch only proven frame deltas.

### 2026-05-19 open PHASER support closure execution

Added an explicit open-source PHASER support closure plan covering:

- PHASER/CMT dedicated-route database completion.
- nextpnr/OpenXC7 topology modeling for PHASER_REF, PHY_CONTROL, PHASER_IN_PHY, PHASER_OUT_PHY, and PLLE2_ADV.
- dedicated hard-macro route support.
- parameter emission coverage.
- hardware acceptance gates.

Execution completed in this pass:

- Made the known frame collision repeatable in `scripts/task6/patch_ypcb_phaser_byte_lane_cmt_route.py`:
  - excludes `INT_R_X1Y19.IMUX11.BYP_BOUNCE_N3_7`
  - preserves the PHASER hard feature `CMT_TOP_R_LOWER_T_X8Y18.PHASER_IN_PHY_X0Y0.CLKOUT_DIV_4_IN_USE`
  - intentionally does not force the failed `HCLK_CMT_X8Y182.HCLK_CMT_MUX_CLK_5.HCLK_CMT_CCIO3` patch because that broke PLL lock in hardware.
- Extended CMT route replacements for observed `PREF_IN0/PREF_IN1` variants so the FASM patch script is no longer dependent on one manually observed route spelling.
- Restored the v4 sequence diagnostic from the temporary PHY_CONTROL-isolation state and rebuilt through the open flow.
- New candidate bitstream:
  - `example_demo/ypcb_00338_1p1/ypcb_phaser_byte_lane_diag_openxc7.bit`
  - SHA256 `f129997d533729abc91f1b8d4c6731b10112519755b3b811629c739a23baae67`
- Hardware result for that candidate:
  - JTAG magic valid
  - `phaser_pll_locked=true`
  - sequence completed (`sequence_done=true`, `sequence_step=4095`)
  - `phaser_ref_locked=false`
  - `in_phase_locked=false`
  - `phyctl_ready=false`

New analysis artifacts:

- Focused FASM diff:
  - `artifacts/task6/phaser-feature-oracle/current-vs-good-phaser-cmt-diff.txt`
- Raw frame diff:
  - `artifacts/task6/phaser-frame-diff/good-v1.frames`
  - `artifacts/task6/phaser-frame-diff/current-v4.frames`
  - `artifacts/task6/phaser-frame-diff/good-v1-vs-current-v4-frame-diff.txt`
- Reduced frame-diff clusters:
  - `artifacts/task6/phaser-frame-diff/good-v1-vs-current-v4-frame-clusters.txt`

Current conclusion:

- The open-flow support patch is now more reproducible: the known collision is handled by script rather than by hand.
- This did not fix hardware PHASER_REF lock.
- Next concrete step is to map the reduced frame-diff clusters back to tile types/tiles and isolate which non-fabric CMT/PHASER frames still differ from the PHASER_REF-locking v1 oracle. Avoid more blind HCLK/CMT forcing; the previous HCLK force broke PLL lock.

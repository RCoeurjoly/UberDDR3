# Seed-Dependent DDR3 Calibration SDF Investigation

This note is specific to the standalone YPCB UberDDR3 OpenXC7 build in this repo.
The current top-level uses `BYTE_LANES = 2` and `ODELAY_SUPPORTED(0)`, so the first-order SDF targets are DQ/DQS input, OSERDES/IOB output without ODELAY, IDELAYCTRL/reset release, clocking, and calibration control.


## Experiment Hygiene Doctrine

Every hardware experiment must be reproducible from git history, not from an uncommitted worktree. Treat each run as a tuple of RTL/debug variant, constraints/locks, tool flags, nextpnr seed, SDF/JSON artifacts, bitstream hash, and hardware result. Commit the source-side definition of that tuple before or immediately after running the experiment, then commit the result table update as part of the same logical experiment record.

Rules:

1. Do not leave RTL, constraints, scripts, flake targets, or documentation for an experiment uncommitted.
2. Do not treat generated `result-*` Nix symlinks as experiment records; record the derivation target, SDF/JSON path, bitstream hash, and hardware JSON/CSV rows instead.
3. If observability RTL changes, it is a new RTL/debug variant and needs its own committed experiment identity.
4. If a hardware result changes after only locks, constraints, or tool flags changed, preserve that exact change in git before interpreting SDF/JSON causality.
5. Keep cause/effect hypotheses separate from solution hypotheses in the ledger. A solution is only promoted after it changes the intended SDF/JSON signature and improves hardware pass/fail in the matrix.

## Current Hardware Matrix

Use the existing board results as the starting classification:

| Candidate | Hardware result | Key status |
| --- | --- | --- |
| `seed-1` | fail | `calib_complete=false`, `state_calibrate=0` |
| `seed-2` | fail | `calib_complete=false`, `state_calibrate=0` |
| `seed-3` | pass | `calib_complete=true`, `state_calibrate=23` |
| `seed-4` | pass | `calib_complete=true`, `state_calibrate=23` |
| `seed-5` | pass | `calib_complete=true`, `state_calibrate=23` |
| `seed-1-robust` | pass | `--no-tmdriv` plus reset-release LUT locks |
| `seed-2-robust` | pass | `--no-tmdriv` plus reset-release LUT locks |

Because the failing unrobust seeds stop at calibration state 0, do not start by assuming late read/write training failure. First compare reset release, IDELAYCTRL readiness, generated clocks, and controller startup paths. Then compare DQ/DQS IO timing.

## Emitting SDF

`nextpnr-xilinx --sdf <file>` emits the routed delay model. `--sdf-cvc` changes SDF formatting for CVC-style consumers; it should not affect placement, routing, FASM, or bitstream behavior. Use both when debugging parser issues. Prefer CVC SDF for `sdf-toolkit` checks in this repo.

The flake exports raw and CVC SDF targets for each existing candidate:

```bash
nix build .#ypcb-ddr3-cvc-sdf-seed-1 -o result-sdf-seed1-fail
nix build .#ypcb-ddr3-cvc-sdf-seed-3 -o result-sdf-seed3-pass
nix build .#ypcb-ddr3-cvc-sdf-seed-1-robust -o result-sdf-seed1-robust
```

The output contains both SDF and a same-run placed JSON:

```bash
ls result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf
ls result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.placed.json
```

Raw SDF targets use `ypcb-ddr3-sdf-seed-N`; robust raw targets use `ypcb-ddr3-sdf-seed-N-robust`.

## Sanity Checks

Run package-level parser checks first:

```bash
nix run .#sdf-toolkit -- stats result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf
nix run .#sdf-toolkit -- stats result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf
nix run .#sdf-toolkit -- diff \
  result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf \
  result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf
```

Then run the DDR-focused normalized comparator:

```bash
nix run .#uberddr3-sdf-compare -- \
  --good-sdf result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.cvc.sdf \
  --bad-sdf result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf \
  --good-json result-sdf-seed3-pass/ypcb_00338_1p1_ddr3.placed.json \
  --bad-json result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.placed.json \
  --label seed1-fail-vs-seed3-pass
```

Repeat the two most useful contrasts:

```bash
nix run .#uberddr3-sdf-compare -- \
  --good-sdf result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.cvc.sdf \
  --bad-sdf result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.cvc.sdf \
  --good-json result-sdf-seed1-robust/ypcb_00338_1p1_ddr3.placed.json \
  --bad-json result-sdf-seed1-fail/ypcb_00338_1p1_ddr3.placed.json \
  --label seed1-fail-vs-seed1-robust

nix run .#uberddr3-sdf-compare -- \
  --good-sdf result-sdf-seed4-pass/ypcb_00338_1p1_ddr3.cvc.sdf \
  --bad-sdf result-sdf-seed2-fail/ypcb_00338_1p1_ddr3.cvc.sdf \
  --label seed2-fail-vs-seed4-pass
```

The comparator writes `artifacts/sdf-comparisons/<label>/summary.json`, `family_lane_metrics.csv`, and `largest_bad_slower_deltas.csv`.

## Path Families To Compare

Prioritize these families in this order for the current failing symptom:

1. `idelayctrl_reset_release`: `ddr3_phy_inst.delay_before_release_reset[*]` and its LUT/FF routing. Existing robust results already implicate this region.
2. `idelayctrl`: IDELAYCTRL placement, RDY routing, reset, and `i_ref_clk` path.
3. `reset_cdc` and `clocking`: `rst_n && clk_locked`, MMCM/PLL/BUFG paths from `clk_wiz`, `controller_clk`, `ddr3_clk`, `ref_clk`, `ddr3_clk_90`.
4. `dqs_input`: pad/IBUFDS to IDELAYE2 to ISERDESE2/controller observations for `genblk7[0]` and `genblk7[1]`.
5. `dq_input`: pad/IBUF to IDELAYE2 to ISERDESE2/controller observations for `genblk5[0..15]`, grouped as lane 0 and lane 1.
6. `dqs_output` and `dq_output`: OSERDESE2/IOB to pad. For this YPCB top, ODELAY paths are mostly not active because `ODELAY_SUPPORTED(0)`.
7. `idelay_control`: `CNTVALUEIN`, `LD`, `CE`, `INC`, bitslip, and per-lane delay update signals from controller to PHY.
8. `calibration_fsm`: `state_calibrate`, `bitslip`, `dqs_start`, `dqs_target`, `dqs_store`, MPR/write-leveling/read-test decision logic.

For each family, look at max delay, p95 delay, intra-lane spread, lane0-vs-lane1 spread, and bad-minus-good deltas. A single larger global max delay is less interesting than a stable separator that appears in both failing seeds and not in passing seeds.

## Actionable Outcomes

Treat SDF evidence as actionable only if it is stable across at least two failing seeds or appears in a fail-vs-robust comparison of the same seed.

If reset release or IDELAYCTRL paths separate pass from fail, keep the existing reset-release BEL locks and expand them only to the minimum set of adjacent reset/RDY/control LUTs or FFs. The existing robust lock file is `example_demo/ypcb_00338_1p1/constraints/ypcb_00338_1p1_ddr3_reset_release_locks.json`.

If DQ/DQS input skew separates pass from fail, generate pre-place BEL locks from a known-good placed JSON for the lane-local `IDELAYE2_data`, `ISERDESE2_data`, `IOBUF_data`, `IDELAYE2_dqs`, `OSERDESE2_dqs`, and `IOBUFDS_dqs` cells under `ddr3_top_inst.ddr3_phy_inst.genblk5[*]` and `genblk7[*]`. Lock only the active 16 DQ bits and 2 DQS lanes for this target.

If IDelay control routing separates pass from fail, place or lock the small control fanout feeding `i_controller_idelay_*_cntvaluein`, `i_controller_idelay_*_ld`, bitslip, and write-leveling control near the DDR PHY clock region. Prefer locking a small cone from a passing seed over whole-design locking.

If clocking differs, lock the MMCM/PLL/BUFG resources from a passing seed and audit generated clock constraints. The current XDC has an input `clk50` clock and nextpnr is also run with `--freq 83.333`; if nextpnr accepts more explicit generated clocks for this flow, add them for `controller_clk`, `ddr3_clk`, `ref_clk`, and `ddr3_clk_90`.

If the bad seed has worse DQ/DQS output delay or skew, first verify whether that path is actually active under `ODELAY_SUPPORTED(0)`. If ODELAY is later enabled, include `ODELAYE2_data`, `ODELAYE2_dqs`, and command/clock ODELAY cells in the lock set.

## Negative Result Interpretation

If SDF does not separate passing and failing seeds, the most likely interpretation is not that the hardware result is impossible. It means the variable is outside nextpnr's emitted digital delay model or hidden by model granularity. Suspects then include missing or inaccurate openXC7 timing arcs for IDELAY/IDELAYCTRL/ISERDES/OSERDES/IOB paths, DQS-specific analog behavior, bitstream feature emission differences in prjxray/FASM, clocking/reset startup behavior not represented as a simple path delay, PVT/board margin, or router behavior such as `tmdriv` affecting an unmodeled resource.

The goal is to replace seed sweeping with the smallest deterministic constraint that moves failing seeds into the passing cluster. If the SDF clusters are inseparable, keep the robust lock experiment as evidence and shift to bitstream/FASM feature diffs, placement legality audits, and hardware margin probes.


## DDR endpoint metric matrix

The preferred SDF workflow is now metric-first rather than full-file diff-first.
Generate or reuse CVC SDF artifacts, then run:

```bash
nix run .#uberddr3-sdf-metrics -- \
  --out-dir artifacts/sdf-metrics/cvc-seed-matrix \
  --sample seed1-fail:fail:result-sdf-seed1-fail \
  --sample seed2-fail:fail:result-sdf-seed2-fail \
  --sample seed3-pass:pass:result-sdf-seed3-pass \
  --sample seed1-robust:robust:result-sdf-seed1-robust \
  --sample seed2-robust:robust:result-sdf-seed2-robust
```

For a rerun after changing only the normalizer, reuse the cached first-stage
query JSON:

```bash
nix run .#uberddr3-sdf-metrics -- --reuse-cache \
  --out-dir artifacts/sdf-metrics/cvc-seed-matrix \
  --sample seed1-fail:fail:result-sdf-seed1-fail \
  --sample seed2-fail:fail:result-sdf-seed2-fail \
  --sample seed3-pass:pass:result-sdf-seed3-pass \
  --sample seed1-robust:robust:result-sdf-seed1-robust \
  --sample seed2-robust:robust:result-sdf-seed2-robust
```

The outputs to inspect first are:

- `candidate_strict_fail_slower.csv`: metrics where all failing seed values are above all passing seed values.
- `candidate_fail_slower.csv`: metrics where failing seed median is above passing seed median.
- `semantic_metrics.csv`: per-sample endpoint, lane spread, control fanout spread, and CNTVALUEIN bus skew metrics.
- `direct_entries.csv`: normalized first-stage query records with both readable pins and exact graph pins.
- `rank_path_fail_slower.sh`: exact `sdf-toolkit rank-paths` commands for the strict fail-slower endpoint candidates.

The rank-path scripts use `sdf-toolkit` as the executable name. Run them from an
environment where `sdf-toolkit` is on `PATH`, for example `nix develop`, or copy
one command and replace `sdf-toolkit` with `nix run .#sdf-toolkit --`.


## Current SDF Findings

The expanded pass/fail matrix includes failing seeds 1/2, passing seeds 3/4/5,
and robust seeds 1/2. The strict fail-slower population shrank from the initial
single-pass-seed matrix, but the surviving separators are still dominated by
IDELAY programming delivery:

```text
idelay_dqs_cntvaluein lane0 dqs0 ctrl=4  fail median 2092.5 ps, pass median 1350.0 ps
idelay_data_cntvaluein lane1 dq14 ctrl=3 fail median 1995.5 ps, pass median 1310.0 ps
idelay_data_cntvaluein lane1 dq8  ctrl=2 fail median 2141.0 ps, pass median 1473.0 ps
idelay_data_cntvaluein lane1 dq10 ctrl=2 fail median 1988.0 ps, pass median 1396.0 ps
idelay_data_cntvaluein lane1 dq12 ctrl=2 fail median 2002.5 ps, pass median 1488.0 ps
```

This keeps the leading hypothesis focused on calibration-to-IDELAY programming
paths, especially `CNTVALUEIN[*]`, rather than global SDF delay or generic
DQ/DQS datapath delay.

The robust-factor split matrix adds `--no-tmdriv` only and reset-locks-only
variants for failing seeds 1/2. Representative medians:

```text
metric                                    fail   pass   no-tmdriv  reset-only  robust
idelay_dqs_cntvaluein lane0 dqs0 ctrl=4   2092.5 1350.0 2067.0     2032.5      1343.0
idelay_data_cntvaluein lane1 dq14 ctrl=3  1995.5 1310.0 1224.5     1547.0      1602.0
idelay_data_cntvaluein lane1 dq8  ctrl=2  2141.0 1473.0 1291.5     1419.0      1443.5
idelay_data_cntvaluein lane0 dq4  ctrl=3  2318.0 1820.0 1314.5     1791.5      1638.5
idelay_data_cntvaluein lane0 dq1  ctrl=3  2313.5 1822.0 1229.5     1708.5      1595.5
idelay_ld               lane0 dq7         2305.5 1968.0 1805.5     2425.0      1310.5
```

Interpretation:

- `--no-tmdriv` improves many DQ `CNTVALUEIN` paths substantially.
- reset-locks-only is mixed and does not consistently move the metrics to the
  pass population.
- the top DQS `CNTVALUEIN[4]` separator is not fixed by either split alone, but
  is fixed in the combined robust build.
- therefore the robust behavior is not explained by one simple global delay
  shift; it is a placement/routing interaction.

The existing reset-release lock file is not currently a reliable physical lock.
A post-build checker reports mismatches for reset-locks-only and robust builds:

the lock file requests `SLICE_X0Y113`, while observed placements include
`SLICE_X0Y107`, `SLICE_X2Y118`, `SLICE_X0Y103`, and `SLICE_X0Y108` depending on
seed/variant. The `YPCB pre-place BEL locks: applied=...` log line is therefore
not sufficient evidence that final placement matches the requested BELs.

A seed3-derived narrow IDELAY lock file was generated for the 10 `CNTVALUEIN`
leaf LUTs and 2 `LD` source FFs. Locking all 12 cells, and then locking only the
10 `CNTVALUEIN` LUTs, both caused nextpnr-xilinx to abort after reporting that
all pre-place locks were applied:

```text
YPCB pre-place BEL locks: applied=10 missing=0 ...
Info: Placed 391 cells based on constraints.
terminate called after throwing an instance of 'std::out_of_range'
what(): unordered_map::at
```

So the absolute-BEL-lock approach is currently blocked for these synthesized
IDELAY-control LUTs by nextpnr-xilinx behavior. The next practical constraint
experiment should avoid exact BEL locks and instead try a softer region/site
locality constraint if the Python API supports it, or fix the pre-place locking
path upstream before relying on BEL locks as a deterministic solution.

## Hardware lock validation: 2026-05-27

The nextpnr BEL-lock crash was fixed by binding constrained macro children for fixed roots in `common/placer_heap.cc`, then carried into this repo as `patches/nextpnr-xilinx-heap-fixed-constrained-children.patch`. With that patch, absolute BEL lock experiments can complete P&R and bitstream generation.

Hardware matrix from `artifacts/hardware/idelay_lock_hardware_matrix.json`:

| Experiment | Seed | Result | Calibration state | Wrong reads | Notes |
|---|---:|---|---:|---:|---|
| baseline | 3 | pass | 23 | 0 | current unmodified control still passes |
| baseline | 5 | pass | 23 | 0 | current unmodified control still passes |
| CNTVALUEIN-only locks | 1 | pass | 23 | 0 | rescued known failing seed |
| CNTVALUEIN-only locks | 2 | pass | 23 | 0 | rescued known failing seed |
| CNTVALUEIN-only locks | 3 | fail | 17 | 1 | lock perturbation causes later BIST/calibration failure |
| CNTVALUEIN-only locks | 4 | pass | 23 | 0 | unaffected passing seed |
| CNTVALUEIN-only locks | 5 | fail | 0 | 0 | lock perturbation causes startup/calibration failure |
| CNTVALUEIN + LD-parent locks | 3 | fail | 0 | 0 | adding LD parent placement does not rescue seed 3 |
| CNTVALUEIN + LD-parent locks | 5 | pass | 23 | 0 | adding LD parent placement rescues seed 5 |

Conclusion: the SDF-derived CNTVALUEIN correlate is real enough to rescue seeds 1 and 2, but absolute locks copied from one passing placement are not yet a universal solution. They perturb the global placement/routing enough to break seed 3, even though current baseline seed 3 passes. The actionable direction is not to freeze isolated leaf LUT BELs as a final constraint. Instead, derive a bounded placement/floorplan rule around the whole IDELAY programming/startup cone, and add metrics for placement perturbation around reset, IDELAYCTRL ready/reset, LD/CE/INC, and calibration state-0 release paths.

A second tool finding matters: LD source FFs are constrained children of packed LUT/FF macros. Locking the FF child directly does not hold. The lock extractor now emits LD parent LUT locks and records the child FF source as metadata.


## Seed3 lock-damage SDF comparison: 2026-05-27

The decisive comparison is now `baseline seed3 pass` versus the two lock-perturbed seed3 failures, not original pass/fail seeds. The focused artifacts are under `artifacts/sdf-comparisons/seed3-lock-damage/` and were generated by `scripts/compare_seed3_lock_damage.py`.

Both lock experiments applied exactly as intended:

| Variant | Lock cells at expected BEL | Lock cells still matching baseline BEL |
|---|---:|---:|
| CNTVALUEIN-only seed3 fail | 10/10 | 10/10 |
| CNTVALUEIN + LD-parent seed3 fail | 12/12 | 12/12 |

That means the seed3 failures are not caused by the lock files putting the selected cells in the wrong place. The locks are copied from the passing seed3 placement and still match it. The failures come from collateral placement/routing changes introduced by constraining those cells.

Filtered SDF results use exact same-seed destination keys and exclude static `PACKER_GND/VCC` edges from the primary dynamic metrics:

| Variant | Family | Dynamic common paths | Median delta | P95 delta | Max delta | Paths >= +500 ps |
|---|---|---:|---:|---:|---:|---:|
| CNTVALUEIN-only seed3 fail | IDELAY programming | 108 | +122.5 ps | +755 ps | +824 ps | 25 |
| CNTVALUEIN-only seed3 fail | read/BIST state-17 | 18 | -97.5 ps | +330 ps | +330 ps | 0 |
| CNTVALUEIN-only seed3 fail | DQ/DQS input and IDELAY pins | 392 | 0 ps | +534 ps | +824 ps | 25 |
| CNTVALUEIN+LD seed3 fail | IDELAY programming | 108 | -209.5 ps | +296 ps | +464 ps | 0 |
| CNTVALUEIN+LD seed3 fail | read/BIST state-17 | 18 | -667.5 ps | -490 ps | -480 ps | 0 |
| CNTVALUEIN+LD seed3 fail | DQ/DQS input and IDELAY pins | 392 | 0 ps | +25 ps | +464 ps | 0 |

Interpretation:

- The CNTVALUEIN-only seed3 state-17 failure still has a credible SDF signature: dynamic IDELAY programming paths to IDELAYE2 CNTVALUEIN/LD and related DQ/DQS IDELAY pins are slower by roughly 0.5-0.8 ns on a large subset of paths. That is consistent with the earlier pass/fail population correlate and remains the best causal candidate for the state-17 wrong-read failure.
- The CNTVALUEIN+LD seed3 state-0 failure does not show the same dynamic SDF separation. IDELAY programming is not worse by the previous threshold, read/BIST paths are mostly faster, and the explicit IDELAYCTRL reset/RDY paths visible in SDF are not slower. This points away from simply adding more LD/CE/INC BEL locks as the next step.
- Placement movement is large in the read/calibration bookkeeping cone even when dynamic SDF paths do not get slower: `dqs_start_index*`, `dqs_start_index_stored*`, `stage2_bank_d`, `stage2_row_d`, read-pipe muxes, and BIST counters move by up to 27 tiles for CNTVALUEIN-only and 51 tiles for CNTVALUEIN+LD. The PHY reset-release counter LUTs also move, by 26 tiles and 17 tiles respectively.
- For the CNTVALUEIN+LD state-0 failure, SDF is not giving a clean dynamic-delay explanation. The likely missing surfaces are asynchronous reset recovery/removal, reset pulse/IDELAYCTRL analog readiness margin, clock-start ordering, or openXC7/nextpnr/prjxray modeling gaps around IDELAYCTRL/IOLOGIC behavior. This is exactly the case where SDF says "do not blindly add more absolute locks".

Actionable next constraint direction:

1. Do not extend the seed3 absolute BEL-lock set directly to CE/INC/reset. The full-lock seed3 result already shows that exact locks can preserve selected cells while damaging the surrounding implementation.
2. Convert the useful CNTVALUEIN evidence into a region/floorplan experiment: keep the IDELAY programming cone near the byte-lane IO/IDELAY columns and near its fanout, but avoid freezing every leaf BEL.
3. For state-0 failures, constrain and instrument the whole startup cone as a unit: IDELAYCTRL site/refclk/reset, `delay_before_release_reset`, `sync_rst`, controller `sync_rst_controller`, and the state-0 release into `state_calibrate`. The current SDF does not prove a dynamic-delay violation there, so the next experiment needs placement locality plus hardware observability, not just more SDF ranking.
4. Keep the comparator exact-key and constant-edge-filtered. The raw SDF diff is misleading here because static `PACKER_GND/VCC` edges and over-normalized `$abc` names can dominate the largest deltas without representing dynamic timing evidence.

## Instrumented seed3 lock hardware matrix: 2026-05-27

Artifacts:

- `artifacts/hardware/instrumented_seed3_lock_hardware_matrix.csv`
- `artifacts/hardware/instrumented_seed3_lock_hardware_matrix.json`
- raw runs:
  - `artifacts/hardware/instrumented-seed3-baseline.json`
  - `artifacts/hardware/instrumented-seed3-idelay-control-locked.json`
  - `artifacts/hardware/instrumented-seed3-idelay-control-full-locked.json`

Results:

| variant | pass | state | instruction | wrong reads | key sticky evidence |
| --- | --- | ---: | ---: | ---: | --- |
| baseline seed3 instrumented | yes | 23 | 22 | 0 | no reset reassertion, no tap mismatch |
| CNTVALUEIN-only lock instrumented | yes | 23 | 22 | 0 | no reset reassertion, no tap mismatch |
| CNTVALUEIN+LD-parent lock instrumented | no | 0 | 2 | 0 | reached state 13 gate, entered calibration, returned to IDLE, `reset_from_calibrate_ever=1`, sync/PHY reset reasserted, no tap mismatch |

Interpretation:

- The instrumentation did not break baseline seed3.
- The regenerated CNTVALUEIN-only lock no longer reproduces the earlier state-17 BIST failure. This means the old CNTVALUEIN-only failure is placement-sensitive enough that the debug payload / resynthesis moved it out of the failing margin.
- The CNTVALUEIN+LD-parent lock still reproduces a calibration-startup failure, but the new evidence separates it from IDELAY programming corruption: `CNTVALUEOUT` matches the loaded taps and both data/DQS mismatch masks are zero.
- The failing CNTVALUEIN+LD-parent bitstream reached the state-0 ready gate and left IDLE at least once, then asserted `reset_from_calibrate` and returned to IDLE while the reset ROM was back at instruction 2. That points at a calibration algorithm abort/reset path, not a BIST read-data failure and not an IDELAY tap-load failure.

Next targeted instrumentation:

Add a small calibration-abort reason code captured at each `reset_from_calibrate <= 1` site. The two current reset sites are in `ANALYZE_DATA` and `CHECK_STARTING_DATA`; capture reason, lane, `start_index_check`, `lane_write_dq_late`, `lane_read_dq_early`, `dq_target_index[lane]`, and `data_start_index[lane]`. This will distinguish whether the LD lock damages write/read alignment assumptions during `ANALYZE_DATA` or causes the `CHECK_STARTING_DATA` search to exhaust its valid start-index range.




## Causality and Solution Hypothesis Ledger

The experiment is not trying to prove that a seed number is good or bad. The seed is only a sampling mechanism that produces different placed/routed implementations from the same requested design. The explanatory variable we care about is a narrow SDF/JSON signature tied to specific cells, pins, locations, routes, or timing families. Hardware calibration plus BIST is the fast accept/reject test for each implementation.

Use two separate tables:

1. Cause/effect hypotheses: a proposed physical or timing signature in SDF/JSON that predicts hardware pass/fail.
2. Solution hypotheses: a proposed RTL, constraint, floorplan, tool-option, or physical-lock change that should remove the bad signature and make hardware pass.

A solution hypothesis is not allowed to become the conclusion until it changes the SDF/JSON signature in the intended direction and improves hardware pass/fail across the same RTL/debug variant matrix.

Artifacts:

- `artifacts/hardware/ddr3_hypothesis_ledger.csv`
- `artifacts/hardware/ddr3_hypothesis_ledger.json`

Current cause/effect hypotheses:

| ID | status | proposed SDF/JSON cause | hardware signature | narrow cells/paths | current evidence | next falsification test |
| --- | --- | --- | --- | --- | --- | --- |
| CE-001 | active, partially supported | IDELAY programming/control paths to DQ/DQS IDELAYE2 pins are too slow or skewed in failing implementations | state-17 wrong-read or calibration/BIST failure after startup | DQ/DQS IDELAYE2 `CNTVALUEIN`, `LD`, related control fan-in | pass/fail population produced strict fail-slower separators; seed3 CNTVALUEIN-only lock-damage comparison showed IDELAY programming p95 +755 ps and 25 dynamic paths >= +500 ps | same RTL/debug variant matrix over more seeds; failing rows must separate on exact-key IDELAY programming metrics, not raw seed |
| CE-002 | active, newly exposed | lane-0 data-alignment search in `CHECK_STARTING_DATA` runs out of valid start-index candidates | first abort reason 2, lane 0, `dq_target_index=35`, no tap mismatch | `dq_target_index[0]`, `data_start_index[0]`, `start_index_check`, `lane_write_dq_late[0]`, `lane_read_dq_early[0]`, read sample classification cone | payload-v3 reduced seed3 baseline fails with consistent first abort reason 2; both regenerated lock variants pass under same RTL/debug variant | add a narrower lane-0 decision observer and compare SDF/JSON for baseline fail versus locked pass around these exact cells |
| CE-003 | active, not SDF-proven | startup/reset/IDELAYCTRL readiness ordering or reset recovery/removal margin causes state-0 returns | state 0 after entering calibration; reset-from-calibrate history set; no tap mismatch | IDELAYCTRL site/refclk/reset/RDY, `delay_before_release_reset`, `sync_rst`, `sync_rst_controller`, state-0 release cone | seed1/seed2 original failures and payload-v2 CNTVALUEIN+LD seed3 failure match this family; filtered SDF did not show a simple dynamic slow-path separator | add reset/ready time counters and compare state-0 failures separately from state-17/read-search failures |

Current solution hypotheses:

| ID | status | proposed fix | intended SDF/JSON change | current result | next test |
| --- | --- | --- | --- | --- | --- |
| SO-001 | diagnostic only | absolute BEL locks for selected CNTVALUEIN and LD-parent cells | force selected IDELAY programming leaf cells to good-reference BELs | mixed: rescues some rows, damages or changes others, passes reduced-v3 seed3 locks | keep as a perturbation tool; do not promote to final fix unless it passes a broad matrix and has a clear narrowed signature |
| SO-002 | proposed | soft floorplan/region constraint for the whole IDELAY programming plus calibration bookkeeping cone | reduce distance/skew for the cone without freezing every leaf BEL | not yet tested | define regions around byte-lane IO/IDELAY columns and compare exact-key metrics before hardware |
| SO-003 | proposed | RTL calibration robustness in `CHECK_STARTING_DATA` | tolerate or recover from narrow alignment windows rather than relying on one fragile placement-dependent outcome | not yet tested | first capture lane-0 window bounds and last accepted/rejected start-index candidates |
| SO-004 | proposed | explicit generated-clock/reset/CDC constraints and startup reset handling | remove unconstrained or under-modeled startup ordering sensitivity | not yet tested as a standalone fix | isolate state-0 failures and verify reset/IDELAYCTRL-ready timing/ordering observability |

## Payload-v3 abort instrumentation: 2026-05-27

Artifacts:

- canonical matrix: `artifacts/hardware/ddr3_causality_matrix.csv`
- canonical matrix JSON: `artifacts/hardware/ddr3_causality_matrix.json`
- raw runs:
  - `artifacts/hardware/v3-seed3-baseline.json`
  - `artifacts/hardware/v3-min-seed3-baseline.json`
  - `artifacts/hardware/v3-min-seed3-baseline-rerun.json`
  - `artifacts/hardware/v3-min-seed3-idelay-control-locked.json`
  - `artifacts/hardware/v3-min-seed3-idelay-control-full-locked.json`

Implementation:

- `rtl/ddr3_controller.v` now captures the first calibration-abort decision into `o_debug_calib_abort[63:0]` at the actual `reset_from_calibrate <= 1` sites, rather than inferring it one cycle later.
- The captured fields are: seen bit, reason code, lane, `state_calibrate`, reset-ROM `instruction_address`, `start_index_check`, `lane_write_dq_late`, `lane_read_dq_early`, `dq_target_index[lane]`, and `data_start_index[lane]`.
- Reason code `1` is `ANALYZE_DATA`, reason code `2` is `CHECK_STARTING_DATA`, and reason code `15` is any unexpected `reset_from_calibrate` state.
- The YPCB JTAG debug payload is now version `3`, and the board-test decoder emits an `abort_debug` object.

Hardware matrix slice:

| experiment | RTL/debug variant | locks | pass | state | instruction | wrong reads | abort evidence |
| --- | --- | --- | --- | ---: | ---: | ---: | --- |
| `v3-seed3-baseline` | payload-v3 wide 128-bit abort RTL | none | no | 4 | 13 | 0 | no abort captured |
| `v3-min-seed3-baseline` | payload-v3 reduced 64-bit abort RTL | none | no | 17 | 22 | 1 | reason 2, lane 0, `dq_target_index=35`, `data_start_index=0`, write-late=1, read-early=0 |
| `v3-min-seed3-baseline-rerun` | payload-v3 reduced 64-bit abort RTL | none | no | 0 | 2 | 2 | same first abort: reason 2, lane 0, `dq_target_index=35` |
| `v3-min-seed3-idelay-control-locked` | payload-v3 reduced 64-bit abort RTL | CNTVALUEIN-only | yes | 23 | 22 | 0 | no abort captured |
| `v3-min-seed3-idelay-control-full-locked` | payload-v3 reduced 64-bit abort RTL | CNTVALUEIN + LD-parent | yes | 23 | 22 | 0 | no abort captured |

Interpretation:

- The requested abort observer works: when calibration resets, it identifies the first failing calibration assumption rather than only the final state after the reset sequence has restarted.
- The wide payload was too intrusive for this design point. It made seed3 fail early in DQS calibration state 4 before any data-calibration abort was captured.
- The reduced payload is still placement/timing intrusive enough to turn the previously passing seed3 baseline into a deterministic failure, but it gives useful causality: the first captured abort is `CHECK_STARTING_DATA` exhaustion on lane 0 with `dq_target_index[0]=35` and `data_start_index[0]=0`.
- That signature is not an IDELAY tap-load failure. In the reduced payload-v3 runs, the data and DQS tap mismatch masks stay zero. The failing assumption is the controller's read/write alignment search, after the tap values were loaded as intended.
- The regenerated CNTVALUEIN-only and CNTVALUEIN+LD-parent lock variants pass under the same reduced observer. This means the lock-induced placement change can move the instrumented design back into a passing margin. It also means these absolute locks are not a universal fix by themselves; they are a lever that changes placement and routing enough to expose or hide the fragile margin.

Current causality model:

1. The original pass/fail population and the CNTVALUEIN-only seed3 lock-damage SDF still point to IDELAY programming/control delay as a real correlate for state-17 wrong-read failures.
2. The payload-v3 abort evidence exposes a second failure mode: lane-0 data-calibration search exhaustion in `CHECK_STARTING_DATA`, with no observed tap-load mismatch.
3. Absolute BEL locks copied from one good placement are therefore diagnostic, not final. They can rescue some seeds, damage others, and even rescue an observer-perturbed seed by changing collateral placement.
4. The fix should be promoted upward only after it survives the matrix: first algorithmic robustness and explicit observability, then soft physical locality constraints around whole cones, then narrow BEL locks only for cells proven to require exact sites.

Next experiment direction:

- Keep payload-v3 reduced abort capture; do not reintroduce the wide optional datapath fields.
- Build a larger seed matrix with the reduced observer for baseline, CNTVALUEIN-only locks, CNTVALUEIN+LD-parent locks, and a soft-region/floorplan variant.
- For every failing run, bucket by abort reason/state before looking at SDF. Compare state-17 wrong-read failures separately from `CHECK_STARTING_DATA` aborts and state-0 startup aborts.
- Add the next observer only around the lane-0 `CHECK_STARTING_DATA` decision: capture the candidate window bounds and the last accepted/rejected `start_index_check`. That should explain why `dq_target_index=35` cannot find a valid `data_start_index` in the failing placement.
- Translate fixes in this order: calibration search robustness in RTL, generated-clock/reset/CDC constraints, soft region constraints for IDELAY programming plus calibration bookkeeping, and only then minimal LOC/BEL locks if a specific primitive/site remains causal across the matrix.

## Exact-Abort Seed3 Lock Matrix: 2026-05-27

This is the first clean same-RTL matrix after moving the abort snapshot to the actual `reset_from_calibrate <= 1` decision sites.

Setup commit sequence:

- `7276a90` adds exact calibration-abort observability.
- `9bbfaba` regenerates the seed3 CNTVALUEIN and CNTVALUEIN+LD-parent lock files from the exact-abort seed3 baseline placement.

Artifacts:

- hardware slice: `artifacts/hardware/exact_abort_seed3_lock_matrix.csv`
- canonical matrix: `artifacts/hardware/ddr3_causality_matrix.csv`
- hypothesis ledger: `artifacts/hardware/ddr3_hypothesis_ledger.csv`
- focused SDF metrics: `artifacts/sdf-metrics/exact-abort-seed3-lock-matrix/`
- baseline SDF/JSON: `result-cvc-sdf-seed3-exact-abort-baseline/`
- CNTVALUEIN-lock SDF/JSON: `result-cvc-sdf-seed3-exact-abort-idelay-control-locked/`
- CNTVALUEIN+LD-lock SDF/JSON: `result-cvc-sdf-seed3-exact-abort-idelay-control-full-locked/`

Hardware results:

| RTL/debug variant | seed | locks | pass | final state | BIST wrong reads | first abort |
| --- | ---: | --- | --- | ---: | ---: | --- |
| exact-abort | 3 | none | yes | 23 | 0 | none |
| exact-abort | 3 | CNTVALUEIN-only | yes | 23 | 0 | none |
| exact-abort | 3 | CNTVALUEIN + LD-parent | no | 0 | 0 | reason 2, lane 0, `CHECK_STARTING_DATA`, `start_index_check=48`, `dq_target_index=33`, `data_start_index=0`, write-late=1, read-early=0 |

Important observations:

- The exact-abort no-lock baseline passes. That means the exact snapshot implementation is less perturbing than the earlier reduced-v3 baseline failure.
- CNTVALUEIN-only regenerated locks also pass.
- CNTVALUEIN+LD-parent regenerated locks fail and now give an exact abort-site snapshot: `CHECK_STARTING_DATA` search exhaustion on lane 0, with no data or DQS tap mismatch.
- Therefore the current same-RTL cause/effect evidence is not “seed3 is bad” and not “all absolute locks help”. It is: adding the LD-parent lock perturbation changes the exact placed/routed implementation enough to make lane-0 data-alignment calibration exhaust its search.

Focused SDF metrics for the pass/pass/fail matrix show strict fail-slower candidates in the failing CNTVALUEIN+LD row:

| metric family | endpoint | fail-pass median delta | strict separation |
| --- | --- | ---: | ---: |
| DQS IDELAY CNTVALUEIN | lane1 dqs1 ctrl=4 | +514 ps | +287 ps |
| DQS IDELAY CNTVALUEIN | lane0 dqs0 ctrl=4 | +467 ps | +75 ps |
| clocking | all endpoints | +464.5 ps | +60 ps |
| reset release | all endpoints | +406 ps | +406 ps |
| DQ IDELAY CNTVALUEIN | lane1 dq9 ctrl=3 | +408 ps | +347 ps |
| IDELAY LD | lane0 dqs0 | +347 ps | +9 ps |

Interpretation:

- CE-002 is strengthened as a concrete hardware failure mode: the failing bitstream aborts exactly in lane-0 `CHECK_STARTING_DATA`, and the tap mismatch monitors stay clean.
- CE-001 remains relevant because the failing same-RTL row has slower IDELAY programming/control candidates, especially DQS CNTVALUEIN ctrl=4 and one LD endpoint. This does not yet prove direct tap-load corruption; it may be margin loss that later appears as calibration search exhaustion.
- CE-003 stays secondary for this row. Reset-release is slower by a strict +406 ps, and reset reassertion history is set after the abort, but the exact first cause observed by RTL is reason 2, not an unexplained startup state-0 return.
- SO-001 is again rejected as a final solution. CNTVALUEIN-only locks pass, but CNTVALUEIN+LD-parent locks fail under the same RTL/debug variant.

Next focused test:

Compare the exact-abort baseline pass against the exact-abort CNTVALUEIN+LD fail around the actual lane-0 `CHECK_STARTING_DATA` decision cone, not the whole design. The next observer should capture only candidate-match history and final comparison operands: which `start_index_check` values matched, final `read_lane_data_shifted`, final `write_pattern[31:0]`, and the lane-0 flags already captured here.
